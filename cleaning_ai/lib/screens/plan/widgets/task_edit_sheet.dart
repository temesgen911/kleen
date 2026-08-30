import 'package:flutter/material.dart';
import '../../../../models/cleaning_plan.dart';
import '../../../../models/scanner_session.dart';
import '../../../../models/task_frequency.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

class TaskEditSheet extends StatefulWidget {
  final PlanTask? existingTask;
  final ReviewItem? existingItem;
  final String? defaultRoom;
  final Function(PlanTask updatedTask) onSaveTask;
  final VoidCallback? onDelete;

  const TaskEditSheet({
    super.key,
    this.existingTask,
    this.existingItem,
    this.defaultRoom,
    required this.onSaveTask,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    PlanTask? existingTask,
    ReviewItem? existingItem,
    String? defaultRoom,
    required Function(PlanTask updatedTask) onSaveTask,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: TaskEditSheet(
          existingTask: existingTask,
          existingItem: existingItem,
          defaultRoom: defaultRoom,
          onSaveTask: onSaveTask,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _roomController;
  late String _action;
  late int _estimatedMinutes;
  late TaskFrequency _frequency;
  late WeekDay _scheduledDay;

  final List<String> _actions = [
    'Wipe',
    'Vacuum',
    'Dust',
    'Mop',
    'Vacuum / Mop',
    'Scrub',
    'Sanitize',
    'Deep Clean',
  ];

  final List<String> _suggestedRooms = [
    'Living Room',
    'Kitchen',
    'Bathroom',
    'Bedroom',
    'Dining Room',
    'Hallway',
    'Office',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    final item = widget.existingItem;

    final initialName = task?.sourceItem.name ?? item?.name ?? '';
    final initialRoom = task?.roomName ?? item?.roomName ?? widget.defaultRoom ?? 'Living Room';
    _action = task?.sourceItem.cleaningAction ?? item?.cleaningAction ?? 'Wipe';
    _estimatedMinutes = task?.estimatedMinutes ?? 10;
    _frequency = task?.frequency ?? (item != null ? TaskFrequency.parse(item.frequency) : TaskFrequency.weekly);
    _scheduledDay = task?.scheduledDay ?? WeekDay.today;

    _nameController = TextEditingController(text: initialName);
    _roomController = TextEditingController(text: initialRoom);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.categoryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Text('Please enter an activity name.'),
        ),
      );
      return;
    }

    final roomName = _roomController.text.trim().isEmpty ? 'Living Room' : _roomController.text.trim();
    final taskId = widget.existingTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}';
    final itemId = widget.existingTask?.sourceItem.id ?? widget.existingItem?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}';

    final updatedSourceItem = ReviewItem(
      id: itemId,
      name: name,
      roomName: roomName,
      category: widget.existingTask?.sourceItem.category ?? widget.existingItem?.category ?? ItemCategory.surfaces,
      cleaningAction: _action,
      frequency: _frequency.displayName,
      isConfirmed: true,
    );

    final updatedTask = PlanTask(
      id: taskId,
      sourceItem: updatedSourceItem,
      estimatedMinutes: _estimatedMinutes,
      scheduledDay: _scheduledDay,
      frequency: _frequency,
      status: widget.existingTask?.status ?? TaskStatus.pending,
      aiTip: widget.existingTask?.aiTip ?? 'Custom activity set by user.',
      weekNumber: widget.existingTask?.weekNumber ?? 1,
    );

    widget.onSaveTask(updatedTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null || widget.existingItem != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141927),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.secondaryPurple.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grab Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Activity Details' : 'Add New Cleaning Activity',
                  style: AppTypography.heading2.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Activity Name
            Text(
              'Activity Name',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Wipe Coffee Table, Vacuum Rug',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryTeal),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Room Name
            Text(
              'Room',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roomController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Living Room, Bathroom',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryTeal),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestedRooms.map((room) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(room, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      backgroundColor: AppColors.surfaceDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        setState(() => _roomController.text = room);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Cleaning Action
            Text(
              'Cleaning Action',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _actions.map((act) {
                final isSelected = _action.toLowerCase() == act.toLowerCase();
                return ChoiceChip(
                  label: Text(act),
                  selected: isSelected,
                  selectedColor: AppColors.secondaryPurple,
                  backgroundColor: AppColors.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.secondaryPurple : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _action = act);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Duration Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Time',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$_estimatedMinutes minutes',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _estimatedMinutes.toDouble(),
              min: 2,
              max: 90,
              divisions: 88,
              activeColor: AppColors.primaryTeal,
              inactiveColor: Colors.white.withValues(alpha: 0.1),
              onChanged: (val) {
                setState(() => _estimatedMinutes = val.round());
              },
            ),
            const SizedBox(height: 16),

            // Recurrence Frequency
            Text(
              'How Often Should It Repeat?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskFrequency.values.map((freq) {
                  final isSelected = _frequency == freq;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(freq.displayName),
                      selected: isSelected,
                      selectedColor: AppColors.categoryGold,
                      backgroundColor: AppColors.surfaceDark,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.backgroundStart : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppColors.categoryGold : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _frequency = freq);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Scheduled Day
            Text(
              'Scheduled Day',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: WeekDay.values.map((day) {
                  final isSelected = _scheduledDay == day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(day.displayName.substring(0, 3)),
                      selected: isSelected,
                      selectedColor: AppColors.secondaryPurple,
                      backgroundColor: AppColors.surfaceDark,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _scheduledDay = day);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Save / Delete Buttons
            Row(
              children: [
                if (widget.onDelete != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete!();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.backgroundStart,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add Activity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
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
