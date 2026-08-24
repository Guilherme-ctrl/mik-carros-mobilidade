import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CarChatRemoteDatasource {
  Future<List<Map<String, dynamic>>> getMessages(String carId);
  Future<void> sendMessage(String carId, String content);
  Stream<void> watchMessages(String carId);
}

class CarChatRemoteDatasourceImpl implements CarChatRemoteDatasource {
  final SupabaseClient _client;
  CarChatRemoteDatasourceImpl(this._client);

  // Sem filtro de car_id nas consultas: a RLS de car_messages já restringe o
  // motorista ao canal do próprio carro (can_access_car_channel). O eq abaixo
  // é performance, não segurança — se ele sumisse, o motorista ainda não veria
  // conversa alheia.
  @override
  Future<List<Map<String, dynamic>>> getMessages(String carId) async {
    final rows = await _client
        .from('car_messages')
        .select('id, author_id, author_name, author_role, content, created_at')
        .eq('car_id', carId)
        .order('created_at', ascending: true)
        .limit(200);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<void> sendMessage(String carId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Sessão expirada');
    await _client.from('car_messages').insert({
      'car_id': carId,
      'author_id': userId,
      'content': content,
    });
  }

  @override
  Stream<void> watchMessages(String carId) {
    // Mesmo padrão de watchComments em missions: o stream é só um SINAL de
    // "mudou", e a busca completa vem depois. Evita reconstruir a lista a
    // partir de payloads parciais do Realtime.
    final controller = StreamController<void>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('car-messages-$carId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'car_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'car_id',
            value: carId,
          ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}
