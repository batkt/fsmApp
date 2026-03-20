import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppToast {
  static _AppToastManager? _manager;

  static void show(BuildContext context, String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 3),
    double? progress,
  }) {
    if (_manager == null) {
      _manager = _AppToastManager();
    }
    _manager!.show(context, message, icon: icon, color: color, duration: duration, progress: progress);
  }

  static void hide() {
    _manager?.hide();
  }
}

class _AppToastManager {
  OverlayEntry? _entry;
  final ValueNotifier<_ToastData?> _data = ValueNotifier(null);

  _AppToastManager();

  void show(BuildContext context, String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 3),
    double? progress,
  }) {
    // Always use the latest context to get theme colors
    final theme = context.colors;
    final newData = _ToastData(
      message: message,
      icon: icon,
      color: color ?? theme.primary,
      progress: progress,
    );

    _data.value = newData;

    if (_entry == null) {
      _entry = OverlayEntry(
        builder: (ctx) => _ToastOverlay(
          dataNotifier: _data,
          onDismiss: hide,
        ),
      );
      // Use rootOverlay: true to show above modals
      final overlay = Overlay.of(context, rootOverlay: true);
      overlay.insert(_entry!);
    }

    if (progress == null) {
      Future.delayed(duration, () {
        if (_data.value == newData) {
          hide();
        }
      });
    }
  }

  void hide() {
    _data.value = null;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_data.value == null) {
        _entry?.remove();
        _entry = null;
      }
    });
  }
}

class _ToastData {
  final String message;
  final IconData? icon;
  final Color color;
  final double? progress;

  _ToastData({
    required this.message,
    this.icon,
    required this.color,
    this.progress,
  });
}

class _ToastOverlay extends StatelessWidget {
  final ValueNotifier<_ToastData?> dataNotifier;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.dataNotifier,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_ToastData?>(
      valueListenable: dataNotifier,
      builder: (context, data, _) {
        if (data == null) return const SizedBox.shrink();
        return _ToastWidget(
          data: data,
          onDismiss: onDismiss,
        );
      },
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final _ToastData data;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mq = MediaQuery.of(context);
    final data = widget.data;
    
    return Positioned(
      top: mq.padding.top + 10,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (data.icon != null) ...[
                        Icon(data.icon, color: data.color, size: 20),
                        const SizedBox(width: 12),
                      ] else if (data.progress != null) ...[
                         SizedBox(
                           width: 18, height: 18,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             value: data.progress,
                             color: data.color,
                           ),
                         ),
                         const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          data.message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.primary,
                          ),
                        ),
                      ),
                      if (data.progress != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${(data.progress! * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: data.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (data.progress != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: data.progress,
                        minHeight: 4,
                        backgroundColor: c.muted,
                        valueColor: AlwaysStoppedAnimation(data.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
