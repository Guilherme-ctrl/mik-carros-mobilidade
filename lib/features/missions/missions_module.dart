import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import 'data/datasources/missions_remote_datasource.dart';
import 'data/repositories/missions_repository_impl.dart';
import 'domain/repositories/missions_repository.dart';
import 'domain/usecases/add_comment.dart';
import 'domain/usecases/get_comments.dart';
import 'domain/usecases/get_my_missions.dart';
import 'domain/usecases/set_outcome_found.dart';
import 'domain/usecases/set_outcome_not_found.dart';
import 'domain/usecases/update_mission_status.dart';
import 'domain/usecases/watch_active_mission.dart';
import 'presentation/cubit/missions_cubit.dart';
import 'presentation/pages/missions_page.dart';

// T10.17 — MissionsModule with /missions/ as driver home post-login
class MissionsModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<MissionsRemoteDatasource>(MissionsRemoteDatasourceImpl.new);
    i.addSingleton<MissionsRepository>(MissionsRepositoryImpl.new);
    i.addSingleton<GetMyMissions>(GetMyMissions.new);
    i.addSingleton<UpdateMissionStatus>(UpdateMissionStatus.new);
    i.addSingleton<WatchActiveMission>(WatchActiveMission.new);
    i.addSingleton<SetOutcomeNotFound>(SetOutcomeNotFound.new);
    i.addSingleton<SetOutcomeFound>(SetOutcomeFound.new);
    i.addSingleton<GetComments>(GetComments.new);
    i.addSingleton<AddComment>(AddComment.new);
    i.addSingleton<MissionsCubit>(MissionsCubit.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: Modular.get<MissionsCubit>()),
          BlocProvider.value(value: Modular.get<NotificationsCubit>()),
        ],
        child: const MissionsPage(),
      ),
    );
  }
}
