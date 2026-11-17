import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/session.dart';
import '../../theme.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Sign in and register on one screen, like the Android app.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();

  bool _isRegister = false;
  UserRole _role = UserRole.client;
  bool _hidePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _email,
      _phone,
      _password,
      _confirm,
      _code,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailRule(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return _emailPattern.hasMatch(v.trim())
        ? null
        : 'Enter a valid email address';
  }

  String? _passwordRule(String? v) {
    if (v == null || v.isEmpty) return 'This field is required';
    if (_isRegister && v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _confirmRule(String? v) {
    if (v == null || v.isEmpty) return 'This field is required';
    return v == _password.text ? null : 'Passwords do not match';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final session = context.read<Session>();

    if (_isRegister) {
      final result = await session.register(
        first: _first.text,
        last: _last.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        role: _role,
        accessCode: _code.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      switch (result) {
        case RegisterResult.success:
          break; // The app switches to the home screen by itself.
        case RegisterResult.invalidCode:
          _message('That access code is not valid.');
        case RegisterResult.emailTaken:
          _message('An account with this email already exists.');
        case RegisterResult.network:
          _message('No connection. Check your internet and try again.');
        case RegisterResult.failed:
          _message('Could not create the account. Please try again.');
      }
    } else {
      final result = await session.signIn(_email.text, _password.text, _role);
      if (!mounted) return;
      setState(() => _busy = false);
      switch (result) {
        case SignInResult.success:
          break;
        case SignInResult.invalid:
          _message('Wrong email or password.');
        case SignInResult.wrongRole:
          _message(
            _role == UserRole.client
                ? 'This is a decorator account. Switch to Decorator to sign in.'
                : 'This is a client account. Switch to Client to sign in.',
          );
        case SignInResult.disabled:
          _message(
            'This account has been disabled. Please contact your decorator.',
          );
        case SignInResult.network:
          _message('No connection. Check your internet and try again.');
        case SignInResult.failed:
          _message('Could not sign in. Please try again.');
      }
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || !mounted) return;
    if (!_emailPattern.hasMatch(email)) {
      _message('Enter a valid email address');
      return;
    }
    final result = await context.read<Session>().resetPassword(email);
    if (!mounted) return;
    _message(switch (result) {
      ActionResult.success =>
        'If that email has an account, a reset link is on its way.',
      ActionResult.network =>
        'No connection. Check your internet and try again.',
      ActionResult.failed => 'Could not send the link. Please try again.',
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Image.asset('assets/logo.png', height: 64),
                const SizedBox(height: 16),
                Text(
                  _isRegister ? 'Create your account' : 'Welcome',
                  style: text.headlineLarge,
                ),
                Text('Excellence in every event.', style: text.bodyMedium),
                const SizedBox(height: 24),
                _RoleToggle(
                  role: _role,
                  onChanged: _busy ? null : (r) => setState(() => _role = r),
                ),
                const SizedBox(height: 20),
                if (_isRegister) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _first,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _last,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                          ),
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'name@example.com',
                  ),
                  validator: _emailRule,
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: _passwordRule,
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _hidePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: _confirmRule,
                  ),
                  if (_role == UserRole.decorator) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _code,
                      decoration: const InputDecoration(
                        labelText: 'Decorator access code',
                        helperText: 'Ask the business owner for this code.',
                      ),
                      validator: _required,
                    ),
                  ],
                  const SizedBox(height: 20),
                ] else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_isRegister ? 'Create an account' : 'Sign in'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          _formKey.currentState?.reset();
                          setState(() => _isRegister = !_isRegister);
                        },
                  child: Text(
                    _isRegister
                        ? 'I already have an account'
                        : 'Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole>? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(UserRole value, String label) {
      final selected = role == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? sand : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: espresso,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: taupe.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          segment(UserRole.client, 'Client'),
          segment(UserRole.decorator, 'Decorator'),
        ],
      ),
    );
  }
}