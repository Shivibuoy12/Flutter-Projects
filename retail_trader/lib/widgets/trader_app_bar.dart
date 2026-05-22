import 'package:flutter/material.dart';

import '../theme/trader_colors.dart';

class TraderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TraderAppBar({super.key, this.onSearchTap, this.extraActions = const []});

  final VoidCallback? onSearchTap;
  final List<Widget> extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [TraderColors.accent, TraderColors.accent.withValues(alpha: 0.65)],
              ),
            ),
            child: const Text('RT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          ),
          const SizedBox(width: 10),
          const Text('Markets'),
        ],
      ),
      actions: [
        SizedBox(
          width: 220,
          child: GestureDetector(
            onTap: onSearchTap ?? () {},
            child: AbsorbPointer(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search symbol or name',
                  prefixIcon: const Icon(Icons.search, size: 20, color: TraderColors.textSecondary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  filled: true,
                  fillColor: TraderColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ...extraActions,
        const SizedBox(width: 8),
      ],
    );
  }
}
