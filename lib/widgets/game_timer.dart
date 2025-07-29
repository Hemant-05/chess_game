import 'package:flutter/material.dart';
import 'dart:async';

class GameTimer extends StatefulWidget {
  final int initialTime;
  final bool isActive;
  final Function(int) onTimeUpdate;
  final VoidCallback? onTimeUp;

  const GameTimer({
    Key? key,
    required this.initialTime,
    required this.isActive,
    required this.onTimeUpdate,
    this.onTimeUp,
  }) : super(key: key);

  @override
  _GameTimerState createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  late int timeLeft;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timeLeft = widget.initialTime;
    _updateTimer();
  }

  @override
  void didUpdateWidget(GameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset timer if initial time changed (for restart functionality)
    if (widget.initialTime != oldWidget.initialTime) {
      timeLeft = widget.initialTime;
      _stopTimer();
      _updateTimer();
    } else if (widget.isActive != oldWidget.isActive) {
      _updateTimer();
    }
  }

  void _updateTimer() {
    if (widget.isActive && timeLeft > 0) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer(); // Ensure no duplicate timers
    timer = Timer.periodic(Duration(seconds: 1), (timer_) {
      print('------========== hay');
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
        widget.onTimeUpdate(timeLeft);
        print('========== $timeLeft');
      } else {
        print('------------ 1 hellow');
        timer_.cancel();
        widget.onTimeUp?.call();
        print('-----------hello ');
      }
    });
  }

  void _stopTimer() {
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = timeLeft ~/ 60;
    int seconds = timeLeft % 60;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isActive ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isActive ? Colors.red : Colors.grey,
          width: 2,
        ),
      ),
      child: Text(
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
