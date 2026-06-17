import 'package:carros_mik_dundee/features/missions/domain/entities/mission.dart';

String formatRequestForWhatsApp(Mission mission) {
  final leaderName  = mission.leaderName  ?? 'Não informado';
  final leaderPhone = mission.leaderPhone ?? 'Não informado';
  final mapsLink    = (mission.mapsLink != null && mission.mapsLink!.isNotEmpty)
      ? mission.mapsLink!
      : 'Não informado';

  return '''Prova: ${mission.event}

Nome Líder: $leaderName
Telefone: $leaderPhone

Endereço: ${mission.street}, ${mission.streetNumber} - ${mission.neighborhood}
Maps: $mapsLink

Objetivo: ${mission.objective}''';
}
