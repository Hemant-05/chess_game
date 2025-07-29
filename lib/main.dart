import 'package:flutter/material.dart';
import 'screens/chess_game_screen.dart';

void main() {
  runApp(ChessGameApp());
}

class ChessGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF1a1a2e),
      ),
      home: ChessGameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
