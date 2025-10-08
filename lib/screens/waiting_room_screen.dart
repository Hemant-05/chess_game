import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/online_models.dart';
import '../services/firebase_service.dart';
import 'online_chess_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final GameRoom room;

  const WaitingRoomScreen({Key? key, required this.room}) : super(key: key);

  @override
  _WaitingRoomScreenState createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<GameRoom?>? _roomSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isWaiting = true;
  int _dotsCount = 0;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startListeningToRoom();
    _startDotsAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void _startDotsAnimation() {
    _dotsTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotsCount = (_dotsCount + 1) % 4;
        });
      }
    });
  }

  void _startListeningToRoom() {
    _roomSubscription = _firebaseService.listenToRoom(widget.room.roomId)
        .listen(_onRoomChanged);
  }

  void _onRoomChanged(GameRoom? updatedRoom) {
    if (updatedRoom == null) {
      // Room was deleted
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room was closed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if opponent joined
    if (updatedRoom.guestPlayerId != null &&
        updatedRoom.status == GameStatus.active) {

      setState(() {
        _isWaiting = false;
      });

      // Show opponent joined message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updatedRoom.guestPlayerName} joined the game!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment then navigate to game
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnlineChessScreen(room: updatedRoom),
            ),
          );
        }
      });
    }
  }

  void _copyRoomPassword() {
    Clipboard.setData(ClipboardData(text: widget.room.roomPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room password copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _leaveRoom() async {
    bool? shouldLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Leave Room'),
          content: Text('Are you sure you want to leave this room?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Leave'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      // Delete the room since host is leaving
      await _firebaseService.deleteRoom(widget.room.roomId);
      return true;
    }
    return false;
  }

  String _getWaitingText() {
    String dots = '.' * _dotsCount;
    return 'Waiting for opponent$dots';
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _animationController.dispose();
    _dotsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _leaveRoom(); // return true to allow pop, false to block
      },
      child: Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        appBar: AppBar(
          title: Text('Waiting Room',style: TextStyle(color: Colors.white),),
          backgroundColor: Color(0xff17172c),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,color: Colors.white,),
            onPressed: _leaveRoom,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Room Info Card
                Card(
                  color: Color(0xFF16213e),
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24,vertical:16),
                    child: Column(
                      children: [
                        // Room Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Room Password: ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 16),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Text(
                                widget.room.roomPassword,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Copy Button
                        ElevatedButton.icon(
                          onPressed: _copyRoomPassword,
                          icon: Icon(Icons.copy),
                          label: Text('Copy Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Host Info
                        Text(
                          'Host: ${widget.room.hostPlayerName}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),

                        Text(
                          'Time Limit: ${widget.room.timeLimit ~/ 60} minutes',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Waiting Animation
                if (_isWaiting) ...[
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.orange,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.hourglass_empty,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    _getWaitingText(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),

                  Text(
                    'Share the room password with your friend to join',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  // Opponent Joined Animation
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    'Opponent Joined!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  Text(
                    'Starting game...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],

                // SizedBox(height: 60),

                // Instructions
                Card(
                  color: Color(0xFF16213e).withOpacity(0.5),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'How to play:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Share the room password with your opponent\n'
                              '2. Wait for them to join using the password\n'
                              '3. Game will start automatically when they join\n'
                              '4. You will play as White pieces',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
