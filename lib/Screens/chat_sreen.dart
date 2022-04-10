import 'dart:html';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../Model/auth_manager.dart';
import '../Model/message_model.dart';
import '../Model/user_model.dart';
import 'package:intl/intl.dart';
import '../services/api_manager.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  ChatScreen({required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final inputController = TextEditingController();
  DateTime now = DateTime.now();
  String inputHint = "send a msg...";
  //語音轉文字
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String _currentLocaleId = 'en_US';
  int resultListened = 0;
  final SpeechToText speech = SpeechToText();
  String _text = "";
  double _confidence = 1.0;
  //文字轉語音
  FlutterTts flutterTts = FlutterTts();


  @override
  void initState() {
    super.initState();
    initSpeechState();
    Future<Auth> _auth = API_Manager().getAuth();
    _auth.then((value) {
      API_Manager.access_token = value.accessToken;
    });
  }

  Future<void> initSpeechState() async {
    //語音轉文字
    var hasSpeech = await speech.initialize(onStatus: statusListener, onError: errorListener, debugLogging: false);
    if (!mounted) return;
    setState(() {
      _hasSpeech = hasSpeech;
    });
    //文字轉語音
    await flutterTts.setSharedInstance(true);
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.voicePrompt
    );
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.awaitSynthCompletion(true);
    await flutterTts.setLanguage("en-US");
  }

  _buildMessage(Message message, bool isMe, bool isImage) {
    final Container msg = Container(
      margin: isMe
          ? EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 80.0,
            )
          : EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
            ),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).accentColor : Color(0xFFFFEFEE),
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
              )
            : BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message.time,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            message.text,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.0),
          isImage ? Image.network(message.text) : SizedBox(height: 0),
        ],
      ),
    );
    if (isMe) {
      return msg;
    }
    return Row(
      children: <Widget>[
        msg,
        IconButton(
          icon: message.isLiked
              ? Icon(Icons.favorite)
              : Icon(Icons.favorite_border),
          iconSize: 30.0,
          color: message.isLiked
              ? Theme.of(context).primaryColor
              : Colors.blueGrey,
          onPressed: () {},
        )
      ],
    );
  }

  _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25.0,
            color: Color(0xffff7575),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: inputController,
              onChanged: (value) {},
              decoration: InputDecoration.collapsed(
                hintText: inputHint,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic),
            iconSize: 25.0,
            color: speech.isListening
                ?Colors.red
                :Color(0xffadadad),
            onPressed: () {
              if(!_hasSpeech || speech.isListening){
                stopListening();
              }{
                startListening();
              }
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25.0,
            color: Color(0xffff7575),
            onPressed: () {
              sendMessage();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          widget.user.name,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_horiz),
            iconSize: 30.0,
            color: Colors.white,
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  child: ListView.builder(
                    reverse: false,
                    padding: EdgeInsets.only(top: 15.0),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Message message = messages[index];
                      final bool isMe = message.sender.id == currentUser.id;
                      final bool isImage = message.text.startsWith("http") &&
                          message.sender.id != currentUser.id;
                      return _buildMessage(message, isMe, isImage);
                    },
                  ),
                ),
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  sendMessage() async {
    String input = inputController.text;
    inputController.text = "";
    String formattedDate = DateFormat('h:mm a').format(now);
    if (input != '') {
      messages.add(Message(
          sender: currentUser,
          time: formattedDate,
          text: input,
          isLiked: false,
          unread: false));
    }
    setState(() {});
    await API_Manager.reply(input);
    if (API_Manager.bot_reply != ["", "", "", "", ""]) {
      for (var i = 0; i < API_Manager.bot_reply.length; i++) {
        if (API_Manager.bot_reply[i] != "") {
          if (API_Manager.bot_reply[i].startsWith(":")) {
            API_Manager.bot_reply[i] = API_Manager.bot_reply[i].substring(2);
            messages.add(Message(
                sender: rasa,
                time: formattedDate,
                text: API_Manager.bot_reply[i],
                isLiked: false,
                unread: false));
            //API_Manager.isImage[i] = null;
          } else {
            messages.add(Message(
                sender: rasa,
                time: formattedDate,
                text: API_Manager.bot_reply[i],
                isLiked: false,
                unread: false));
            await flutterTts.speak(API_Manager.bot_reply[i]);
          }
          API_Manager.bot_reply[i] = "";
        }
      }
    }
    setState(() {});
  }

  void startListening() {
    inputHint = 'Listing...';
    speech.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
          inputController.text = _text;
          if (val.hasConfidenceRating && val.confidence > 0) {
            _confidence = val.confidence;
          }
        }),
        partialResults: false,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    inputHint = "send a msg...";
    inputController.text = _text;
    setState(() {
      level = 0.0;
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    stopListening();
    print('onError: ' + error.toString());
  }

  void statusListener(String status) {
    print('onStatus: ' + status.toString());
  }

}
