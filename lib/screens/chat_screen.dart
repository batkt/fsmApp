import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.projectId,
    this.taskId,
    required this.barilgiinId,
    required this.baiguullagiinId,
    required this.title,
  });

  final String projectId;
  final String? taskId;
  final String barilgiinId;
  final String baiguullagiinId;
  final String title;

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
  }

  @override
  void dispose() {
    SocketService.offNewMessage();
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
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
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
    setState(() => _sending = true);

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
      if (msg != null) {
        _messages.add(msg);
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
    setState(() => _sending = true);
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
      if (msg != null) {
        _messages.add(msg);
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: c.cardBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: c.primary)),
            Text(SocketService.isConnected ? 'Онлайн' : 'Холбогдож байна...',
                style: TextStyle(fontSize: 12, color: c.mutedForeground)),
          ],
        ),
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
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: msg.isImage
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: radius,
              border: isMine ? null : Border.all(color: c.border.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (msg.isImage && msg.fileUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiService.baseUrl}${msg.fileUrl}',
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

                // File
                if (msg.isFile && msg.fileUrl != null)
                  Row(children: [
                    Icon(Icons.insert_drive_file_rounded,
                        size: 20, color: textColor.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(msg.fileName ?? 'Файл',
                          style: TextStyle(
                              color: textColor, fontSize: 14,
                              decoration: TextDecoration.underline)),
                    ),
                  ]),

                // Text
                if (msg.isText || msg.medeelel.isNotEmpty)
                  Text(msg.medeelel,
                      style: TextStyle(color: textColor, fontSize: 15)),

                // Time
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(time,
                      style: TextStyle(fontSize: 10, color: timeColor)),
                ),
              ],
            ),
          ),
        ],
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
