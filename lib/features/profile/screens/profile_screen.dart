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
                backgroundColor: AppColors.primary,
                expandedHeight: 200,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primary],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primaryFixed,
                          backgroundImage: user?.avatarUrl.isNotEmpty == true
                              ? NetworkImage(user!.avatarUrl) : null,
                          child: user?.avatarUrl.isEmpty != false
                              ? Text(user?.initials ?? '?',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28, fontWeight: FontWeight.w800,
                                      color: AppColors.primary))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(user?.name ?? 'Loading...',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        if (user?.kosName.isNotEmpty == true)
                          Text('${user!.kosName}${user.room.isNotEmpty ? " · ${user.room}" : ""}',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withAlpha(200))),
                      ]),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Barang Saya', style: GoogleFonts.plusJakartaSans(
                        fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const SizedBox(height: 12),
                  ]),
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
}
