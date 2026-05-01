import 'dart:ui';

import 'package:flutter/material.dart';

bool appAnimationsEnabled(BuildContext context) {
  return !MediaQuery.of(context).disableAnimations;
}

/// A reusable radial-expansion Hero pattern.
///
/// Hero tag convention used across the app:
/// - `hero_roommate_<roommateId>`
/// - `hero_expense_<expenseId>`
/// - `hero_balance_<householdId|scope>`
/// - `hero_fab_add`
/// - `hero_settlement_<stableKey>`
class RadialHero extends StatelessWidget {
  const RadialHero({
    super.key,
    required this.tag,
    required this.maxRadius,
    required this.child,
    this.enabled = true,
  });

  final String tag;
  final double maxRadius;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Hero(
      tag: tag,
      createRectTween: (begin, end) => MaterialRectCenterArcTween(
        begin: begin,
        end: end,
      ),
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final Widget toHero = toHeroContext.widget;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
              child: child,
            );
          },
          child: toHero,
        );
      },
      child: RadialExpansion(
        maxRadius: maxRadius,
        child: child,
      ),
    );
  }
}

class RadialExpansion extends StatelessWidget {
  const RadialExpansion({
    super.key,
    required this.maxRadius,
    required this.child,
  });

  final double maxRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final diameter = maxRadius * 2;
    return ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Center(child: child),
      ),
    );
  }
}

class AppRadialPageRoute<T> extends PageRouteBuilder<T> {
  AppRadialPageRoute({
    required WidgetBuilder builder,
    required Duration duration,
    Curve curve = Curves.easeInOut,
    bool blurBackground = false,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(parent: animation, curve: curve);

           Widget current = FadeTransition(opacity: curved, child: child);
           if (blurBackground) {
             current = AnimatedBuilder(
               animation: curved,
               builder: (context, child) {
                 final t = curved.value;
                 return BackdropFilter(
                   filter: ImageFilter.blur(
                     sigmaX: 12 * t,
                     sigmaY: 12 * t,
                   ),
                   child: child,
                 );
               },
               child: current,
             );
           }
           return current;
         },
       );
}

