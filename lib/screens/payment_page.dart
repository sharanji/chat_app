import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:search_page/search_page.dart';
import 'package:unite/components/bottom_bar.dart';
import 'package:unite/model/chatuser.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  DocumentReference? newpaymentRef;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payments Screen'),
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('payments')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (ctx, snapShot) {
            if (!snapShot.hasData || snapShot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No Payments Histroy'),
              );
            }

            return ListView.builder(
                itemCount: snapShot.data!.docs.length,
                itemBuilder: (ctx, index) {
                  return ListTile(
                    title: Text(
                        'Payment Rs : ${int.parse(snapShot.data!.docs[index]['amount']) / 100}'),
                    subtitle: Text('Payment to : ${snapShot.data!.docs[index]['payToName']}'),
                    trailing: Text(
                      snapShot.data!.docs[index]['status'] != 1
                          ? snapShot.data!.docs[index]['status'] == 2
                              ? 'Failed'
                              : 'Pending/Canceled'
                          : 'Success',
                      style: TextStyle(
                          color: snapShot.data!.docs[index]['status'] != 1
                              ? snapShot.data!.docs[index]['status'] == 2
                                  ? Colors.red
                                  : Colors.amber
                              : Colors.green),
                    ),
                  );
                });
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: newPayment,
        child: const Icon(Icons.add),
      ),
    );
  }

  void newPayment() async {
    var users = await FirebaseFirestore.instance.collection('users').get();

    Iterable<ChatUser> people = users.docs.map((u) => ChatUser(u['name'], u.reference.id));

    // ignore: use_build_context_synchronously
    showSearch(
      context: context,
      delegate: SearchPage<ChatUser>(
        items: people.toList(),
        searchLabel: 'Search people to pay',
        suggestion: const Center(
          child: Text('Filter people by name'),
        ),
        failure: const Center(
          child: Text('No person found :('),
        ),
        filter: (person) => [
          person.name,
        ],
        builder: (person) => ListTile(
          onTap: () {
            Navigator.pop(context);
            startPayment(person);
          },
          leading: const CircleAvatar(),
          title: Text(person.name),
        ),
      ),
    );
  }

  void startPayment(ChatUser benifiter) async {
    try {
      var paymentIntent = await createPaymentIntent('100', 'INR', benifiter);

      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret:
                    paymentIntent!['client_secret'], //Gotten from payment intent
                style: ThemeMode.light,
                merchantDisplayName: 'Sharan'),
          )
          .then((value) {});

      displayPaymentSheet();
    } catch (err) {
      print(err);
      // throw Exception(err);
    }
  }

  createPaymentIntent(String amount, String currency, ChatUser benifiter) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      DocumentReference newPaymentIntent = FirebaseFirestore.instance.collection('payments').doc();
      await newPaymentIntent.set({
        'payTo': benifiter.uid,
        'payToName': benifiter.name,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'amount': amount,
        'status': 0,
      });
      newpaymentRef = newPaymentIntent;

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer sk_test_51IyCOjSETJCIOiuJqbhCqudoRQ2FtB6gq7tEV4YZ1vE19iWTMP56StC6EzxfiLk2vTWMGzYBpEbeDkSbVhHDs0bb00bF12JYXX',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100.0,
                      ),
                      SizedBox(height: 10.0),
                      Text("Payment Successful!"),
                    ],
                  ),
                ));

        newpaymentRef!.update({'status': 1});
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
      newpaymentRef!.set({'status': 2});
    } catch (e) {
      print('$e');
    }
  }
}
