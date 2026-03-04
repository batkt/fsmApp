import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class NotificationModal extends StatefulWidget {
  const NotificationModal({
    super.key,
    required this.notifications,
    required this.onMarkAllRead,
    this.onNotificationTap,
  });
  final List<AppNotification> notifications;
  final Future<void> Function() onMarkAllRead;
  final void Function(AppNotification)? onNotificationTap;

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  late List<AppNotification> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = List.from(widget.notifications);
  }

  void _markRead(int index) {
    final notif = _notifs[index];
    if (widget.onNotificationTap != null) {
      widget.onNotificationTap!(notif);
    } else {
      setState(() {
        _notifs[index] = _notifs[index].copyWith(isRead: true);
      });
    }
  }

  void _markAllRead() async {
    // Optimistically update UI first
    setState(() {
      _notifs = _notifs.map((n) => n.copyWith(isRead: true)).toList();
    });
    // Then call the callback to sync with backend
    await widget.onMarkAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = _notifs.where((n) => !n.isRead).length;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.75),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    color: c.brandGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Мэдэгдэл',
                    style: TextStyle(
                      fontSize: context.rFontSize(20),
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                  ),
                  const Spacer(),
                  if (unread > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.destructive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: c.destructive.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '$unread шинэ',
                        style: TextStyle(
                          fontSize: context.rFontSize(13),
                          fontWeight: FontWeight.w600,
                          color: c.destructive,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: unread > 0 ? _markAllRead : null,
                    child: Text(
                      'Бүгд уншсан',
                      style: TextStyle(
                        fontSize: context.rFontSize(14),
                        color: unread > 0 ? c.brandGreen : c.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),

            // ── List ──
            Flexible(
              child: _notifs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: c.border,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Мэдэгдэл байхгүй',
                            style: TextStyle(color: c.mutedForeground),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifs.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: c.border, height: 1, indent: 68),
                      itemBuilder: (_, i) => _NotifTile(
                        notif: _notifs[i],
                        onTap: () => _markRead(i),
                      ),
                    ),
            ),
            SizedBox(height: safeAreaBottom > 0 ? safeAreaBottom : 20),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  Color _typeColor(NotifType t, AppColorScheme c) {
    switch (t) {
      case NotifType.task:
      case NotifType.taskCreated:
      case NotifType.taskUpdated:
      case NotifType.taskStarted:
      case NotifType.taskReset:
        return c.info;
      case NotifType.taskCompleted:
        return c.success;
      case NotifType.taskExpired:
        return c.warningOrange;
      case NotifType.alert:
      case NotifType.assignment:
      case NotifType.reminder:
        return c.warningOrange;
      case NotifType.info:
      case NotifType.projectCreated:
      case NotifType.projectUpdated:
      case NotifType.chatMessage:
        return c.blueAccent;
      case NotifType.success:
        return c.success;
      case NotifType.medegdel:
        return c.brandGreen;
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Дөнгөж';
    if (d.inMinutes < 60) return '${d.inMinutes} мин';
    if (d.inHours < 24) return '${d.inHours} цаг';
    return '${d.inDays} өдөр';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tc = _typeColor(notif.type, c);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : c.brandGreen.withOpacity(0.03),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notifIcon(notif.type), color: tc, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: context.rFontSize(16),
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: c.primary,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(notif.time),
                        style: TextStyle(
                          fontSize: context.rFontSize(13),
                          color: c.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: context.rFontSize(15),
                      color: c.mutedForeground,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Show the notification modal as a bottom sheet
Future<void> showNotificationModal(
  BuildContext context, {
  required List<AppNotification> notifications,
  required Future<void> Function() onMarkAllRead,
  void Function(AppNotification)? onNotificationTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: NotificationModal(
        notifications: notifications,
        onMarkAllRead: onMarkAllRead,
        onNotificationTap: onNotificationTap,
      ),
    ),
  );
}
