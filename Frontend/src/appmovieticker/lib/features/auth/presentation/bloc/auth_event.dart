import 'package:flutter/foundation.dart';

@immutable
abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String emailOrPhone;
  final String password;

  SignInRequested(this.emailOrPhone, this.password);
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String? fullName;
  final String? gender;
  final String? dateOfBirth;
  final String? address;

  SignUpRequested({
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.address,
  });
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otpCode;

  VerifyOtpRequested({required this.email, required this.otpCode});
}
