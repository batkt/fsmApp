import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.projectId,
    this.taskId,
    required this.barilgiinId,
    required this.baiguullagiinId,
    required this.title,
    this.showBackButton = true,
  });

  final String projectId;
  final String? taskId;
  final String barilgiinId;
  final String baiguullagiinId;
  final String title;
  final bool showBackButton;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  String get _myId => AuthService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
    _markChatNotificationsAsRead();
  }

  /// Mark all unread chat notifications for this project/task as read
  Future<void> _markChatNotificationsAsRead() async {
    try {
      // Get all unread chat notifications for this project/task
      final notifications = await NotificationService.getNotifications(
        projectId: widget.projectId,
        taskId: widget.taskId,
        turul: 'chatMessage',
        kharsanEsekh: false,
      );

      // Mark each as read
      for (final notif in notifications) {
        await NotificationService.markAsRead(notif.id);
      }
    } catch (_) {
      // Silently fail - notifications are not critical
    }
  }

  @override
  void dispose() {
    SocketService.offNewMessage();
    SocketService.offUserStatus();
    SocketService.offMessagesRead();
    SocketService.leaveRoom(projectId: widget.projectId, taskId: widget.taskId);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _setupSocket() {
    SocketService.connect();
    SocketService.joinRoom(projectId: widget.projectId, taskId: widget.taskId);
    
    SocketService.onNewMessage((msg) {
      if (!mounted) return;
      
      // Safety Filter: Ensure message belongs to THIS specific chat view
      if (msg.projectId != widget.projectId) return;
      if (widget.taskId != null && msg.taskId != widget.taskId) return;
      if (widget.taskId == null && msg.taskId != null && msg.taskId!.isNotEmpty) return;

      if (_messages.any((m) => m.id == msg.id)) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
      
      // If we are in the chat, mark it as read
      if (msg.ajiltniiId != _myId) {
        _markAllAsRead();
      }
    });

    SocketService.onUserStatus((uid, sts) {
      if (mounted) setState(() {});
    });

    // Handle read receipts from others
    SocketService.onMessagesRead((ids, uid) {
      if (!mounted) return;
      setState(() {
        for (var m in _messages) {
          if (ids.contains(m.id)) {
            if (!m.unshsan.contains(uid)) {
              m.unshsan.add(uid);
            }
          }
        }
      });
    });
  }

  void _markAllAsRead() {
    final unreadIds = _messages
        .where((m) => !m.unshsan.contains(_myId) && m.ajiltniiId != _myId)
        .map((m) => m.id)
        .toList();

    if (unreadIds.isNotEmpty) {
      ChatService.markAsRead(
        chatIds: unreadIds,
        projectId: widget.projectId,
        taskId: widget.taskId,
      );
      // Optimistically update locally
      setState(() {
        for (var m in _messages) {
          if (unreadIds.contains(m.id)) {
            if (!m.unshsan.contains(_myId)) m.unshsan.add(_myId);
          }
        }
      });
    }
  }

  Future<void> _loadMessages() async {
    final msgs = await ChatService.getMessages(
      projectId: widget.projectId,
      taskId: widget.taskId,
    );
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollToBottom();
    _markAllAsRead();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = ChatMessage(
      id: localId,
      projectId: widget.projectId,
      taskId: widget.taskId,
      ajiltniiId: _myId,
      ajiltniiNer: AuthService.currentUser?.ner ?? 'Та',
      medeelel: text,
      turul: 'text',
      barilgiinId: widget.barilgiinId,
      baiguullagiinId: widget.baiguullagiinId,
      createdAt: DateTime.now(),
      unshsan: [],
      isLocal: true,
    );

    setState(() {
      _sending = true;
      _messages.add(localMsg);
    });
    _scrollToBottom();

    final msg = await ChatService.sendText(
      projectId: widget.projectId,
      taskId: widget.taskId,
      medeelel: text,
      barilgiinId: widget.barilgiinId,
      baiguullagiinId: widget.baiguullagiinId,
    );

    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.removeWhere((m) => m.id == localId);
      if (msg != null) {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      } else {
        AppToast.show(context, 'Мессеж илгээхэд алдаа гарлаа',
            icon: Icons.error_outline_rounded,
            color: context.colors.destructive);
      }
    });
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    await _uploadFile(picked.path);
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return;
    await _uploadFile(picked.path);
  }

  Future<void> _uploadFile(String path) async {
    final isImage = path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.png') || path.toLowerCase().endsWith('.jpeg');
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = ChatMessage(
      id: localId,
      projectId: widget.projectId,
      taskId: widget.taskId,
      ajiltniiId: _myId,
      ajiltniiNer: AuthService.currentUser?.ner ?? 'Та',
      medeelel: isImage ? 'Зураг илгээж байна...' : 'Файл илгээж байна...',
      turul: 'text',
      barilgiinId: widget.barilgiinId,
      baiguullagiinId: widget.baiguullagiinId,
      createdAt: DateTime.now(),
      unshsan: [],
      isLocal: true,
    );

    setState(() {
      _sending = true;
      _messages.add(localMsg);
    });
    _scrollToBottom();

    final msg = await ChatService.uploadFile(
      filePath: path,
      projectId: widget.projectId,
      taskId: widget.taskId,
      barilgiinId: widget.barilgiinId,
      baiguullagiinId: widget.baiguullagiinId,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.removeWhere((m) => m.id == localId);
      if (msg != null) {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      } else {
        AppToast.show(context, 'Файл илгээхэд алдаа гарлаа',
            icon: Icons.error_outline_rounded,
            color: context.colors.destructive);
      }
    });
    _scrollToBottom();
  }

  void _showAttachMenu() {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _AttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Зураг',
                  color: c.brandGreen,
                  onTap: () { Navigator.pop(ctx); _pickImage(); },
                ),
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Камер',
                  color: c.info,
                  onTap: () { Navigator.pop(ctx); _takePhoto(); },
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _openGallery(ChatMessage tappedMsg) {
    // Filter only images
    final imageMessages = _messages.where((m) => m.isImage && m.fileUrl != null).toList();
    if (imageMessages.isEmpty) return;

    final initialIndex = imageMessages.indexWhere((m) => m.id == tappedMsg.id);
    int currentIndex = initialIndex >= 0 ? initialIndex : 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () async {
                  final msg = imageMessages[currentIndex];
                  final url = '${ApiService.baseUrl}/${msg.fileUrl}';
                  try {
                    final appDocDir = await getApplicationDocumentsDirectory();
                    final savePath = '${appDocDir.path}/${msg.fileName ?? 'image.jpg'}';
                    await Dio().download(url, savePath);
                    if (context.mounted) {
                      AppToast.show(context, 'Зураг татагдлаа', icon: Icons.check_circle_rounded, color: context.colors.success);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.show(context, 'Татахад алдаа гарлаа', icon: Icons.error_outline_rounded, color: context.colors.destructive);
                    }
                  }
                },
              ),
            ],
          ),
          body: PhotoViewGallery.builder(
            itemCount: imageMessages.length,
            pageController: PageController(initialPage: currentIndex),
            onPageChanged: (idx) => currentIndex = idx,
            builder: (context, index) {
              final msg = imageMessages[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage('${ApiService.baseUrl}/${msg.fileUrl}'),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: msg.id),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: c.cardBackground,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: c.primary)),
            Text(
              SocketService.isConnected 
                  ? (() {
                      final memberIds = _messages.map((m) => m.ajiltniiId).where((id) => id.isNotEmpty).toSet();
                      if (memberIds.isEmpty) return 'Онлайн'; 
                      int active = 0;
                      for (var id in memberIds) {
                        if (SocketService.onlineUsers[id] == 'online' || id == _myId) active++;
                      }
                      int inactive = memberIds.length - active;
                      if (inactive < 0) inactive = 0;
                      return 'Идэвхтэй $active, Идэвхгүй $inactive';
                    })()
                  : 'Холбогдож байна...',
              style: TextStyle(fontSize: 12, color: c.mutedForeground)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: Icon(Icons.info_outline_rounded, color: c.brandGreen, size: 20),
              label: Text('Дэлгэрэнгүй', style: TextStyle(color: c.brandGreen, fontWeight: FontWeight.w600, fontSize: 13)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      messages: _messages,
                      title: widget.title,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.brandGreen, strokeWidth: 2.5))
              : _messages.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 56, color: c.border),
                        const SizedBox(height: 12),
                        Text('Мессеж байхгүй байна',
                            style: TextStyle(color: c.mutedForeground, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Эхлээд мессеж бичнэ үү',
                            style: TextStyle(color: c.mutedForeground.withOpacity(0.7), fontSize: 13)),
                      ],
                    ))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) => _buildMessage(_messages[i], c),
                    ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: c.cardBackground,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              // Attach button
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, color: c.brandGreen, size: 28),
                onPressed: _showAttachMenu,
              ),
              // Text input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: c.primary, fontSize: 15),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(
                      hintText: 'Мессеж бичих...',
                      hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Send button
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _sending ? c.muted : c.brandGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _sending
                      ? SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                            color: c.brandGreen, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _sending ? null : _sendText,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMessage(ChatMessage msg, AppColorScheme c) {
    final isMine = msg.isMine(_myId);
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = isMine ? c.brandGreen : c.cardBackground;
    final textColor = isMine ? Colors.white : c.primary;
    final timeColor = isMine ? Colors.white70 : c.mutedForeground;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
      bottomRight: isMine ? Radius.zero : const Radius.circular(16),
    );

    // Time string
    final time = msg.createdAt != null
        ? '${msg.createdAt!.hour.toString().padLeft(2, '0')}:${msg.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for others
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: c.brandGreen.withOpacity(0.15),
              child: Text(
                  msg.ajiltniiNer.isNotEmpty ? msg.ajiltniiNer[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.brandGreen)),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble content
          Flexible(
            child: Column(
              crossAxisAlignment: align,
              children: [
                // Sender name (for others)
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(msg.ajiltniiNer,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.brandGreen)),
                  ),

                // Bubble
                GestureDetector(
                  onLongPress: () => _showSeenByInfo(msg),
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.70),
                    padding: msg.isImage
                        ? EdgeInsets.zero // Remove padding for raw images
                        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isImage ? Colors.transparent : bgColor,
                      borderRadius: radius,
                      border: (isMine || msg.isImage) ? null : Border.all(color: c.border.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Image
                      if (msg.isImage && msg.fileUrl != null)
                        GestureDetector(
                          onTap: () => _openGallery(msg),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              '${ApiService.baseUrl}/${msg.fileUrl}',
                              width: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  width: 220, height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: c.brandGreen, strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                width: 220, height: 100,
                                decoration: BoxDecoration(
                                  color: c.muted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.broken_image_rounded, color: c.mutedForeground),
                              ),
                            ),
                          ),
                        ),

                      // File
                      if (msg.isFile && msg.fileUrl != null)
                        Row(
                          mainAxisSize: MainAxisSize.min, // Vital to prevent forcing bubble width expansion
                          children: [
                            Icon(Icons.insert_drive_file_rounded,
                                size: 20, color: textColor.withOpacity(0.8)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(msg.fileName ?? 'Файл',
                                  style: TextStyle(
                                      color: textColor, fontSize: 14,
                                      decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),

                      // Text & Time Shrink-Wrapping (For texts and files)
                      if (!msg.isImage)
                        Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            // Caption or Main Text
                            if ((msg.isText || msg.medeelel.isNotEmpty) && msg.medeelel != msg.fileName)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(msg.medeelel,
                                    style: TextStyle(color: textColor, fontSize: 15)),
                              ),
                            // Time Stamp
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(time, style: TextStyle(fontSize: 10, color: timeColor)),
                                  if (isMine) ...[
                                    const SizedBox(width: 4),
                                    if (msg.isLocal)
                                      Icon(Icons.radio_button_unchecked_rounded, size: 12, color: timeColor)
                                    else if (msg.unshsan.isNotEmpty)
                                      Icon(Icons.done_all_rounded, size: 14, color: Colors.blueAccent.shade100)
                                    else
                                      Icon(Icons.check_circle_outline_rounded, size: 13, color: timeColor),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                      // Dedicated Layout for Image Captions & Timestamp
                      if (msg.isImage)
                        SizedBox(
                          width: 220, // Forces constraints to precisely match the image size
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Caption
                              if (msg.medeelel.isNotEmpty && msg.medeelel != msg.fileName)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6, right: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(msg.medeelel, style: TextStyle(color: textColor, fontSize: 15)),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),

                              // Overlay Time Pill
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(time, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                      if (isMine) ...[
                                        const SizedBox(width: 4),
                                        if (msg.isLocal)
                                          const Icon(Icons.radio_button_unchecked_rounded, size: 12, color: Colors.white)
                                        else if (msg.unshsan.isNotEmpty)
                                          Icon(Icons.done_all_rounded, size: 14, color: Colors.blueAccent.shade100)
                                        else
                                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: Colors.white),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

          // Avatar for mine
          if (isMine) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: c.brandGreen,
              child: Text(
                  msg.ajiltniiNer.isNotEmpty ? msg.ajiltniiNer[0].toUpperCase() : 'Б',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  void _showSeenByInfo(ChatMessage msg) {
    if (msg.isLocal) return; 
    final c = context.colors;
    
    final namesMap = <String, String>{};
    for (var m in _messages) {
      if (m.ajiltniiId.isNotEmpty && m.ajiltniiNer.isNotEmpty) {
        namesMap[m.ajiltniiId] = m.ajiltniiNer;
      }
    }

    final seenUserIds = msg.unshsan.where((id) => id != msg.ajiltniiId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Уншсан хүмүүс', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.primary)),
            ),
            if (seenUserIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text('Хэн ч уншаагүй байна', style: TextStyle(color: c.mutedForeground)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: seenUserIds.length,
                  itemBuilder: (ctx, i) {
                    final uid = seenUserIds[i];
                    final name = namesMap[uid] ?? 'Үл мэдэгдэх хэрэглэгч';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: c.brandGreen.withOpacity(0.1),
                        child: Text(name[0].toUpperCase(), style: TextStyle(color: c.brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: TextStyle(color: c.primary, fontSize: 14)),
                      trailing: Icon(Icons.done_all_rounded, color: Colors.blueAccent.shade100, size: 18),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colors.primary)),
      ]),
    );
  }
}
