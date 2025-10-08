enum GameStatus { waiting, active, finished }
enum RoomType { create, join, random }

class GameRoom {
  final String roomId;
  final String roomPassword;
  final String hostPlayerId;
  final String hostPlayerName;
  final String? guestPlayerId;
  final String? guestPlayerName;
  final GameStatus status;
  final DateTime createdAt;
  final int timeLimit;

  GameRoom({
    required this.roomId,
    required this.roomPassword,
    required this.hostPlayerId,
    required this.hostPlayerName,
    this.guestPlayerId,
    this.guestPlayerName,
    this.status = GameStatus.waiting,
    required this.createdAt,
    this.timeLimit = 600,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      roomId: json['roomId'] ?? '',
      roomPassword: json['roomPassword'] ?? '',
      hostPlayerId: json['hostPlayerId'] ?? '',
      hostPlayerName: json['hostPlayerName'] ?? '',
      guestPlayerId: json['guestPlayerId'],
      guestPlayerName: json['guestPlayerName'],
      status: GameStatus.values.firstWhere(
            (e) => e.toString() == 'GameStatus.${json['status']}',
        orElse: () => GameStatus.waiting,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      timeLimit: json['timeLimit'] ?? 600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomPassword': roomPassword,
      'hostPlayerId': hostPlayerId,
      'hostPlayerName': hostPlayerName,
      'guestPlayerId': guestPlayerId,
      'guestPlayerName': guestPlayerName,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'timeLimit': timeLimit,
    };
  }
}

class OnlineGameState {
  final String roomId;
  final List<List<String?>> board; // Store piece IDs instead of objects
  final String currentPlayer; // 'white' or 'black'
  final List<Map<String, dynamic>> moveHistory;
  final List<String> capturedWhitePieces;
  final List<String> capturedBlackPieces;
  final int whiteTimeLeft;
  final int blackTimeLeft;
  final bool isGameOver;
  final String? gameResult;
  final String lastMoveBy;
  final DateTime lastMoveTime;

  OnlineGameState({
    required this.roomId,
    required this.board,
    required this.currentPlayer,
    required this.moveHistory,
    required this.capturedWhitePieces,
    required this.capturedBlackPieces,
    required this.whiteTimeLeft,
    required this.blackTimeLeft,
    this.isGameOver = false,
    this.gameResult,
    required this.lastMoveBy,
    required this.lastMoveTime,
  });

  factory OnlineGameState.fromJson(Map<String, dynamic> json) {
    try {
      // Handle board data with null safety
      List<List<String?>> boardData = [];
      if (json['board'] != null) {
        var boardJson = json['board'] as List;
        boardData = boardJson.map<List<String?>>((row) {
          if (row is List) {
            // Standard list row
            return List<String?>.from(row);
          } else if (row is Map) {
            // Convert sparse map {4:wp4} to list [null, null, null, null, wp4, null, ...]
            List<String?> tempRow = List.filled(8, null);
            (row).forEach((key, value) {
              int idx = int.parse(key.toString());
              tempRow[idx] = value as String?;
            });
            return tempRow;
          } else {
            // Should never happen, fallback to empty row
            return List<String?>.filled(8, null);
          }
        }).toList();
      } else {
        // Create empty board if null
        boardData = List.generate(8, (i) => List<String?>.filled(8, null));
      }

      // Handle move history with null safety
      List<Map<String, dynamic>> moveHistoryData = [];
      if (json['moveHistory'] != null) {
        moveHistoryData = List<Map<String, dynamic>>.from(
            (json['moveHistory'] as List).map((item) => Map<String, dynamic>.from(item as Map))
        );
      }

      // Handle captured pieces with null safety
      List<String> capturedWhiteData = [];
      if (json['capturedWhitePieces'] != null) {
        capturedWhiteData = List<String>.from(json['capturedWhitePieces'] as List);
      }

      List<String> capturedBlackData = [];
      if (json['capturedBlackPieces'] != null) {
        capturedBlackData = List<String>.from(json['capturedBlackPieces'] as List);
      }

      return OnlineGameState(
        roomId: json['roomId'] ?? '',
        board: boardData,
        currentPlayer: json['currentPlayer'] ?? 'white',
        moveHistory: moveHistoryData,
        capturedWhitePieces: capturedWhiteData,
        capturedBlackPieces: capturedBlackData,
        whiteTimeLeft: json['whiteTimeLeft'] ?? 600,
        blackTimeLeft: json['blackTimeLeft'] ?? 600,
        isGameOver: json['isGameOver'] ?? false,
        gameResult: json['gameResult'],
        lastMoveBy: json['lastMoveBy'] ?? '',
        lastMoveTime: DateTime.parse(
            json['lastMoveTime'] ?? DateTime.now().toIso8601String()
        ),
      );
    } catch (e) {
      print('Error parsing OnlineGameState: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'board': board,
      'currentPlayer': currentPlayer,
      'moveHistory': moveHistory,
      'capturedWhitePieces': capturedWhitePieces,
      'capturedBlackPieces': capturedBlackPieces,
      'whiteTimeLeft': whiteTimeLeft,
      'blackTimeLeft': blackTimeLeft,
      'isGameOver': isGameOver,
      'gameResult': gameResult,
      'lastMoveBy': lastMoveBy,
      'lastMoveTime': lastMoveTime.toIso8601String(),
    };
  }
}

class PlayerProfile {
  final String playerId;
  final String playerName;
  final bool isOnline;
  final DateTime lastSeen;

  PlayerProfile({
    required this.playerId,
    required this.playerName,
    required this.isOnline,
    required this.lastSeen,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}
