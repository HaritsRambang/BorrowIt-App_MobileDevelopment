import 'dart:io';
import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../catalog/services/item_service.dart';

class AddItemScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const AddItemScreen({super.key, required this.cameras});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _kosCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _category = 'Perkakas';
  String _condition = 'Baik';
  int _maxDays = 3;
  File? _imageFile;
  bool _showCamera = false;
  CameraController? _cameraCtrl;
  bool _isLoading = false;
  final _service = ItemService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    _cameraCtrl = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
    );
    await _cameraCtrl!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _kosCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    final xfile = await _cameraCtrl!.takePicture();
    setState(() {
      _imageFile = File(xfile.path);
      _showCamera = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil foto barang terlebih dahulu')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;
      await _service.addItem(
        imageFile: _imageFile!,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        condition: _condition,
        pricePerDay: price,
        maxDays: _maxDays,
        location: _locationCtrl.text.trim(),
        kosName: _kosCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCamera) return _buildCameraView();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Barang'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Photo section
            GestureDetector(
              onTap: () => setState(() => _showCamera = true),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageFile != null ? AppColors.primary : AppColors.outlineVariant,
                    width: _imageFile != null ? 2 : 1,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Ganti', style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ]),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: AppColors.onPrimaryContainer, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text('Ambil Foto Barang', style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                        const SizedBox(height: 4),
                        Text('Gunakan kamera langsung', style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.onSurfaceVariant)),
                      ]),
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Informasi Barang'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nama Barang', prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                  labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
              items: AppConstants.categories
                  .where((c) => c != 'Semua')
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(
                  labelText: 'Kondisi Barang', prefixIcon: Icon(Icons.star_outline_rounded)),
              items: AppConstants.conditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Harga & Durasi'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga per Hari (Rp) — isi 0 untuk Gratis',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Max days
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Maks. Durasi Pinjam', style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.onSurface)),
                Row(children: [
                  _DayBtn(icon: Icons.remove,
                      onTap: _maxDays > 1 ? () => setState(() => _maxDays--) : null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_maxDays hari', style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  _DayBtn(icon: Icons.add,
                      onTap: _maxDays < 14 ? () => setState(() => _maxDays++) : null),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Lokasi'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Kamar / Lantai (cth: Kamar 12, Lantai 1)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kosCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Kos (opsional)',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Tambahkan Barang'),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraCtrl != null && _cameraCtrl!.value.isInitialized
          ? Stack(fit: StackFit.expand, children: [
              CameraPreview(_cameraCtrl!),
              Positioned(bottom: 40, left: 0, right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    IconButton(
                      onPressed: () => setState(() => _showCamera = false),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                    ),
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(128), width: 4),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppColors.primary, size: 34),
                      ),
                    ),
                    const SizedBox(width: 56),
                  ])),
            ])
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface));
}

class _DayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _DayBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: onTap != null ? AppColors.primaryContainer : AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16,
          color: onTap != null ? AppColors.onPrimaryContainer : AppColors.outline),
    ),
  );
}
