import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:unite/components/bottom_bar.dart';
import 'package:unite/model/chatuser.dart';
import 'package:unite/screens/profile.dart';
import './message_screen.dart';
import 'package:unite/services/chatservices.dart';
import 'package:search_page/search_page.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 100,
            padding: const EdgeInsets.all(25),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(Icons.account_circle),
                  ),
                ),
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: newChat,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(Icons.add),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('chats').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text('No Chats found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var currentChat = snapshot.data!.docs[index];
                        List participant = snapshot.data!.docs[index]['participants'];
                        participant.remove(userId);

                        return FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(participant.first)
                              .get(),
                          builder: (context, userDetails) {
                            if (userDetails.connectionState != ConnectionState.done) {
                              return const CupertinoActivityIndicator();
                            }
                            var userName = userDetails.data!['name'];
                            return ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MessageScreen(
                                      userId: participant.first,
                                      userName: userName,
                                      chatId: currentChat.id,
                                    ),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                foregroundImage: NetworkImage(
                                  userDetails.data!['profileImage'],
                                ),
                              ),
                              title: Text(userName.toString()),
                              subtitle: Text(currentChat['lastMessage']['message']),
                            );
                          },
                        );
                      },
                    );
                  }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }

  void newChat() async {
    var users = await FirebaseFirestore.instance.collection('users').get();

    Iterable<ChatUser> people = users.docs.map((u) => ChatUser(u['name'], u.reference.id));

    // ignore: use_build_context_synchronously
    showSearch(
      context: context,
      delegate: SearchPage<ChatUser>(
        items: people.toList(),
        searchLabel: 'Search people',
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MessageScreen(
                  userId: person.uid,
                  userName: person.name,
                  chatId: null,
                ),
              ),
            );
          },
          leading: const CircleAvatar(),
          title: Text(person.name),
        ),
      ),
    );
  }
}
