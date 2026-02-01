import 'app_user_user_model.dart';

class Admin extends AppUser {
  Admin({
    required String userId,
    required String name,
    required String email,
    required String password,
  }) : super(
    userId: userId,
    name: name,
    email: email,
    password: password,
    role: 'admin',
  );

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }
}