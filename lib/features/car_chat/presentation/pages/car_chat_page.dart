import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../domain/entities/car_message.dart';
import '../cubit/car_chat_cubit.dart';
import '../cubit/car_chat_state.dart';

// Conversa privada com o gestor de carros.
//
// Separada do chat da missão de propósito: aquele é sobre UMA solicitação e
// some quando ela encerra; este acompanha o carro o dia inteiro e serve para
// abastecimento, troca de turno, problema mecânico. Quem garante que ninguém
// mais lê é a RLS de car_messages — a tela não esconde nada que o banco
// entregaria.
class CarChatPage extends StatefulWidget {
  final String carId;

  // Sem carNumber: o subtítulo diria ao motorista o número do próprio carro,
  // que ele já sabe — e obrigaria a carregar o número no estado de missões só
  // para isso.
  const CarChatPage({super.key, required this.carId});

  @override
  State<CarChatPage> createState() => _CarChatPageState();
}

class _CarChatPageState extends State<CarChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final CarChatCubit _cubit;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _cubit = Modular.get<CarChatCubit>()..init(widget.carId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    // Depois do frame: antes dele o ListView ainda não tem a extensão nova.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final erro = await _cubit.send(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (erro == null) {
      _controller.clear();
    } else {
      // O texto NÃO é limpo quando falha: quem digitou não pode perder a
      // mensagem por causa de um problema de rede.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não enviou: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gestor de carros'),
              const Text(
                'Conversa privada',
                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<CarChatCubit, CarChatState>(
                listener: (_, state) {
                  if (state is CarChatLoaded) _scrollToEnd();
                },
                builder: (context, state) {
                  if (state is CarChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CarChatError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s4),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }
                  final messages = (state as CarChatLoaded).messages;
                  if (messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.s4),
                        child: Text(
                          'Nenhuma mensagem ainda.\nFale com o gestor por aqui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.onSurfaceMuted),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _Bubble(message: messages[i]),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Mensagem para o gestor…',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    _sending
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton.filled(
                            onPressed: _send,
                            icon: const Icon(Icons.send_rounded, size: 18),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final CarMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Do gestor à esquerda, minhas à direita — a convenção de qualquer app de
    // mensagem. `fromManager` vem do papel gravado no envio.
    final meu = !message.fromManager;
    return Align(
      alignment: meu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: meu ? AppColors.brandPinkMuted : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: meu
                ? AppColors.brandPink.withValues(alpha: 0.35)
                : AppColors.surface3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${message.authorName} · ${DateFormat('HH:mm').format(message.createdAt.toLocal())}',
              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceDisabled),
            ),
            const SizedBox(height: 2),
            Text(
              message.content,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
