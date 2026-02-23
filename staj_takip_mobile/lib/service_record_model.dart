import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceTicket {
  final String id;
  final String ticketNo;
  final String companyName;
  final String status; // Bekliyor, Atandı, Yolda, Tamamlandı
  final String customerName;
  final String customerPhone;
  final String address;
  final String deviceType; // Beyaz Eşya, Klima, TV, Montaj, Bakım
  final String deviceDetail;
  final String description;
  final String assignedTo;
  final String priority; // Düşük, Normal, Yüksek, Acil
  final double price;
  final bool isWarranty;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<StatusHistory> statusHistory;

  ServiceTicket({
    required this.id,
    required this.ticketNo,
    required this.companyName,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.deviceType,
    required this.deviceDetail,
    required this.description,
    required this.assignedTo,
    this.priority = 'Normal',
    this.price = 0,
    this.isWarranty = false,
    required this.createdAt,
    this.updatedAt,
    this.statusHistory = const [],
  });

  factory ServiceTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceTicket(
      id: doc.id,
      ticketNo: data['ticketNo'] ?? '',
      companyName: data['companyName'] ?? '',
      status: data['status'] ?? 'Bekliyor',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      address: data['address'] ?? '',
      deviceType: data['deviceType'] ?? '',
      deviceDetail: data['deviceDetail'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      priority: data['priority'] ?? 'Normal',
      price: (data['price'] ?? 0).toDouble(),
      isWarranty: data['isWarranty'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      statusHistory:
          (data['statusHistory'] as List<dynamic>?)
              ?.map((e) => StatusHistory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketNo': ticketNo,
      'companyName': companyName,
      'status': status,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'deviceType': deviceType,
      'deviceDetail': deviceDetail,
      'description': description,
      'assignedTo': assignedTo,
      'priority': priority,
      'price': price,
      'isWarranty': isWarranty,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    };
  }
}

class StatusHistory {
  final String status;
  final String time;
  final DateTime timestamp;

  StatusHistory({
    required this.status,
    required this.time,
    required this.timestamp,
  });

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: map['status'] ?? '',
      time: map['time'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'time': time,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
