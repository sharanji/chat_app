class ChatMessages {
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  int type;

  ChatMessages(
      {required this.idFrom,
      required this.idTo,
      required this.timestamp,
      required this.content,
      required this.type});

  Map<String, dynamic> toJson() {
    return {
      'fromUserId': idFrom,
      'toUserId': idTo,
      'timestamp': timestamp,
      'message': content,
      'type': type,
    };
  }

  factory ChatMessages.fromDocument(documentSnapshot) {
    String idFrom = documentSnapshot.get('fromUserId');
    String idTo = documentSnapshot.get('toUserId');
    String timestamp = documentSnapshot.get('timestamp');
    String content = documentSnapshot.get('message');
    int type = documentSnapshot.get('type');

    return ChatMessages(
        idFrom: idFrom, idTo: idTo, timestamp: timestamp, content: content, type: type);
  }
}
