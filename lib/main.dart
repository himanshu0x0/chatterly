import 'package:chatterly/theme/theme.dart';
import 'package:chatterly/ui/screens/chat_screen.dart';
import 'package:chatterly/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatterly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),   // 👈 First screen shown
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}

