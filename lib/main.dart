import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'services/firebase_service.dart';
import 'services/websocket_service.dart';
import 'widgets/brutalist_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with Web configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC1rYzNae0B6asNmgxSLYCUMTrasNmqxOo",
      authDomain: "class-app-a0548.firebaseapp.com",
      databaseURL: "https://class-app-a0548-default-rtdb.firebaseio.com",
      projectId: "class-app-a0548",
      storageBucket: "class-app-a0548.firebasestorage.app",
      messagingSenderId: "471676018320",
      appId: "1:471676018320:web:c64fb644db1eaa0bc6c215",
      measurementId: "G-DPN575BS69",
    ),
  );
  
  runApp(const ClassApp());
}

class ClassApp extends StatelessWidget {
  const ClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => FirebaseService()),
        ChangeNotifierProvider(create: (context) => WebSocketService()),
      ],
      child: MaterialApp(
        title: 'Class App',
        theme: BrutalistTheme.dark(),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}