import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_app/db/share_pref.dart';
// import 'package:women_safety_app/child/bottom_screens/child_home_page.dart';

import 'child/bottom_page.dart';
import 'utils/flutter_background_service.dart';
import 'firebase_options.dart';   // <-- add this



final navigatorkey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // <-- use firebase_options.dart
  );
  await MySharedPreference.init();
  //await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        // scaffoldMessengerKey: navigatorkey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.firaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          primarySwatch: Colors.blue,
        ),
        home: BottomPage());
  }
}
