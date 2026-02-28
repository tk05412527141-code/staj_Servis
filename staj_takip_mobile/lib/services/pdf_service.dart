import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateServiceReport(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final now = DateTime.now();

    final ticketNo = data['ticketNo'] ?? 'N/A';
    final customerName = data['customerName'] ?? 'İsimsiz Müşteri';
    final address = data['address'] ?? 'Adres belirtilmemiş';
    final deviceType = data['deviceType'] ?? 'Bilinmiyor';
    final deviceDetail = data['deviceDetail'] ?? '';
    final description = data['description'] ?? '';
    final price = (data['price'] ?? 0).toDouble();
    final companyName = data['companyName'] ?? 'Servis Takip';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('Teknik Servis Formu'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Fiş No: $ticketNo'),
                        pw.Text('Tarih: ${dateFormat.format(now)}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Customer Info
                pw.Text(
                  'Müşteri Bilgileri',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Ad Soyad: $customerName'),
                pw.Text('Adres: $address'),
                pw.SizedBox(height: 20),

                // Device Info
                pw.Text(
                  'Cihaz ve İşlem Detayları',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Cihaz Tipi: $deviceType'),
                pw.Text('Model/Detay: $deviceDetail'),
                pw.SizedBox(height: 10),
                pw.Text('Yapılan İşlem / Açıklama:'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(description),
                ),
                pw.SizedBox(height: 20),

                // Footer / Total
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOPLAM TUTAR:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${price.toStringAsFixed(2)} TL',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide()),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Teknisyen İmzası'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide()),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Müşteri İmzası'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save or Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'servis_formu_$ticketNo.pdf',
    );
  }
}
