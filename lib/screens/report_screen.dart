import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriod = 'month';
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    final now = DateTime.now();

    Map<String, DateTime> range;
    switch (_selectedPeriod) {
      case 'week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        range = {
          'from': DateTime(monday.year, monday.month, monday.day),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'month':
        range = {
          'from': DateTime(now.year, now.month, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'year':
        range = {
          'from': DateTime(now.year, 1, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      default:
        range = {
          'from': DateTime(now.year, now.month, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
    }

    _reportData = await appState.reportGenerator.generatePeriodReport(
      from: range['from']!,
      to: range['to']!,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Báo cáo', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    Row(
                      children: [
                        _buildPeriodChip('Tuần này', 'week'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Tháng này', 'month'),
                        const SizedBox(width: 8),
                        _buildPeriodChip('Năm nay', 'year'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary cards
                    if (_reportData != null) ...[
                      _buildSummaryRow(),
                      const SizedBox(height: 24),

                      // Pie chart
                      if ((_reportData!['sortedCategories'] as List).isNotEmpty) ...[
                        const Text(
                          'Phân bố chi tiêu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: _buildPieChart(
                              _reportData!['sortedCategories'] as List),
                        ),
                        const SizedBox(height: 24),
                        // Category breakdown
                        ...(_buildCategoryBreakdown(
                            _reportData!['sortedCategories'] as List)),
                      ],

                      if ((_reportData!['sortedCategories'] as List).isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Column(
                              children: [
                                Icon(Icons.pie_chart_outline,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có dữ liệu chi tiêu',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        _selectedPeriod = period;
        _loadReport();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final total = _reportData!['total'] as double;
    final count = _reportData!['expenseCount'] as int;
    final change = _reportData!['changePercent'] as double?;
    final topCategory = _reportData!['topCategory'] as String?;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.monetization_on,
            label: 'Tổng chi',
            value: _formatAmount(total),
            subtitle: '$count khoản',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: change != null && change >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            label: 'So với kỳ trước',
            value: change != null
                ? '${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)}%'
                : '---',
            subtitle: topCategory ?? '',
            valueColor: change != null
                ? (change >= 0 ? Colors.redAccent : Color(0xFF4CAF50))
                : Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChart(List categories) {
    final total = _reportData!['total'] as double;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(categories.length, (i) {
          final cat = categories[i] as Map<String, dynamic>;
          final amount = cat['amount'] as double;
          final percent = total > 0 ? (amount / total * 100) : 0.0;

          return PieChartSectionData(
            color: Color(cat['color'] as int? ?? 0xFF4CAF50),
            value: amount,
            title: '${percent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildCategoryBreakdown(List categories) {
    final total = _reportData!['total'] as double;

    return categories.map((cat) {
      final name = cat['name'] as String;
      final amount = cat['amount'] as double;
      final percent = total > 0 ? (amount / total * 100) : 0.0;
      final color = Color(cat['color'] as int? ?? 0xFF4CAF50);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatAmount(amount),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỉ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} k';
    }
    return amount.toStringAsFixed(0);
  }
}
