import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agrothink/config/constants.dart';
import 'package:agrothink/config/routes.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;

  int _activeIndex = 0;
  int? _focusedIndex;
  late final List<Map<String, String>> _features;

  @override
  void initState() {
    super.initState();
    _features =
        AppConstants.onboardingData
            .where((item) => item['title'] != 'Welcome to Agrothink')
            .toList();

    final featuresCount = _features.length;

    _rotationController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    )..repeat();

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _focusAnimation = CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    );

    _rotationController.addListener(() {
      if (_focusedIndex != null) return;
      final newIndex =
          ((_rotationController.value + 0.75) * featuresCount).floor() %
          featuresCount;
      if (newIndex != _activeIndex) {
        setState(() {
          _activeIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const Spacer(flex: 1),
              _buildCircleAnimator(),
              _buildFeatureText(),
              const Spacer(flex: 2),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Agrothink',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAnimator() {
    final size = MediaQuery.of(context).size;
    final radius = size.width * 0.38;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _focusController]),
      builder: (context, child) {
        final rotationValue = _rotationController.value;
        final focusValue = _focusAnimation.value;

        final children = <Widget>[];
        Widget? focusedChild;

        for (int index = 0; index < _features.length; index++) {
          final angle =
              (2 * math.pi / _features.length) * index -
              (2 * math.pi * rotationValue);
          final yPos = -math.sin(angle);
          final xPos = math.cos(angle);

          final isThisItemFocused = _focusedIndex == index;
          final isAnyItemFocused = _focusedIndex != null;

          final double orbitScale = 0.6 + 0.4 * (yPos + 1) / 2;
          double finalScale = orbitScale;
          if (isAnyItemFocused) {
            if (isThisItemFocused) {
              finalScale = lerpDouble(orbitScale, 1.5, focusValue)!;
            } else {
              finalScale =
                  lerpDouble(orbitScale, orbitScale * 0.5, focusValue)!;
            }
          }

          final double orbitOpacity = 0.6 + 0.4 * (yPos + 1) / 2;
          double finalOpacity = orbitOpacity;
          if (isAnyItemFocused) {
            if (isThisItemFocused) {
              finalOpacity = lerpDouble(orbitOpacity, 1.0, focusValue)!;
            } else {
              finalOpacity = lerpDouble(orbitOpacity, 0.2, focusValue)!;
            }
          }

          final double orbitX = xPos * radius;
          final double orbitY = yPos * radius * 0.7;
          double finalX = orbitX;
          double finalY = orbitY;

          if (isThisItemFocused) {
            finalX = lerpDouble(orbitX, 0, focusValue)!;
            finalY = lerpDouble(orbitY, -radius * 0.4, focusValue)!;
          }

          final childWidget = GestureDetector(
            onTap: () {
              setState(() {
                if (_focusedIndex == index) {
                  _focusedIndex = null;
                  _focusController.reverse();
                  _rotationController.repeat();
                } else {
                  _focusedIndex = index;
                  _focusController.forward(from: 0.0);
                  _rotationController.stop();
                }
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform(
                  transform:
                      Matrix4.identity()
                        ..translate(0.0, 70.0)
                        ..scale(1.0, 0.4),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3 * finalOpacity),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFeatureIcon(
                  _getIconForTitle(_features[index]['title']!),
                  _focusedIndex == null
                      ? (index == _activeIndex)
                      : isThisItemFocused,
                ),
              ],
            ),
          );

          final transformedChild = Transform(
            transform:
                Matrix4.identity()
                  ..translate(finalX, finalY)
                  ..scale(finalScale),
            alignment: Alignment.center,
            child: Opacity(opacity: finalOpacity, child: childWidget),
          );

          if (isThisItemFocused) {
            focusedChild = transformedChild;
          } else {
            children.add(transformedChild);
          }
        }

        if (focusedChild != null) {
          children.add(focusedChild);
        }

        return SizedBox(
          width: radius * 2.2,
          height: radius * 2.2,
          child: Stack(alignment: Alignment.center, children: children),
        );
      },
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'AGROX':
        return Icons.chat_bubble_outline;
      case 'AI-Powered Disease Detection':
        return Icons.camera_alt_outlined;
      case 'AI Planting Guide':
        return Icons.eco_outlined;
      case 'AI-Powered To-Do List':
        return Icons.check_circle_outline;
      case 'AI Crop Monitoring':
        return Icons.sensors;
      case 'AI-Curated Updates':
        return Icons.feed_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildFeatureIcon(IconData icon, bool isActive) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
                : [],
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : AppTheme.primaryColor,
        size: 50,
      ),
    );
  }

  Widget _buildFeatureText() {
    final indexToShow = _focusedIndex ?? _activeIndex;
    final feature = _features[indexToShow];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Column(
          key: ValueKey<int>(indexToShow),
          children: [
            Text(
              feature['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              feature['description']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: CustomButton(
        text: 'Get Started',
        onPressed: _navigateToLogin,
        fullWidth: true,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }
}
