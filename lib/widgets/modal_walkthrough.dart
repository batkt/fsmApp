import 'package:flutter/material.dart';
import '../services/walkthrough_service.dart';
import 'walkthrough_overlay.dart';

/// Helper to show walkthrough for modals
class ModalWalkthrough {
  static void show(BuildContext context, WalkthroughConfig config) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _ModalWalkthroughDialog(config: config),
    );
  }
}

class _ModalWalkthroughDialog extends StatefulWidget {
  const _ModalWalkthroughDialog({required this.config});

  final WalkthroughConfig config;

  @override
  State<_ModalWalkthroughDialog> createState() =>
      _ModalWalkthroughDialogState();
}

class _ModalWalkthroughDialogState extends State<_ModalWalkthroughDialog> {
  int _currentIndex = 0;
  bool _isCompleted = false;

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
      setState(() => _isCompleted = completed);
      if (completed) {
        Navigator.pop(context);
      }
    }
  }

  void _skip() {
    Navigator.pop(context);
  }

  void _complete() async {
    await WalkthroughService.markCompleted(widget.config.screenId);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return const SizedBox.shrink();

    return WalkthroughOverlay(
      steps: widget.config.steps,
      currentStepIndex: _currentIndex,
      onComplete: _complete,
      onSkip: _skip,
    );
  }
}
