import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/photo_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // ล็อกทิศทางหน้าจอให้อยู่ในแนวตั้ง (Portrait Only) เพื่อความเสถียรในการ swipe
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PhotoCleanerApp());
}

class PhotoCleanerApp extends StatelessWidget {
  const PhotoCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ผูก PhotoProvider เข้ากับ Root Widget ของแอป
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ],
      child: MaterialApp(
        title: 'Photo Cleaner',
        debugShowCheckedModeBanner: false,
        
        // ---------------- iOS 18 Dark Theme Configuration ----------------
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
          primaryColor: Colors.blueAccent,
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            surface: Color(0xFF1E293B), // Slate 800
            error: Colors.redAccent,
          ),
          fontFamily: '.SF Pro Text', // ฟอนต์ระบบ iOS (ถ้าบน Android จะ fallback เป็น Roboto อัตโนมัติ)
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
        ),

        // กำหนดหน้าแรกของแอป
        home: const HomeScreen(),
      ),
    );
  }
}