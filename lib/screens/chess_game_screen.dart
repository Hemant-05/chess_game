import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chess_models.dart';
import '../logic/game_logic.dart';
import '../logic/ai_player.dart';
import '../widgets/chess_board.dart';
import '../widgets/captured_pieces.dart';
import '../widgets/game_timer.dart';

class ChessGameScreen extends StatefulWidget {
  @override
  _ChessGameScreenState createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  late GameState gameState;
  Position? selectedPosition;
  List<Position> validMoves = [];
  GameMode gameMode = GameMode.playerVsPlayer;
  Difficulty aiDifficulty = Difficulty.medium;
  AIPlayer? aiPlayer;
  bool isThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    setState(() {
      gameState = GameState(
        board: ChessGameLogic.initializeBoard(),
        currentPlayer: PieceColor.white,
        moveHistory: [],
        capturedWhitePieces: [],
        capturedBlackPieces: [],
        whiteTimeLeft: 5, // Reset to 10 minutes
        blackTimeLeft: 600, // Reset to 10 minutes
        isGameOver: false,
        gameResult: null,
      );

      selectedPosition = null;
      validMoves = [];
      isThinking = false;
    });

    if (gameMode == GameMode.playerVsComputer) {
      aiPlayer = AIPlayer(aiDifficulty);
    }
  }

  void _onSquareTapped(Position position) {
    if (gameState.isGameOver) {
      _showGameOverDialog();
      return;
    }

    ChessPiece? tappedPiece = gameState.board[position.row][position.col];

    // If no piece is selected
    if (selectedPosition == null) {
      if (tappedPiece != null) {
        // Check if it's the current player's piece
        if (tappedPiece.color != gameState.currentPlayer) {
          _showWrongPlayerWarning();
          return;
        }

        setState(() {
          selectedPosition = position;
          validMoves = ChessGameLogic.getValidMoves(
              gameState.board,
              position,
              tappedPiece
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
      } else if (tappedPiece != null && tappedPiece.color == gameState.currentPlayer) {
        // Select different piece of same color
        setState(() {
          selectedPosition = position;
          validMoves = ChessGameLogic.getValidMoves(
              gameState.board,
              position,
              tappedPiece
          );
        });
      } else {
        // Try to move to the tapped position
        _attemptMove(selectedPosition!, position);
      }
    }
  }

  void _attemptMove(Position from, Position to) {
    if (ChessGameLogic.isValidMove(gameState.board, from, to, gameState.currentPlayer)) {
      _makeMove(from, to);
    } else {
      setState(() {
        selectedPosition = null;
        validMoves = [];
      });
    }
  }

  void _makeMove(Position from, Position to) {
    ChessPiece? movingPiece = gameState.board[from.row][from.col];
    ChessPiece? capturedPiece = gameState.board[to.row][to.col];

    if (movingPiece == null) return;

    // Create the move
    ChessMove move = ChessMove(
      from: from,
      to: to,
      piece: movingPiece,
      capturedPiece: capturedPiece,
    );

    // Update board
    List<List<ChessPiece?>> newBoard = List.generate(8, (i) => List.from(gameState.board[i]));
    newBoard[to.row][to.col] = movingPiece;
    newBoard[from.row][from.col] = null;

    // Update captured pieces
    List<ChessPiece> newCapturedWhite = List.from(gameState.capturedWhitePieces);
    List<ChessPiece> newCapturedBlack = List.from(gameState.capturedBlackPieces);

    if (capturedPiece != null) {
      if (capturedPiece.color == PieceColor.white) {
        newCapturedWhite.add(capturedPiece);
      } else {
        newCapturedBlack.add(capturedPiece);
      }
    }

    // Check for game ending conditions
    bool gameOver = false;
    String? gameResult;

    // Check if king was captured
    if (capturedPiece != null && capturedPiece.type == PieceType.king) {
      gameOver = true;
      gameResult = capturedPiece.color == PieceColor.white
          ? 'Black wins by capturing the king!'
          : 'White wins by capturing the king!';
    }

    // Check if opponent has no pieces left
    if (!gameOver) {
      PieceColor opponentColor = gameState.currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white;

      bool hasOpponentPieces = false;
      for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
          if (newBoard[row][col]?.color == opponentColor) {
            hasOpponentPieces = true;
            break;
          }
        }
        if (hasOpponentPieces) break;
      }

      if (!hasOpponentPieces) {
        gameOver = true;
        gameResult = gameState.currentPlayer == PieceColor.white
            ? 'White wins - Black has no pieces left!'
            : 'Black wins - White has no pieces left!';
      }
    }

    // Update game state
    setState(() {
      gameState = GameState(
        board: newBoard,
        currentPlayer: gameOver ? gameState.currentPlayer : (gameState.currentPlayer == PieceColor.white
            ? PieceColor.black
            : PieceColor.white),
        moveHistory: [...gameState.moveHistory, move],
        capturedWhitePieces: newCapturedWhite,
        capturedBlackPieces: newCapturedBlack,
        whiteTimeLeft: gameState.whiteTimeLeft,
        blackTimeLeft: gameState.blackTimeLeft,
        isGameOver: gameOver,
        gameResult: gameResult,
      );
      selectedPosition = null;
      validMoves = [];
    });

    // Show game over dialog if game ended
    if (gameOver) {
      Future.delayed(Duration(milliseconds: 500), () {
        _showGameOverDialog();
      });
      return;
    }

    // Check for AI move
    if (gameMode == GameMode.playerVsComputer &&
        gameState.currentPlayer == PieceColor.black &&
        !gameState.isGameOver) {
      _makeAIMove();
    }
  }

  void _makeAIMove() async {
    if (aiPlayer == null) return;

    setState(() {
      isThinking = true;
    });

    // Add delay to simulate thinking
    await Future.delayed(Duration(milliseconds: 1000));

    ChessMove? aiMove = aiPlayer!.getAIMove(gameState);

    if (aiMove != null) {
      _makeMove(aiMove.from, aiMove.to);
    }

    setState(() {
      isThinking = false;
    });
  }

  void _undoMove() {
    if (gameState.moveHistory.isEmpty || gameState.isGameOver) return;

    ChessMove lastMove = gameState.moveHistory.last;
    List<List<ChessPiece?>> newBoard = List.generate(8, (i) => List.from(gameState.board[i]));

    // Restore the moving piece to its original position
    newBoard[lastMove.from.row][lastMove.from.col] = lastMove.piece;
    newBoard[lastMove.to.row][lastMove.to.col] = lastMove.capturedPiece;

    // Restore captured pieces
    List<ChessPiece> newCapturedWhite = List.from(gameState.capturedWhitePieces);
    List<ChessPiece> newCapturedBlack = List.from(gameState.capturedBlackPieces);

    if (lastMove.capturedPiece != null) {
      if (lastMove.capturedPiece!.color == PieceColor.white) {
        newCapturedWhite.removeLast();
      } else {
        newCapturedBlack.removeLast();
      }
    }

    setState(() {
      gameState = GameState(
        board: newBoard,
        currentPlayer: gameState.currentPlayer == PieceColor.white
            ? PieceColor.black
            : PieceColor.white,
        moveHistory: gameState.moveHistory.sublist(0, gameState.moveHistory.length - 1),
        capturedWhitePieces: newCapturedWhite,
        capturedBlackPieces: newCapturedBlack,
        whiteTimeLeft: gameState.whiteTimeLeft,
        blackTimeLeft: gameState.blackTimeLeft,
        isGameOver: false,
        gameResult: null,
      );
      selectedPosition = null;
      validMoves = [];
    });
  }

  void _showWrongPlayerWarning() {
    if (!gameState.isGameOver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('It\'s ${gameState.currentPlayer == PieceColor.white ? 'White' : 'Black'}\'s turn!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showGameModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Game Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Player vs Player'),
                onTap: () {
                  setState(() {
                    gameMode = GameMode.playerVsPlayer;
                  });
                  Navigator.of(context).pop();
                  _initializeGame();
                },
              ),
              ListTile(
                title: Text('Player vs Computer'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDifficultyDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Difficulty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Easy'),
                onTap: () {
                  setState(() {
                    gameMode = GameMode.playerVsComputer;
                    aiDifficulty = Difficulty.easy;
                  });
                  Navigator.of(context).pop();
                  _initializeGame();
                },
              ),
              ListTile(
                title: Text('Medium'),
                onTap: () {
                  setState(() {
                    gameMode = GameMode.playerVsComputer;
                    aiDifficulty = Difficulty.medium;
                  });
                  Navigator.of(context).pop();
                  _initializeGame();
                },
              ),
              ListTile(
                title: Text('Hard'),
                onTap: () {
                  setState(() {
                    gameMode = GameMode.playerVsComputer;
                    aiDifficulty = Difficulty.hard;
                  });
                  Navigator.of(context).pop();
                  _initializeGame();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over!'),
          content: Text(gameState.gameResult ?? 'Game has ended'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
              child: Text('New Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showGameModeDialog();
              },
              child: Text('Change Mode'),
            ),
          ],
        );
      },
    );
  }

  void _onTimeUpdate(int timeLeft, PieceColor player) {
    if (gameState.isGameOver) return;

    setState(() {
      if (player == PieceColor.white) {
        gameState = GameState(
          board: gameState.board,
          currentPlayer: gameState.currentPlayer,
          moveHistory: gameState.moveHistory,
          capturedWhitePieces: gameState.capturedWhitePieces,
          capturedBlackPieces: gameState.capturedBlackPieces,
          whiteTimeLeft: timeLeft,
          blackTimeLeft: gameState.blackTimeLeft,
          isGameOver: gameState.isGameOver,
          gameResult: gameState.gameResult,
        );
      } else {
        gameState = GameState(
          board: gameState.board,
          currentPlayer: gameState.currentPlayer,
          moveHistory: gameState.moveHistory,
          capturedWhitePieces: gameState.capturedWhitePieces,
          capturedBlackPieces: gameState.capturedBlackPieces,
          whiteTimeLeft: gameState.whiteTimeLeft,
          blackTimeLeft: timeLeft,
          isGameOver: gameState.isGameOver,
          gameResult: gameState.gameResult,
        );
      }
    });
  }

  void _onTimeUp(PieceColor player) {
    print('-------------- time up');
    setState(() {
      gameState = GameState(
        board: gameState.board,
        currentPlayer: gameState.currentPlayer,
        moveHistory: gameState.moveHistory,
        capturedWhitePieces: gameState.capturedWhitePieces,
        capturedBlackPieces: gameState.capturedBlackPieces,
        whiteTimeLeft: player == PieceColor.white ? 0 : gameState.whiteTimeLeft,
        blackTimeLeft: player == PieceColor.black ? 0 : gameState.blackTimeLeft,
        isGameOver: true,
        gameResult: player == PieceColor.white
            ? 'Black wins - White ran out of time!'
            : 'White wins - Black ran out of time!',
      );
    });
    print('-helllo');
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        print('-------------- $mounted :');
        _showGameOverDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text('Chess Game',style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF16213e),
        actions: [
          // Undo button in app bar
          IconButton(
            icon: Icon(Icons.undo,color: Colors.white,),
            onPressed: gameState.moveHistory.isNotEmpty && !gameState.isGameOver
                ? _undoMove
                : null,
            tooltip: 'Undo Move',
          ),
          // Restart button in app bar
          IconButton(
            icon: Icon(Icons.refresh,color: Colors.white,),
            onPressed: () {
              _initializeGame();
            },
            tooltip: 'Restart Game',
          ),
          // Settings button
          IconButton(
            icon: Icon(Icons.settings,color: Colors.white,),
            onPressed: _showGameModeDialog,
            tooltip: 'Game Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Black player info and timer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16,vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: gameState.currentPlayer == PieceColor.black
                              ? Colors.red
                              : Colors.grey,
                          child: Text(
                            'B',
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
                                gameMode == GameMode.playerVsComputer ? 'Computer' : 'Black',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isThinking)
                                Text(
                                  'Thinking...',
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
                    key: ValueKey('blackTimer_${gameState.blackTimeLeft}'),
                    initialTime: gameState.blackTimeLeft,
                    isActive: gameState.currentPlayer == PieceColor.black && !gameState.isGameOver,
                    onTimeUpdate: (timeLeft) => _onTimeUpdate(timeLeft, PieceColor.black),
                    onTimeUp: () => _onTimeUp(PieceColor.black),
                  ),
                ],
              ),
            ),

            // Captured black pieces
            CapturedPieces(
              capturedPieces: gameState.capturedBlackPieces,
              color: PieceColor.black,
            ),

            // Chess board
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: ChessBoard(
                  board: gameState.board,
                  validMoves: validMoves,
                  selectedPosition: selectedPosition,
                  onSquareTapped: _onSquareTapped,
                  currentPlayer: gameState.currentPlayer,
                ),
              ),
            ),

            // Captured white pieces
            CapturedPieces(
              capturedPieces: gameState.capturedWhitePieces,
              color: PieceColor.white,
            ),

            // White player info and timer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16,vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: gameState.currentPlayer == PieceColor.white
                              ? Colors.red
                              : Colors.grey,
                          child: Text(
                            'W',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'White',
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
                  GameTimer(
                    key: ValueKey('whiteTimer_${gameState.whiteTimeLeft}'),
                    initialTime: gameState.whiteTimeLeft,
                    isActive: gameState.currentPlayer == PieceColor.white && !gameState.isGameOver,
                    onTimeUpdate: (timeLeft) => _onTimeUpdate(timeLeft, PieceColor.white),
                    onTimeUp: () => _onTimeUp(PieceColor.white),
                  ),
                ],
              ),
            ),

            // Game status display
            /*if (gameState.isGameOver)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  gameState.gameResult ?? 'Game Over',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),*/
          ],
        ),
      ),
    );
  }
}
