import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    QuerySnapshot messageSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> messages = [];
    for (var doc in messageSnapshot.docs) {
      messages.add({'id': doc.id, 'data': doc.data()});
    }
    return messages;
  }

  Future<List<Map<String, dynamic>>> getPreviousChats(String userId) async {
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    List<Map<String, dynamic>> chatList = [];
    for (var doc in chatSnapshot.docs) {
      chatList.add({'id': doc.id, 'data': doc.data()});
    }
    return chatList;
  }

  Future<void> sendMessage(
      String chatId, String senderId, String receiverId, String message) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'sender': senderId,
      'receiver': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': {
        'sender': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      }
    });
  }

  Future<String?> sendMessageToNewUser(String senderId, String receiverId, String message) async {
    // Check if a chat between the two users already exists
    QuerySnapshot chatSnapshot =
        await _firestore.collection('chats').where('participants', arrayContains: senderId).get();

    DocumentSnapshot? existingChat;
    for (var doc in chatSnapshot.docs) {
      List<dynamic> participants = doc['participants'];
      if (participants.contains(receiverId)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat != null) {
      // Chat already exists, send message in existing chat
      await sendMessage(existingChat.id, senderId, receiverId, message);
    } else {
      // Chat does not exist, create a new chat
      DocumentReference newChatRef = _firestore.collection('chats').doc();
      await newChatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': {
          'sender': senderId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      // Add the message to the messages subcollection
      await newChatRef.collection('messages').add({
        'sender': senderId,
        'receiver': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return newChatRef.id;
    }
  }
}
