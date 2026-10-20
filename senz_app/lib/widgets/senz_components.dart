import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../navigation/senz_screen.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomPaint(
        size: Size(compact ? 41 : 82, compact ? 17 : 34),
        painter: BrandPainter(),
      ),
      Text(
        'SENZ',
        style: TextStyle(
          color: senzDeepGreen,
          fontSize: compact ? 24 : 58,
          height: .98,
          fontWeight: FontWeight.w800,
          letterSpacing: compact ? 1 : 3,
        ),
      ),
      if (!compact) ...[
        const SizedBox(height: 12),
        const Text(
          'Sign. Speak. Connect.',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
      ],
    ],
  );
}

class BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF113E36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final sx = size.width / 82;
    final sy = size.height / 34;
    canvas.save();
    canvas.scale(sx, sy);
    canvas.drawLine(const Offset(18, 27), const Offset(10, 12), paint);
    canvas.drawLine(const Offset(31, 22), const Offset(25, 5), paint);
    canvas.drawLine(const Offset(64, 27), const Offset(72, 12), paint);
    canvas.drawLine(const Offset(51, 22), const Offset(57, 5), paint);
    final arc1 = Path()
      ..moveTo(36, 15)
      ..cubicTo(40, 11, 44, 11, 48, 15);
    final arc2 = Path()
      ..moveTo(32, 9)
      ..cubicTo(39, 2, 46, 2, 53, 9);
    canvas.drawPath(arc1, paint);
    canvas.drawPath(arc2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Landscape extends StatelessWidget {
  const Landscape({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: LandscapePainter());
}

class LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final layers = <(Color, List<Offset>)>[
      (
        const Color(0xFFDCEBD8),
        [
          const Offset(0, .25),
          const Offset(.14, .32),
          const Offset(.30, .51),
          const Offset(.47, .65),
          const Offset(.62, .66),
          const Offset(.82, .53),
          const Offset(1, .51),
        ],
      ),
      (
        const Color(0xFFABCBAA),
        [
          const Offset(0, .02),
          const Offset(.12, .13),
          const Offset(.30, .39),
          const Offset(.47, .55),
          const Offset(.63, .72),
          const Offset(.79, .66),
          const Offset(1, .57),
        ],
      ),
      (
        const Color(0x887EB183),
        [
          const Offset(0, .57),
          const Offset(.14, .50),
          const Offset(.34, .53),
          const Offset(.52, .67),
          const Offset(.66, .67),
          const Offset(.82, .61),
          const Offset(1, .62),
        ],
      ),
    ];
    for (final layer in layers) {
      final path = Path()..moveTo(0, layer.$2.first.dy * size.height);
      for (final point in layer.$2.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = layer.$1);
    }
  }

  @override
  bool shouldRepaint(covariant LandscapePainter oldDelegate) => false;
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 19,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: .9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D2F513D),
          blurRadius: 20,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}

class GloveStage extends StatefulWidget {
  const GloveStage({super.key, this.bends = const [0, 0, 0, 0, 0]});
  final List<double> bends;

  @override
  State<GloveStage> createState() => _GloveStageState();
}

class _GloveStageState extends State<GloveStage> with TickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);
  late final AnimationController _poseMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 230),
    value: 1,
  );
  late List<double> _from;
  late List<double> _target;
  late List<double> _shown;
  late Listenable _animations;

  @override
  void initState() {
    super.initState();
    _from = _normalizedPose(widget.bends);
    _target = _from;
    _shown = _from;
    _animations = Listenable.merge([_motion, _poseMotion]);
  }

  @override
  void didUpdateWidget(covariant GloveStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalizedPose(widget.bends);
    if (!_samePose(next, _target)) {
      _from = _shown;
      _target = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _poseMotion.forward(from: 0);
      });
    }
  }

  List<double> _normalizedPose(List<double> values) => List<double>.generate(
    5,
    (index) => index < values.length ? values[index].clamp(0, 1) : 0,
  );

  bool _samePose(List<double> a, List<double> b) =>
      List.generate(5, (index) => a[index] == b[index]).every((same) => same);

  @override
  void dispose() {
    _motion.dispose();
    _poseMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animations,
    builder: (context, _) {
      final phase = _motion.value * math.pi * 2;
      final progress = Curves.easeOutCubic.transform(_poseMotion.value);
      _shown = List<double>.generate(
        5,
        (index) => _from[index] + (_target[index] - _from[index]) * progress,
      );
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 225,
            height: 225,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x99CBE0C6),
              boxShadow: [
                BoxShadow(
                  color: Color(0x52DCEBD7),
                  blurRadius: 0,
                  spreadRadius: 18,
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(math.sin(phase) * 2, -math.sin(phase) * 3),
            child: Transform.rotate(
              angle: math.sin(phase) * .015,
              child: CustomPaint(
                size: const Size(190, 220),
                painter: GlovePainter(bends: _shown),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class GlovePainter extends CustomPainter {
  const GlovePainter({required this.bends});
  final List<double> bends;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 220, size.height / 250);
    final hand = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF183F38), Color(0xFF092C2B)],
      ).createShader(const Rect.fromLTWH(0, 0, 220, 250));
    final shade = Paint()..color = const Color(0xFF143D38);
    final stroke = Paint()
      ..color = const Color(0xFF57A75B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fingerSpecs = <(Offset, double, double, double, double)>[
      (const Offset(76, 158), 27, 23, -.76, 1), // Thumb
      (const Offset(87, 145), 38, 30, -.10, 1), // Index
      (const Offset(108, 139), 47, 35, 0, 1), // Middle
      (const Offset(130, 142), 41, 31, .08, -1), // Ring
      (const Offset(151, 151), 31, 25, .34, -1), // Little
    ];
    for (var i = 0; i < fingerSpecs.length; i++) {
      final spec = fingerSpecs[i];
      _drawFinger(
        canvas,
        spec.$1,
        spec.$2,
        spec.$3,
        spec.$4,
        spec.$5,
        bends[i].clamp(0, 1),
        hand,
      );
    }

    final palm = Path()
      ..moveTo(76, 163)
      ..cubicTo(72, 149, 78, 137, 91, 138)
      ..cubicTo(100, 136, 105, 134, 111, 136)
      ..cubicTo(124, 132, 137, 137, 143, 142)
      ..cubicTo(157, 138, 168, 147, 165, 164)
      ..cubicTo(163, 180, 157, 192, 151, 201)
      ..lineTo(150, 232)
      ..lineTo(80, 232)
      ..lineTo(79, 197)
      ..cubicTo(73, 188, 72, 175, 76, 163)
      ..close();
    canvas.drawPath(palm, hand);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(81, 198, 68, 34),
        const Radius.circular(4),
      ),
      shade,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(101, 207, 28, 16),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF32714D),
    );
    canvas.drawLine(const Offset(87, 154), const Offset(101, 183), stroke);
    canvas.drawLine(const Offset(106, 152), const Offset(111, 181), stroke);
    canvas.drawLine(const Offset(130, 154), const Offset(128, 181), stroke);
    canvas.drawLine(const Offset(151, 160), const Offset(145, 183), stroke);
    canvas.restore();
  }

  void _drawFinger(
    Canvas canvas,
    Offset base,
    double proximalLength,
    double distalLength,
    double openAngle,
    double curlDirection,
    double bend,
    Paint hand,
  ) {
    final proximalAngle = openAngle + bend * curlDirection * .58;
    final distalAngle = proximalAngle + bend * curlDirection * 1.06;
    final joint = _along(base, proximalLength, proximalAngle);
    final tip = _along(joint, distalLength, distalAngle);
    final outline = Paint()
      ..color = const Color(0xFF0C302B)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final inner = Paint()
      ..shader = hand.shader
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, joint, outline);
    canvas.drawLine(joint, tip, outline);
    canvas.drawLine(base, joint, inner);
    canvas.drawLine(joint, tip, inner);
    canvas.drawCircle(joint, 4, Paint()..color = const Color(0xFF58B55A));
    canvas.drawCircle(tip, 3, Paint()..color = const Color(0xFF8BD16B));
  }

  Offset _along(Offset start, double length, double angle) => Offset(
    start.dx + math.sin(angle) * length,
    start.dy - math.cos(angle) * length,
  );

  @override
  bool shouldRepaint(covariant GlovePainter oldDelegate) =>
      !_sameBends(oldDelegate.bends, bends);

  bool _sameBends(List<double> oldBends, List<double> newBends) =>
      oldBends.length == newBends.length &&
      List.generate(
        oldBends.length,
        (index) => oldBends[index] == newBends[index],
      ).every((same) => same);
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final SenzScreen selected;
  final ValueChanged<SenzScreen> onSelect;
  static const items = <(SenzScreen, String, IconData)>[
    (SenzScreen.home, 'Home', Icons.home_outlined),
    (SenzScreen.sensors, 'Sensors', Icons.sensors_outlined),
    (SenzScreen.translate, 'Translate', Icons.translate_rounded),
    (SenzScreen.history, 'History', Icons.history_rounded),
  ];
  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    decoration: const BoxDecoration(
      color: Color(0xFFFDFEFA),
      border: Border(top: BorderSide(color: Color(0xFFDAE4D8))),
    ),
    child: Row(
      children: [
        for (final item in items)
          Expanded(
            child: Semantics(
              selected: selected == item.$1,
              button: true,
              label: item.$2,
              child: InkWell(
                onTap: () => onSelect(item.$1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      color: selected == item.$1
                          ? senzLeaf
                          : const Color(0xFF72807C),
                      size: 23,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected == item.$1
                            ? senzLeaf
                            : const Color(0xFF72807C),
                        fontWeight: selected == item.$1
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
