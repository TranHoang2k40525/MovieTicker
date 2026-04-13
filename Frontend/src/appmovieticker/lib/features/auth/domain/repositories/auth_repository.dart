import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String emailOrPhone, String password);
  Future<Either<Failure, void>> signUp({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? address,
  });
  Future<Either<Failure, void>> verifyOtp(String email, String otpCode);
}
