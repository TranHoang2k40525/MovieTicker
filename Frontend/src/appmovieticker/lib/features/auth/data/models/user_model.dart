import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({super.id, super.email, super.phone, super.fullName});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['accountId'] as int?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['fullName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': id,
      'email': email,
      'phone': phone,
      'fullName': fullName,
    };
  }
}
