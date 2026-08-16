import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/scanner_session.dart';

/// Bottom sheet for manually adding a detected item.
class AddItemSheet extends StatefulWidget {
  final Function(ReviewItem) onAdd;

  const AddItemSheet({super.key, required this.onAdd});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _actionController = TextEditingController();
  final _freqController = TextEditingController(text: 'Every 7 days');
  ItemCategory _selectedCategory = ItemCategory.surfaces;

  @override
  void dispose() {
    _nameController.dispose();
    _actionController.dispose();
    _freqController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final action = _actionController.text.trim();
    final freq = _freqController.text.trim();
    if (name.isEmpty || action.isEmpty) return;

    widget.onAdd(ReviewItem(
      name: name,
      category: _selectedCategory,
      cleaningAction: action,
      frequency: freq.isEmpty ? 'Every 7 days' : freq,
      isManuallyAdded: true,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1220),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Add Item', style: AppTypography.heading2),
          const SizedBox(height: 4),
          Text('Add anything the AI may have missed.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),

          // Name field
          _buildField('Item Name', 'e.g. Bookshelf', _nameController),
          const SizedBox(height: 12),

          // Category picker
          Text('Category',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ItemCategory.values.map((cat) {
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: selected
                        ? AppColors.secondaryPurple.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: selected
                          ? AppColors.secondaryPurple.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    cat.displayName,
                    style: AppTypography.bodySmall.copyWith(
                      color: selected ? AppColors.secondaryPurple : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Cleaning action
          _buildField('Cleaning Action', 'e.g. Wipe', _actionController),
          const SizedBox(height: 12),

          // Frequency
          _buildField('Frequency', 'e.g. Every 7 days', _freqController),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text('Add Item',
                  style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.secondaryPurple.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ],
    );
  }
}
