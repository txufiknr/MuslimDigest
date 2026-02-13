import 'package:flutter/material.dart';
import '../../widgets/animations/progress_bar.dart';
import '../../variables/user.dart';
import '../../config/feeds.dart';

/// Footer widget displaying reading streak progress
class ReadingStreakFooter extends StatelessWidget {
  const ReadingStreakFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = readCount / DAILY_READ_TARGET;
    // final remaining = DAILY_READ_TARGET - readCount;

    return AnimatedProgressBar(
      progress: progress,
      height: 6,
      backgroundColor: Colors.grey[200]!,
      // progressColor: _getProgressColor(progress),
      animationDuration: const Duration(milliseconds: 300),
    );

    // return Container(
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     border: Border(
    //       top: BorderSide(
    //         color: Colors.grey[200]!,
    //         width: 1,
    //       ),
    //     ),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       // Progress info
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           Text(
    //             'Daily Reading Streak',
    //             style: TextStyle(
    //               fontSize: 14,
    //               fontWeight: FontWeight.w600,
    //               color: Colors.grey[800],
    //             ),
    //           ),
    //           Text(
    //             '$readCount/$DAILY_READ_TARGET',
    //             style: TextStyle(
    //               fontSize: 14,
    //               fontWeight: FontWeight.w500,
    //               color: Colors.grey[600],
    //             ),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(height: 8),
          
    //       // Progress bar
    //       AnimatedProgressBar(
    //         progress: progress,
    //         height: 6,
    //         backgroundColor: Colors.grey[200]!,
    //         progressColor: _getProgressColor(progress),
    //         animationDuration: const Duration(milliseconds: 300),
    //       ),
    //       const SizedBox(height: 8),
          
    //       // Motivational text
    //       Text(
    //         _getMotivationalText(remaining),
    //         style: TextStyle(
    //           fontSize: 12,
    //           color: Colors.grey[600],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  // Color _getProgressColor(double progress) {
  //   if (progress >= 1.0) {
  //     return Colors.green;
  //   } else if (progress >= 0.7) {
  //     return Colors.blue;
  //   } else if (progress >= 0.4) {
  //     return Colors.orange;
  //   } else {
  //     return Colors.red;
  //   }
  // }

  // String _getMotivationalText(int remaining) {
  //   if (remaining <= 0) {
  //     return '🎉 Daily goal achieved! Keep up the great work!';
  //   } else if (remaining <= 5) {
  //     return '🔥 Almost there! $remaining more to go!';
  //   } else if (remaining <= 15) {
  //     return '💪 Good progress! $remaining articles remaining.';
  //   } else {
  //     return '📚 Start your reading journey! $remaining articles to read today.';
  //   }
  // }
}
