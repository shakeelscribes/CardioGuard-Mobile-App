import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import '../models/models.dart';
import 'result_screen.dart';

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<PredictionRecord> _history = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseHistoryService.getHistory();
      final records = data.map((e) => PredictionRecord(
            id: e['id'].toString(),
            date: DateTime.parse(e['date']),
            gender: e['gender'],
            ageYears: e['age_years'],
            height: e['height'],
            weight: (e['weight'] as num).toDouble(),
            apHi: e['ap_hi'],
            apLo: e['ap_lo'],
            cholesterol: e['cholesterol'],
            gluc: e['gluc'],
            smoke: e['smoke'],
            alco: e['alco'],
            active: e['active'],
            prediction: e['prediction'],
            probability: (e['probability'] as num).toDouble(),
            riskLevel: e['risk_level'],
            advice: e['advice'],
            bmi: (e['bmi'] as num).toDouble(),
            bmiCategory: e['bmi_category'],
          )).toList();
      if (!mounted) return;
      setState(() {
        _history = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(PredictionRecord record) async {
    await SupabaseHistoryService.deletePrediction(record.id);
    _load();
  }

  Future<void> _downloadPdf() async {
    if (_history.isEmpty || _isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfService.generateAndShareHistoryPdf(context, _history);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to generate PDF. Please try again.'),
          backgroundColor: context.c.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showDeleteDialog(PredictionRecord record) {
    final c = context.c;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // ✅ theme-aware
        backgroundColor: c.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Record',
            style: TextStyle(color: c.textPrimary)),
        content: Text(
          'Are you sure you want to delete this prediction record?',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete(record);
            },
            child: Text('Delete', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.c;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            FadeInDown(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SectionHeader(
                      title: 'Prediction History',
                      subtitle: 'All your past CVD checks',
                    ),
                  ),
                  // ── Download PDF button ──────────────────────
                  Tooltip(
                    message: 'Download all results as PDF',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _history.isEmpty
                            ? context.c.surfaceLight
                            : context.c.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _history.isEmpty
                              ? context.c.cardBorder
                              : context.c.primary.withOpacity(0.35),
                        ),
                      ),
                      child: _isGeneratingPdf
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.c.primary,
                              ),
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _history.isEmpty ? null : _downloadPdf,
                              icon: Icon(
                                Icons.download_rounded,
                                color: _history.isEmpty
                                    ? context.c.textMuted
                                    : context.c.primary,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: c.primary),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: c.primary,
                  child: _history.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      // ✅ theme-aware
                                      color: c.primary.withOpacity(0.1),
                                    ),
                                    child: Icon(Icons.history_rounded,
                                        color: c.primary, size: 48),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No records yet',
                                    style: TextStyle(
                                        color: c.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Run a prediction to see your history',
                                    style:
                                        TextStyle(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => FadeInUp(
                            delay: Duration(milliseconds: 50 * i),
                            child: _HistoryCard(
                              record: _history[i],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ResultScreen(record: _history[i]),
                                  ),
                                );
                                _load();
                              },
                              onDelete: () =>
                                  _showDeleteDialog(_history[i]),
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// HISTORY CARD
// ─────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final PredictionRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  // ✅ Uses context.c for theme-aware risk colors
  Color _riskColor(AppThemeColors c) {
    switch (record.riskLevel.toLowerCase()) {
      case 'low':
        return c.success;
      case 'medium':
        return c.warning;
      default:
        return c.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final riskColor = _riskColor(c);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // ✅ Risk % circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: riskColor.withOpacity(0.15),
              border: Border.all(
                color: riskColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${record.probability.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RiskBadge(riskLevel: record.riskLevel),
                    const SizedBox(width: 8),
                    Text(
                      record.prediction ? 'CVD Detected' : 'No CVD',
                      style: TextStyle(
                        // ✅ theme-aware
                        color: record.prediction ? c.danger : c.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(record.date),
                  // ✅ theme-aware
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'BMI: ${record.bmi.toStringAsFixed(1)} • BP: ${record.apHi}/${record.apLo}',
                  // ✅ theme-aware
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          Column(
            children: [
              // ✅ theme-aware arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: c.textMuted,
                size: 14,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline_rounded,
                  // ✅ danger stays same in both themes
                  color: c.danger,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}