import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/mission.dart';
import '../cubit/missions_cubit.dart';

// O botão que encerra a missão (20260824000002).
//
// Existe porque "Achei"/"Não achei" DEIXARAM de encerrar. Antes, um toque num
// daqueles dois botões fechava a missão na hora, sem confirmação e sem volta —
// num celular, dentro de um carro em movimento. Agora reportar é reversível e o
// encerramento é este passo separado, com diálogo.
//
// A regra de "todos precisam ter reportado" é do RPC; aqui ela é espelhada
// apenas para explicar a espera. Quando falta alguém o botão não é escondido,
// e sim desabilitado COM o motivo ao lado: um botão que some não diz ao
// motorista que ele está esperando o carro 12.
class CloseMissionButton extends StatefulWidget {
  final Mission mission;
  const CloseMissionButton({super.key, required this.mission});

  @override
  State<CloseMissionButton> createState() => _CloseMissionButtonState();
}

class _CloseMissionButtonState extends State<CloseMissionButton> {
  bool _closing = false;

  Future<void> _confirmAndClose() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Encerrar missão?'),
        content: Text(
          widget.mission.coAssignedCars.isEmpty
              ? 'A missão será finalizada e seu carro ficará livre para a próxima. Não dá para desfazer.'
              : 'A missão será finalizada para TODOS os carros e eles ficarão livres para a próxima. Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    // O cubit já emite MissionsError quando o RPC recusa; aqui só desfazemos o
    // estado local de carregamento.
    await BlocProvider.of<MissionsCubit>(context).closeMission(widget.mission.id);
    if (mounted) setState(() => _closing = false);
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.mission.carsPendingOutcome;
    final ready = widget.mission.allCarsReported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: ready ? AppColors.success : AppColors.surface3,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          onPressed: (!ready || _closing) ? null : _confirmAndClose,
          icon: _closing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.flag_outlined, size: 18),
          label: const Text('Encerrar missão'),
        ),
        if (!ready) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            pending.length == 1
                ? 'Aguardando o desfecho do carro ${pending.first}.'
                : 'Aguardando o desfecho dos carros ${pending.join(', ')}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onSurfaceDisabled,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
