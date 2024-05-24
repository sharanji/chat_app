import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:unite/components/bottom_bar.dart';
import 'package:unite/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:unite/screens/home.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  Stripe.publishableKey =
      'pk_test_51IyCOjSETJCIOiuJ4aOpTuUwc0aMN1JMnlmVk1xxjKsGYSOZqTnry5bodhv2rpMsRz35ZQoBVVOjP8MR3XJsbbhh009BavDKQR';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: StreamBuilder(
        stream: _auth.userChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData && (!snapshot.data!.isAnonymous)) {
            return ChatScreen();
          }

          return LoginPage();
        },
      ),
    );
  }
}
