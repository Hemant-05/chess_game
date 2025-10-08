import 'package:chess_game/screens/waiting_room_screen.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/online_models.dart';
import 'online_chess_screen.dart';
import 'chess_game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _roomPasswordController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to Firebase...';
    });

    try {
      await _firebaseService.initialize();
      setState(() {
        _statusMessage = 'Connected successfully!';
      });

      // Hide success message after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Connection failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initializeFirebase,
          ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createRoom() async {
    if (!_firebaseService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for Firebase to initialize'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      GameRoom room = await _firebaseService.createRoom();
      _navigateToWaitingRoom(room); // Navigate to waiting room instead of game

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room created! Password: ${room.roomPassword}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _joinRoom() async {
    String password = _roomPasswordController.text.trim().toUpperCase();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter room password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      GameRoom? room = await _firebaseService.joinRoom(password);
      if (room != null) {
        _navigateToOnlineGame(room); // Guest goes directly to game
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined room successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room not found or already full'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _findRandomMatch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      GameRoom? room = await _firebaseService.findRandomMatch();
      if (room != null) {
        _navigateToOnlineGame(room);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match found!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to find match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text('Chess Game',style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF16213e),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('failed') || _statusMessage.contains('error')
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('failed') || _statusMessage.contains('error')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),

            // Rest of your UI remains the same...
            // Title
            Text(
              'Welcome to Chess Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Online Section
            Card(
              color: Color(0xFF16213e),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Online Multiplayer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Create Room
                    ElevatedButton(
                      onPressed: _firebaseService.isInitialized ? _createRoom : null,
                      child: Text('Create Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Join Room
                    TextField(
                      controller: _roomPasswordController,
                      decoration: InputDecoration(
                        hintText: 'Enter room password',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      // onPressed: (){},
                      onPressed: _firebaseService.isInitialized ? _joinRoom : null,
                      child: Text('Join Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Random Match
                    ElevatedButton(
                      onPressed: _firebaseService.isInitialized ? _findRandomMatch : null,
                      child: Text('Random Match'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Offline Section
            Card(
              color: Color(0xFF16213e),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Offline Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _playOffline,
                      child: Text('Play Offline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWaitingRoom(GameRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingRoomScreen(room: room),
      ),
    );
  }

  void _navigateToOnlineGame(GameRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineChessScreen(room: room),
      ),
    );
  }

  void _playOffline() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessGameScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _roomPasswordController.dispose();
    super.dispose();
  }
}
