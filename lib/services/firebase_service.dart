import 'dart:async';
import 'dart:math';
import 'package:chess_game/models/chess_models.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/online_models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _database = FirebaseDatabase.instanceFor(
      databaseURL: 'https://chess-game-5fafd-default-rtdb.asia-southeast1.firebasedatabase.app',app: Firebase.app());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  String? _currentPlayerId;
  String? _currentPlayerName;
  bool _isInitialized = false;

  // Getters
  String? get currentPlayerId => _currentPlayerId;
  String? get currentPlayerName => _currentPlayerName;
  bool get isInitialized => _isInitialized;

  // Initialize service with better error handling
  Future<void> initialize() async {
    try {
      print('Starting Firebase service initialization...');

      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is not initialized. Please check your Firebase configuration.');
      }

      // Set database URL if needed (replace with your database URL)
      /*_database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://your-project-name-default-rtdb.firebaseio.com/',
      );*/

      // Sign in anonymously
      UserCredential userCredential = await _auth.signInAnonymously();
      _currentPlayerId = userCredential.user?.uid;

      if (_currentPlayerId == null) {
        throw Exception('Failed to get user ID from Firebase Auth');
      }

      _currentPlayerName = 'Player_${_currentPlayerId!.substring(0, 6)}';

      print('Firebase Auth successful. User ID: $_currentPlayerId');

      // Test database connection
      await _testDatabaseConnection();

      // Set player online status
      await _setPlayerOnlineStatus(true);

      _isInitialized = true;
      print('Firebase service initialized successfully');

    } catch (e) {
      print('Firebase initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // Test database connection
  Future<void> _testDatabaseConnection() async {
    try {
      DatabaseReference testRef = _database.ref('test');
      await testRef.set({'timestamp': DateTime.now().toIso8601String()});
      await testRef.remove();
      print('Database connection test successful');
    } catch (e) {
      print('Database connection test failed: $e');
      throw Exception('Database connection failed. Please check your Firebase Realtime Database configuration.');
    }
  }

  // Generate room password
  String _generateRoomPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  // Create game room
  Future<GameRoom> createRoom({int timeLimit = 600}) async {
    if (!_isInitialized) {
      throw Exception('Firebase service not initialized. Please wait for initialization to complete.');
    }

    if (_currentPlayerId == null) {
      throw Exception('User not authenticated. Please restart the app.');
    }

    try {
      String roomId = _uuid.v4();
      String roomPassword = _generateRoomPassword();

      GameRoom room = GameRoom(
        roomId: roomId,
        roomPassword: roomPassword,
        hostPlayerId: _currentPlayerId!,
        hostPlayerName: _currentPlayerName!,
        createdAt: DateTime.now(),
        timeLimit: timeLimit,
      );

      await _database.ref('rooms/$roomId').set(room.toJson());

      // Initialize game state
      await _initializeGameState(roomId, timeLimit);

      print('Room created successfully: $roomPassword');
      return room;

    } catch (e) {
      print('Error creating room: $e');
      throw Exception('Failed to create room: $e');
    }
  }

  // Rest of your FirebaseService methods remain the same...
  // (I'll include the key ones with error handling)
  // Join room by password
  Future<GameRoom?> joinRoom(String roomPassword) async {
    if (_currentPlayerId == null) throw Exception('Player not initialized');

    try {
      // Find room by password
      Query query = _database.ref('rooms').orderByChild('roomPassword').equalTo(roomPassword);
      DatabaseEvent event = await query.once();

      if (event.snapshot.exists) {
        Map<String, dynamic> roomsData = Map<String, dynamic>.from(event.snapshot.value as Map);

        for (String roomId in roomsData.keys) {
          GameRoom room = GameRoom.fromJson(Map<String, dynamic>.from(roomsData[roomId]));

          if (room.status == GameStatus.waiting && room.guestPlayerId == null) {
            // Update room with guest player
            await updateRoomWithGuest(roomId, _currentPlayerId!, _currentPlayerName!);

            // Return updated room
            GameRoom updatedRoom = GameRoom(
              roomId: room.roomId,
              roomPassword: room.roomPassword,
              hostPlayerId: room.hostPlayerId,
              hostPlayerName: room.hostPlayerName,
              guestPlayerId: _currentPlayerId,
              guestPlayerName: _currentPlayerName,
              status: GameStatus.active,
              createdAt: room.createdAt,
              timeLimit: room.timeLimit,
            );

            return updatedRoom;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error joining room: $e');
      return null;
    }
  }
  // Update timer
  Future<void> updateTimer(String roomId, PieceColor player, int timeLeft) async {
    DatabaseReference gameRef = _database.ref('games/$roomId');

    if (player == PieceColor.white) {
      await gameRef.child('whiteTimeLeft').set(timeLeft);
    } else {
      await gameRef.child('blackTimeLeft').set(timeLeft);
    }

    // Check for timeout
    if (timeLeft <= 0) {
      await gameRef.update({
        'isGameOver': true,
        'gameResult': player == PieceColor.white
            ? 'Black wins - White ran out of time!'
            : 'White wins - Black ran out of time!',
      });
    }
  }


  // Listen to room changes
  Stream<GameRoom?> listenToRoom(String roomId) {
    return _database.ref('rooms/$roomId').onValue.map((event) {
      if (event.snapshot.exists) {
        return GameRoom.fromJson(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
      return null;
    });
  }

  // Listen to game state changes
  Stream<OnlineGameState?> listenToGameState(String roomId) {
    return _database.ref('games/$roomId').onValue.map((event) {
      if (event.snapshot.exists) {
        return OnlineGameState.fromJson(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
      return null;
    });
  }

  // Random matchmaking
  Future<GameRoom?> findRandomMatch({int timeLimit = 600}) async {
    if (_currentPlayerId == null) throw Exception('Player not initialized');

    // Look for waiting rooms
    Query query = _database.ref('rooms')
        .orderByChild('status')
        .equalTo('waiting');

    DatabaseEvent event = await query.once();

    if (event.snapshot.exists) {
      Map<String, dynamic> roomsData = Map<String, dynamic>.from(event.snapshot.value as Map);

      for (String roomId in roomsData.keys) {
        GameRoom room = GameRoom.fromJson(Map<String, dynamic>.from(roomsData[roomId]));

        if (room.hostPlayerId != _currentPlayerId && room.guestPlayerId == null) {
          // Join this room
          GameRoom updatedRoom = GameRoom(
            roomId: room.roomId,
            roomPassword: room.roomPassword,
            hostPlayerId: room.hostPlayerId,
            hostPlayerName: room.hostPlayerName,
            guestPlayerId: _currentPlayerId,
            guestPlayerName: _currentPlayerName,
            status: GameStatus.active,
            createdAt: room.createdAt,
            timeLimit: room.timeLimit,
          );

          await _database.ref('rooms/$roomId').set(updatedRoom.toJson());
          return updatedRoom;
        }
      }
    }

    // No rooms found, create one
    return await createRoom(timeLimit: timeLimit);
  }

  Future<void> _setPlayerOnlineStatus(bool isOnline) async {
    if (_currentPlayerId != null) {
      try {
        PlayerProfile profile = PlayerProfile(
          playerId: _currentPlayerId!,
          playerName: _currentPlayerName!,
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );

        await _database.ref('players/$_currentPlayerId').set(profile.toJson());

        if (isOnline) {
          // Set offline when app is closed
          await _database.ref('players/$_currentPlayerId/isOnline').onDisconnect().set(false);
          await _database.ref('players/$_currentPlayerId/lastSeen').onDisconnect().set(DateTime.now().toIso8601String());
        }
      } catch (e) {
        print('Error setting player online status: $e');
      }
    }
  }

  // Initialize game state
  Future<void> _initializeGameState(String roomId, int timeLimit) async {
    List<List<String?>> initialBoard = List.generate(8, (i) => List.filled(8, null));

    // Set up initial pieces (using piece IDs)
    initialBoard[0] = ['br1', 'bn1', 'bb1', 'bq', 'bk', 'bb2', 'bn2', 'br2'];
    initialBoard[1] = List.generate(8, (i) => 'bp$i');
    initialBoard[6] = List.generate(8, (i) => 'wp$i');
    initialBoard[7] = ['wr1', 'wn1', 'wb1', 'wq', 'wk', 'wb2', 'wn2', 'wr2'];

    OnlineGameState gameState = OnlineGameState(
      roomId: roomId,
      board: initialBoard,
      currentPlayer: 'white',
      moveHistory: [],
      capturedWhitePieces: [],
      capturedBlackPieces: [],
      whiteTimeLeft: timeLimit,
      blackTimeLeft: timeLimit,
      lastMoveBy: '',
      lastMoveTime: DateTime.now(),
    );

    await _database.ref('games/$roomId').set(gameState.toJson());
  }

  // Make a move
  Future<bool> makeMove({
    required String roomId,
    required Position from,
    required Position to,
    required String pieceId,
    String? capturedPieceId,
  }) async {
    if (_currentPlayerId == null) return false;

    DatabaseReference gameRef = _database.ref('games/$roomId');

    try {
      // Get current game state first
      final snapshot = await gameRef.get();

      if (!snapshot.exists) return false;

      OnlineGameState currentState = OnlineGameState.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map)
      );

      // Validate it's player's turn
      bool isWhiteTurn = currentState.currentPlayer == 'white';
      bool isPlayerWhite = await _isPlayerWhite(roomId);

      if (isWhiteTurn != isPlayerWhite) return false;

      // Update board
      List<List<String?>> newBoard = List.generate(8,
              (i) => List<String?>.from(currentState.board[i])
      );

      newBoard[to.row][to.col] = pieceId;
      newBoard[from.row][from.col] = null;

      // Update captured pieces
      List<String> newCapturedWhite = List.from(currentState.capturedWhitePieces);
      List<String> newCapturedBlack = List.from(currentState.capturedBlackPieces);

      if (capturedPieceId != null) {
        if (capturedPieceId.startsWith('w')) {
          newCapturedWhite.add(capturedPieceId);
        } else {
          newCapturedBlack.add(capturedPieceId);
        }
      }

      // Add move to history
      List<Map<String, dynamic>> newMoveHistory = List.from(currentState.moveHistory);
      newMoveHistory.add({
        'from': {'row': from.row, 'col': from.col},
        'to': {'row': to.row, 'col': to.col},
        'pieceId': pieceId,
        'capturedPieceId': capturedPieceId,
        'timestamp': DateTime.now().toIso8601String(),
        'playerId': _currentPlayerId,
      });

      // Check for game ending conditions
      bool gameOver = false;
      String? gameResult;

      // Check if king was captured
      if (capturedPieceId == 'wk') {
        gameOver = true;
        gameResult = 'Black wins - White king captured!';
      } else if (capturedPieceId == 'bk') {
        gameOver = true;
        gameResult = 'White wins - Black king captured!';
      }

      OnlineGameState newState = OnlineGameState(
        roomId: roomId,
        board: newBoard,
        currentPlayer: gameOver ? currentState.currentPlayer :
        (currentState.currentPlayer == 'white' ? 'black' : 'white'),
        moveHistory: newMoveHistory,
        capturedWhitePieces: newCapturedWhite,
        capturedBlackPieces: newCapturedBlack,
        whiteTimeLeft: currentState.whiteTimeLeft,
        blackTimeLeft: currentState.blackTimeLeft,
        isGameOver: gameOver,
        gameResult: gameResult,
        lastMoveBy: _currentPlayerId!,
        lastMoveTime: DateTime.now(),
      );

      // Use atomic update instead of transaction for better performance
      await gameRef.set(newState.toJson());
      return true;

    } catch (e) {
      print('Error making move: $e');
      return false;
    }
  }
  // Helper methods
  Future<bool> _isPlayerWhite(String roomId) async {
    final roomSnapshot = await _database.ref('rooms/$roomId').get();
    if (roomSnapshot.exists) {
      GameRoom room = GameRoom.fromJson(Map<String, dynamic>.from(roomSnapshot.value as Map));
      return room.hostPlayerId == _currentPlayerId;
    }
    return false;
  }

// Delete room (when host leaves)
  Future<void> deleteRoom(String roomId) async {
    try {
      // Delete room data
      await _database.ref('rooms/$roomId').remove();

      // Delete associated game data
      await _database.ref('games/$roomId').remove();

      print('Room deleted successfully: $roomId');
    } catch (e) {
      print('Error deleting room: $e');
    }
  }

// Update room status when guest joins
  Future<void> updateRoomWithGuest(String roomId, String guestPlayerId, String guestPlayerName) async {
    try {
      await _database.ref('rooms/$roomId').update({
        'guestPlayerId': guestPlayerId,
        'guestPlayerName': guestPlayerName,
        'status': 'active',
      });
    } catch (e) {
      print('Error updating room with guest: $e');
      rethrow;
    }
  }

// Clean up resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _setPlayerOnlineStatus(false);
    }
  }
}
