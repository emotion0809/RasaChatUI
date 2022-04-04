import 'package:rasa_chat_ui/Model/user_model.dart';

class Message {

  final User sender;
  final String time;
  final String text;
  final bool isLiked;
  final bool unread;

  Message(this.isLiked, {
    required this.sender,
    required this.time,
    required this.text,
    required this.unread,
  });
}

final User currentUser = User(id: 0, name: 'Current User', imageUrl: 'assets/images/greg.jpg',);
final User rasa = User(id: 0, name: 'Rasa', imageUrl: 'assets/images/rasa.png');

// FAVORITE CONTACTS
List<User> favorites = [rasa];

// EXAMPLE CHATS ON HOME SCREEN
List<Message> chats = [

];

// EXAMPLE MESSAGES IN CHAT SCREEN
List<Message> messages = [];