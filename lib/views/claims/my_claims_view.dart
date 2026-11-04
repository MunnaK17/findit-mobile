import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/claim_model.dart';
import '../../services/claim_service.dart';
import '../../services/supabase_service.dart';

class MyClaimsView extends StatefulWidget {
  final bool embedded;

  const MyClaimsView({super.key, this.embedded = false});

  @override
  State<MyClaimsView> createState() => _MyClaimsViewState();
}

class _MyClaimsViewState extends State<MyClaimsView> {
  List<ClaimModel> _claims = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final data = await ClaimService.getMyClaims();
    if (mounted) {
      setState(() {
        _claims = data;
        if (data.isEmpty && SupabaseService.lastError != null) {
          _errorMessage = SupabaseService.lastError;
        }
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: c.scaffoldBg,
              elevation: 0,
              title: const Text('Klaim Saya'),
            ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.accentAmber),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat daftar pengajuan klaim...',
                    style: TextStyle(fontSize: 13, color: c.textMuted),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 48, color: c.dangerText),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal Memuat Klaim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadClaims,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _claims.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadClaims,
                      color: AppColors.accentAmber,
                      child: ListView(
                        padding: const EdgeInsets.all(40),
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: c.cardBgLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.cardBorder),
                            ),
                            child: Icon(Icons.inventory_2_outlined, size: 36, color: c.textMuted),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Belum Ada Pengajuan Klaim',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Jika Anda mengenali barang milik Anda di daftar temuan, buka detail barang lalu ketuk "Klaim Barang Ini".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadClaims,
                      color: AppColors.accentAmber,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _claims.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final claim = _claims[index];
                          final statusText = c.statusTextColor(claim.statusKlaim);
                          final statusBg = c.statusBgColor(claim.statusKlaim);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        claim.report?.namaBarang ?? 'Barang Temuan #${claim.idReport}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusText.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        _getStatusLabel(claim.statusKlaim),
                                        style: TextStyle(
                                          color: statusText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (claim.report?.lokasi != null)
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: c.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        claim.report!.lokasi,
                                        style: TextStyle(fontSize: 12, color: c.textMuted),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: c.cardBgLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: c.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bukti yang diajukan:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: c.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        claim.pesanKlaim,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: c.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 12, color: c.textMuted),
                                    const SizedBox(width: 5),
                                    Text(
                                      claim.tanggalKlaim,
                                      style: TextStyle(fontSize: 11, color: c.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
