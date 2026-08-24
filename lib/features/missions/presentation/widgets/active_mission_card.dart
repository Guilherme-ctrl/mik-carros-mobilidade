import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';
import 'close_mission_button.dart';
import 'comments_section.dart';
import 'mission_action_button.dart';
import 'outcome_buttons.dart';
import 'queue_badge.dart';
import 'package:carros_mik_dundee/shared/widgets/whatsapp_share_button.dart';

class ActiveMissionCard extends StatelessWidget {
  final Mission mission;
  // The DRIVER'S car, for QueueBadge. Not derivable from [mission]: a mission
  // can be served by several cars, so it has no single carId to read.
  final String carId;

  const ActiveMissionCard({
    super.key,
    required this.mission,
    required this.carId,
  });

  Future<void> _openMaps() async {
    if (mission.mapsLink != null && mission.mapsLink!.isNotEmpty) {
      final uri = Uri.parse(mission.mapsLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        return;
      }
    }

    // A coordenada ganha do texto quando existe: navegar por ponto exato não
    // depende do app de mapas acertar a interpretação do endereço.
    //
    // Sem ela, cai no texto — que AGORA carrega a cidade de verdade. Antes esta
    // linha colava ", Blumenau, SC" fixo, e como a gincana também acontece em
    // Gaspar, Indaial, Timbó e Pomerode, o motorista era mandado para a rua de
    // mesmo nome em Blumenau.
    final dest = mission.hasCoordinates
        ? '${mission.latitude},${mission.longitude}'
        : Uri.encodeComponent(mission.navigationAddress);

    final Uri nativeUri;
    if (Platform.isAndroid) {
      nativeUri = Uri.parse('google.navigation:q=$dest&mode=d');
    } else {
      nativeUri = Uri.parse('comgooglemaps://?daddr=$dest&directionsmode=driving');
    }

    if (await canLaunchUrl(nativeUri)) {
      await launchUrl(nativeUri);
      return;
    }

    if (Platform.isIOS) {
      final appleMaps = Uri.parse('http://maps.apple.com/?daddr=$dest&dirflg=d');
      if (await canLaunchUrl(appleMaps)) {
        await launchUrl(appleMaps);
        return;
      }
    }

    final fallback = Uri.parse('https://maps.google.com/maps?daddr=$dest');
    await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.s4),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mission.event,
                    style: tt.titleLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                _StatusChip(mission.ownStatus),
                if (mission.ownOutcome != null) ...[
                  const SizedBox(width: AppSpacing.s1),
                  OutcomeBadge(mission.ownOutcome!),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              'Prova ${mission.stage}',
              style: tt.bodySmall,
            ),
            // US4/FR5 — sits directly under the header line, next to the status
            // chip. Renders nothing at all when the queue has fewer than two
            // missions, or when the queue read fails, so it takes no vertical
            // space in the common case.
            QueueBadge(carId: carId),
            if (mission.coAssignedCars.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s2),
              CoAssignedCarsRoster(cars: mission.coAssignedCars),
            ],
            const SizedBox(height: AppSpacing.s4),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.s4),

            _Field(label: 'Endereço', value: mission.fullAddress),
            const SizedBox(height: AppSpacing.s2),
            _Field(label: 'Objetivo', value: mission.objective),
            if (mission.notes != null) ...[
              const SizedBox(height: AppSpacing.s2),
              _Field(label: 'Observações', value: mission.notes!),
            ],
            if (mission.leaderName != null) ...[
              const SizedBox(height: AppSpacing.s2),
              _Field(
                label: 'Líder',
                value: [
                  mission.leaderName!,
                  if (mission.leaderPhone != null) mission.leaderPhone!,
                ].join(' · '),
              ),
            ],
            const SizedBox(height: AppSpacing.s4),

            OutlinedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Abrir no Maps'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),

            WhatsAppShareButton(mission: mission),
            const SizedBox(height: AppSpacing.s3),

            if (mission.leaderPhone != null) ...[
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('tel:${mission.leaderPhone}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Ligar para Líder'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],

            MissionActionButton(mission: mission),
            if (mission.ownOutcome != null) ...[
              // Desde 20260824000002 reportar não encerra mais. Este bloco
              // deixou de ser um estado final e virou um estado de ESPERA: o
              // desfecho está registrado, a missão continua aberta, e o
              // encerramento é o botão abaixo.
              const SizedBox(height: AppSpacing.s3),
              _CompletionMessage(found: mission.ownOutcome == RequestOutcome.found),
              const SizedBox(height: AppSpacing.s2),
              // report_car_outcome passou a aceitar sobrescrita enquanto a
              // missão está aberta, então um "Não achei" por engano tem
              // conserto — e precisa ter, já que a confirmação agora protege o
              // encerramento, não o desfecho.
              OutcomeButtons(mission: mission),
              const SizedBox(height: AppSpacing.s3),
              CloseMissionButton(mission: mission),
            ] else ...[
              const SizedBox(height: AppSpacing.s3),
              OutcomeButtons(mission: mission),
            ],
            const SizedBox(height: AppSpacing.s4),

            CommentsSection(requestId: mission.id),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceDisabled,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  // FR7 — this is always the driver's OWN car's progress, never an
  // aggregate mission status (there isn't one anymore, by design).
  final CarStatus status;
  const _StatusChip(this.status);

  static const _fg = {
    CarStatus.carAssigned: AppColors.statusPending,
    CarStatus.onTheWay:    AppColors.statusBusy,
    CarStatus.onSite:      AppColors.statusAvailable,
    CarStatus.returning:   AppColors.statusDone,
  };

  static const _bg = {
    CarStatus.carAssigned: AppColors.statusPendingBg,
    CarStatus.onTheWay:    AppColors.statusBusyBg,
    CarStatus.onSite:      AppColors.statusAvailableBg,
    CarStatus.returning:   AppColors.statusDoneBg,
  };

  static const _labels = {
    CarStatus.carAssigned: 'Designado',
    CarStatus.onTheWay:    'A caminho',
    CarStatus.onSite:      'No local',
    CarStatus.returning:   'Retornando',
  };

  @override
  Widget build(BuildContext context) {
    final fg = _fg[status] ?? AppColors.onSurfaceMuted;
    final bg = _bg[status] ?? AppColors.surface2;
    final label = _labels[status] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CompletionMessage extends StatelessWidget {
  final bool found;
  const _CompletionMessage({required this.found});

  @override
  Widget build(BuildContext context) {
    final color = found ? AppColors.success : AppColors.warning;
    final bg = found ? AppColors.statusAvailableBg : AppColors.statusBusyBg;
    final icon = found ? Icons.check_circle_outline : Icons.cancel_outlined;
    // Sem ponto de exclamação e sem ar de fim: desde 20260824000002 reportar
    // não encerra, e prometer conclusão aqui faria o motorista guardar o
    // celular com a missão ainda aberta e o carro ainda preso a ela.
    final label = found
        ? 'Você reportou: alvo encontrado.'
        : 'Você reportou: alvo não encontrado.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'A missão segue aberta até alguém encerrar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// FR3.3 — identification-only roster of other cars sharing this mission.
// Deliberately renders only car number + pilot name: no location field
// exists on CarSummary to leak here even by accident.
class CoAssignedCarsRoster extends StatelessWidget {
  final List<CarSummary> cars;
  const CoAssignedCarsRoster({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s1,
      children: cars.map((c) => _CarChip(car: c)).toList(),
    );
  }
}

class _CarChip extends StatelessWidget {
  final CarSummary car;
  const _CarChip({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined, size: 14, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(
            '${car.carNumber} · ${car.pilotName}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
