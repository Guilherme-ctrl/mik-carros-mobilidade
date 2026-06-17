import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';
import 'comments_section.dart';
import 'mission_action_button.dart';
import 'package:carros_mik_dundee/shared/widgets/whatsapp_share_button.dart';

class ActiveMissionCard extends StatelessWidget {
  final Mission mission;

  const ActiveMissionCard({super.key, required this.mission});

  Future<void> _openMaps() async {
    if (mission.mapsLink != null && mission.mapsLink!.isNotEmpty) {
      final uri = Uri.parse(mission.mapsLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        return;
      }
    }

    final dest = Uri.encodeComponent('${mission.fullAddress}, Blumenau, SC');

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
                _StatusChip(mission.status),
              ],
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              'Prova ${mission.stage}',
              style: tt.bodySmall,
            ),
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
  final MissionStatus status;
  const _StatusChip(this.status);

  static const _fg = {
    MissionStatus.carAssigned: AppColors.statusPending,
    MissionStatus.onTheWay:    AppColors.statusBusy,
    MissionStatus.onSite:      AppColors.statusAvailable,
    MissionStatus.returning:   AppColors.statusDone,
  };

  static const _bg = {
    MissionStatus.carAssigned: AppColors.statusPendingBg,
    MissionStatus.onTheWay:    AppColors.statusBusyBg,
    MissionStatus.onSite:      AppColors.statusAvailableBg,
    MissionStatus.returning:   AppColors.statusDoneBg,
  };

  static const _labels = {
    MissionStatus.carAssigned: 'Designado',
    MissionStatus.onTheWay:    'A caminho',
    MissionStatus.onSite:      'No local',
    MissionStatus.returning:   'Retornando',
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
