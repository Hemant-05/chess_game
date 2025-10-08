import 'package:chess_game/models/online_models.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chess_models.dart';
import '../logic/game_logic.dart';
import '../services/firebase_service.dart';
import '../widgets/chess_board.dart';
import '../widgets/captured_pieces.dart';
import '../widgets/game_timer.dart';

class OnlineChessScreen extends StatefulWidget {
  final GameRoom room;

  const OnlineChessScreen({Key? key, required this.room}) : super(key: key);

  @override
  _OnlineChessScreenState createState() => _OnlineChessScreenState();
}

class _OnlineChessScreenState extends State<OnlineChessScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  OnlineGameState? onlineGameState;
  GameState? localGameState;
  Position? selectedPosition;
  List<Position> validMoves = [];
  bool isPlayerWhite = false;
  bool isMyTurn = false;
  bool _gameStarted = false;

  StreamSubscription<OnlineGameState?>? _gameStateSubscription;
  StreamSubscription<GameRoom?>? _roomSubscription;

  @override
  void initState() {
    super.initState();
    _initializeOnlineGame();
  }

  void _initializeOnlineGame() {
    isPlayerWhite =
        widget.room.hostPlayerId == _firebaseService.currentPlayerId;

    _gameStateSubscription = _firebaseService
        .listenToGameState(widget.room.roomId)
        .listen(_onGameStateChanged);

    _roomSubscription = _firebaseService
        .listenToRoom(widget.room.roomId)
        .listen(_onRoomChanged);
  }

  void _onGameStateChanged(OnlineGameState? newState) {
    if (newState != null) {
      // Check if this is the first time both players are present
      if (!_gameStarted && widget.room.guestPlayerId != null) {
        _gameStarted = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game Started! Good luck!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        onlineGameState = newState;
        localGameState = _convertToLocalGameState(newState);
        isMyTurn = _checkIfMyTurn(newState);

        // Clear selection if it's not player's turn
        if (!isMyTurn) {
          selectedPosition = null;
          validMoves = [];
        }
      });

      // Show game over dialog if game ended
      if (newState.isGameOver && newState.gameResult != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _showGameOverDialog(newState.gameResult!);
        });
      }
    }
  }

  void _onRoomChanged(GameRoom? room) {
    if (room == null) {
      // Room was deleted, navigate back
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Room was closed by host')));
    }
  }

  GameState _convertToLocalGameState(OnlineGameState onlineState) {
    // Convert online board to local board with actual ChessPiece objects
    List<List<ChessPiece?>> board = List.generate(
      8,
      (row) => List.generate(8, (col) {
        String? pieceId = onlineState.board[row][col];
        if (pieceId != null) {
          return _createPieceFromId(pieceId);
        }
        return null;
      }),
    );

    return GameState(
      board: board,
      currentPlayer: onlineState.currentPlayer == 'white'
          ? PieceColor.white
          : PieceColor.black,
      moveHistory: [], // Convert move history if needed
      capturedWhitePieces: onlineState.capturedWhitePieces
          .map(_createPieceFromId)
          .toList(),
      capturedBlackPieces: onlineState.capturedBlackPieces
          .map(_createPieceFromId)
          .toList(),
      whiteTimeLeft: onlineState.whiteTimeLeft,
      blackTimeLeft: onlineState.blackTimeLeft,
      isGameOver: onlineState.isGameOver,
      gameResult: onlineState.gameResult,
    );
  }

  ChessPiece _createPieceFromId(String pieceId) {
    PieceColor color = pieceId.startsWith('w')
        ? PieceColor.white
        : PieceColor.black;
    PieceType type;

    String typeChar = pieceId[1];
    switch (typeChar) {
      case 'k':
        type = PieceType.king;
        break;
      case 'q':
        type = PieceType.queen;
        break;
      case 'r':
        type = PieceType.rook;
        break;
      case 'b':
        type = PieceType.bishop;
        break;
      case 'n':
        type = PieceType.knight;
        break;
      case 'p':
        type = PieceType.pawn;
        break;
      default:
        type = PieceType.pawn;
    }

    return ChessPiece(type: type, color: color, id: pieceId);
  }

  bool _checkIfMyTurn(OnlineGameState gameState) {
    if (gameState.isGameOver) return false;

    bool isWhiteTurn = gameState.currentPlayer == 'white';
    return isWhiteTurn == isPlayerWhite;
  }

  void _onSquareTapped(Position position) {
    if (!isMyTurn || localGameState == null || localGameState!.isGameOver) {
      if (!isMyTurn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wait for your turn!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    ChessPiece? tappedPiece = localGameState!.board[position.row][position.col];

    // If no piece is selected
    if (selectedPosition == null) {
      if (tappedPiece != null) {
        // Check if it's the current player's piece
        PieceColor expectedColor = isPlayerWhite
            ? PieceColor.white
            : PieceColor.black;
        if (tappedPiece.color != expectedColor) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only move your own pieces!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }

        setState(() {
          selectedPosition = position;
          validMoves = ChessGameLogic.getValidMoves(
            localGameState!.board,
            position,
            tappedPiece,
          );
        });
      }
    } else {
      // A piece is already selected
      if (selectedPosition == position) {
        // Deselect if same square is tapped
        setState(() {
          selectedPosition = null;
          validMoves = [];
        });
      } else if (tappedPiece != null &&
          tappedPiece.color ==
              (isPlayerWhite ? PieceColor.white : PieceColor.black)) {
        // Select different piece of same color
        setState(() {
          selectedPosition = position;
          validMoves = ChessGameLogic.getValidMoves(
            localGameState!.board,
            position,
            tappedPiece,
          );
        });
      } else {
        // Try to move to the tapped position
        _attemptMove(selectedPosition!, position);
      }
    }
  }

  void _attemptMove(Position from, Position to) async {
    if (localGameState == null) return;

    PieceColor expectedColor = isPlayerWhite
        ? PieceColor.white
        : PieceColor.black;
    if (ChessGameLogic.isValidMove(
      localGameState!.board,
      from,
      to,
      expectedColor,
    )) {
      ChessPiece? movingPiece = localGameState!.board[from.row][from.col];
      ChessPiece? capturedPiece = localGameState!.board[to.row][to.col];

      if (movingPiece != null) {
        // Make move online
        bool success = await _firebaseService.makeMove(
          roomId: widget.room.roomId,
          from: from,
          to: to,
          pieceId: movingPiece.id,
          capturedPieceId: capturedPiece?.id,
        );

        if (success) {
          setState(() {
            selectedPosition = null;
            validMoves = [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to make move. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        selectedPosition = null;
        validMoves = [];
      });
    }
  }

  void _onTimeUpdate(int timeLeft, PieceColor player) {
    if (onlineGameState != null && isMyTurn) {
      _firebaseService.updateTimer(widget.room.roomId, player, timeLeft);
    }
  }

  void _showGameOverDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over!'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to main menu
              },
              child: Text('Back to Menu'),
            ),
          ],
        );
      },
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

  // Update the timer widgets to only be active when game has started
  Widget _buildPlayerTimer(bool isActive, int timeLeft, PieceColor player) {
    return GameTimer(
      key: ValueKey('${player.toString()}_timer_$timeLeft'),
      initialTime: timeLeft,
      isActive: isActive && _gameStarted && !localGameState!.isGameOver && widget.room.guestPlayerId != null,
      onTimeUpdate: (timeLeft) => _onTimeUpdate(timeLeft, player),
      onTimeUp: () { }//=> _onTimeUp(player),
    );
  }

  @override
  void dispose() {
    _gameStateSubscription?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (localGameState == null) {
      return Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        appBar: AppBar(
          title: Text('Online Chess'),
          backgroundColor: Color(0xFF16213e),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Loading game...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        return await _leaveRoom();
      } ,
      child: Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        appBar: AppBar(
          leading: IconButton(onPressed: () async {
            await _leaveRoom();
          }, icon: Icon(Icons.arrow_back,color: Colors.white,)),
          title: Text('Online Chess - Room: ${widget.room.roomPassword}',style: TextStyle(color: Colors.white),),
          backgroundColor: Color(0xFF16213e),
          actions: [
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Room Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room ID: ${widget.room.roomPassword}'),
                        Text('Host: ${widget.room.hostPlayerName}'),
                        if (widget.room.guestPlayerName != null)
                          Text('Guest: ${widget.room.guestPlayerName}')
                        else
                          Text('Guest: Waiting...'),
                        Text('You are: ${isPlayerWhite ? 'White' : 'Black'}'),
                        if (!_gameStarted && widget.room.guestPlayerId == null)
                          Text('\nWaiting for opponent to join...',
                              style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Game status indicator
                if (!_gameStarted || widget.room.guestPlayerId == null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    color: Colors.orange.withOpacity(0.2),
                    child: Text(
                      widget.room.guestPlayerId == null
                          ? 'Waiting for opponent to join...'
                          : 'Game starting...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Opponent info (top)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: (!isPlayerWhite && isMyTurn) ||
                                  (isPlayerWhite && !isMyTurn)
                                  ? Colors.red
                                  : Colors.grey,
                              child: Text(
                                isPlayerWhite ? 'B' : 'W',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isPlayerWhite
                                    ? (widget.room.guestPlayerName ?? 'Waiting...')
                                    : widget.room.hostPlayerName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildPlayerTimer(
                        !isMyTurn,
                        isPlayerWhite ? localGameState!.blackTimeLeft : localGameState!.whiteTimeLeft,
                        isPlayerWhite ? PieceColor.black : PieceColor.white,
                      ),
                    ],
                  ),
                ),

                // Opponent captured pieces
                CapturedPieces(
                  capturedPieces: isPlayerWhite
                      ? localGameState!.capturedBlackPieces
                      : localGameState!.capturedWhitePieces,
                  color: isPlayerWhite ? PieceColor.black : PieceColor.white,
                ),

                // Chess board
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: ChessBoard(
                      board: localGameState!.board,
                      validMoves: validMoves,
                      selectedPosition: selectedPosition,
                      onSquareTapped: _onSquareTapped,
                      currentPlayer: localGameState!.currentPlayer,
                    ),
                  ),
                ),

                // Player captured pieces
                CapturedPieces(
                  capturedPieces: isPlayerWhite
                      ? localGameState!.capturedWhitePieces
                      : localGameState!.capturedBlackPieces,
                  color: isPlayerWhite ? PieceColor.white : PieceColor.black,
                ),

                // Player info (bottom)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: isMyTurn
                                  ? Colors.red
                                  : Colors.grey,
                              child: Text(
                                isPlayerWhite ? 'W' : 'B',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isMyTurn)
                                    Text(
                                      'Your turn',
                                      style: TextStyle(
                                        color: Colors.yellow,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GameTimer(
                        key: ValueKey(
                          'playerTimer_${isPlayerWhite ? localGameState!.whiteTimeLeft : localGameState!.blackTimeLeft}',
                        ),
                        initialTime: isPlayerWhite
                            ? localGameState!.whiteTimeLeft
                            : localGameState!.blackTimeLeft,
                        isActive: isMyTurn && !localGameState!.isGameOver,
                        onTimeUpdate: (timeLeft) => _onTimeUpdate(
                          timeLeft,
                          isPlayerWhite ? PieceColor.white : PieceColor.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Game status
                if (localGameState!.isGameOver)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        localGameState!.gameResult ?? 'Game Over',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
