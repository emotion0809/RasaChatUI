import 'dart:convert';
import 'dart:io';

import '../Model/auth_manager.dart';
import 'package:http/http.dart' as http;

import '../Model/message_model.dart';
import '../Model/reply_manager.dart';

class API_Manager {
  static String access_token = "";
  static List<String> bot_reply = ["","","","",""];

  Future<Auth> getAuth() async {

    final response = await http.post(
      Uri.parse('http://192.168.1.1:5002/api/auth'),
      body: '{"username": "me", "password": "PASSWORD"}',
    );

    //return NewModel.fromJson(json.decode(response.body));
    if (response.statusCode == 200) {
      return Auth.fromJson(json.decode(response.body));
    } else {
      throw Exception('Access denied');
    }
  }

  static Future<Reply> reply(String chat) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.1:5002/api/conversations/3/messages/'),
      headers: {
        'Content-Type': 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $access_token',
      },
      body: '{"message":"$chat"}',
    );

    if (response.statusCode == 200) {

      List result = jsonDecode(response.body);

      for (int i = 0; i < result.length; i++) {
        bot_reply[i] =
            result[i].toString().substring(23, result[i].toString().length - 1);
      }
    }
    return Reply.fromJson(json.decode('{"recipient_id": "{conversationID}","text": "Hey! How are you?"}'));
  }
}