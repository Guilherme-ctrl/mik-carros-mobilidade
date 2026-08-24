import 'package:flutter_test/flutter_test.dart';
import 'package:carros_mik_dundee/features/car_chat/domain/entities/car_message.dart';

Map<String, dynamic> raw({String role = 'central_admin'}) => {
      'id': 'm1',
      'author_id': 'u1',
      'author_name': 'Gestor',
      'author_role': role,
      'content': 'Passa no posto',
      'created_at': '2026-08-24T13:00:00Z',
    };

void main() {
  group('CarMessage.fromMap', () {
    test('lê os campos do canal privado', () {
      final m = CarMessage.fromMap(raw());
      expect(m.id, 'm1');
      expect(m.authorName, 'Gestor');
      expect(m.content, 'Passa no posto');
      expect(m.createdAt.toUtc(), DateTime.utc(2026, 8, 24, 13));
    });

    // fromManager decide de que lado a bolha aparece. Se ele inverter, a
    // conversa inteira troca de lado na tela.
    test('fromManager é verdadeiro só para central_admin', () {
      expect(CarMessage.fromMap(raw(role: 'central_admin')).fromManager, isTrue);
      expect(CarMessage.fromMap(raw(role: 'driver')).fromManager, isFalse);
      expect(CarMessage.fromMap(raw(role: 'central_operator')).fromManager, isFalse);
    });

    // author_name e author_role são preenchidos por trigger, mas a coluna tem
    // DEFAULT '' — uma linha sem eles não pode derrubar a tela.
    test('tolera nome e papel ausentes', () {
      final m = CarMessage.fromMap({
        'id': 'm2',
        'author_id': 'u2',
        'author_name': null,
        'author_role': null,
        'content': 'oi',
        'created_at': '2026-08-24T13:00:00Z',
      });
      expect(m.authorName, 'Usuário');
      expect(m.fromManager, isFalse);
    });
  });
}
