import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MissionsRemoteDatasource {
  Future<String?> getDriverCarId();
  // The car's CURRENT assignment (request_cars.removed_at IS NULL AND
  // is_current) — never a queued one, which also has removed_at IS NULL.
  Future<List<Map<String, dynamic>>> getMissionsForCar(String carId);
  // Today's already-closed assignments this car actually served (removed_at set,
  // is_current, mission reached its natural closure — NOT a Mesa Central
  // removal/transfer, per request_cars.removal_reason IS NULL, matching U1's
  // ADR-2/ADR-5 semantics).
  Future<List<Map<String, dynamic>>> getMissionsHistoryForCar(String carId);
  // FR3.3 — identification-only roster of the mission's other assigned cars.
  Future<List<Map<String, dynamic>>> getCoAssignedCars(String requestId, String excludingCarId);
  Future<void> updateCarStatus(String requestId, String carId, String newStatus);
  Future<void> reportOutcome(String requestId, String carId, String outcome);
  Future<void> closeRequest(String requestId);
  Future<Map<String, dynamic>> reopenRequest(String requestId);
  // Emits null whenever a DB change occurs — cubit uses it as a reload trigger
  Stream<void> watchMissionsForCar(String carId);

  // US4/FR5 — the driver's reduced queue projection. Returns the single row of
  // get_car_queue_summary as {total_count, items}.
  Future<Map<String, dynamic>> getCarQueueSummary(String carId);
  // Emits null whenever this car's queue may have changed — same reload-trigger
  // shape as watchMissionsForCar.
  Stream<void> watchQueueCount(String carId);

  Future<List<Map<String, dynamic>>> getComments(String requestId);
  Future<void> addComment(String requestId, String content);
  Stream<void> watchComments(String requestId);
}

class MissionsRemoteDatasourceImpl implements MissionsRemoteDatasource {
  final SupabaseClient _client;
  MissionsRemoteDatasourceImpl() : _client = Supabase.instance.client;

  // T10.16 — cache key scoped per user so multi-driver devices work correctly
  String _prefKey(String userId) => 'driver_car_id_$userId';

  static const _missionSelect =
      '*, requests(*, leaders(name, phone))';

  @override
  Future<String?> getDriverCarId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = _prefKey(user.id);

    // O cache era consultado PRIMEIRO e nunca invalidado ("se tem cache,
    // devolve"), então trocar o motorista de carro deixava o app preso ao carro
    // antigo para sempre. Medido no Sentry (FLUTTER-D): 5.924 eventos de
    // "Forbidden: car ... does not belong to current user" vindos de UM
    // aparelho, entre 25 e 27/07 — cada atualização de localização falhando.
    //
    // Agora a rede manda e o cache é plano B. É para isso que ele serve: o
    // motorista abrir o app numa área sem sinal e ainda saber qual é o carro
    // dele. Não para congelar uma resposta antiga.
    try {
      final row = await _client
          .from('cars')
          .select('id')
          .eq('driver_user_id', user.id)
          .maybeSingle();

      if (row == null) {
        // Ficou sem carro. O cache NÃO pode sobreviver a isto — é exatamente o
        // estado que produzia o erro em looping.
        await prefs.remove(key);
        return null;
      }

      final carId = row['id'] as String;
      await prefs.setString(key, carId);
      return carId;
    } catch (_) {
      return prefs.getString(key);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMissionsForCar(String carId) async {
    // U1 (ADR-1): request_cars is the source of truth for "which missions is
    // this car currently on" — replaces the old .eq('assigned_car_id', carId)
    // read against requests directly.
    //
    // is_current = true is NOT redundant with removed_at IS NULL (FR5.2/FR5.5).
    // Before the fila-missoes intent a car had at most ONE removed_at IS NULL
    // row, so the null check alone identified the current mission. U1 broke that
    // assumption: a car now has 1 current + N QUEUED rows, all with
    // removed_at IS NULL. Without this filter a queued row could come back here
    // — and, because the order is assigned_at DESC, a mission queued AFTER the
    // current one sorts FIRST, so MissionsCubit's `missions.firstOrNull` would
    // hand the driver a queued mission rendered as the active one, with the full
    // _missionSelect payload: address, objective, and the Líder's name/phone.
    // FR5.2/FR5.5 say the driver gets a count and nothing else until a mission
    // is promoted. Same principle as U1's ADR-6 ("progress/outcome only on the
    // current row"), applied to the READ side.
    final rows = await _client
        .from('request_cars')
        .select(_missionSelect)
        .eq('car_id', carId)
        .isFilter('removed_at', null)
        .eq('is_current', true)
        .order('assigned_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getMissionsHistoryForCar(String carId) async {
    // removal_reason IS NULL distinguishes "closed because the mission ended"
    // (ADR-5's MissionClosureTrigger) from an explicit 'removed'/'transferred'
    // action — a driver's history should show missions they actually saw
    // through, not ones Mesa Central pulled them off of.
    //
    // is_current = true is required for the same reason as in getMissionsForCar,
    // one step later in the lifecycle. fn_mission_closure (U1, Algorithm 3) sets
    // removed_at on ALL of the mission's still-open rows without setting
    // removal_reason — including this car's QUEUED rows, which never became
    // current and which the driver never worked. Those land with exactly the
    // shape this query matches (removed_at set, removal_reason NULL), so without
    // the filter the driver's history would list missions they never took.
    // is_current never regresses (domain-entities.md), so it stays true on a row
    // that was genuinely served and false on one that was only ever queued.
    final rows = await _client
        .from('request_cars')
        .select(_missionSelect)
        .eq('car_id', carId)
        .not('removed_at', 'is', null)
        .isFilter('removal_reason', null)
        .eq('is_current', true)
        .order('assigned_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getCoAssignedCars(
      String requestId, String excludingCarId) async {
    // Identification fields only (FR3.3) — no car_locations join, ever.
    //
    // outcome entra na projeção porque o encerramento passou a ser manual
    // (20260824000002): a tela precisa saber se TODOS já reportaram antes de
    // oferecer o botão de encerrar, e close_request recusa enquanto faltar
    // alguém. Não é dado sensível — é o desfecho de um carro que o motorista
    // já vê listado como companheiro de missão.
    //
    // is_current = true é correção, não filtro novo: sem ele esta consulta
    // devolvia também os carros que têm esta missão apenas NA FILA, que
    // apareciam na tela como se estivessem na missão junto. Eles não estão.
    final rows = await _client
        .from('request_cars')
        .select('outcome, cars(number, pilot_name, copilot_name)')
        .eq('request_id', requestId)
        .neq('car_id', excludingCarId)
        .eq('is_current', true)
        .isFilter('removed_at', null);
    return List<Map<String, dynamic>>.from(
      (rows as List).map((r) {
        final row = r as Map<String, dynamic>;
        return <String, dynamic>{
          ...row['cars'] as Map<String, dynamic>,
          'outcome': row['outcome'],
        };
      }),
    );
  }

  @override
  Future<void> updateCarStatus(String requestId, String carId, String newStatus) async {
    await _client.rpc('update_car_status', params: {
      'p_request_id': requestId,
      'p_car_id': carId,
      'p_new_status': newStatus,
    });
  }

  @override
  Future<void> closeRequest(String requestId) async {
    // Encerramento manual (20260824000002). A autorização (Mesa Central, Líder
    // ou chefe de carro) e a exigência de que todos tenham reportado vivem no
    // RPC, não aqui — o app só precisa reagir à mensagem de erro.
    await _client.rpc('close_request', params: {'p_request_id': requestId});
  }

  @override
  Future<Map<String, dynamic>> reopenRequest(String requestId) async {
    // RETURNS TABLE chega como lista de linhas; esta função devolve uma só.
    final rows = await _client.rpc('reopen_request', params: {'p_request_id': requestId});
    final list = rows as List?;
    if (list == null || list.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(list.first as Map);
  }

  @override
  Future<void> reportOutcome(String requestId, String carId, String outcome) async {
    // ADR-7 — symmetric for found/not_found, replaces the old edge-function
    // (found) + bare table update (not_found) pair.
    await _client.rpc('report_car_outcome', params: {
      'p_request_id': requestId,
      'p_car_id': carId,
      'p_outcome': outcome,
    });
  }

  @override
  Stream<void> watchMissionsForCar(String carId) {
    // Unfiltered on request_cars, same "re-fetch on any tick" pattern the old
    // requests-table subscription used — deliberately not optimized further
    // in this intent (component-dependency.md notes this is chatty by design
    // choice, not oversight).
    final controller = StreamController<void>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('driver-missions-$carId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'request_cars',
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> getCarQueueSummary(String carId) async {
    // FILA-ADR-5 — this RPC is the ONLY sanctioned read path for the driver's
    // queue, and U1's code-summary says so in as many words. The live policy
    // request_cars_select_driver_shared WOULD let this app select the queued
    // rows (and embed requests(*) into them) directly; the reduced projection
    // is a UX contract enforced by the function, not by RLS, so a direct query
    // here would silently bypass FR5.2/FR5.5 while still "working".
    final result = await _client.rpc('get_car_queue_summary', params: {
      'p_car_id': carId,
    });

    // RETURNS TABLE(total_count INT, items JSONB) — PostgREST sends a
    // one-element array, the same shape the web client unwraps from
    // get_fleet_queue_overview.
    final rows = List<Map<String, dynamic>>.from(result as List);
    if (rows.isEmpty) {
      // The function aggregates (count + jsonb_agg over a CTE), so it always
      // yields exactly one row — an empty response means the contract moved.
      // Throw rather than synthesise a zero count, which would be
      // indistinguishable from a genuinely empty queue and would hide the
      // breakage behind a correct-looking UI.
      throw StateError('get_car_queue_summary não retornou nenhuma linha');
    }
    return rows.first;
  }

  @override
  Stream<void> watchQueueCount(String carId) {
    // Filtered by car_id, unlike watchMissionsForCar: that one is deliberately
    // chatty (a documented choice), but nothing here needs another car's ticks.
    //
    // request_cars ONLY — deliberately not request_priorities, even though a
    // Mesa Central re-prioritisation reorders this queue. Two independent
    // reasons, both structural: request_priorities is not in the
    // supabase_realtime publication, and it has no driver SELECT policy at all
    // (FILA-ADR-2 keeps it central-only so FR2.3.1 holds by construction), so
    // Realtime would filter those events out for this subscriber anyway.
    // Subscribing to it would be a dead callback that merely looks correct.
    // Consequence, and it is a real one: a priority-only reorder does not push
    // to the driver. It cannot change totalCount (no row enters or leaves the
    // queue), so the badge stays accurate — only the ORDER inside an
    // already-expanded QueueSummaryExpansion can be briefly stale, until the
    // next request_cars change. Flagged in code-summary.md for U1.
    final controller = StreamController<void>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('driver-queue-$carId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'request_cars',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'car_id',
            value: carId,
          ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String requestId) async {
    final rows = await _client
        .from('request_comments')
        .select('id, request_id, author_id, author_name, content, created_at')
        .eq('request_id', requestId)
        .order('created_at', ascending: true)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<void> addComment(String requestId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Não autenticado');
    await _client.from('request_comments').insert({
      'request_id': requestId,
      'author_id': user.id,
      'content': content,
    });
  }

  @override
  Stream<void> watchComments(String requestId) {
    final controller = StreamController<void>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('comments-$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'request_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: requestId,
          ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}
