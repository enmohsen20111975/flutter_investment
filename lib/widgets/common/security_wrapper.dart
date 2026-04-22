import 'package:flutter/material.dart';
import '../../controllers/investment_controller.dart';
import '../../services/security_service.dart';

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  final InvestmentController controller;

  const SecurityWrapper({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper>
    with WidgetsBindingObserver {
  // Start UNLOCKED — security is opt-in, not forced by default.
  bool _isLocked = false;
  bool _isAuthenticating = false;
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;

  bool get _securityEnabled =>
      widget.controller.biometricEnabled || widget.controller.appPinEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Only lock on startup if the user explicitly opted in
    if (_securityEnabled) {
      _isLocked = true;
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_securityEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isLocked) setState(() => _isLocked = true);
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked && !_isAuthenticating) _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (!widget.controller.biometricEnabled || _isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final success = await SecurityService.instance.authenticate(
      reason: 'الرجاء توثيق الهوية لفتح التطبيق وحماية خصوصيتك.',
    );

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _isLocked = !success;
      });
    }
  }

  Future<void> _unlockWithPin() async {
    if (!widget.controller.appPinEnabled) {
      await _authenticate();
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _pinError = 'الرجاء إدخال رمز PIN.');
      return;
    }

    final valid = await widget.controller.validateApplicationPin(pin);
    if (mounted) {
      setState(() {
        if (valid) {
          _pinError = null;
          _isLocked = false;
        } else {
          _pinError = 'رمز PIN غير صحيح.';
          _isLocked = true;
        }
      });
    }
  }

  /// Emergency bypass: disables lock in prefs and unlocks immediately.
  Future<void> _disableLockAndProceed() async {
    await widget.controller.setBiometricEnabled(false);
    if (mounted) setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          widget.child,
          if (_isLocked)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'التطبيق مقفل',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'استخدم بصمة الإصبع أو رمز PIN لفتح التطبيق.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 40),
                          if (widget.controller.appPinEnabled) ...[
                            TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'رمز PIN',
                                errorText: _pinError,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) {
                                if (_pinError != null) {
                                  setState(() => _pinError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _unlockWithPin,
                                icon: const Icon(Icons.dialpad_outlined),
                                label: const Text('فتح برمز PIN'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.controller.biometricEnabled) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _authenticate,
                                  icon: const Icon(Icons.fingerprint),
                                  label:
                                      const Text('فتح بالبصمة أو رمز الجهاز'),
                                ),
                              ),
                            ],
                          ] else if (_isAuthenticating) ...[
                            const CircularProgressIndicator()
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _authenticate,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('فتح بالبصمة أو PIN'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _unlockWithPin,
                                icon: const Icon(Icons.dialpad_outlined),
                                label: const Text(
                                    'استخدام رمز الجهاز (PIN/Pattern)'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _disableLockAndProceed,
                            child: const Text(
                              'تعطيل القفل والمتابعة',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
