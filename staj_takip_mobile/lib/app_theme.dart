import 'package:flutter/material.dart';

class AppTheme {
  // Profesyonel Kurumsal Renk Paleti
  static const Color primaryBlue = Color(0xFF1A237E); // Deep Navy
  static const Color darkBlue = Color(0xFF0D1442); // Midnight Blue
  static const Color lightBlue = Color(0xFFF0F2F9); // Soft Ice Blue
  static const Color accentTeal = Color(0xFF26A69A); // Muted Teal
  static const Color accentGold = Color(
    0xFFC5A059,
  ); // Kurumsal Gold (vurgu için)

  // Durum renkleri (Profesyonel Muted tonlar)
  static const Color statusYolda = Color(0xFFE67E22);
  static const Color statusAtandi = Color(0xFF27AE60);
  static const Color statusBekliyor = Color(0xFF7F8C8D);
  static const Color statusTamamlandi = Color(0xFF2980B9);

  // Genel renkler
  static const Color backgroundGrey = Color(0xFFF4F7F9);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textGrey = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFFBDC3C7);
  static const Color danger = Color(0xFFC0392B);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);

  // Gradient (Daha hafif ve kurumsal)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF283593)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dashboardGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF3949AB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryBlue,
      scaffoldBackgroundColor: backgroundGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textGrey),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // Durum adından renge çevir
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'yolda':
        return statusYolda;
      case 'atandı':
      case 'atandi':
        return statusAtandi;
      case 'bekliyor':
        return statusBekliyor;
      case 'tamamlandı':
      case 'tamamlandi':
        return statusTamamlandi;
      default:
        return textGrey;
    }
  }

  // Kategori ikonu
  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beyaz eşya':
      case 'beyaz esya':
        return Icons.kitchen;
      case 'klima':
        return Icons.ac_unit;
      case 'bakım':
      case 'bakim':
        return Icons.build;
      case 'tv':
      case 'televizyon':
        return Icons.tv;
      case 'montaj':
        return Icons.construction;
      default:
        return Icons.miscellaneous_services;
    }
  }
}
