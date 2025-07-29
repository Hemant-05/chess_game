import '../models/chess_models.dart';
import '../utils/path_const.dart';

class ChessGameLogic {
  static List<List<ChessPiece?>> initializeBoard() {
    List<List<ChessPiece?>> board = List.generate(8, (i) => List.filled(8, null));

    // Place black pieces
    board[0][0] = ChessPiece(type: PieceType.rook, color: PieceColor.black, id: 'br1');
    board[0][1] = ChessPiece(type: PieceType.knight, color: PieceColor.black, id: 'bn1');
    board[0][2] = ChessPiece(type: PieceType.bishop, color: PieceColor.black, id: 'bb1');
    board[0][3] = ChessPiece(type: PieceType.queen, color: PieceColor.black, id: 'bq');
    board[0][4] = ChessPiece(type: PieceType.king, color: PieceColor.black, id: 'bk');
    board[0][5] = ChessPiece(type: PieceType.bishop, color: PieceColor.black, id: 'bb2');
    board[0][6] = ChessPiece(type: PieceType.knight, color: PieceColor.black, id: 'bn2');
    board[0][7] = ChessPiece(type: PieceType.rook, color: PieceColor.black, id: 'br2');

    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.black, id: 'bp$i');
    }

    // Place white pieces
    board[7][0] = ChessPiece(type: PieceType.rook, color: PieceColor.white, id: 'wr1');
    board[7][1] = ChessPiece(type: PieceType.knight, color: PieceColor.white, id: 'wn1');
    board[7][2] = ChessPiece(type: PieceType.bishop, color: PieceColor.white, id: 'wb1');
    board[7][3] = ChessPiece(type: PieceType.queen, color: PieceColor.white, id: 'wq');
    board[7][4] = ChessPiece(type: PieceType.king, color: PieceColor.white, id: 'wk');
    board[7][5] = ChessPiece(type: PieceType.bishop, color: PieceColor.white, id: 'wb2');
    board[7][6] = ChessPiece(type: PieceType.knight, color: PieceColor.white, id: 'wn2');
    board[7][7] = ChessPiece(type: PieceType.rook, color: PieceColor.white, id: 'wr2');

    for (int i = 0; i < 8; i++) {
      board[6][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.white, id: 'wp$i');
    }

    return board;
  }

  static List<Position> getValidMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> validMoves = [];

    switch (piece.type) {
      case PieceType.pawn:
        validMoves = _getPawnMoves(board, position, piece);
        break;
      case PieceType.rook:
        validMoves = _getRookMoves(board, position, piece);
        break;
      case PieceType.knight:
        validMoves = _getKnightMoves(board, position, piece);
        break;
      case PieceType.bishop:
        validMoves = _getBishopMoves(board, position, piece);
        break;
      case PieceType.queen:
        validMoves = _getQueenMoves(board, position, piece);
        break;
      case PieceType.king:
        validMoves = _getKingMoves(board, position, piece);
        break;
    }

    return validMoves;
  }

  static List<Position> _getPawnMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> moves = [];
    int direction = piece.color == PieceColor.white ? -1 : 1;
    int startRow = piece.color == PieceColor.white ? 6 : 1;

    // Forward move
    int newRow = position.row + direction;
    if (newRow >= 0 && newRow < 8 && board[newRow][position.col] == null) {
      moves.add(Position(newRow, position.col));

      // Double forward move from starting position
      if (position.row == startRow) {
        newRow = position.row + (2 * direction);
        if (newRow >= 0 && newRow < 8 && board[newRow][position.col] == null) {
          moves.add(Position(newRow, position.col));
        }
      }
    }

    // Diagonal captures
    for (int colOffset in [-1, 1]) {
      int newCol = position.col + colOffset;
      newRow = position.row + direction;
      if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
        ChessPiece? targetPiece = board[newRow][newCol];
        if (targetPiece != null && targetPiece.color != piece.color) {
          moves.add(Position(newRow, newCol));
        }
      }
    }

    return moves;
  }

  static List<Position> _getRookMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> moves = [];
    List<List<int>> directions = [[0, 1], [0, -1], [1, 0], [-1, 0]];

    for (List<int> direction in directions) {
      for (int i = 1; i < 8; i++) {
        int newRow = position.row + (direction[0] * i);
        int newCol = position.col + (direction[1] * i);

        if (newRow < 0 || newRow >= 8 || newCol < 0 || newCol >= 8) break;

        ChessPiece? targetPiece = board[newRow][newCol];
        if (targetPiece == null) {
          moves.add(Position(newRow, newCol));
        } else {
          if (targetPiece.color != piece.color) {
            moves.add(Position(newRow, newCol));
          }
          break;
        }
      }
    }

    return moves;
  }

  static List<Position> _getKnightMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> moves = [];
    List<List<int>> knightMoves = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ];

    for (List<int> move in knightMoves) {
      int newRow = position.row + move[0];
      int newCol = position.col + move[1];

      if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
        ChessPiece? targetPiece = board[newRow][newCol];
        if (targetPiece == null || targetPiece.color != piece.color) {
          moves.add(Position(newRow, newCol));
        }
      }
    }

    return moves;
  }

  static List<Position> _getBishopMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> moves = [];
    List<List<int>> directions = [[1, 1], [1, -1], [-1, 1], [-1, -1]];

    for (List<int> direction in directions) {
      for (int i = 1; i < 8; i++) {
        int newRow = position.row + (direction[0] * i);
        int newCol = position.col + (direction[1] * i);

        if (newRow < 0 || newRow >= 8 || newCol < 0 || newCol >= 8) break;

        ChessPiece? targetPiece = board[newRow][newCol];
        if (targetPiece == null) {
          moves.add(Position(newRow, newCol));
        } else {
          if (targetPiece.color != piece.color) {
            moves.add(Position(newRow, newCol));
          }
          break;
        }
      }
    }

    return moves;
  }

  static List<Position> _getQueenMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> moves = [];
    moves.addAll(_getRookMoves(board, position, piece));
    moves.addAll(_getBishopMoves(board, position, piece));
    return moves;
  }

  static List<Position> _getKingMoves(
      List<List<ChessPiece?>> board,
      Position position,
      ChessPiece piece,
      ) {
    List<Position> moves = [];
    List<List<int>> directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1], [0, 1],
      [1, -1], [1, 0], [1, 1]
    ];

    for (List<int> direction in directions) {
      int newRow = position.row + direction[0];
      int newCol = position.col + direction[1];

      if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
        ChessPiece? targetPiece = board[newRow][newCol];
        if (targetPiece == null || targetPiece.color != piece.color) {
          moves.add(Position(newRow, newCol));
        }
      }
    }

    return moves;
  }

  static bool isValidMove(
      List<List<ChessPiece?>> board,
      Position from,
      Position to,
      PieceColor currentPlayer,
      ) {
    ChessPiece? piece = board[from.row][from.col];
    if (piece == null || piece.color != currentPlayer) return false;

    List<Position> validMoves = getValidMoves(board, from, piece);
    return validMoves.contains(to);
  }

  static bool isInCheck(List<List<ChessPiece?>> board, PieceColor kingColor) {
    // Find king position
    Position? kingPosition;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece != null && piece.type == PieceType.king && piece.color == kingColor) {
          kingPosition = Position(row, col);
          break;
        }
      }
    }

    if (kingPosition == null) return false;

    // Check if any opponent piece can attack the king
    PieceColor opponentColor = kingColor == PieceColor.white ? PieceColor.black : PieceColor.white;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece != null && piece.color == opponentColor) {
          List<Position> moves = getValidMoves(board, Position(row, col), piece);
          if (moves.contains(kingPosition)) {
            return true;
          }
        }
      }
    }

    return false;
  }
}
