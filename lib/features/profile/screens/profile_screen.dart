import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../catalog/services/item_service.dart';
import '../../catalog/screens/item_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<UserModel?>(
        future: AuthService().getUserById(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.surface,
                pinned: true,
                automaticallyImplyLeading: false,
                title: Text('Borrow-It',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      }
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Bento Grid
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceVariant),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(12),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primaryFixed,
                              backgroundImage: user?.avatarUrl.isNotEmpty == true
                                  ? NetworkImage(user!.avatarUrl)
                                  : null,
                              child: user?.avatarUrl.isEmpty != false
                                  ? Text(user?.initials ?? '?',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user?.name ?? 'Loading...',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                                  const SizedBox(height: 4),
                                  if (user?.kosName.isNotEmpty == true)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text('${user!.kosName}${user.room.isNotEmpty ? ", Kamar ${user.room}" : ""}',
                                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified, size: 14, color: AppColors.onPrimaryContainer),
                                            const SizedBox(width: 4),
                                            Text('Terverifikasi', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onPrimaryContainer)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.outlineVariant),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14, color: AppColors.onSurface),
                                            const SizedBox(width: 4),
                                            Text('Joined 2024', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Score Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.tertiaryFixedDim.withAlpha(76)),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text('SKOR BORROW-IT',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.onTertiaryFixedVariant)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('98', style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.tertiaryContainer, height: 1)),
                                Text('/100', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.tertiaryContainer.withAlpha(178))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Sangat dapat dipercaya', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onTertiaryFixedVariant)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dampak Komunitas
                      Text('Dampak Komunitas', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(Icons.handshake, '12', 'Barang Dibagikan', AppColors.secondaryFixed, AppColors.onSecondaryFixed),
                          _buildStatCard(Icons.assignment_turned_in, '100%', 'Pengembalian', AppColors.primaryFixed, AppColors.onPrimaryFixed),
                          _buildStatCard(Icons.bolt, '< 1hr', 'Waktu Respon', AppColors.surfaceVariant, AppColors.onSurfaceVariant),
                          _buildStatCard(Icons.favorite, '8', 'Peminjam Berulang', AppColors.tertiaryFixed, AppColors.onTertiaryFixed),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Ulasan Tetangga
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ulasan Tetangga', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                          Row(
                            children: [
                              Text('4.9', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, size: 20, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('(15)', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReviewCard('Kak Rina', 'Dipinjam: Kamera Mirrorless', 'Sangat ramah dan barangnya sesuai deskripsi. Pengambilan juga sangat mudah!', '2 hari yang lalu', 'https://i.pravatar.cc/150?u=rina'),
                      const SizedBox(height: 12),
                      _buildReviewCard('Mbak Sari', 'Dipinjam: Proyektor Mini', 'Kondisi proyektor bagus banget buat nobar. Orangnya juga fast response.', '1 minggu yang lalu', 'https://i.pravatar.cc/150?u=sari'),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withAlpha(50)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Lihat Semua 15 Ulasan'),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text('Barang Saya', style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    ],
                  ),
                ),
              ),

              // My items stream
              StreamBuilder<List<ItemModel>>(
                stream: ItemService().getMyItems(),
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(children: [
                            const Icon(Icons.inventory_2_outlined, size: 48,
                                color: AppColors.outlineVariant),
                            const SizedBox(height: 12),
                            Text('Belum ada barang',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Tap tombol + untuk menambahkan barang',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.outline)),
                          ]),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    sliver: SliverList.separated(
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(item.imageUrl,
                                      width: 56, height: 56, fit: BoxFit.cover)
                                  : Container(width: 56, height: 56,
                                      color: AppColors.surfaceContainerLow,
                                      child: const Icon(Icons.image_outlined,
                                          color: AppColors.outlineVariant)),
                            ),
                            title: Text(item.name, style: GoogleFonts.plusJakartaSans(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                            subtitle: Text(item.priceLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                            trailing: Switch(
                              value: item.isAvailable,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) =>
                                  ItemService().toggleAvailability(item.id, val),
                            ),
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => ItemDetailScreen(item: item))),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String subtitle, String content, String date, String avatarUrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: AppColors.surfaceDim,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withAlpha(76),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('5.0', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline)),
        ],
      ),
    );
  }
}
