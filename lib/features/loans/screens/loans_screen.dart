import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/loan_model.dart';
import '../../catalog/services/item_service.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = ItemService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Pinjaman', style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [Tab(text: 'Yang Saya Pinjam'), Tab(text: 'Masuk')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // My loans as borrower
          StreamBuilder<List<LoanModel>>(
            stream: _service.getMyLoansAsBorrower(),
            builder: (ctx, snap) => _buildList(ctx, snap, asBorrower: true),
          ),
          // Incoming requests (as owner)
          StreamBuilder<List<LoanModel>>(
            stream: _service.getIncomingRequests(),
            builder: (ctx, snap) => _buildList(ctx, snap, asBorrower: false),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, AsyncSnapshot<List<LoanModel>> snap,
      {required bool asBorrower}) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = snap.data ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text(asBorrower ? 'Belum ada pinjaman' : 'Tidak ada permintaan',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _LoanCard(loan: items[i], asBorrower: asBorrower,
          service: _service),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final bool asBorrower;
  final ItemService service;
  const _LoanCard({required this.loan, required this.asBorrower, required this.service});

  Color _statusColor() {
    switch (loan.status) {
      case AppConstants.loanStatusPending: return AppColors.tertiaryContainer;
      case AppConstants.loanStatusApproved:
      case AppConstants.loanStatusActive: return AppColors.primary;
      case AppConstants.loanStatusCompleted: return AppColors.onSurfaceVariant;
      case AppConstants.loanStatusRejected:
      case AppConstants.loanStatusCancelled: return AppColors.error;
      default: return AppColors.outline;
    }
  }

  String _statusLabel() {
    switch (loan.status) {
      case AppConstants.loanStatusPending: return 'Menunggu';
      case AppConstants.loanStatusApproved: return 'Disetujui';
      case AppConstants.loanStatusActive: return 'Aktif';
      case AppConstants.loanStatusCompleted: return 'Selesai';
      case AppConstants.loanStatusRejected: return 'Ditolak';
      case AppConstants.loanStatusCancelled: return 'Dibatalkan';
      default: return loan.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(10),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: loan.itemImageUrl.isNotEmpty
                  ? Image.network(loan.itemImageUrl, width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loan.itemName, style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text(
                asBorrower ? 'Dari ${loan.ownerName}' : 'Diminta oleh ${loan.borrowerName}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text('${loan.days} hari · ${loan.totalPrice > 0 ? "Rp${loan.totalPrice.toStringAsFixed(0)}" : "Gratis"}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor().withAlpha(25),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _statusColor().withAlpha(80)),
              ),
              child: Text(_statusLabel(), style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor())),
            ),
          ]),

          // Owner action buttons
          if (!asBorrower && loan.isPending) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => service.updateLoanStatus(
                    loan.id, AppConstants.loanStatusRejected),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                child: const Text('Tolak'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final due = DateTime.now().add(Duration(days: loan.days));
                  service.updateLoanStatus(loan.id, AppConstants.loanStatusApproved,
                      dueDate: due);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
                child: const Text('Setujui'),
              )),
            ]),
          ],

          // Borrower: mark as returned
          if (asBorrower && loan.isActive) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 38,
              child: ElevatedButton.icon(
                onPressed: () => service.updateLoanStatus(
                    loan.id, AppConstants.loanStatusCompleted),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Tandai Sudah Dikembalikan'),
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 60, height: 60, color: AppColors.surfaceContainerLow,
    child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppColors.outlineVariant)),
  );
}
