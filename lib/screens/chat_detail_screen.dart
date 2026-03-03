import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ChatDetailScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final String title;

  const ChatDetailScreen({
    super.key,
    required this.messages,
    required this.title,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Extract unique members from the chat messages
  List<Map<String, String>> get _members {
    final Map<String, String> uniqueMembers = {};
    for (var m in widget.messages) {
      if (m.ajiltniiId.isNotEmpty && m.ajiltniiNer.isNotEmpty) {
        uniqueMembers[m.ajiltniiId] = m.ajiltniiNer;
      }
    }
    return uniqueMembers.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  // Filter only images
  List<ChatMessage> get _images =>
      widget.messages.where((m) => m.isImage && m.fileUrl != null).toList();

  // Filter only files
  List<ChatMessage> get _files =>
      widget.messages.where((m) => m.isFile && m.fileUrl != null).toList();

  void _openGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoViewGallery.builder(
            itemCount: _images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              final msg = _images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider:
                    NetworkImage('${ApiService.baseUrl}/${msg.fileUrl}'),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: 'detail_${msg.id}'),
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
        backgroundColor: c.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Дэлгэрэнгүй',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: c.primary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: c.brandGreen,
          unselectedLabelColor: c.mutedForeground,
          indicatorColor: c.brandGreen,
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              return Colors.transparent; // completely disables hover/ripple/highlight
            },
          ),
          tabs: const [
            Tab(text: 'Гишүүд'),
            Tab(text: 'Зураг'),
            Tab(text: 'Файл'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Members Tab
          _members.isEmpty
              ? Center(
                  child: Text('Гишүүн байхгүй',
                      style: TextStyle(color: c.mutedForeground)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: CircleAvatar(
                        backgroundColor: c.brandGreen.withOpacity(0.15),
                        child: Text(
                          member['name']![0].toUpperCase(),
                          style: TextStyle(
                            color: c.brandGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member['name']!,
                          style: TextStyle(
                              color: c.primary, fontWeight: FontWeight.w500)),
                    );
                  },
                ),

          // Images Tab
          _images.isEmpty
              ? Center(
                  child: Text('Зураг байхгүй',
                      style: TextStyle(color: c.mutedForeground)))
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final msg = _images[index];
                    return GestureDetector(
                      onTap: () => _openGallery(index),
                      child: Hero(
                        tag: 'detail_${msg.id}',
                        child: Image.network(
                          '${ApiService.baseUrl}/${msg.fileUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: c.border,
                            child: Icon(Icons.broken_image, color: c.muted),
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Files Tab
          _files.isEmpty
              ? Center(
                  child: Text('Файл байхгүй',
                      style: TextStyle(color: c.mutedForeground)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final msg = _files[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.insert_drive_file_rounded,
                            color: c.brandGreen),
                      ),
                      title: Text(msg.fileName ?? 'Файл',
                          style: TextStyle(
                              color: c.primary,
                              decoration: TextDecoration.underline)),
                      subtitle: msg.createdAt != null
                          ? Text(
                              '${msg.createdAt!.year}-${msg.createdAt!.month.toString().padLeft(2, '0')}-${msg.createdAt!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(color: c.mutedForeground))
                          : null,
                    );
                  },
                ),
        ],
      ),
    );
  }
}
