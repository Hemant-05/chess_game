enum PieceType { king, queen, rook, bishop, knight, pawn }
enum PieceColor { white, black }
enum GameMode { playerVsPlayer, playerVsComputer }
enum Difficulty { easy, medium, hard }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  final String id;

  ChessPiece({
    required this.type,
    required this.color,
    required this.id,
  });

  String get svgPath {
    String colorPrefix = color == PieceColor.white ? 'white' : 'black';
    String pieceTypeString = type.toString().split('.').last;
    return '${colorPrefix}${pieceTypeString[0].toUpperCase()}${pieceTypeString.substring(1)}';
  }
}

class ChessMove {
  final Position from;
  final Position to;
  final ChessPiece piece;
  final ChessPiece? capturedPiece;
  final bool isEnPassant;
  final bool isCastling;
  final PieceType? promotionPiece;

  ChessMove({
    required this.from,
    required this.to,
    required this.piece,
    this.capturedPiece,
    this.isEnPassant = false,
    this.isCastling = false,
    this.promotionPiece,
  });
}

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Position &&
              runtimeType == other.runtimeType &&
              row == other.row &&
              col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}

class GameState {
  final List<List<ChessPiece?>> board;
  final PieceColor currentPlayer;
  final List<ChessMove> moveHistory;
  final List<ChessPiece> capturedWhitePieces;
  final List<ChessPiece> capturedBlackPieces;
  final bool isGameOver;
  final String? gameResult;
  final int whiteTimeLeft;
  final int blackTimeLeft;

  GameState({
    required this.board,
    required this.currentPlayer,
    required this.moveHistory,
    required this.capturedWhitePieces,
    required this.capturedBlackPieces,
    this.isGameOver = false,
    this.gameResult,
    this.whiteTimeLeft = 600, // 10 minutes
    this.blackTimeLeft = 600, // 10 minutes
  });
}
