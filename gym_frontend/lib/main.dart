import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await CacheService().init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Gym',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1A2340),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1A2340)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A2340),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEEF1F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE2EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE2EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7A99), fontSize: 14),
          hintStyle: const TextStyle(color: Color(0xFFAAB4CC)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          selectedItemColor: Color(0xFF00897B),
          unselectedItemColor: Color(0xFF6B7A99),
          type: BottomNavigationBarType.fixed,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF00897B),
          unselectedLabelColor: Color(0xFF6B7A99),
          indicatorColor: Color(0xFF00897B),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEEF1F8),
          selectedColor: const Color(0xFF00897B),
          labelStyle: const TextStyle(color: Color(0xFF1A2340)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerColor: const Color(0xFFDDE2EE),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFDDE2EE),
          thickness: 0.5,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
