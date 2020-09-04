import 'package:bloc/bloc.dart';
import 'package:mentorship_client/auth/auth_bloc.dart';
import 'package:mentorship_client/auth/bloc.dart';
import 'package:mentorship_client/failure.dart';
import 'package:mentorship_client/remote/repositories/auth_repository.dart';
import 'package:mentorship_client/screens/login/bloc/login_event.dart';
import 'package:mentorship_client/screens/login/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc;

  LoginBloc(this.authRepository, this.authBloc) : super(LoginInitial());

  @override
  Stream<LoginState> mapEventToState(event) async* {
    if (event is LoginButtonPressed) {
      yield LoginInProgress();
      try {
        final token = await authRepository.login(event.login);
        yield LoginSuccess();
        authBloc.add(JustLoggedIn(token.token));
      } on Failure catch (failure) {
        yield LoginFailure(failure.message);
      }
    }
  }
}
