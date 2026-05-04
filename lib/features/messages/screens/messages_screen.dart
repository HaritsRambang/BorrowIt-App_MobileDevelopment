import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Pesan', style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ChatService().getMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data?.docs.toList() ?? [];
          
          // Client-side sort to avoid Firestore composite index
          docs.sort((a, b) {
            final aAt = (a.data()['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bAt = (b.data()['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bAt.compareTo(aAt);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 72, color: AppColors.outlineVariant),
                const SizedBox(height: 16),
                Text('Belum ada percakapan', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Mulai chat dari halaman detail barang', style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.outline)),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final participants = List<String>.from(data['participants'] ?? []);
              final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
              final otherId = participants.firstWhere((p) => p != uid, orElse: () => '');
              final otherName = names[otherId] as String? ?? 'Unknown';
              final lastMsg = data['lastMessage'] as String? ?? '';
              final lastAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
              final isMe = data['lastSenderId'] == uid;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.secondaryContainer,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppColors.onSecondaryContainer),
                  ),
                ),
                title: Text(otherName, style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                subtitle: Text(
                  isMe ? 'Kamu: $lastMsg' : lastMsg,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                trailing: lastAt != null ? Text(
                  _formatTime(lastAt),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
                ) : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: docs[i].id,
                    receiverId: otherId,
                    receiverName: otherName,
                  ),
                )),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}
