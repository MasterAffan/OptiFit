import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.bottomNavHeight,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: AppTheme.bottomNavShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.public,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.fitness_center,
            label: 'Workouts',
            index: 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.smart_toy,
            label: 'AI',
            index: 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.show_chart,
            label: 'Progress',
            index: 3,
          ),
          _buildNavItem(
            context,
            icon: Icons.person,
            label: 'Profile',
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final bool isSelected = currentIndex == index;
    final color = isSelected ? AppTheme.primary : AppTheme.textSubtle;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppTheme.bottomNavIconSize,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.bottomNavLabelSize,
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 