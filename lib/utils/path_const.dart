class PathConst{
  // black pieces
static const String blackKing = 'assets/black/king.svg';
static const String blackQueen = 'assets/black/queen.svg';
static const String blackRook = 'assets/black/rook.svg';
static const String blackBishop = 'assets/black/bishop.svg';
static const String blackKnight = 'assets/black/knight.svg';
static const String blackPawn = 'assets/black/pawn.svg';

// white pieces
static const String whiteKing = 'assets/white/king.svg';
static const String whiteQueen = 'assets/white/queen.svg';
static const String whiteRook = 'assets/white/rook.svg';
static const String whiteBishop = 'assets/white/bishop.svg';
static const String whiteKnight = 'assets/white/knight.svg';
static const String whitePawn = 'assets/white/pawn.svg';

  static String getPiecePath(String pieceKey) {
    switch (pieceKey) {
      case 'whiteKing': return whiteKing;
      case 'whiteQueen': return whiteQueen;
      case 'whiteRook': return whiteRook;
      case 'whiteBishop': return whiteBishop;
      case 'whiteKnight': return whiteKnight;
      case 'whitePawn': return whitePawn;
      case 'blackKing': return blackKing;
      case 'blackQueen': return blackQueen;
      case 'blackRook': return blackRook;
      case 'blackBishop': return blackBishop;
      case 'blackKnight': return blackKnight;
      case 'blackPawn': return blackPawn;
      default: return '';
    }
  }
}