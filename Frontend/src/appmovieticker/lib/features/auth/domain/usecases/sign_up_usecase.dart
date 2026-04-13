import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? address,
  }) {
    return repository.signUp(
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      fullName: fullName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      address: address,
    );
  }
}
