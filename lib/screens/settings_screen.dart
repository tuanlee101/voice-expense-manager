import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          _buildSection(
            title: 'Ngôn ngữ / Language',
            children: [
              _buildRadioTile(
                value: 'vi',
                groupValue: appState.currentLanguage,
                title: 'Tiếng Việt',
                subtitle: 'Giao diện và giọng nói tiếng Việt',
                onChanged: (v) => appState.setLanguage(v!),
              ),
              _buildRadioTile(
                value: 'en',
                groupValue: appState.currentLanguage,
                title: 'English',
                subtitle: 'UI and voice in English',
                onChanged: (v) => appState.setLanguage(v!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TTS Speed
          _buildSection(
            title: 'Tốc độ đọc / Speech Rate',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(appState.ttsSpeed * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Slider(
                      value: appState.ttsSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      activeColor: const Color(0xFF4CAF50),
                      inactiveColor: Colors.white24,
                      onChanged: (v) => appState.setTtsSpeed(v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chậm',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        Text('Nhanh',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data Management
          _buildSection(
            title: 'Dữ liệu',
            children: [
              _buildActionTile(
                icon: Icons.file_download,
                title: 'Xuất dữ liệu CSV',
                subtitle: 'Xuất tất cả chi tiêu ra file CSV',
                onTap: () => _exportData(context),
              ),
              _buildActionTile(
                icon: Icons.delete_forever,
                title: 'Xoá tất cả dữ liệu',
                subtitle: 'Xoá toàn bộ chi tiêu, ngân sách và cài đặt',
                titleColor: Colors.redAccent,
                onTap: () => _deleteAllData(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security
          _buildSection(
            title: 'Bảo mật',
            children: [
              _buildActionTile(
                icon: Icons.lock,
                title: 'Đổi mã PIN',
                subtitle: 'Thay đổi mã PIN bảo vệ',
                onTap: () => _changePin(context),
              ),
              _buildInfoTile(
                icon: Icons.shield,
                title: 'Mã hoá',
                subtitle: 'Dữ liệu được mã hoá AES-256',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // About
          _buildSection(
            title: 'Ứng dụng',
            children: [
              _buildInfoTile(
                icon: Icons.info,
                title: 'Phiên bản',
                subtitle: 'Voice Expense Manager v1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                color: const Color(0xFF4CAF50),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String value,
    required String groupValue,
    required String title,
    required String subtitle,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFF4CAF50) : Colors.white38,
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? const Color(0xFF4CAF50)),
      title: Text(title,
          style: TextStyle(color: titleColor ?? Colors.white)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final appState = context.read<AppState>();
    try {
      await appState.databaseService.exportToCsv();
      // Save to file
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xuất dữ liệu thành công')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Xoá tất cả dữ liệu?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hành động này không thể hoàn tác. Toàn bộ chi tiêu, ngân sách và cài đặt sẽ bị xoá.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AppState>().authService.deleteAllData();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final pinController = TextEditingController();
    final isChanged = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Đổi mã PIN',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Mã PIN mới (4+ ký tự)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đổi', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );

    if (isChanged == true && pinController.text.isNotEmpty && context.mounted) {
      await context.read<AppState>().authService.setPin(pinController.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đổi mã PIN thành công')),
        );
      }
    }
  }
}
