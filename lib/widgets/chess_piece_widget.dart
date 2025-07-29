import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/chess_models.dart';
import '../utils/path_const.dart';

class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;

  const ChessPieceWidget({
    Key? key,
    required this.piece,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String svgPath = PathConst.getPiecePath(piece.svgPath);

    return Container(
      width: size,
      height: size,
      child: SvgPicture.asset(
        svgPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
