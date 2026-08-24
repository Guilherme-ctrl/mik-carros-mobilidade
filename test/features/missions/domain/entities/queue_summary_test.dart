import 'package:flutter_test/flutter_test.dart';
import 'package:carros_mik_dundee/features/missions/domain/entities/queue_summary.dart';

void main() {
  group('QueuePriority', () {
    test('fromString parses all three levels', () {
      expect(QueuePriority.fromString('baixa'), QueuePriority.baixa);
      expect(QueuePriority.fromString('normal'), QueuePriority.normal);
      expect(QueuePriority.fromString('alta'), QueuePriority.alta);
    });

    test('fromString rejects an unknown value', () {
      expect(() => QueuePriority.fromString('urgente'), throwsArgumentError);
    });

    test('supabaseValue round-trips through fromString', () {
      for (final p in QueuePriority.values) {
        expect(QueuePriority.fromString(p.supabaseValue), p);
      }
    });
  });

  group('QueueSummaryItemData.fromMap (FILA-ADR-5 — reduced projection)', () {
    test('maps requestId and priority from get_car_queue_summary shape', () {
      final item = QueueSummaryItemData.fromMap({
        'request_id': 'req-1',
        'priority': 'alta',
      });

      expect(item.requestId, 'req-1');
      expect(item.priority, QueuePriority.alta);
    });

    // The point of this class is what it does NOT carry — a stray `label`,
    // `event`, or `address` key in the map must never surface as a field, even
    // if a future RPC change accidentally adds one to the payload.
    test('ignores any extra keys the map might carry — no label/event/address field exists', () {
      final item = QueueSummaryItemData.fromMap({
        'request_id': 'req-2',
        'priority': 'normal',
        'label': 'Prova de Rally',
        'event': 'Rally', 'address': 'Rua X',
      });

      expect(item.requestId, 'req-2');
      expect(item.priority, QueuePriority.normal);
      // No `label`/`event`/`address` getter exists on QueueSummaryItemData at
      // all — this is a structural guarantee, not just a runtime assertion.
      // The props list below is the closest thing to a runtime witness: only
      // requestId/priority ever participate in equality.
      expect(item.props, [item.requestId, item.priority]);
    });
  });

  group('QueueSummary.fromMap', () {
    test('maps totalCount and items, preserving RPC order', () {
      final summary = QueueSummary.fromMap({
        'total_count': 2,
        'items': [
          {'request_id': 'req-1', 'priority': 'alta'},
          {'request_id': 'req-2', 'priority': 'baixa'},
        ],
      });

      expect(summary.totalCount, 2);
      expect(summary.items, hasLength(2));
      expect(summary.items[0].requestId, 'req-1');
      expect(summary.items[1].requestId, 'req-2');
    });

    test('tolerates a null items list (car with an empty queue)', () {
      final summary = QueueSummary.fromMap({'total_count': 0, 'items': null});

      expect(summary.totalCount, 0);
      expect(summary.items, isEmpty);
    });
  });

  group('QueueSummary.showsBadge (FR5.1/FR5.4)', () {
    test('is false with zero queued missions', () {
      expect(const QueueSummary(totalCount: 0, items: []).showsBadge, isFalse);
    });

    // Limiar baixado de 2 para 1 em 2026-08-24: uma única missão na fila também
    // precisa avisar. Este caso é o que a mudança inverteu — se ele voltar a
    // esperar isFalse, o limiar regrediu.
    test('is true with exactly one queued mission', () {
      expect(const QueueSummary(totalCount: 1, items: []).showsBadge, isTrue);
    });

    test('is true from two queued missions up', () {
      expect(const QueueSummary(totalCount: 2, items: []).showsBadge, isTrue);
      expect(const QueueSummary(totalCount: 5, items: []).showsBadge, isTrue);
    });
  });
}
