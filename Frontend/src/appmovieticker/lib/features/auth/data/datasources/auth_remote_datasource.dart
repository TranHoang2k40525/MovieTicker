import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn(String emailOrPhone, String password);
  Future<void> signUp({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? address,
  });
  Future<void> verifyOtp(String email, String otpCode);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<void> signUp({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? address,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.register,
        data: {
          'Email': email,
          'Phone': phone,
          'Password': password,
          'ConfirmPassword': confirmPassword,
          if (fullName != null) 'FullName': fullName,
          if (gender != null) 'Gender': gender,
          if (dateOfBirth != null) 'DateOfBirth': dateOfBirth,
          if (address != null) 'Address': address,
        },
      );

      final dynamic raw = response.data;
      late final Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        throw ServerException('Ð?nh d?ng ph?n h?i không h?p l?');
      }

      if (data['success'] == false) {
        throw ServerException(data['message'] ?? 'Ðang ký th?t b?i');
      }
    } on DioException catch (e) {
      final dynamic err = e.response?.data;
      String message;
      if (err is Map<String, dynamic>) {
        message = err['message']?.toString() ?? 'Ðang ký th?t b?i';
      } else if (err is String) {
        try {
          final json = jsonDecode(err) as Map<String, dynamic>;
          message = json['message']?.toString() ?? 'Ðang ký th?t b?i';
        } catch (_) {
          message = e.message ?? 'Ðang ký th?t b?i';
        }
      } else {
        message = e.message ?? 'Ðang ký th?t b?i';
      }

      throw ServerException(message);
    }
  }

  @override
  Future<Map<String, dynamic>> signIn(
    String emailOrPhone,
    String password,
  ) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.login,
        data: {'EmailOrPhone': emailOrPhone, 'Password': password},
      );

      final dynamic raw = response.data;
      late final Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        throw ServerException('Ð?nh d?ng ph?n h?i không h?p l?');
      }

      if (data['success'] == true) {
        final dynamic inner = data['data'];
        if (inner is Map<String, dynamic>) {
          return inner;
        } else {
          throw ServerException('Ð?nh d?ng d? li?u dang nh?p không h?p l?');
        }
      } else {
        throw ServerException(data['message'] ?? 'Ðang nh?p th?t b?i');
      }
    } on DioException catch (e) {
      final dynamic err = e.response?.data;
      String message;
      if (err is Map<String, dynamic>) {
        message = err['message']?.toString() ?? 'Ðang nh?p th?t b?i';
      } else if (err is String) {
        try {
          final json = jsonDecode(err) as Map<String, dynamic>;
          message = json['message']?.toString() ?? 'Ðang nh?p th?t b?i';
        } catch (_) {
          message = e.message ?? 'Ðang nh?p th?t b?i';
        }
      } else {
        message = e.message ?? 'Ðang nh?p th?t b?i';
      }

      throw ServerException(message);
    }
  }

  @override
  Future<void> verifyOtp(String email, String otpCode) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.verifyOtp,
        data: {'Email': email, 'OtpCode': otpCode},
      );

      final dynamic raw = response.data;
      late final Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        throw ServerException('Ð?nh d?ng ph?n h?i không h?p l?');
      }

      if (data['success'] == false) {
        throw ServerException(data['message'] ?? 'Xác th?c mã OTP th?t b?i');
      }
    } on DioException catch (e) {
      final dynamic err = e.response?.data;
      String message;
      if (err is Map<String, dynamic>) {
        message = err['message']?.toString() ?? 'L?i k?t n?i xác th?c OTP';
      } else if (err is String) {
        try {
          final json = jsonDecode(err) as Map<String, dynamic>;
          message = json['message']?.toString() ?? 'L?i k?t n?i xác th?c OTP';
        } catch (_) {
          message = e.message ?? 'L?i k?t n?i xác th?c OTP';
        }
      } else {
        message = e.message ?? 'L?i k?t n?i xác th?c OTP';
      }

      throw ServerException(message);
    }
  }
}

