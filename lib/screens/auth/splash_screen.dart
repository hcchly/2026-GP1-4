import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/khota_colors.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Khota animated splash: "a step forward".
///
/// Motion (about 2 seconds):
///  1. The lower, broken chevron (the damaged sidewalk) rises in.
///  2. The upper, intact chevron steps up out of it into place.
///  3. The Arabic word "خطى" is written in from right to left.
///  4. The dot of the خ pops in, then the tagline fades up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _auth = widget.auth ?? FirebaseAuthService.instance;

  /// Whole intro timeline in seconds.
  static const double _total = 2.1;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );

  static const _layers = [
    'assets/images/splash_mark_bottom.png',
    'assets/images/splash_mark_top.png',
    'assets/images/splash_word.png',
    'assets/images/splash_word_dot.png',
  ];

  bool _started = false;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up the header pattern for the current mode so the first screen's
    // header shows the image straight away, not the fallback colour.
    precacheImage(AssetImage(context.khota.headerImage), context);
    if (_started) return;
    for (final layer in _layers) {
      precacheImage(AssetImage(layer), context);
    }
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      Future<void>.delayed(const Duration(milliseconds: 1800), _goNext);
    } else {
      _controller.forward().whenComplete(() {
        Future<void>.delayed(const Duration(milliseconds: 900), _goNext);
      });
    }
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final next = _auth.currentUser == null
        ? const LoginScreen()
        : const MainShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress (0..1) of a segment between [from] and [to] seconds.
  double _seg(double from, double to) {
    final t = _controller.value * _total;
    return ((t - from) / (to - from)).clamp(0.0, 1.0).toDouble();
  }

  // Easing curves matched to the approved web preview.
  static const _easeOut = Cubic(0.2, 0.8, 0.2, 1);
  static const _stepCurve = Cubic(0.3, 1.35, 0.4, 1); // small overshoot
  static const _wipeCurve = Cubic(0.65, 0, 0.35, 1);
  static const _popCurve = Cubic(0.3, 1.6, 0.5, 1);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.khota.isDark
            ? context.khota.background
            : AppColors.mint,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The lockup (word + mark) takes about 62% of the width.
              final width = (constraints.maxWidth * 0.62)
                  .clamp(0.0, 300.0)
                  .toDouble();
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _logo(width),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 42,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final p = Curves.easeOut.transform(_seg(1.6, 2.1));
                        return Opacity(
                          opacity: p,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - p)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'أرصفة أفضل تبدأ بخطوة',
                            textAlign: TextAlign.center,
                            style: text.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The four logo layers share one canvas (822 × 260), so they line up
  /// exactly when stacked.
  Widget _logo(double width) {
    final bottom = _easeOut.transform(_seg(0.10, 0.65));
    final stepT = _seg(0.35, 1.05);
    final step = _stepCurve.transform(stepT);
    final wipe = _wipeCurve.transform(_seg(0.95, 1.55));
    final popT = _seg(1.45, 1.80);
    final pop = _popCurve.transform(popT);

    return Semantics(
      label: 'شعار خُطى',
      image: true,
      child: SizedBox(
        width: width,
        height: width * 260 / 822,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Damaged lower chevron rises in.
            Opacity(
              opacity: bottom,
              child: FractionalTranslation(
                translation: Offset(0, 0.14 * (1 - bottom)),
                child: _layer(_layers[0]),
              ),
            ),
            // 2. Intact upper chevron steps up and forward into place.
            Opacity(
              opacity: (stepT / 0.4).clamp(0.0, 1.0).toDouble(),
              child: FractionalTranslation(
                translation: Offset(-0.035 * (1 - step), 0.26 * (1 - step)),
                child: _layer(_layers[1]),
              ),
            ),
            // 3. Word written in from right to left.
            ClipRect(
              clipper: _RevealFromRight(wipe),
              child: _layer(_layers[2]),
            ),
            // 4. The dot of the خ pops in.
            Opacity(
              opacity: popT,
              child: Transform.scale(
                scale: 0.2 + 0.8 * pop,
                alignment: const Alignment(-0.18, -0.70),
                child: _layer(_layers[3]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layer(String asset) => Image.asset(
    asset,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}

class _RevealFromRight extends CustomClipper<Rect> {
  const _RevealFromRight(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    size.width * (1 - progress),
    0,
    size.width * progress,
    size.height,
  );

  @override
  bool shouldReclip(_RevealFromRight old) => old.progress != progress;
}
