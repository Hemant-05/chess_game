import 'dart:math';
import '../models/chess_models.dart';
import 'game_logic.dart';

class AIPlayer {
  final Difficulty difficulty;
  final Random _random = Random();

  AIPlayer(this.difficulty);

  ChessMove? getAIMove(GameState gameState) {
    List<ChessMove> possibleMoves = _getAllPossibleMoves(gameState.board, PieceColor.black);

    if (possibleMoves.isEmpty) return null;

    switch (difficulty) {
      case Difficulty.easy:
        return possibleMoves[_random.nextInt(possibleMoves.length)];
      case Difficulty.medium:
        return _getMediumMove(gameState, possibleMoves);
      case Difficulty.hard:
        return _getHardMove(gameState, possibleMoves);
    }
  }

  List<ChessMove> _getAllPossibleMoves(List<List<ChessPiece?>> board, PieceColor color) {
    List<ChessMove> moves = [];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece != null && piece.color == color) {
          Position from = Position(row, col);
          List<Position> validMoves = ChessGameLogic.getValidMoves(board, from, piece);

          for (Position to in validMoves) {
            ChessPiece? capturedPiece = board[to.row][to.col];
            moves.add(ChessMove(
              from: from,
              to: to,
              piece: piece,
              capturedPiece: capturedPiece,
            ));
          }
        }
      }
    }

    return moves;
  }

  ChessMove _getMediumMove(GameState gameState, List<ChessMove> possibleMoves) {
    // Prioritize captures
    List<ChessMove> captureMoves = possibleMoves.where((move) => move.capturedPiece != null).toList();
    if (captureMoves.isNotEmpty) {
      return captureMoves[_random.nextInt(captureMoves.length)];
    }

    return possibleMoves[_random.nextInt(possibleMoves.length)];
  }

  ChessMove _getHardMove(GameState gameState, List<ChessMove> possibleMoves) {
    // Simple evaluation: prioritize high-value captures and central control
    ChessMove bestMove = possibleMoves[0];
    int bestScore = -1000;

    for (ChessMove move in possibleMoves) {
      int score = _evaluateMove(move, gameState.board);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  int _evaluateMove(ChessMove move, List<List<ChessPiece?>> board) {
    int score = 0;

    // Capture value
    if (move.capturedPiece != null) {
      score += _getPieceValue(move.capturedPiece!);
    }

    // Central control
    if (move.to.row >= 2 && move.to.row <= 5 && move.to.col >= 2 && move.to.col <= 5) {
      score += 10;
    }

    return score;
  }

  int _getPieceValue(ChessPiece piece) {
    switch (piece.type) {
      case PieceType.pawn:
        return 10;
      case PieceType.knight:
      case PieceType.bishop:
        return 30;
      case PieceType.rook:
        return 50;
      case PieceType.queen:
        return 90;
      case PieceType.king:
        return 1000;
    }
  }
}
