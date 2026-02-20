import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRecord {
  final String id;
  final String companyName;
  final bool isWarranty;
  final String replacedPart;
  final String serviceEmployee;
  final DateTime date;

  ServiceRecord({
    required this.id,
    required this.companyName,
    required this.isWarranty,
    required this.replacedPart,
    required this.serviceEmployee,
    required this.date,
  });

  factory ServiceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRecord(
      id: doc.id,
      companyName: data['companyName'] ?? 'Bilinmeyen Şirket',
      isWarranty: data['isWarranty'] ?? false,
      replacedPart: data['replacedPart'] ?? 'Yok',
      serviceEmployee: data['serviceEmployee'] ?? 'Atanmamış',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'isWarranty': isWarranty,
      'replacedPart': replacedPart,
      'serviceEmployee': serviceEmployee,
      'date': Timestamp.fromDate(date),
    };
  }
}
