import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: const Color(0xFFBBBBBB),
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppText.body(fontSize: 12, color: AppColors.primaryTeal),
        unselectedLabelStyle: AppText.body(fontSize: 12, color: const Color(0xFFBBBBBB)),
        showUnselectedLabels: false,
        onTap: (i) {
          if (i == 0) {
            context.go('/');
          } else {
            final paths = ['/library', '/history', '/settings'];
            final path = paths[i - 1];
            // Keep home at the bottom of the stack so back gesture returns to it.
            // If already on a tab, replace it (no duplicate stacking).
            if (context.canPop()) {
              context.pushReplacement(path);
            } else {
              context.push(path);
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'My Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
