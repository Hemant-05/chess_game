import 'package:flutter/material.dart';
import '../models/chess_models.dart';
import 'chess_piece_widget.dart';

class CapturedPieces extends StatelessWidget {
  final List<ChessPiece> capturedPieces;
  final PieceColor color;

  const CapturedPieces({
    Key? key,
    required this.capturedPieces,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ChessPiece> filteredPieces = capturedPieces
        .where((piece) => piece.color == color)
        .toList();

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white,width: 1)
      ),
      child: Row(
        children: [
          Text(
            color == PieceColor.white ? 'White: ' : 'Black: ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filteredPieces.map((piece) {
                  return Container(
                    width: 30,
                    height: 30,
                    padding: EdgeInsets.only(right: 4),
                    child: ChessPieceWidget(
                      piece: piece,
                      size: 30,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
