import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_record_model.dart';

class AddServiceRecordScreen extends StatefulWidget {
  final String companyName;

  const AddServiceRecordScreen({super.key, required this.companyName});

  @override
  State<AddServiceRecordScreen> createState() => _AddServiceRecordScreenState();
}

class _AddServiceRecordScreenState extends State<AddServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  final _replacedPartController = TextEditingController();
  final _serviceEmployeeController = TextEditingController();
  bool _isWarranty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.companyName);
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newRecord = ServiceRecord(
          id: '', // Firestore will generate
          companyName: widget.companyName,
          isWarranty: _isWarranty,
          replacedPart: _replacedPartController.text.trim(),
          serviceEmployee: _serviceEmployeeController.text.trim(),
          date: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('service_records')
            .add(newRecord.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt Başarıyla Eklendi!')),
          );
          Navigator.of(context).pop(); // Return to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _replacedPartController.dispose();
    _serviceEmployeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Servis Kaydı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Şirket Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                readOnly: true, // Kullanıcı değiştiremez
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şirket adını giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _replacedPartController,
                decoration: const InputDecoration(
                  labelText: 'Değişen Parça',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen değişen parçayı giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceEmployeeController,
                decoration: const InputDecoration(
                  labelText: 'Servis Elemanı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen servis elemanını giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Garanti Kapsamında mı?'),
                value: _isWarranty,
                onChanged: (bool value) {
                  setState(() {
                    _isWarranty = value;
                  });
                },
                secondary: Icon(
                  _isWarranty ? Icons.check_circle : Icons.cancel,
                  color: _isWarranty ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
