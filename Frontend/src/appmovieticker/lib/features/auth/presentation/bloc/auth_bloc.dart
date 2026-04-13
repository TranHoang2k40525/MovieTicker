import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.verifyOtpUseCase,
  }) : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signInUseCase(event.emailOrPhone, event.password);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (user) => emit(AuthSuccess('Đăng nhập thành công')),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signUpUseCase(
        email: event.email,
        phone: event.phone,
        password: event.password,
        confirmPassword: event.confirmPassword,
        fullName: event.fullName,
        gender: event.gender,
        dateOfBirth: event.dateOfBirth,
        address: event.address,
      );
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess('Đăng ký thành công, vui lòng xác thực OTP')),
      );
    });

    on<VerifyOtpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await verifyOtpUseCase(event.email, event.otpCode);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess('Xác thực OTP thành công')),
      );
    });
  }
}
