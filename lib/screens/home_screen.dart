import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../voice/voice_input_module.dart';
import '../models/expense_category.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'expense_list_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _feedbackText = 'Nhấn micro để bắt đầu';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupVoiceCallbacks();
  }

  void _setupVoiceCallbacks() {
    final appState = context.read<AppState>();
    appState.voiceInput.onStateChanged = (state) {
      if (!mounted) return;
      setState(() {
        _isListening = state == VoiceInputState.listening;
        if (_isListening) {
          _pulseController.repeat(reverse: true);
          _feedbackText = 'Đang nghe...';
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    };

    appState.voiceInput.onFeedback = (msg) {
      if (!mounted) return;
      setState(() => _feedbackText = msg);
    };

    appState.voiceInput.onCommandProcessed = (command) async {
      if (!mounted) return;
      setState(() => _feedbackText = 'Đang xử lý: ${command.rawText}');

      final response = await appState.handleVoiceCommand(command);
      if (!mounted) return;

      setState(() => _feedbackText = response);
      await appState.voiceInput.speakFeedback(response);
    };
  }

  Future<void> _startListening() async {
    final appState = context.read<AppState>();

    // Check session expiry (R10.5)
    if (appState.authService.isSessionExpired()) {
      appState.authService.lock();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    await appState.voiceInput.startListening();
  }

  Future<void> _stopListening() async {
    final appState = context.read<AppState>();
    await appState.voiceInput.stopListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Voice Expense Manager',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Feedback area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Voice animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isListening ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: _isListening
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    // Feedback text with typing effect area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _feedbackText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isListening ? Colors.white : Colors.white70,
                          fontSize: 18,
                          fontStyle: _isListening ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quick tips
                    Text(
                      'Thử nói:\n"Chi 50 nghìn tiền cà phê"\n"Tuần này tôi tiêu bao nhiêu?"\n"Báo cáo tháng này"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent expenses preview
          if (appState.recentExpenses.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Gần đây',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ExpenseListScreen()),
                          ),
                          child: Text(
                            'Xem tất cả',
                            style: TextStyle(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: appState.recentExpenses.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final expense = appState.recentExpenses[index];
                        final cat = appState.categories.firstWhere(
                          (c) => c.id == expense.categoryId,
                          orElse: () => const ExpenseCategory(
                              id: '', name: '?', isDefault: false),
                        );
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, size: 8, color: Color(cat.color)),
                              const SizedBox(height: 4),
                              Text(
                                _formatCompact(expense.amount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Microphone button
      floatingActionButton: SizedBox(
        width: 72,
        height: 72,
        child: FloatingActionButton(
          onPressed: _isListening ? _stopListening : _startListening,
          backgroundColor: _isListening
              ? const Color(0xFFE53935)
              : const Color(0xFF4CAF50),
          elevation: 8,
          child: Icon(
            _isListening ? Icons.stop : Icons.mic,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
