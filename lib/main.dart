import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'firebase_options.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  List<String> notificationHistory = [];

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;

    messaging.subscribeToTopic("messaging");

    messaging.getToken().then((value) {
      print("FCM Token: $value");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
      print("message received");
      print(event.notification!.body);
      print(event.data);

      String? type = event.data['type'];
      String displayMessage = event.notification!.body!;

      if (type == 'important') {
        displayMessage = '🔥 IMPORTANT: $displayMessage';

        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 500);
        }
      }

      // Save to notification history
      setState(() {
        notificationHistory.add(displayMessage);
      });

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    type == 'important' ? Icons.warning : Icons.notifications,
                    color: type == 'important' ? Colors.red : Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Text('Notification'),
                ],
              ),
              content: Text(displayMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                String? token = await messaging.getToken();
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text("FCM Token"),
                        content: SelectableText(token ?? "Token not found"),
                      ),
                );
              },
              child: Text("Show FCM Token"),
            ),
            SizedBox(height: 20),
            Text(
              "📜 Notification History:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child:
                  notificationHistory.isEmpty
                      ? Center(child: Text("No notifications received yet."))
                      : ListView.builder(
                        itemCount: notificationHistory.length,
                        itemBuilder:
                            (context, index) => ListTile(
                              leading: Icon(Icons.notifications_active),
                              title: Text(notificationHistory[index]),
                            ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
