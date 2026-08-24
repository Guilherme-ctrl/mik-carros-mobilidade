import 'package:flutter_modular/flutter_modular.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/car_chat_remote_datasource.dart';
import 'data/repositories/car_chat_repository_impl.dart';
import 'domain/repositories/car_chat_repository.dart';
import 'domain/usecases/get_car_messages.dart';
import 'domain/usecases/send_car_message.dart';
import 'domain/usecases/watch_car_messages.dart';
import 'presentation/cubit/car_chat_cubit.dart';
import 'presentation/pages/car_chat_page.dart';

class CarChatModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<CarChatRemoteDatasource>(
      () => CarChatRemoteDatasourceImpl(Supabase.instance.client),
    );
    i.addSingleton<CarChatRepository>(CarChatRepositoryImpl.new);
    i.addSingleton<GetCarMessages>(GetCarMessages.new);
    i.addSingleton<SendCarMessage>(SendCarMessage.new);
    i.addSingleton<WatchCarMessages>(WatchCarMessages.new);
    // Factory, não singleton: o cubit assina um canal de Realtime por carro e
    // precisa morrer junto com a página. Um singleton manteria a inscrição viva
    // e, ao reabrir, empilharia outra.
    i.add<CarChatCubit>(CarChatCubit.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) {
      // O id do carro vem da tela de missões, que já o resolveu — evita uma
      // segunda consulta de "qual é o meu carro" só para abrir o chat.
      return CarChatPage(carId: r.args.data as String? ?? '');
    });
  }
}
