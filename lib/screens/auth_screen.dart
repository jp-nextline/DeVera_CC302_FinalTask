import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/fancy.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _displayName = TextEditingController();

  bool _isRegister = false;
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final error = _isRegister
        ? await state.register(
            _username.text,
            _password.text,
            _displayName.text,
          )
        : await state.login(_username.text, _password.text);
    // On success, MaterialApp swaps this screen for MainShell automatically.
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.appPalette;
    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FadeSlideIn(
                      index: 0,
                      child: Center(child: BrandLogo(size: 92)),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        'Brain Humor',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeSlideIn(
                      index: 2,
                      child: Text(
                        _isRegister
                            ? 'Create your account and start building decks.'
                            : 'Best way to learn anything.\nLog in to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeSlideIn(
                      index: 3,
                      child: DepthCard(
                        padding: const EdgeInsets.all(20),
                        radius: 28,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isRegister) ...[
                                TextFormField(
                                  controller: _displayName,
                                  decoration: appInputDecoration(
                                    context,
                                    'Display name (optional)',
                                    prefix: const Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _username,
                                autocorrect: false,
                                decoration: appInputDecoration(
                                  context,
                                  'Username',
                                  prefix: const Icon(Icons.person_outline),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter a username';
                                  }
                                  if (_isRegister && v.trim().length < 3) {
                                    return 'At least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _hidePassword,
                                decoration: appInputDecoration(
                                  context,
                                  'Password',
                                  prefix: const Icon(Icons.lock_outline),
                                  suffix: IconButton(
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter a password';
                                  }
                                  if (_isRegister && v.length < 6) {
                                    return 'At least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (_isRegister) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirm,
                                  obscureText: _hidePassword,
                                  decoration: appInputDecoration(
                                    context,
                                    'Confirm password',
                                    prefix: const Icon(Icons.lock_outline),
                                  ),
                                  validator: (v) => v != _password.text
                                      ? 'Passwords do not match'
                                      : null,
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              GradientButton(
                                label: _busy
                                    ? 'Please wait...'
                                    : (_isRegister
                                          ? 'Register'
                                          : 'Get Started'),
                                expand: true,
                                onPressed: _busy ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      index: 4,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _isRegister = !_isRegister;
                          _error = null;
                        }),
                        child: Text(
                          _isRegister
                              ? 'Already have an account? Login'
                              : 'No account yet? Register',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
