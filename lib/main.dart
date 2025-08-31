import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // removes the debug banner
      title: "Baby Evie's Arrival",
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.pink[100],
        scaffoldBackgroundColor: Colors.purple[50],
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          displayMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int storkClicks = 0;
  bool showLaborButton = false;
  final DateTime dueDate = DateTime(2025, 12, 31);
  late Timer _timer;
  Duration remaining = Duration();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        remaining = dueDate.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _storkClicked() {
    storkClicks++;
    if (storkClicks == 6) {
      setState(() {
        showLaborButton = true;
      });
    }
  }

  void _laborButtonClicked() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Send a message"),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: "Write your congratulatory message",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final reply = messageController.text.trim();
              Navigator.of(dialogContext).pop(); // synchronous, safe

              if (reply.isNotEmpty) {
                _sendGuestMessage(reply); // send without using BuildContext
              }

              setState(() {
                storkClicks = 0;
                showLaborButton = false;
              });

              _notifyGuests(); // notify guests asynchronously
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGuestMessage(String message) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('sendGuestMessage')
          .call({'message': message});
    } catch (_) {
      // silently handle
    }
  }

  Future<void> _notifyGuests() async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('notifyGuests')
          .call({'message': "I'm in labor! Baby Evie is arriving soon 💖"});
    } catch (_) {
      // silently handle
    }
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return "$days d : $hours h : $minutes m : $seconds s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background butterfly
          Positioned.fill(
            child: Image.asset(
              'assets/images/butterfly_bw.png',
              fit: BoxFit.cover,
              color: Colors.white.withAlpha(50),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          // Foreground content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _storkClicked,
                    child: Image.asset(
                      'assets/images/stork.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Baby Evie is arriving soon!!",
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/ultrasound.png',
                    width: 250,
                    height: 250,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink[100]?.withAlpha(128),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withAlpha(77),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      _formatDuration(remaining),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.purpleAccent,
                            offset: Offset(0, 0),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Due Date: ${dueDate.month}/${dueDate.day}/${dueDate.year}",
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Dear Aaliyah and my soon-to-be granddaughter, I love you so much and am so excited to meet Baby Evie! 💖",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  if (showLaborButton)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[300],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _laborButtonClicked,
                      child: const Text("I'm in labor!"),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
