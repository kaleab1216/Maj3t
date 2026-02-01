import 'admin_model.dart';
import 'customer_model.dart';
import 'delivery_driver_model.dart';

abstract class AppUser {
  final String userId;
  final String name;
  final String email;
  final String password;
  final String role;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap();

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final role = map['role'] ?? 'customer';

    if (role == 'customer') {
      return Customer.fromMap(map);
    } else if (role == 'admin') {
      return Admin.fromMap(map);
    } else if (role == 'delivery_driver') {
      return DeliveryDriver.fromMap(map);
    } else {
      return RegularUser.fromMap(map);
    }
  }
}

class RegularUser extends AppUser {
  RegularUser({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String role,
  }) : super(
    userId: userId,
    name: name,
    email: email,
    password: password,
    role: role,
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

  factory RegularUser.fromMap(Map<String, dynamic> map) {
    return RegularUser(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'customer',
    );
  }
}