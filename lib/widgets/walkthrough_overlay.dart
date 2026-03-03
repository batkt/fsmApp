import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/walkthrough_service.dart';

/// Overlay widget that shows walkthrough steps with highlights
class WalkthroughOverlay extends StatefulWidget {
  const WalkthroughOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
    this.currentStepIndex = 0,
  });

  final List<WalkthroughStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final int currentStepIndex;

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentStepIndex;
  }

  @override
  void didUpdateWidget(WalkthroughOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStepIndex != widget.currentStepIndex) {
      _currentIndex = widget.currentStepIndex;
    }
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      setState(() => _currentIndex++);
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentIndex];
    final renderObject = step.targetKey.currentContext?.findRenderObject();

    if (renderObject == null || !renderObject.attached) {
      // Target not found, skip to next step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_currentIndex < widget.steps.length - 1) {
            _nextStep();
          } else {
            widget.onComplete();
          }
        }
      });
      return const SizedBox.shrink();
    }

    final box = renderObject as RenderBox;
    final targetPosition = box.localToGlobal(Offset.zero);
    final targetSize = box.size;

    return Stack(
      children: [
        // Dark overlay with hole
        _DarkOverlay(
          targetPosition: targetPosition,
          targetSize: targetSize,
          padding: 16,
        ),
        // Tooltip
        _TooltipWidget(
          step: step,
          targetPosition: targetPosition,
          targetSize: targetSize,
          position: step.position,
          currentIndex: _currentIndex,
          totalSteps: widget.steps.length,
          onNext: _nextStep,
          onPrevious: _previousStep,
          onSkip: widget.onSkip,
          onComplete: widget.onComplete,
        ),
      ],
    );
  }
}

/// Dark overlay with a hole for the highlighted element
class _DarkOverlay extends StatelessWidget {
  const _DarkOverlay({
    required this.targetPosition,
    required this.targetSize,
    required this.padding,
  });

  final Offset targetPosition;
  final Size targetSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
        targetPosition: targetPosition,
        targetSize: targetSize,
        padding: padding,
      ),
      child: Container(color: Colors.transparent),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.targetPosition,
    required this.targetSize,
    required this.padding,
  });

  final Offset targetPosition;
  final Size targetSize;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw dark overlay
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cut out the target area with rounded corners
    final targetRect = Rect.fromLTWH(
      targetPosition.dx - padding,
      targetPosition.dy - padding,
      targetSize.width + (padding * 2),
      targetSize.height + (padding * 2),
    );

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(12)),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, paint);

    // Draw highlight border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) {
    return oldDelegate.targetPosition != targetPosition ||
        oldDelegate.targetSize != targetSize;
  }
}

/// Tooltip widget that shows step information
class _TooltipWidget extends StatelessWidget {
  const _TooltipWidget({
    required this.step,
    required this.targetPosition,
    required this.targetSize,
    required this.position,
    required this.currentIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.onComplete,
  });

  final WalkthroughStep step;
  final Offset targetPosition;
  final Size targetSize;
  final WalkthroughPosition position;
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final screenSize = MediaQuery.of(context).size;

    // Calculate tooltip position based on target and preferred position
    Offset tooltipPosition;
    double tooltipWidth = screenSize.width - 32;

    switch (position) {
      case WalkthroughPosition.top:
        tooltipPosition = Offset(16, targetPosition.dy - 200);
        break;
      case WalkthroughPosition.bottom:
        tooltipPosition = Offset(
          16,
          targetPosition.dy + targetSize.height + 24,
        );
        break;
      case WalkthroughPosition.left:
        tooltipPosition = Offset(
          targetPosition.dx - tooltipWidth - 16,
          targetPosition.dy + targetSize.height / 2 - 100,
        );
        break;
      case WalkthroughPosition.right:
        tooltipPosition = Offset(
          targetPosition.dx + targetSize.width + 16,
          targetPosition.dy + targetSize.height / 2 - 100,
        );
        break;
      case WalkthroughPosition.center:
        tooltipPosition = Offset(16, screenSize.height / 2 - 150);
        break;
    }

    // Ensure tooltip stays on screen
    if (tooltipPosition.dy < 16) {
      tooltipPosition = Offset(tooltipPosition.dx, 16);
    }
    if (tooltipPosition.dy + 200 > screenSize.height - 16) {
      tooltipPosition = Offset(tooltipPosition.dx, screenSize.height - 216);
    }

    return Positioned(
      left: tooltipPosition.dx,
      top: tooltipPosition.dy,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentIndex + 1} / $totalSteps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.brandGreen,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Алгасах',
                      style: TextStyle(fontSize: 14, color: c.mutedForeground),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 15,
                  color: c.mutedForeground,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Navigation buttons
              Row(
                children: [
                  if (currentIndex > 0)
                    TextButton(
                      onPressed: onPrevious,
                      child: Text(
                        'Буцах',
                        style: TextStyle(color: c.mutedForeground),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: currentIndex == totalSteps - 1
                        ? onComplete
                        : onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentIndex == totalSteps - 1 ? 'Дуусгах' : 'Дараах',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
