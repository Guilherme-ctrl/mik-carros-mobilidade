import 'package:equatable/equatable.dart';

// Mission priority (request_priority enum, U1/FILA-ADR-2). Modelled as an enum
// for the same reason RequestStatus/CarStatus are: it is a closed DB enum, and
// the widget layer needs a display label, not a raw wire string.
//
// A driver can never READ request_priorities directly — the table has a
// central-only SELECT policy and no driver policy at all (FILA-ADR-2, so that
// FR2.3.1 holds by construction). This value reaches the app exclusively as a
// projected field of get_car_queue_summary, which is SECURITY DEFINER.
enum QueuePriority {
  baixa,
  normal,
  alta;

  static QueuePriority fromString(String s) => switch (s) {
        'baixa'  => baixa,
        'normal' => normal,
        'alta'   => alta,
        _        => throw ArgumentError('Prioridade desconhecida: $s'),
      };

  String get supabaseValue => switch (this) {
        baixa  => 'baixa',
        normal => 'normal',
        alta   => 'alta',
      };

  // PT-BR display label, matching the web dashboard's QueuePriorityRow options
  // so Mesa Central and the driver read the same word for the same value.
  String get label => switch (this) {
        baixa  => 'Baixa',
        normal => 'Normal',
        alta   => 'Alta',
      };
}

// One queued (not-yet-current) mission, as the driver is allowed to see it.
//
// FILA-ADR-5 / FR5.5 / FR5.6 — this class has exactly two fields BY DESIGN, and
// that is the privacy boundary, not an unfinished model. get_car_queue_summary
// projects {request_id, priority} and deliberately nothing else: no event name,
// no address, no objective, no Líder. Adding a field here would be inventing
// data the RPC never returns; the correct place to widen the projection, if a
// requirement ever calls for it, is the RPC — not this class.
class QueueSummaryItemData extends Equatable {
  // Identity/key only — never rendered to the driver. It is the request's id,
  // which on its own reveals nothing.
  final String requestId;
  final QueuePriority priority;

  const QueueSummaryItemData({
    required this.requestId,
    required this.priority,
  });

  factory QueueSummaryItemData.fromMap(Map<String, dynamic> map) => QueueSummaryItemData(
        requestId: map['request_id'] as String,
        priority:  QueuePriority.fromString(map['priority'] as String),
      );

  @override
  List<Object?> get props => [requestId, priority];
}

// The driver-facing queue picture for one car: how many missions are waiting
// behind the current one, plus the minimal per-item summary.
//
// [items] arrives already ordered by the RPC (priority DESC, request created_at
// ASC — the ONE canonical queue ordering, shared verbatim with the promotion
// algorithm so the driver never sees a "next" different from the one the system
// will actually promote). The client must not re-sort it.
class QueueSummary extends Equatable {
  // Number of QUEUED rows — the current mission is not counted.
  final int totalCount;
  final List<QueueSummaryItemData> items;

  const QueueSummary({
    required this.totalCount,
    required this.items,
  });

  factory QueueSummary.fromMap(Map<String, dynamic> map) => QueueSummary(
        totalCount: map['total_count'] as int,
        items: ((map['items'] as List?) ?? const [])
            .map((e) => QueueSummaryItemData.fromMap(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  // O badge aparece a partir de UMA missão na fila.
  //
  // Era >= 2, por uma leitura literal do enunciado aprovado (Q8=B). Na prática
  // isso criava o caso exato que a feature existe para evitar: com uma única
  // missão enfileirada o motorista tem mais trabalho pela frente e a tela não
  // dá sinal nenhum. Corrigido em 2026-08-24 a pedido direto do dono do
  // produto — o objetivo é "o motorista sabe que terá mais missões", e uma
  // fila de uma missão já é mais missões.
  //
  // Lives on the entity rather than inline in QueueBadge so the threshold is
  // covered by a unit test: this package has no widget tests, so a rule left
  // inside the widget would ship unverified.
  bool get showsBadge => totalCount >= 1;

  @override
  List<Object?> get props => [totalCount, items];
}
