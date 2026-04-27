import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/timezone_service.dart';
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
  ChatMessage? _replyingTo;
  ChatMessage? _editingMsg;

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
    SocketService.offMessageEdited();
    SocketService.offMessageDeleted();
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
      if (widget.taskId == null && msg.taskId != null && msg.taskId!.isNotEmpty)
        return;

      if (_messages.any((m) => m.id == msg.id)) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();

      // If we are in the chat, mark it as read
      if (msg.ajiltniiId != _myId) {
        _markAllAsRead();
      }
    });

    SocketService.onMessageEdited((msg) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = msg;
        }
      });
    });

    SocketService.onMessageDeleted((chatId) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == chatId);
        if (idx != -1) {
          final old = _messages[idx];
          _messages[idx] = ChatMessage(
            id: old.id,
            projectId: old.projectId,
            taskId: old.taskId,
            ajiltniiId: old.ajiltniiId,
            ajiltniiNer: old.ajiltniiNer,
            medeelel: 'Мессеж устгагдлаа',
            turul: old.turul,
            fileUrl: old.fileUrl,
            fileName: old.fileName,
            barilgiinId: old.barilgiinId,
            baiguullagiinId: old.baiguullagiinId,
            createdAt: old.createdAt,
            unshsan: old.unshsan,
            isDeleted: true,
          );
        }
      });
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

    if (_editingMsg != null) {
      _editMsgSubmit(text);
      return;
    }

    _msgCtrl.clear();
    final replyToData = _replyingTo != null
        ? ReplyTo(
            chatId: _replyingTo!.id,
            medeelel: _replyingTo!.medeelel,
            ajiltniiNer: _replyingTo!.ajiltniiNer,
            turul: _replyingTo!.turul,
          )
        : null;

    setState(() {
      _replyingTo = null;
    });

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
      createdAt: DateTime.now().toUtc(),
      unshsan: [],
      isLocal: true,
      replyTo: replyToData,
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
      replyTo: replyToData,
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
        AppToast.show(
          context,
          'Мессеж илгээхэд алдаа гарлаа',
          icon: Icons.error_outline_rounded,
          color: context.colors.destructive,
        );
      }
    });
    _scrollToBottom();
  }

  Future<void> _editMsgSubmit(String newText) async {
    if (_editingMsg == null) return;
    final msgId = _editingMsg!.id;
    _msgCtrl.clear();
    setState(() => _editingMsg = null);

    final updated = await ChatService.edit(msgId, newText);
    if (!mounted) return;

    if (updated != null) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) _messages[idx] = updated;
      });
    } else {
      AppToast.show(
        context,
        'Зурвас засахад алдаа гарлаа',
        icon: Icons.error_outline_rounded,
        color: context.colors.destructive,
      );
    }
  }

  Future<void> _deleteMsg(String id) async {
    final success = await ChatService.delete(id);
    if (!success && mounted) {
      AppToast.show(
        context,
        'Зурвас устгахад алдаа гарлаа',
        icon: Icons.error_outline_rounded,
        color: context.colors.destructive,
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    await _uploadFile(picked.path);
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked == null) return;
    await _uploadFile(picked.path);
  }

  Future<void> _uploadFile(String path) async {
    final isImage =
        path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.jpeg');
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
      createdAt: DateTime.now().toUtc(),
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
        AppToast.show(
          context,
          'Файл илгээхэд алдаа гарлаа',
          icon: Icons.error_outline_rounded,
          color: context.colors.destructive,
        );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttachOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Зураг',
                      color: c.brandGreen,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage();
                      },
                    ),
                    _AttachOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Камер',
                      color: c.info,
                      onTap: () {
                        Navigator.pop(ctx);
                        _takePhoto();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGallery(ChatMessage tappedMsg) {
    // Filter only images
    final imageMessages = _messages
        .where((m) => m.isImage && m.fileUrl != null)
        .toList();
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
                    debugPrint('[Chat] Downloading image from: $url');
                    final appDocDir = await getApplicationDocumentsDirectory();
                    final savePath =
                        '${appDocDir.path}/${msg.fileName ?? 'image.jpg'}';
                    debugPrint('[Chat] Saving to: $savePath');
                    await Dio().download(url, savePath);
                    debugPrint('[Chat] Download successful, now saving to gallery...');
                    
                    final result = await ImageGallerySaver.saveFile(savePath);
                    debugPrint('[Chat] Gallery save result: $result');

                    if (context.mounted) {
                      AppToast.show(
                        context,
                        'Зураг галлерей руу хадгалагдлаа',
                        icon: Icons.check_circle_rounded,
                        color: context.colors.success,
                      );
                    }
                  } catch (e) {
                    debugPrint('[Chat] Gallery save failed: $e');
                    if (context.mounted) {
                      AppToast.show(
                        context,
                        'Галлерей руу хадгалахад алдаа гарлаа: $e',
                        icon: Icons.error_outline_rounded,
                        color: context.colors.destructive,
                      );
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
                imageProvider: NetworkImage(
                  '${ApiService.baseUrl}/${msg.fileUrl}',
                ),
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
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: c.primary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: Icon(
                Icons.info_outline_rounded,
                color: c.brandGreen,
                size: 20,
              ),
              label: Text(
                'Дэлгэрэнгүй',
                style: TextStyle(
                  color: c.brandGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
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
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: c.brandGreen,
                      strokeWidth: 2.5,
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 56,
                          color: c.border,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Мессеж байхгүй байна',
                          style: TextStyle(
                            color: c.mutedForeground,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Эхлээд мессеж бичнэ үү',
                          style: TextStyle(
                            color: c.mutedForeground.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessage(_messages[i], c),
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: c.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply Preview
                  if (_replyingTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.cardBackground,
                        border: Border(
                          bottom: BorderSide(color: c.border.withOpacity(0.3), width: 0.5),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.reply_rounded, size: 14, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        _replyingTo!.ajiltniiNer,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _replyingTo!.medeelel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: c.mutedForeground),
                              onPressed: () => setState(() => _replyingTo = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Edit Preview
                  if (_editingMsg != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: c.border.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Засаж байна',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  _editingMsg!.medeelel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _msgCtrl.clear();
                              setState(() => _editingMsg = null);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Row(
                      children: [
                        // Attach button
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: c.brandGreen,
                            size: 28,
                          ),
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
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: _editingMsg != null
                                    ? 'Засах...'
                                    : 'Мессеж бичих...',
                                hintStyle: TextStyle(
                                  color: c.mutedForeground.withOpacity(0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Send button
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _sending ? c.muted : (_editingMsg != null ? Colors.blue : c.brandGreen),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _sending
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _editingMsg != null
                                        ? Icons.check_rounded
                                        : Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            onPressed: _sending ? null : _sendText,
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
    );
  }

  Widget _buildMessage(ChatMessage msg, AppColorScheme c) {
    if (msg.isDeleted) {
      final isMine = msg.isMine(_myId);
      final radius = BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
        bottomRight: isMine ? Radius.zero : const Radius.circular(16),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.muted.withOpacity(0.5),
              borderRadius: radius,
              border: Border.all(color: c.border.withOpacity(0.2)),
            ),
            child: Text(
              'Мессеж устгагдлаа',
              style: TextStyle(
                color: c.mutedForeground,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

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

    // Time string in Mongolia timezone (UTC+8)
    final time = TimezoneService.formatTime(msg.createdAt);

    return Dismissible(
      key: Key(msg.id),
      direction: msg.isDeleted ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          // Left swipe (Right to Left) -> Reply (Half swipe behavior)
          setState(() => _replyingTo = msg);
          HapticFeedback.mediumImpact();
          return false; // Spring back
        } else if (dir == DismissDirection.startToEnd) {
          // Right swipe (Left to Right) -> Delete (Full swipe behavior)
          final user = AuthService.currentUser;
          final isAdmin = user?.role.toLowerCase() == 'admin' || user?.role.toLowerCase() == 'manager';
          final isMine = msg.isMine(_myId);
          
          if (isMine || isAdmin) {
            HapticFeedback.vibrate();
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final colorScheme = ctx.colors;
                return AlertDialog(
                  backgroundColor: colorScheme.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    'Мессеж устгах',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Та энэ мессежийг устгахдаа итгэлтэй байна уу?',
                    style: TextStyle(color: colorScheme.primary.withOpacity(0.8)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Болих', style: TextStyle(color: colorScheme.mutedForeground)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: colorScheme.destructive),
                      child: const Text('Устгах', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            );
            if (confirm == true) {
              _deleteMsg(msg.id);
              return true; // Proceed with disappearance animation
            }
          } else {
            AppToast.show(context, 'Устгах эрхгүй байна', icon: Icons.lock_outline_rounded);
          }
          return false;
        }
        return false;
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          // Immediately update local state to reflect the deletion
          // to ensure it shows as a placeholder if the widget is rebuilt
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx != -1) {
              final old = _messages[idx];
              _messages[idx] = ChatMessage(
                id: old.id,
                projectId: old.projectId,
                taskId: old.taskId,
                ajiltniiId: old.ajiltniiId,
                ajiltniiNer: old.ajiltniiNer,
                medeelel: 'Мессеж устгагдлаа',
                turul: old.turul,
                fileUrl: old.fileUrl,
                fileName: old.fileName,
                barilgiinId: old.barilgiinId,
                baiguullagiinId: old.baiguullagiinId,
                createdAt: old.createdAt,
                unshsan: old.unshsan,
                isDeleted: true,
              );
            }
          });
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.teal.withOpacity(0.2),
        child: const Icon(Icons.reply_rounded, color: Colors.teal, size: 28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: c.brandGreen.withOpacity(0.15),
                child: Text(
                  msg.ajiltniiNer.isNotEmpty ? msg.ajiltniiNer[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.brandGreen),
                ),
              ),
              const SizedBox(width: 8),
            ],
  
            Flexible(
              child: Column(
                crossAxisAlignment: align,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        msg.ajiltniiNer,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.brandGreen),
                      ),
                    ),
  
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(msg),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: msg.isImage ? Colors.transparent : bgColor,
                        borderRadius: radius,
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.05),
                             blurRadius: 4,
                             offset: const Offset(0, 2),
                           )
                        ],
                        border: (isMine || msg.isImage) ? null : Border.all(color: c.border.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.replyTo != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(isMine ? 0.15 : 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: isMine ? Colors.white70 : c.brandGreen,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.replyTo!.ajiltniiNer,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isMine ? Colors.white : c.brandGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (msg.replyTo!.medeelel.isNotEmpty)
                                      Text(
                                        msg.replyTo!.medeelel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMine 
                                              ? Colors.white.withOpacity(0.8) 
                                              : c.mutedForeground,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
  
                            Padding(
                              padding: msg.isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg.isImage && msg.fileUrl != null)
                                    GestureDetector(
                                      onTap: () => _openGallery(msg),
                                      child: Image.network(
                                        '${ApiService.baseUrl}/${msg.fileUrl}',
                                        width: 240,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(width: 240, height: 120, color: c.muted, child: const Icon(Icons.broken_image_rounded)),
                                      ),
                                    ),
  
                                  if (msg.isFile && msg.fileUrl != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.insert_drive_file_rounded, size: 20, color: textColor.withOpacity(0.8)),
                                        const SizedBox(width: 8),
                                        Flexible(child: Text(msg.fileName ?? 'Файл', style: TextStyle(color: textColor, fontSize: 13, decoration: TextDecoration.underline))),
                                      ],
                                    ),
  
                                  if (!msg.isImage && msg.medeelel.isNotEmpty)
                                    Text(msg.medeelel, style: TextStyle(color: textColor, fontSize: 14)),
  
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (msg.isEdited)
                                        Text('зассан ', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: timeColor.withOpacity(0.7))),
                                      Text(time, style: TextStyle(fontSize: 10, color: timeColor)),
                                      if (isMine) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          msg.isLocal ? Icons.access_time_rounded : (msg.unshsan.isNotEmpty ? Icons.done_all_rounded : Icons.check_rounded),
                                          size: 12,
                                          color: (msg.unshsan.isNotEmpty && !msg.isLocal) ? Colors.blueAccent.shade100 : timeColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                  msg.ajiltniiNer.isNotEmpty
                      ? msg.ajiltniiNer[0].toUpperCase()
                      : 'Б',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    if (msg.isDeleted) return;

    final c = context.colors;
    final isMine = msg.isMine(_myId);
    final user = AuthService.currentUser;
    final isAdmin = user?.role.toLowerCase() == 'admin' || user?.role.toLowerCase() == 'manager';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Colors.teal),
                title: const Text('Хариулах'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingTo = msg);
                },
              ),

              ListTile(
                leading: Icon(Icons.copy_rounded, color: c.mutedForeground),
                title: const Text('Хуулах'),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.medeelel));
                  AppToast.show(context, 'Хуулагдлаа', icon: Icons.copy_rounded);
                },
              ),

              ListTile(
                leading: Icon(Icons.remove_red_eye_outlined, color: c.mutedForeground),
                title: const Text('Уншсан хүмүүс'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSeenByInfo(msg);
                },
              ),

              if (isMine && !msg.isImage)
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                  title: const Text('Засах'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _editingMsg = msg;
                      _msgCtrl.text = msg.medeelel;
                    });
                  },
                ),

              if (isMine || isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Устгах'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMsg(msg.id);
                  },
                ),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
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

    final seenUserIds = msg.unshsan
        .where((id) => id != msg.ajiltniiId)
        .toList();

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Уншсан хүмүүс',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.primary,
                ),
              ),
            ),
            if (seenUserIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  'Хэн ч уншаагүй байна',
                  style: TextStyle(color: c.mutedForeground),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
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
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            color: c.brandGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(color: c.primary, fontSize: 14),
                      ),
                      trailing: Icon(
                        Icons.done_all_rounded,
                        color: Colors.blueAccent.shade100,
                        size: 18,
                      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
