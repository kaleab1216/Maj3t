import 'app_user_user_model.dart';

class Customer extends AppUser {
  final String preferredLanguage;

  Customer({
    required String userId,
    required String name,
    required String email,
    required String password,
    required this.preferredLanguage,
  }) : super(
    userId: userId,
    name: name,
    email: email,
    password: password,
    role: 'customer',
  );

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'preferredLanguage': preferredLanguage,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      preferredLanguage: map['preferredLanguage'] ?? 'en',
    );
  }
}