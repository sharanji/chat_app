import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:unite/components/bottom_bar.dart';
import 'package:unite/services/chatservices.dart';
import 'package:uuid/uuid.dart';

class MessageScreen extends StatefulWidget {
  MessageScreen({super.key, required this.userId, required this.userName, required this.chatId});
  String userId;
  String userName;
  String? chatId;

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final user1 = types.User(id: widget.userId, firstName: widget.userName);
    final curr_user =
        types.User(id: FirebaseAuth.instance.currentUser!.uid, firstName: widget.userName);

    return Scaffold(
      appBar: AppBar(
        title: Text(user1.firstName!),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }

            List<types.Message> messages = snapshot.data!.docs
                .map(
                  (m) => types.TextMessage(
                    author: types.User(id: m['sender']),
                    id: const Uuid().v1(),
                    type: types.MessageType.text,
                    text: m['message'],
                  ),
                )
                .toList();

            return Chat(
                messages: messages,
                user: curr_user,
                onSendPressed: (msg) async {
                  if (widget.chatId == null) {
                    var currChatId = await chatService.sendMessageToNewUser(
                      FirebaseAuth.instance.currentUser!.uid,
                      user1.id,
                      msg.text,
                    );
                    setState(() {
                      widget.chatId = currChatId;
                    });
                  } else {
                    chatService.sendMessage(
                      widget.chatId!,
                      FirebaseAuth.instance.currentUser!.uid,
                      user1.id,
                      msg.text,
                    );
                  }
                });
          }),
    );
  }
}
