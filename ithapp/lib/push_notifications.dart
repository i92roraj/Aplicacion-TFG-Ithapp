import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';




class PushNotificationsService{

  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;
  static StreamController<String> _messagestreamController = new StreamController.broadcast();
  static Stream<String> get messageStream => _messagestreamController.stream;

  static Future _background(RemoteMessage message) async{

    print('background handler ${message.messageId}');

  _messagestreamController.add(message.notification?.body ?? 'no titulo');

  }
  
  static Future _onMessage(RemoteMessage message) async{

    print('on message handler ${message.messageId}');

     _messagestreamController.add(message.notification?.body ?? 'no titulo');

  }
  
  static Future _onOpenMessage(RemoteMessage message) async{

    print('onOpenMessage handler ${message.messageId}');

     _messagestreamController.add(message.notification?.body ?? 'no titulo');

  }

  static Future initializeApp() async {





  FirebaseMessaging.onBackgroundMessage(_background);
  FirebaseMessaging.onMessage.listen(_onMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_onOpenMessage);


  }

static closeStreams(){
  _messagestreamController.close();
}

}