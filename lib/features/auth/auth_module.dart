import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/get_current_session.dart';
import 'domain/usecases/sign_in_with_email.dart';
import 'domain/usecases/sign_out.dart';
import 'domain/usecases/update_push_token.dart';
import 'presentation/cubit/auth_cubit.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/splash_page.dart';

class AuthModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<AuthRemoteDatasource>(AuthRemoteDatasourceImpl.new);
    i.addSingleton<AuthRepository>(AuthRepositoryImpl.new);
    i.addSingleton<SignInWithEmail>(SignInWithEmail.new);
    i.addSingleton<SignOut>(SignOut.new);
    i.addSingleton<GetCurrentSession>(GetCurrentSession.new);
    i.addSingleton<UpdatePushToken>(UpdatePushToken.new);
    i.addSingleton<AuthCubit>(AuthCubit.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/splash',
      child: (_) => BlocProvider.value(
        value: Modular.get<AuthCubit>(),
        child: const SplashPage(),
      ),
    );
    r.child(
      '/login',
      child: (_) => BlocProvider.value(
        value: Modular.get<AuthCubit>(),
        child: const LoginPage(),
      ),
    );
  }
}
