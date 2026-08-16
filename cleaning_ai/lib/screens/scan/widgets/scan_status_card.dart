import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../models/scanner_session.dart';
import '../ai_detect_screen.dart';

class ScanStatusCard extends StatelessWidget {
  final ScannerSession session;
  final VoidCallback onNextRoom;

  const ScanStatusCard({
    super.key,
    required this.session,
    required this.onNextRoom,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoom = session.currentRoom;
    final photosInCurrent = currentRoom.photoCount;
    final totalPhotos = session.totalCapturedPhotos;
    final bool currentHasMin = photosInCurrent >= 2;
    final bool hasNextRoom =
        session.currentRoomIndex < session.rooms.length - 1;
    final bool canStartAnalysis = totalPhotos >= 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassCard(
        baseColor: AppColors.glassWhite,
        glowColor: canStartAnalysis
            ? AppColors.secondaryPurple
            : Colors.transparent,
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left progress info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(currentRoom.icon,
                          size: 14, color: AppColors.secondaryPurple),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          currentRoom.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryPurple
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$photosInCurrent/3',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalPhotos > photosInCurrent
                        ? '$totalPhotos total photos across rooms'
                        : (photosInCurrent < 2
                            ? 'Take ${2 - photosInCurrent} more for this room'
                            : 'Room ready for analysis'),
                    style: AppTypography.bodySmall.copyWith(
                      color: photosInCurrent >= 2
                          ? AppColors.primaryTeal
                          : AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentHasMin && hasNextRoom)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: onNextRoom,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Next Room',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: canStartAnalysis
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AIDetectScreen(session: session),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryPurple,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Analyze',
                        style: AppTypography.bodySmall.copyWith(
                          color: canStartAnalysis ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
