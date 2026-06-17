import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../../../features/location/domain/usecases/start_location_tracking.dart';
import '../../../../features/location/domain/usecases/stop_location_tracking.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithEmail _signIn;
  final SignOut _signOut;
  final GetCurrentSession _getSession;

  AuthCubit(this._signIn, this._signOut, this._getSession) : super(AuthInitial());

  Future<void> checkSession() async {
    emit(AuthLoading());
    final result = await _getSession();
    result.fold(
      (_) => emit(Unauthenticated()),
      (session) {
        if (session != null) {
          Modular.get<StartLocationTracking>()();
          emit(Authenticated(session));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    final result = await _signIn(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (session) {
        Modular.get<StartLocationTracking>()();
        emit(Authenticated(session));
      },
    );
  }

  Future<void> signOut() async {
    Modular.get<StopLocationTracking>()();
    await _signOut();
    emit(Unauthenticated());
  }
}
