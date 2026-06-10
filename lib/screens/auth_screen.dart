import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isFirstTime = false;
  bool _obscurePin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final appState = context.read<AppState>();
    final hasPin = await appState.authService.hasPin();
    setState(() {
      _isFirstTime = !hasPin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    final pin = _pinController.text;

    if (_isFirstTime) {
      if (pin.length < 4) {
        setState(() => _errorMessage = 'Mã PIN phải có ít nhất 4 ký tự');
        return;
      }
      await appState.authService.setPin(pin);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      final isValid = await appState.authService.verifyPin(pin);
      if (!mounted) return;
      if (isValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Sai mã PIN. Còn ${3 - appState.authService.failedAttempts} lần thử.';
          _pinController.clear();
        });

        if (appState.authService.isVoiceDisabled()) {
          _errorMessage = 'Đã nhập sai quá 3 lần. Vui lòng khởi động lại ứng dụng.';
        }
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Voice Expense Manager',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFirstTime ? 'Thiết lập mã PIN bảo vệ' : 'Nhập mã PIN để tiếp tục',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mã PIN';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isFirstTime ? 'Tạo mã PIN' : 'Mở khoá',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
