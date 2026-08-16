import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../../../models/scanner_session.dart';
import 'review_item_row.dart';
import 'add_item_sheet.dart';

/// The large glass card that shows all detected items grouped by category and filtered by room.
class DetectedItemsCard extends StatefulWidget {
  final ScannerSession session;
  final VoidCallback onSessionChanged;

  const DetectedItemsCard({
    super.key,
    required this.session,
    required this.onSessionChanged,
  });

  @override
  State<DetectedItemsCard> createState() => _DetectedItemsCardState();
}

class _DetectedItemsCardState extends State<DetectedItemsCard> {
  bool _editMode = false;
  String _selectedRoom = 'All';

  Color _accentFor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.surfaces:
        return AppColors.categoryBlue;
      case ItemCategory.furniture:
        return AppColors.categoryPurple;
      case ItemCategory.electronics:
        return AppColors.categoryOrange;
      case ItemCategory.other:
        return AppColors.categoryGold;
    }
  }

  IconData _iconFor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.surfaces:
        return Icons.layers_outlined;
      case ItemCategory.furniture:
        return Icons.chair_outlined;
      case ItemCategory.electronics:
        return Icons.devices_outlined;
      case ItemCategory.other:
        return Icons.category_outlined;
    }
  }

  void _openAddItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(
        onAdd: (item) {
          setState(() => widget.session.addItem(item));
          widget.onSessionChanged();
        },
      ),
    );
  }

  void _toggleAll(bool confirmed) {
    setState(() {
      for (final item in widget.session.reviewItems) {
        if (_selectedRoom == 'All' || item.roomName == _selectedRoom) {
          item.isConfirmed = confirmed;
        }
      }
    });
    widget.onSessionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.session.totalCount;
    final roomNames = ['All', ...widget.session.availableRoomNames];

    final filteredItems = _selectedRoom == 'All'
        ? widget.session.reviewItems
        : widget.session.itemsForRoom(_selectedRoom);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(alpha: 0.2),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1.5),
                    ),
                    child:
                        Icon(Icons.check, size: 13, color: Colors.green[400]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detected Items ($total)',
                    style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _editMode = !_editMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        _editMode ? 'Done' : 'Edit All',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Room Filter Pills ──────────────────────────────────────────
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: roomNames.map((room) {
                  final isSelected = _selectedRoom == room;
                  final count = room == 'All'
                      ? total
                      : widget.session.itemsForRoom(room).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRoom = room),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryPurple
                                  .withValues(alpha: 0.22)
                              : AppColors.surfaceDark.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondaryPurple
                                : Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondaryPurple
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              room,
                              style: AppTypography.bodySmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($count)',
                              style: AppTypography.bodySmall.copyWith(
                                color: isSelected
                                    ? AppColors.secondaryPurple
                                    : AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Edit mode toolbar
            if (_editMode) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _EditChip(
                      label: 'Select All',
                      onTap: () => _toggleAll(true),
                    ),
                    const SizedBox(width: 8),
                    _EditChip(
                      label: 'Deselect All',
                      onTap: () => _toggleAll(false),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0x22FFFFFF)),

            // ── Categories ──────────────────────────────────────────────────
            ...ItemCategory.values.map((cat) {
              final items = filteredItems.where((i) => i.category == cat).toList();
              if (items.isEmpty) return const SizedBox.shrink();
              return _CategorySection(
                category: cat,
                accent: _accentFor(cat),
                icon: _iconFor(cat),
                items: items,
                editMode: _editMode,
                onToggle: (id) {
                  setState(() => widget.session.toggleConfirmed(id));
                  widget.onSessionChanged();
                },
              );
            }),

            // ── Add Item footer ──────────────────────────────────────────────
            const Divider(height: 1, color: Color(0x22FFFFFF)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missing something?',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add any items that weren\'t detected.',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openAddItem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentOrange.withValues(alpha: 0.85),
                            AppColors.accentCoral.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.accentOrange.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            'Add Item',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final ItemCategory category;
  final Color accent;
  final IconData icon;
  final List<ReviewItem> items;
  final bool editMode;
  final Function(String) onToggle;

  const _CategorySection({
    required this.category,
    required this.accent,
    required this.icon,
    required this.items,
    required this.editMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                category.displayName,
                style: AppTypography.bodySmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Item rows
        ...items.map((item) => ReviewItemRow(
              name: item.name,
              roomName: item.roomName,
              cleaningAction: item.cleaningAction,
              frequency: item.frequency,
              isConfirmed: item.isConfirmed,
              categoryAccent: accent,
              onToggle: () => onToggle(item.id),
            )),
      ],
    );
  }
}

// ─── Glass Container ──────────────────────────────────────────────────────────

class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.glassWhite.withValues(alpha: 0.12),
                  AppColors.surfaceDark.withValues(alpha: 0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Specular top highlight line
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.1, 0.5, 0.9],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Chip ───────────────────────────────────────────────────────────────

class _EditChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EditChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
