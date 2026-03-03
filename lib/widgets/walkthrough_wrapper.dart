import 'package:flutter/material.dart';
import '../services/walkthrough_service.dart';
import 'walkthrough_overlay.dart';

/// Wrapper widget that manages walkthrough state for a screen
class WalkthroughWrapper extends StatefulWidget {
  const WalkthroughWrapper({
    super.key,
    required this.child,
    required this.config,
    this.autoStart = false,
  });

  final Widget child;
  final WalkthroughConfig config;
  final bool autoStart;

  @override
  State<WalkthroughWrapper> createState() => _WalkthroughWrapperState();
}

class _WalkthroughWrapperState extends State<WalkthroughWrapper> {
  bool _showWalkthrough = false;

  @override
  void initState() {
    super.initState();
    _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    final completed = await WalkthroughService.isCompleted(
      widget.config.screenId,
    );
    if (mounted) {
      setState(() {
        _showWalkthrough = widget.autoStart && !completed;
      });
    }
  }

  void _startWalkthrough() {
    setState(() {
      _showWalkthrough = true; // Allow restarting even if completed
    });
  }

  void _completeWalkthrough() async {
    await WalkthroughService.markCompleted(widget.config.screenId);
    if (mounted) {
      setState(() {
        _showWalkthrough = false;
      });
    }
  }

  void _skipWalkthrough() {
    setState(() => _showWalkthrough = false);
  }

  @override
  Widget build(BuildContext context) {
    return _WalkthroughWrapperInherited(
      startWalkthrough: _startWalkthrough,
      child: Stack(
        children: [
          widget.child,
          if (_showWalkthrough)
            WalkthroughOverlay(
              steps: widget.config.steps,
              onComplete: _completeWalkthrough,
              onSkip: _skipWalkthrough,
            ),
        ],
      ),
    );
  }
}

/// Inherited widget to access walkthrough controls from child widgets
class _WalkthroughWrapperInherited extends InheritedWidget {
  const _WalkthroughWrapperInherited({
    required this.startWalkthrough,
    required super.child,
  });

  final VoidCallback startWalkthrough;

  @override
  bool updateShouldNotify(_WalkthroughWrapperInherited oldWidget) {
    return oldWidget.startWalkthrough != startWalkthrough;
  }

  static _WalkthroughWrapperInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_WalkthroughWrapperInherited>();
  }
}

/// Extension to easily start walkthrough from any widget
extension WalkthroughExtension on BuildContext {
  void startWalkthrough() {
    _WalkthroughWrapperInherited.of(this)?.startWalkthrough();
  }
}
