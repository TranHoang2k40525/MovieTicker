import 'package:flutter/foundation.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess([this.message = 'Success']);
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
