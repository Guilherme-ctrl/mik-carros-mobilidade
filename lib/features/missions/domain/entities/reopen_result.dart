import 'package:equatable/equatable.dart';

// Resultado de reopen_request (20260824000004).
//
// Duas listas, e não um bool, porque a devolução dos carros é melhor esforço:
// encerrar solta a guarnição, e soltar faz a fila de cada carro avançar — na
// hora de reabrir, um deles pode já estar em outra missão. Quem reabriu precisa
// saber com quem ficou, senão sai achando que o time inteiro voltou.
class ReopenResult extends Equatable {
  final List<String> restored;
  final List<String> unavailable;

  const ReopenResult({this.restored = const [], this.unavailable = const []});

  factory ReopenResult.fromMap(Map<String, dynamic> map) => ReopenResult(
        restored: List<String>.from(
            (map['restored_car_numbers'] as List?) ?? const []),
        unavailable: List<String>.from(
            (map['unavailable_car_numbers'] as List?) ?? const []),
      );

  // A missão voltou para a fila de despacho em vez de recomeçar com alguém.
  bool get needsReassignment => restored.isEmpty;

  @override
  List<Object?> get props => [restored, unavailable];
}
