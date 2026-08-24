import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:carros_mik_dundee/features/missions/data/datasources/missions_remote_datasource.dart';
import 'package:carros_mik_dundee/features/missions/data/repositories/missions_repository_impl.dart';
import 'package:carros_mik_dundee/features/missions/domain/entities/queue_summary.dart';
import 'package:carros_mik_dundee/features/missions/domain/entities/reopen_result.dart';

class MockDatasource extends Mock implements MissionsRemoteDatasource {}

void main() {
  late MockDatasource datasource;
  late MissionsRepositoryImpl repository;

  const carId = 'car-a';

  Map<String, dynamic> missionRow({String requestId = 'req-1', String status = 'car_assigned'}) => {
        'status': status,
        'outcome': null,
        'assigned_at': '2026-08-11T10:00:00Z',
        'requests': {
          'id': requestId,
          'event': 'Prova',
          'stage': '1',
          'street': 'Rua',
          'street_number': '1',
          'neighborhood': 'Centro',
          'objective': 'Obj',
          'maps_link': null,
          'notes': null,
          'status': 'car_assigned',
          'leaders': null,
        },
      };

  setUp(() {
    datasource = MockDatasource();
    repository = MissionsRepositoryImpl(datasource);
  });

  group('getMissionsForCar', () {
    test('hydrates each row with its co-assigned roster (FR3.3)', () async {
      when(() => datasource.getMissionsForCar(carId))
          .thenAnswer((_) async => [missionRow()]);
      when(() => datasource.getCoAssignedCars('req-1', carId)).thenAnswer(
        (_) async => [
          {'number': 'T-B', 'pilot_name': 'Piloto B', 'copilot_name': null},
        ],
      );

      final result = await repository.getMissionsForCar(carId);

      expect(result.isRight(), isTrue);
      final missions = result.getOrElse(() => []);
      expect(missions, hasLength(1));
      expect(missions.first.coAssignedCars, hasLength(1));
      expect(missions.first.coAssignedCars.first.carNumber, 'T-B');
      verify(() => datasource.getCoAssignedCars('req-1', carId)).called(1);
    });

    test('a datasource exception becomes a Left(ServerFailure), not a thrown error', () async {
      when(() => datasource.getMissionsForCar(carId)).thenThrow(Exception('network down'));

      final result = await repository.getMissionsForCar(carId);

      expect(result.isLeft(), isTrue);
    });
  });

  group('getMissionsHistoryForCar', () {
    test('does not fetch a roster for historical rows (not displayed there)', () async {
      when(() => datasource.getMissionsHistoryForCar(carId))
          .thenAnswer((_) async => [missionRow()]);

      final result = await repository.getMissionsHistoryForCar(carId);

      expect(result.isRight(), isTrue);
      verifyNever(() => datasource.getCoAssignedCars(any(), any()));
    });
  });

  group('reportOutcome / updateCarStatus (ADR-7 / ADR-3)', () {
    test('reportOutcome delegates with (requestId, carId, outcome)', () async {
      when(() => datasource.reportOutcome('req-1', carId, 'found'))
          .thenAnswer((_) async {});

      final result = await repository.reportOutcome('req-1', carId, 'found');

      expect(result, const Right<Object, void>(null));
      verify(() => datasource.reportOutcome('req-1', carId, 'found')).called(1);
    });

    // Encerramento manual (20260824000002) — o passo que "Achei"/"Não achei"
    // deixaram de fazer.
    test('closeRequest delegates with the request id', () async {
      when(() => datasource.closeRequest('req-1')).thenAnswer((_) async {});

      final result = await repository.closeRequest('req-1');

      expect(result, const Right<Object, void>(null));
      verify(() => datasource.closeRequest('req-1')).called(1);
    });

    // A recusa mais comum do RPC ("ainda falta o desfecho do carro X") chega
    // como exceção e precisa virar Left, não estourar na tela.
    test('closeRequest failure surfaces as Left', () async {
      when(() => datasource.closeRequest('req-1'))
          .thenThrow(Exception('Ainda falta o desfecho do(s) carro(s): T-B'));

      final result = await repository.closeRequest('req-1');

      expect(result.isLeft(), isTrue);
    });

    // Reabertura (20260824000004). O RETURNS TABLE do RPC chega como linha, e a
    // conversão para ReopenResult é o que a tela usa para dizer quais carros
    // voltaram — errar aqui faz o motorista achar que a guarnição inteira voltou.
    test('reopenRequest converte a linha do RPC em ReopenResult', () async {
      when(() => datasource.reopenRequest('req-1')).thenAnswer((_) async => {
            'restored_car_numbers': ['R-B'],
            'unavailable_car_numbers': ['R-A'],
          });

      final result = await repository.reopenRequest('req-1');

      final value = result.getOrElse(() => const ReopenResult());
      expect(value.restored, ['R-B']);
      expect(value.unavailable, ['R-A']);
      expect(value.needsReassignment, isFalse);
    });

    test('reopenRequest sem carro devolvido pede reatribuição', () async {
      when(() => datasource.reopenRequest('req-1')).thenAnswer((_) async => {
            'restored_car_numbers': <String>[],
            'unavailable_car_numbers': ['R-A'],
          });

      final result = await repository.reopenRequest('req-1');

      expect(result.getOrElse(() => const ReopenResult()).needsReassignment, isTrue);
    });

    test('reopenRequest failure surfaces as Left', () async {
      when(() => datasource.reopenRequest('req-1'))
          .thenThrow(Exception('Só é possível reabrir uma missão encerrada'));

      final result = await repository.reopenRequest('req-1');

      expect(result.isLeft(), isTrue);
    });

    test('updateCarStatus failure surfaces as Left', () async {
      when(() => datasource.updateCarStatus('req-1', carId, 'on_the_way'))
          .thenThrow(Exception('invalid transition'));

      final result = await repository.updateCarStatus('req-1', carId, 'on_the_way');

      expect(result.isLeft(), isTrue);
    });
  });

  group('watchActiveMission (debt #44 — Either-wrapped stream)', () {
    test('maps a change signal to Right(Mission) via a fresh fetch', () async {
      when(() => datasource.watchMissionsForCar(carId))
          .thenAnswer((_) => Stream.value(null));
      when(() => datasource.getMissionsForCar(carId))
          .thenAnswer((_) async => [missionRow()]);
      when(() => datasource.getCoAssignedCars(any(), any())).thenAnswer((_) async => []);

      final emitted = await repository.watchActiveMission(carId).first;

      expect(emitted.isRight(), isTrue);
      expect(emitted.getOrElse(() => null)?.id, 'req-1');
    });

    test('a stream error is wrapped as Left, never rethrown to the caller', () async {
      when(() => datasource.watchMissionsForCar(carId))
          .thenAnswer((_) => Stream.error(Exception('realtime dropped')));

      final emitted = await repository.watchActiveMission(carId).first;

      expect(emitted.isLeft(), isTrue);
    });
  });

  group('watchQueueCount (US4/FR5 — FILA-ADR-5 reduced projection)', () {
    Map<String, dynamic> queueSummaryRow({int totalCount = 1}) => {
          'total_count': totalCount,
          'items': [
            {'request_id': 'req-9', 'priority': 'alta'},
          ],
        };

    test('seeds an initial value without waiting for a Realtime tick (FR5.3)', () async {
      // No emission on the watch stream at all — the seed fetch on listen is
      // what must produce the first value, not the first change signal.
      when(() => datasource.watchQueueCount(carId))
          .thenAnswer((_) => const Stream<void>.empty());
      when(() => datasource.getCarQueueSummary(carId))
          .thenAnswer((_) async => queueSummaryRow(totalCount: 3));

      final emitted = await repository.watchQueueCount(carId).first;

      expect(emitted.isRight(), isTrue);
      expect(emitted.getOrElse(() => const QueueSummary(totalCount: 0, items: [])).totalCount, 3);
      verify(() => datasource.getCarQueueSummary(carId)).called(1);
    });

    test('maps a change signal to a fresh Right(QueueSummary)', () async {
      when(() => datasource.watchQueueCount(carId)).thenAnswer((_) => Stream.value(null));
      when(() => datasource.getCarQueueSummary(carId))
          .thenAnswer((_) async => queueSummaryRow(totalCount: 2));

      // .skip(1): the first emission is the seed (see test above); this test
      // is about the SECOND emission, driven by the change signal.
      final emitted = await repository.watchQueueCount(carId).skip(1).first;

      expect(emitted.isRight(), isTrue);
      final summary = emitted.getOrElse(() => const QueueSummary(totalCount: 0, items: []));
      expect(summary.totalCount, 2);
      expect(summary.items.single.requestId, 'req-9');
      expect(summary.items.single.priority, QueuePriority.alta);
    });

    test('a datasource RPC failure is wrapped as Left, never rethrown', () async {
      when(() => datasource.watchQueueCount(carId))
          .thenAnswer((_) => const Stream<void>.empty());
      when(() => datasource.getCarQueueSummary(carId))
          .thenThrow(Exception('rpc get_car_queue_summary failed'));

      final emitted = await repository.watchQueueCount(carId).first;

      expect(emitted.isLeft(), isTrue);
    });

    test('a Realtime stream error is wrapped as Left, not rethrown to the caller', () async {
      when(() => datasource.watchQueueCount(carId))
          .thenAnswer((_) => Stream.error(Exception('realtime dropped')));
      when(() => datasource.getCarQueueSummary(carId))
          .thenAnswer((_) async => queueSummaryRow());

      // Skip the seed (Right) — this test targets the error the *change*
      // signal itself carries, not the initial fetch.
      final emitted = await repository.watchQueueCount(carId).skip(1).first;

      expect(emitted.isLeft(), isTrue);
    });
  });
}
