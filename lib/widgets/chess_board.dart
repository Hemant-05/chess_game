import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/chess_models.dart';
import '../logic/game_logic.dart';
import 'chess_piece_widget.dart';

class ChessBoard extends StatelessWidget {
  final List<List<ChessPiece?>> board;
  final List<Position> validMoves;
  final Position? selectedPosition;
  final Function(Position) onSquareTapped;
  final PieceColor currentPlayer;

  const ChessBoard({
    Key? key,
    required this.board,
    required this.validMoves,
    this.selectedPosition,
    required this.onSquareTapped,
    required this.currentPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Make board responsive and prevent overflow
    double maxBoardSize = math.min(screenWidth * 0.9, screenHeight * 0.5);
    double boardSize = maxBoardSize;

    return Container(
      width: boardSize,
      height: boardSize,
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.95,
        maxHeight: screenHeight * 0.5,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown, width: 2),
      ),
      child: Column(
        children: List.generate(8, (row) {
          return Expanded(
            child: Row(
              children: List.generate(8, (col) {
                bool isLightSquare = (row + col) % 2 == 0;
                bool isSelected = selectedPosition?.row == row && selectedPosition?.col == col;
                bool isValidMove = validMoves.any((pos) => pos.row == row && pos.col == col);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSquareTapped(Position(row, col)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.yellow.withOpacity(0.8)
                            : isLightSquare
                            ? Color(0xFFF0D9B5)
                            : Color(0xFFB58863),
                        border: isValidMove
                            ? Border.all(color: Colors.green, width: 3)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (isValidMove && board[row][col] == null)
                            Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (board[row][col] != null)
                            Center(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double pieceSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.8;
                                  return ChessPieceWidget(
                                    piece: board[row][col]!,
                                    size: pieceSize,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
