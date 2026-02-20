import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'service_record_model.dart';
import 'add_service_record_screen.dart';
import 'add_employee_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userCompanyName;
  String? _userRole; // Rolünü tutacak değişken
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCompany();
  }

  Future<void> _fetchUserCompany() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Query users collection to find the document with matching email

        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          setState(() {
            _userCompanyName = userData['companyName'];
            _userRole = userData['role']; // Rolü alıyoruz
            _isLoading = false;
          });
        }
        /* For testing/demo: Using specific document ID provided by user
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc('Qt3MdtMMnpUTX78GXHIV')
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data()!;
          setState(() {
            _userCompanyName = userData['companyName'];
            _userRole = userData['role'];
            _isLoading = false;
          });
        } else {
          // Fallback if user document not found
          setState(() {
            _isLoading = false;
          });
        }
        */
        else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user company: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userCompanyName == null || _userCompanyName!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bilgi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Henüz bir şirkete atanmadınız.\nLütfen şirket yöneticiniz ile iletişime geçerek sizi eklemesini isteyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$_userCompanyName Servis Kayıtları'),
        actions: [
          // Eğer yönetici ise bu butonu göster
          if (_userRole == 'manager')
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Çalışan Ekle',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEmployeeScreen(
                      managerCompanyName: _userCompanyName!,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_records')
            .where('companyName', isEqualTo: _userCompanyName)
            // .orderBy('date', descending: true) // Index hatasını önlemek için geçici olarak kapattık
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '$_userCompanyName şirketine ait servis kaydı bulunamadı.\n\nSağ alttaki (+) butonu ile ilk kaydı ekleyebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final records = snapshot.data!.docs
              .map((doc) => ServiceRecord.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.companyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (record.companyName == 'B Şirketi') ...[
                        Text(
                          'Sorun: ${record.animalProblem ?? 'Belirtilmedi'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (record.interventions != null &&
                            record.interventions!.isNotEmpty)
                          Text('Müdahale: ${record.interventions}'),
                        if (record.medications != null &&
                            record.medications!.isNotEmpty)
                          Text('İlaç: ${record.medications}'),
                        Text('Hekim: ${record.serviceEmployee}'),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              record.isWarranty
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: record.isWarranty
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              record.isWarranty
                                  ? 'Garanti Kapsamında'
                                  : 'Garanti Dışı',
                              style: TextStyle(
                                color: record.isWarranty
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Değişen Parça: ${record.replacedPart}'),
                        Text('İlgilenen: ${record.serviceEmployee}'),
                      ],
                      Text(
                        'Tarih: ${record.date.day}/${record.date.month}/${record.date.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AddServiceRecordScreen(companyName: _userCompanyName!),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Yeni Kayıt Ekle',
      ),
    );
  }
}
