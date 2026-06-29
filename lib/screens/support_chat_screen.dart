import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
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

  // Voice recording states
  bool _isRecording = false;
  int _recordingTime = 0;
  Timer? _recordingTimer;
  AudioRecorder? _audioRecorder;
  String? _recordedFilePath;

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
    _recordingTimer?.cancel();
    _audioRecorder?.dispose();
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
        _guestId = 'ajiltan_${user.id}';
      } else {
        _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      }

      final displayName = user?.ner ?? '';
      final baiguullagaName = user?.baiguullagaNer ?? '';

      final res = await http.post(
        Uri.parse('$chatApiBase/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'guestId': _guestId,
          'displayName': displayName,
          'project': 'fsmApp',
          'baiguullagaName': baiguullagaName,
          'ajiltniiNer': displayName,
        }),
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
      final user = AuthService.currentUser;
      final displayName = user?.ner ?? '';
      final baiguullagaName = user?.baiguullagaNer ?? '';

      final res = await http.post(
        Uri.parse(
          '$chatApiBase/conversations/${_conversation!['id']}/messages',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'guestId': _guestId,
          'project': 'fsmApp',
          'displayName': displayName,
          'baiguullagaName': baiguullagaName,
          'ajiltniiNer': displayName,
        }),
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

  Future<void> _startRecording() async {
    try {
      _audioRecorder ??= AudioRecorder();
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder!.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingTime = 0;
          _recordedFilePath = path;
        });

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) {
            setState(() {
              _recordingTime++;
            });
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Микрофон ашиглах зөвшөөрөл олгоно уу')),
        );
      }
    } catch (e) {
      debugPrint('Start recording error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Бичлэг эхлүүлэхэд алдаа гарлаа: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder == null || !_isRecording) return;
    _recordingTimer?.cancel();

    try {
      final path = await _audioRecorder!.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null && mounted) {
        _uploadAndSendFile(path, 'audio', duration: _recordingTime);
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Бичлэг зогсооход алдаа гарлаа: $e')),
      );
    }
  }

  Future<void> _cancelRecording() async {
    if (_audioRecorder == null || !_isRecording) return;
    _recordingTimer?.cancel();
    try {
      await _audioRecorder!.stop();
      setState(() {
        _isRecording = false;
      });
      if (_recordedFilePath != null) {
        final file = File(_recordedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Cancel recording error: $e');
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        _uploadAndSendFile(image.path, 'image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Зураг сонгоход алдаа гарлаа: $e')),
      );
    }
  }

  Future<void> _uploadAndSendFile(String path, String fileType, {int? duration}) async {
    if (_conversation == null) return;

    setState(() => _sending = true);

    try {
      final uri = Uri.parse('https://admin.zevtabs.mn/api/v1/chat/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['fileType'] = fileType
        ..files.add(await http.MultipartFile.fromPath('file', path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final fileUrl = body['fileUrl'];

          final user = AuthService.currentUser;
          final displayName = user?.ner ?? '';
          final baiguullagaName = user?.baiguullagaNer ?? '';

          final res = await http.post(
            Uri.parse('$chatApiBase/conversations/${_conversation!['id']}/messages'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'text': '',
              'fileUrl': fileUrl,
              'fileType': fileType,
              'duration': duration,
              'guestId': _guestId,
              'project': 'fsmApp',
              'displayName': displayName,
              'baiguullagaName': baiguullagaName,
              'ajiltniiNer': displayName,
            }),
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
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Файл илгээхэд алдаа гарлаа')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл хуулахад алдаа гарлаа')),
        );
      }
    } catch (e) {
      debugPrint('Upload/Send error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа гарлаа: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Widget _buildChoiceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 260),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.brandGreen.withOpacity(0.4), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: c.cardBackground,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c.brandGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: c.brandGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: c.brandGreen.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Чат эхлүүлэх',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Та доорх сонголтуудаас сонгож чатыг эхлүүлнэ үү.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.mutedForeground),
                          ),
                          const SizedBox(height: 24),
                          _buildChoiceButton(
                            context,
                            icon: Icons.smart_toy_outlined,
                            label: 'Чатботтой ярих',
                            onPressed: () {
                              _msgCtrl.text = 'Чатботтой ярих';
                              _sendMessage();
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildChoiceButton(
                            context,
                            icon: Icons.support_agent_outlined,
                            label: 'Оператортой холбогдох',
                            onPressed: () {
                              _msgCtrl.text = 'Оператортой холбогдох';
                              _sendMessage();
                            },
                          ),
                        ],
                      ),
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
                                    if (m['text'] != null && m['text'].toString().isNotEmpty)
                                      Text(
                                        m['text'] ?? '',
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : c.primary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    if (m['fileUrl'] != null) ...[
                                      const SizedBox(height: 6),
                                      if (m['fileType'] == 'image')
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ImagePreviewScreen(
                                                    imageUrl: 'https://admin.zevtabs.mn/api/file?path=${m['fileUrl']}',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(maxHeight: 200),
                                              child: Image.network(
                                                'https://admin.zevtabs.mn/api/file?path=${m['fileUrl']}',
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Container(
                                                  padding: const EdgeInsets.all(8),
                                                  color: Colors.black.withOpacity(0.1),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.broken_image, color: Colors.grey),
                                                      SizedBox(width: 8),
                                                      Text('Зураг харуулахад алдаа гарлаа', style: TextStyle(fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (m['fileType'] == 'audio')
                                        VoiceMessageWidget(
                                          fileUrl: m['fileUrl'],
                                          duration: m['duration'] != null ? (m['duration'] as num).toInt() : null,
                                          isUser: isUser,
                                        ),
                                    ],
                                    if (m['createdAt'] != null) ...[
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          (() {
                                            try {
                                              final dt = DateTime.parse(m['createdAt'].toString()).toLocal();
                                              final month = dt.month.toString().padLeft(2, '0');
                                              final day = dt.day.toString().padLeft(2, '0');
                                              final hour = dt.hour.toString().padLeft(2, '0');
                                              final minute = dt.minute.toString().padLeft(2, '0');
                                              return "$month/$day $hour:$minute";
                                            } catch (_) {
                                              return "";
                                            }
                                          })(),
                                          style: TextStyle(
                                            color: isUser
                                                ? Colors.white.withOpacity(0.7)
                                                : c.mutedForeground,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
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
              child: _isRecording
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const _BlinkingRedDot(),
                            const SizedBox(width: 8),
                            Text(
                              '${(_recordingTime ~/ 60).toString().padLeft(2, '0')}:${(_recordingTime % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _cancelRecording,
                              child: Text(
                                'Болих',
                                style: TextStyle(color: c.mutedForeground),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _stopRecording,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Илгээх',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.image_outlined, color: c.mutedForeground),
                          onPressed: _pickAndSendImage,
                        ),
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
                        IconButton(
                          icon: Icon(Icons.mic_none_outlined, color: c.mutedForeground),
                          onPressed: _startRecording,
                        ),
                        const SizedBox(width: 4),
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

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class VoiceMessageWidget extends StatefulWidget {
  final String fileUrl;
  final int? duration;
  final bool isUser;

  const VoiceMessageWidget({
    super.key,
    required this.fileUrl,
    this.duration,
    required this.isUser,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    if (widget.duration != null) {
      _duration = Duration(seconds: widget.duration!);
    }
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser ? Colors.white : Colors.black87;
    final url = 'https://admin.zevtabs.mn/api/file?path=${widget.fileUrl}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: color,
            size: 32,
          ),
          onPressed: () async {
            if (_isPlaying) {
              await _player.pause();
            } else {
              await _player.play(UrlSource(url));
            }
          },
        ),
        const SizedBox(width: 8),
        Text(
          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _BlinkingRedDot extends StatefulWidget {
  const _BlinkingRedDot();

  @override
  State<_BlinkingRedDot> createState() => _BlinkingRedDotState();
}

class _BlinkingRedDotState extends State<_BlinkingRedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animCtrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
