import 'package:flutter_test/flutter_test.dart';
import 'package:carros_mik_dundee/features/missions/domain/entities/mission.dart';

void main() {
  group('CarStatus (per-car progress, ADR-3)', () {
    test('fromString parses all four in-flight values', () {
      expect(CarStatus.fromString('car_assigned'), CarStatus.carAssigned);
      expect(CarStatus.fromString('on_the_way'), CarStatus.onTheWay);
      expect(CarStatus.fromString('on_site'), CarStatus.onSite);
      expect(CarStatus.fromString('returning'), CarStatus.returning);
    });

    test('fromString rejects a request-level value (they moved to RequestStatus)', () {
      expect(() => CarStatus.fromString('completed'), throwsArgumentError);
    });

    test('nextDriverStatus walks the chain and stops at returning', () {
      expect(CarStatus.carAssigned.nextDriverStatus, CarStatus.onTheWay);
      expect(CarStatus.onTheWay.nextDriverStatus, CarStatus.onSite);
      expect(CarStatus.onSite.nextDriverStatus, CarStatus.returning);
      // FR6.1 — the step after "returning" is reporting an outcome, not
      // another status transition, so this is null by design (not a bug).
      expect(CarStatus.returning.nextDriverStatus, isNull);
    });

    test('supabaseValue round-trips through fromString', () {
      for (final s in CarStatus.values) {
        expect(CarStatus.fromString(s.supabaseValue), s);
      }
    });
  });

  group('RequestStatus (request-level, narrowed by ADR-3)', () {
    test('fromString parses the five surviving values', () {
      expect(RequestStatus.fromString('open'), RequestStatus.open);
      expect(RequestStatus.fromString('under_review'), RequestStatus.underReview);
      expect(RequestStatus.fromString('car_assigned'), RequestStatus.carAssigned);
      expect(RequestStatus.fromString('completed'), RequestStatus.completed);
      expect(RequestStatus.fromString('cancelled'), RequestStatus.cancelled);
    });

    test('fromString rejects a removed per-car value', () {
      expect(() => RequestStatus.fromString('on_the_way'), throwsArgumentError);
    });

    test('isTerminal is true only for completed/cancelled', () {
      expect(RequestStatus.completed.isTerminal, isTrue);
      expect(RequestStatus.cancelled.isTerminal, isTrue);
      expect(RequestStatus.open.isTerminal, isFalse);
      expect(RequestStatus.carAssigned.isTerminal, isFalse);
    });
  });

  group('CarSummary (FR3.3 — identification only, no location field exists)', () {
    test('fromMap parses number/pilot/copilot', () {
      final s = CarSummary.fromMap({
        'number': 'T-B',
        'pilot_name': 'Piloto B',
        'copilot_name': 'Copiloto B',
      });
      expect(s.carNumber, 'T-B');
      expect(s.pilotName, 'Piloto B');
      expect(s.copilotName, 'Copiloto B');
    });

    test('fromMap tolerates a null copilot', () {
      final s = CarSummary.fromMap({'number': 'T-A', 'pilot_name': 'Piloto A', 'copilot_name': null});
      expect(s.copilotName, isNull);
    });
  });

  group('Mission.fromMap (request_cars row joined to requests+leaders)', () {
    Map<String, dynamic> row({String? outcome, List<Map<String, dynamic>>? coAssigned}) => {
          'status': 'on_the_way',
          'outcome': outcome,
          'assigned_at': '2026-08-11T10:00:00Z',
          'requests': {
            'id': 'req-1',
            'event': 'Prova X',
            'stage': '1',
            'street': 'Rua A',
            'street_number': '10',
            'neighborhood': 'Centro',
            'objective': 'Achar o alvo',
            'maps_link': null,
            'notes': null,
            'status': 'car_assigned',
            'leaders': {'name': 'Líder', 'phone': '47900000000'},
          },
        };

    test('parses request-level and car-level fields into separate properties', () {
      final m = Mission.fromMap(row());
      expect(m.id, 'req-1');
      expect(m.requestStatus, RequestStatus.carAssigned);
      expect(m.ownStatus, CarStatus.onTheWay);
      expect(m.ownOutcome, isNull);
      expect(m.leaderName, 'Líder');
      expect(m.coAssignedCars, isEmpty);
    });

    test('parses a reported outcome', () {
      final m = Mission.fromMap(row(outcome: 'found'));
      expect(m.ownOutcome, RequestOutcome.found);
    });

    test('merges an externally-fetched co-assigned roster (FR3.3)', () {
      final roster = [
        const CarSummary(carNumber: 'T-B', pilotName: 'Piloto B'),
      ];
      final m = Mission.fromMap(row(), coAssignedCars: roster);
      expect(m.coAssignedCars, roster);
    });

    test('fullAddress composes street/number/neighborhood', () {
      final m = Mission.fromMap(row());
      expect(m.fullAddress, 'Rua A, 10 — Centro');
    });
  });

  // ── encerramento manual (20260824000002) ───────────────────────────────────
  //
  // close_request recusa enquanto qualquer carro ativo estiver sem desfecho.
  // allCarsReported é a cópia dessa regra que a tela consegue ler, e estes
  // testes existem para que as duas não se separem em silêncio.
  // Cidade e coordenadas (20260824000006). O destino da navegação deixou de ser
  // montado com "Blumenau" fixo no código.
  group('Mission — destino da navegação', () {
    Map<String, dynamic> row({String? city, num? lat, num? lon}) => {
          'status': 'car_assigned',
          'outcome': null,
          'assigned_at': '2026-08-24T10:00:00Z',
          'requests': {
            'id': 'r1',
            'event': 'Prova',
            'stage': '1',
            'street': 'Rua Itajaí',
            'street_number': '100',
            'neighborhood': 'Centro',
            'city': city,
            'latitude': lat,
            'longitude': lon,
            'objective': 'Obj',
            'maps_link': null,
            'notes': null,
            'status': 'car_assigned',
            'leaders': null,
          },
        };

    test('a cidade vem da solicitação, não do código', () {
      final m = Mission.fromMap(row(city: 'Gaspar'));
      expect(m.city, 'Gaspar');
      expect(m.navigationAddress, contains('Gaspar'));
      expect(m.navigationAddress, isNot(contains('Blumenau')));
    });

    // A regressão que este teste tranca: com a cidade fixa, uma missão em
    // Gaspar mandava o motorista para a Rua Itajaí DE BLUMENAU.
    test('linha sem cidade cai em Blumenau, e não em string vazia', () {
      expect(Mission.fromMap(row(city: null)).city, 'Blumenau');
    });

    test('coordenadas são reconhecidas quando existem', () {
      final m = Mission.fromMap(row(city: 'Blumenau', lat: -26.9194, lon: -49.0661));
      expect(m.hasCoordinates, isTrue);
      expect(m.latitude, closeTo(-26.9194, 0.0001));
    });

    test('endereço digitado à mão fica sem coordenada, e isso não é erro', () {
      final m = Mission.fromMap(row(city: 'Blumenau'));
      expect(m.hasCoordinates, isFalse);
      expect(m.latitude, isNull);
    });
  });

  group('Mission.allCarsReported / carsPendingOutcome', () {
    Mission build({
      RequestOutcome? own,
      List<CarSummary> roster = const [],
    }) =>
        Mission(
          id: 'req-1',
          event: 'Prova',
          stage: '1',
          street: 'Rua',
          streetNumber: '1',
          neighborhood: 'Centro',
          objective: 'Obj',
          requestStatus: RequestStatus.carAssigned,
          ownStatus: CarStatus.carAssigned,
          ownOutcome: own,
          coAssignedCars: roster,
          createdAt: DateTime.utc(2026, 8, 24),
        );

    const reported = CarSummary(
      carNumber: 'T-B',
      pilotName: 'Piloto B',
      outcome: RequestOutcome.notFound,
    );
    const silent = CarSummary(carNumber: 'T-C', pilotName: 'Piloto C');

    test('carro sozinho: basta o próprio desfecho', () {
      expect(build(own: null).allCarsReported, isFalse);
      expect(build(own: RequestOutcome.found).allCarsReported, isTrue);
    });

    test('não é suficiente eu ter reportado se outro carro não reportou', () {
      final m = build(own: RequestOutcome.found, roster: const [reported, silent]);
      expect(m.allCarsReported, isFalse);
      expect(m.carsPendingOutcome, ['T-C']);
    });

    test('todos reportaram: pronto para encerrar, nada pendente', () {
      final m = build(own: RequestOutcome.found, roster: const [reported]);
      expect(m.allCarsReported, isTrue);
      expect(m.carsPendingOutcome, isEmpty);
    });
  });

  group('CarSummary.fromMap', () {
    test('lê o desfecho do companheiro de missão', () {
      final c = CarSummary.fromMap({
        'number': 'T-B',
        'pilot_name': 'Piloto B',
        'copilot_name': null,
        'outcome': 'found',
      });
      expect(c.outcome, RequestOutcome.found);
    });

    test('ausência de desfecho vira null, não erro', () {
      final c = CarSummary.fromMap({
        'number': 'T-B',
        'pilot_name': 'Piloto B',
        'copilot_name': null,
        'outcome': null,
      });
      expect(c.outcome, isNull);
    });
  });
}
