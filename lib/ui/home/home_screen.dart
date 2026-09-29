import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/ui/shared/app_bottom_nav.dart';
import 'package:quizzapp/utils/svg_assets.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // App logo
              Image.asset(
                'assets/images/Quizapp.png',
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),

              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Quiz',
                      style: AppText.heading(
                        fontSize: 52,
                        color: const Color(0xFF1C1C1C),
                      ),
                    ),
                    TextSpan(
                      text: 'app',
                      style: AppText.heading(
                        fontSize: 52,
                        color: const Color(0xFFCC3333),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'The ultimate quiz party game!',
                style: AppText.body(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),

              const Spacer(flex: 2),

              // Host Game button — pink with hard shadow
              _BigButton(
                label: 'Host Game',
                iconSvg: SvgAssets.hostIcon,
                color: AppColors.primaryPink,
                onTap: () => context.push('/library'),
              ),
              const SizedBox(height: 24),
              // Join Game button — teal with hard shadow
              _BigButton(
                label: 'Join Game',
                iconSvg: SvgAssets.joinIcon,
                color: AppColors.primaryTeal,
                onTap: () => context.push('/join'),
              ),

              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    ));
  }
}

/// Large pill button with hard shadow + dark border (matches stitch reference).
class _BigButton extends StatelessWidget {
  final String label;
  final String iconSvg;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.iconSvg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hardShadow, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.hardShadow,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(iconSvg, width: 28, height: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppText.heading(
                fontSize: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


