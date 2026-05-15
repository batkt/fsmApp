import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

const String chatApiBase = 'https://admin.zevtabs.mn/api/v1/chat';
const String chatSocketUrl = 'https://admin.zevtabs.mn';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = true;
  bool _sending = false;
  String _guestId = '';
  Map<String, dynamic>? _conversation;
  List<dynamic> _messages = [];
  IO.Socket? _socket;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user != null) {
        _guestId = 'guest_${user.id}';
      } else {
        _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      }

      final displayName = user?.ner ?? '';

      final res = await http.post(
        Uri.parse('$chatApiBase/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'guestId': _guestId, 'displayName': displayName}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(res.body)['data'];
        _conversation = data;

        final msgRes = await http.get(
          Uri.parse(
            '$chatApiBase/conversations/${data['id']}/messages?guestId=$_guestId',
          ),
        );

        if (msgRes.statusCode >= 200 && msgRes.statusCode < 300) {
          final msgData = json.decode(msgRes.body)['data'] as List;
          setState(() {
            _messages = List.from(msgData);
          });
        }
        _setupSocket();
      } else {
        setState(() => _error = 'Чат холбогдоход алдаа гарлаа.');
      }
    } catch (e) {
      setState(() => _error = 'Чат холбогдоход алдаа гарлаа: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  void _setupSocket() {
    if (_conversation == null) return;

    _socket = IO.io(chatSocketUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });

    _socket?.emit('join', {
      'conversationId': _conversation!['id'],
      'guestId': _guestId,
    });

    _socket?.on('message:new', (payload) {
      if (!mounted) return;
      if (payload != null &&
          payload['conversationId'] == _conversation!['id'] &&
          payload['message'] != null) {
        final msg = payload['message'];
        setState(() {
          if (!_messages.any((m) => m['id'] == msg['id'])) {
            _messages.add(msg);
          }
        });
        _scrollToBottom();
      }
    });
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

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _conversation == null || _sending) return;

    _msgCtrl.clear();
    setState(() => _sending = true);

    try {
      final res = await http.post(
        Uri.parse(
          '$chatApiBase/conversations/${_conversation!['id']}/messages',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text, 'guestId': _guestId}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = json.decode(res.body)['data'];
        setState(() {
          if (data['userMsg'] != null &&
              !_messages.any((m) => m['id'] == data['userMsg']['id'])) {
            _messages.add(data['userMsg']);
          }
          if (data['botMsg'] != null &&
              !_messages.any((m) => m['id'] == data['botMsg']['id'])) {
            _messages.add(data['botMsg']);
          }
        });
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Мессеж илгээхэд алдаа гарлаа')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Алдаа: $e')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isHuman = _conversation?['humanMode'] == true;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тусламжийн чат',
              style: TextStyle(color: c.primary, fontSize: 16),
            ),
            Text(
              isHuman ? 'Оператор хариулж байна' : 'Автомат тусламж',
              style: TextStyle(
                color: c.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: c.cardBackground,
        iconTheme: IconThemeData(color: c.primary),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: c.brandGreen))
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: c.destructive)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _initChat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.brandGreen,
                          ),
                          child: const Text(
                            'Дахин оролдох',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'Чат эхлүүлэх\nТа асуух зүйлээ доор бичнэ үү.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: c.brandGreen.withOpacity(0.2),
                                child: Text(
                                  m['role'] == 'agent'
                                      ? (m['agentDisplayName']?[0] ?? 'О')
                                      : 'Б',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.brandGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? c.brandGreen
                                      : c.cardBackground,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                      isUser ? 16 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isUser ? 4 : 16,
                                    ),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(color: c.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser &&
                                        m['role'] == 'agent' &&
                                        m['agentDisplayName'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          m['agentDisplayName'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: c.brandGreen,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      m['text'] ?? '',
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : c.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_sending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Илгээж байна...',
                    style: TextStyle(fontSize: 12, color: c.mutedForeground),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Мессеж бичих...',
                        hintStyle: TextStyle(color: c.mutedForeground),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: c.brandGreen),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: c.background,
                      ),
                      style: TextStyle(color: c.primary),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _sending ? c.border : c.brandGreen,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _sending ? null : _sendMessage,
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
}
