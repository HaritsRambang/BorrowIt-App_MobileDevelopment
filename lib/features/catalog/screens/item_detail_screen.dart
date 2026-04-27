import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/item_model.dart';
import '../services/item_service.dart';
import '../../messages/screens/chat_screen.dart';
import '../../messages/services/chat_service.dart';
import '../../notifications/services/notification_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _itemService = ItemService();
  final _notifService = NotificationService();
  int _days = 1;
  bool _isRequesting = false;
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == widget.item.ownerId;

  Future<void> _requestLoan() async {
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa meminjam barang milik sendiri')),
      );
      return;
    }
    setState(() => _isRequesting = true);
    try {
      await _itemService.requestLoan(
        item: widget.item,
        days: _days,
        message: _messageCtrl.text.trim(),
      );
      await _notifService.sendNotification(
        toUserId: widget.item.ownerId,
        title: 'Permintaan Pinjam Baru!',
        body:
            '${FirebaseAuth.instance.currentUser?.displayName ?? "Seseorang"} ingin meminjam "${widget.item.name}" selama $_days hari.',
        type: 'loan_request',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan terkirim! Tunggu konfirmasi pemilik.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _openChat() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final chatId = ChatService.chatId(uid, widget.item.ownerId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          receiverId: widget.item.ownerId,
          receiverName: widget.item.ownerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 64, color: AppColors.outlineVariant),
                        ),
                      ))
                  : Container(
                      color: AppColors.surfaceContainerLow,
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 64, color: AppColors.outlineVariant),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isAvailable ? AppColors.primaryContainer : AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        item.isAvailable ? 'Tersedia' : 'Sedang Dipinjam',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: item.isAvailable ? AppColors.onPrimaryContainer : AppColors.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.location,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(item.name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onSurface, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(item.priceLabel,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Text(item.description,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurfaceVariant, height: 1.6)),
                  const SizedBox(height: 20),

                  // Owner card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outlineVariant.withAlpha(128)),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.secondaryContainer,
                        child: Text(
                          item.ownerName.isNotEmpty ? item.ownerName[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.ownerName,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('Balasan dalam ~1 jam',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Bento info
                  Row(children: [
                    Expanded(child: _InfoCard(icon: Icons.calendar_month_outlined,
                        label: 'Maks. Durasi', value: '${item.maxDays} hari')),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(icon: Icons.verified_user_outlined,
                        label: 'Kondisi', value: item.condition)),
                  ]),
                  const SizedBox(height: 16),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.onSecondaryFixed),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Pastikan Anda membaca pedoman peminjaman komunitas sebelum mengajukan.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSecondaryFixed, height: 1.4),
                      )),
                    ]),
                  ),

                  if (!_isOwner && item.isAvailable) ...[
                    const SizedBox(height: 24),
                    Text('Pilih Durasi', style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Durasi', style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface)),
                        Row(children: [
                          _DayBtn(icon: Icons.remove,
                              onTap: _days > 1 ? () => setState(() => _days--) : null),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('$_days hari',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary))),
                          _DayBtn(icon: Icons.add,
                              onTap: _days < item.maxDays ? () => setState(() => _days++) : null),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pesan untuk pemilik (opsional)',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    if (item.pricePerDay > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Total Biaya', style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onPrimaryFixed)),
                          Text('Rp${(item.pricePerDay * _days).toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ]),
                      ),
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!_isOwner && item.isAvailable)
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isRequesting ? null : _requestLoan,
                  icon: _isRequesting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(item.pricePerDay > 0
                      ? 'Ajukan — Rp${(item.pricePerDay * _days).toStringAsFixed(0)}'
                      : 'Ajukan Peminjaman (Gratis)'),
                ),
              ),
            if (!_isOwner) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat dengan Pemilik'),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outlineVariant.withAlpha(128)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
    ]),
  );
}

class _DayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _DayBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: onTap != null ? AppColors.primaryContainer : AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18,
          color: onTap != null ? AppColors.onPrimaryContainer : AppColors.outline),
    ),
  );
}
