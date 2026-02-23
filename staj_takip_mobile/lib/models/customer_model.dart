import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String companyName;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email = '',
    required this.address,
    required this.companyName,
    required this.createdAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      companyName: data['companyName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'companyName': companyName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
