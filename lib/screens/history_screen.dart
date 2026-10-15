import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/diagnosis.dart';
import '../models/scan_record.dart';
import '../routes.dart';
import '../services/scan_history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/big_touch_button.dart';

/// Screen 7: Scan History Screen
/// Displays past leaf scans stored locally offline.
/// Tapping any record re-opens the complete Diagnosis Result screen.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScanHistoryService _historyService = ScanHistoryService();
  List<ScanRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _records = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecord(String id) async {
    await _historyService.deleteScan(id);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.earthSand,
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _records.isEmpty
                ? _buildEmptyState(context, l10n)
                : RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: _loadHistory,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildHistoryCard(context, record, l10n);
                      },
                    ),
                  ),
      ),
    );
  }

  /// Empty state message with friendly illustration and scan call to action
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
              ),
              child: const Icon(
                Icons.history_edu_outlined,
                size: 54,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noScansYet,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.highContrastDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noScansYetPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.mutedDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            BigTouchButton(
              icon: Icons.camera_alt,
              label: l10n.startFirstScan,
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Individual history scan card
  Widget _buildHistoryCard(
    BuildContext context,
    ScanRecord record,
    AppLocalizations l10n,
  ) {
    final (Color severityColor, String severityText) = switch (record.severity) {
      DiagnosisSeverity.mild => (AppTheme.severityLow, l10n.severityMild),
      DiagnosisSeverity.moderate => (AppTheme.severityMedium, l10n.severityModerate),
      DiagnosisSeverity.severe => (AppTheme.severityHigh, l10n.severitySevere),
      DiagnosisSeverity.none => (AppTheme.severityLow, '—'),
    };

    final formattedDate = _formatDate(record.scannedAt);

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.severityHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteRecord(record.id),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Tapping an item opens the complete saved result
            Navigator.pushNamed(
              context,
              AppRoutes.result,
              arguments: {
                'diagnosis': record.diagnosis,
                'imagePath': record.photoPath,
                'cropName': record.cropName,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Small photo thumbnail
                _buildThumbnail(record.photoPath),
                const SizedBox(width: 14),

                // Disease Name, Crop Name, and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.diseaseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.highContrastDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (record.detectedCrop != null && record.detectedCrop!.isNotEmpty)
                                    ? record.detectedCrop!
                                    : (record.diagnosis.detectedCrop.isNotEmpty
                                        ? record.diagnosis.detectedCrop
                                        : record.cropName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              formattedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.mutedDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Severity plain text chip & chevron (only shown for diseased scans)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (record.severity != DiagnosisSeverity.none &&
                        !record.diagnosis.isHealthy &&
                        !record.diagnosis.isPoorPhoto &&
                        !record.diagnosis.isNotAPlant)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: severityColor, width: 1.2),
                        ),
                        child: Text(
                          severityText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.mutedDark,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Small photo thumbnail with disk cache fallback
  Widget _buildThumbnail(String photoPath) {
    if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
          image: DecorationImage(
            image: FileImage(File(photoPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
      ),
      child: const Icon(
        Icons.eco,
        size: 32,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute $ampm';
  }
}
