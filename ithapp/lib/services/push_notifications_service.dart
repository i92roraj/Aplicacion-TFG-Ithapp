import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService{





static FirebaseMessaging messaging = FirebaseMessaging.instance;
static String? token;
static StreamController<String> _messageStream = new StreamController.broadcast();
static Stream<String> get messagesStream => _messageStream.stream;


static Future _backgroundHandler(RemoteMessage message) async {

print('background Handler ${message.messageId}');
print(message.data);

_messageStream.add(message.notification?.body ?? 'no titulo');

}

static Future _onMessageHandler(RemoteMessage message) async {

print('on message Handler ${message.messageId}');
print(message.data);

_messageStream.add(message.notification?.body ?? 'no titulo');

}

static Future _onOpenMessageOpenApp(RemoteMessage message) async {

print('on message oepn ap Handler ${message.messageId}');
print(message.data);

_messageStream.add(message.notification?.body ?? 'no titulo');

}

static Future initializeApp() async {

await Firebase.initializeApp();

token = await FirebaseMessaging.instance.getToken();

print('Token: $token');

//Handlers

FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
FirebaseMessaging.onMessage.listen(_onMessageHandler);
FirebaseMessaging.onMessageOpenedApp.listen(_onOpenMessageOpenApp);


}

static closeStreams() {

  _messageStream.close();
}

}