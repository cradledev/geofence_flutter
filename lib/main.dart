import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './pages/root_page.dart';
import './services/authentication.dart';
import 'package:firebase_core/firebase_core.dart';

// import 'package:firebase_messaging/firebase_messaging.dart';
// import './services/pushnotification.dart';
import './services/notificationService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        // Initialize FlutterFire
        future: kIsWeb
            ? Firebase.initializeApp(
                options: const FirebaseOptions(
                    apiKey: "AIzaSyD6pdwf7ZAFEziLhwupv0uln1HVV_3pqZg",
                    authDomain: "geo-fencing-flutter.firebaseapp.com",
                    projectId: "geo-fencing-flutter",
                    storageBucket: "geo-fencing-flutter.appspot.com",
                    messagingSenderId: "380600200961",
                    appId: "1:380600200961:web:b32bd58f69568cbebbf500",
                    measurementId: "G-6MMYZHWBRM"))
            : Firebase.initializeApp(),
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return const Text("something went wrong on initializing firebase.");
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return RootPage(auth: AuthService());
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return _buildWaitingScreen();
        },
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'Flutter Demo',
  //     theme: ThemeData(
  //       // This is the theme of your application.
  //       //
  //       // Try running your application with "flutter run". You'll see the
  //       // application has a blue toolbar. Then, without quitting the app, try
  //       // changing the primarySwatch below to Colors.green and then invoke
  //       // "hot reload" (press "r" in the console where you ran "flutter run",
  //       // or simply save your changes to "hot reload" in a Flutter IDE).
  //       // Notice that the counter didn't reset back to zero; the application
  //       // is not restarted.
  //       primarySwatch: Colors.blue,
  //     ),
  //     home:  RootPage(auth: AuthService()),
  //   );
  // }
}

// 
