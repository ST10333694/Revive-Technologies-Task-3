import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/business.dart';
import '../../services/business_repository.dart';
import '../../widgets/empty_state.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = BusinessRepository();
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _branch = TextEditingController();
  final _reference = TextEditingController();
  final _deposit = TextEditingController(text: '40');
  String _type = accountTypes.first;

  bool _loading = true;
  bool _failed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_holder, _bank, _number, _branch, _reference, _deposit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final p = await _repo.getPayment();
      if (!mounted) return;
      setState(() {
        _holder.text = p.accountHolder;
        _bank.text = p.bankName;
        _number.text = p.accountNumber;
        _branch.text = p.branchCode;
        _reference.text = p.reference;
        _deposit.text = '${p.depositPercent}';
        _type = accountTypes.contains(p.accountType) ? p.accountType : accountTypes.first;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    final details = PaymentDetails(
      accountHolder: _holder.text.trim(),
      bankName: _bank.text.trim(),
      accountType: _type,
      accountNumber: _number.text.trim(),
      branchCode: _branch.text.trim(),
      reference: _reference.text.trim(),
      depositPercent: int.tryParse(_deposit.text.trim()) ?? 40,
    );

    var queued = false;
    try {
      await _repo.savePayment(details).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      queued = true;
        } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(queued ? 'Saved. It will sync when you are back online.' : 'Payment details saved'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment & Bank Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment & Bank Details')),
        body: EmptyState(
          title: 'Could not load your payment details',
          message: 'Check your connection and try again.',
          action: FilledButton(onPressed: _load, child: const Text('Try again')),
        ),
      );
    }

    final digits = [FilteringTextInputFormatter.digitsOnly];

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Payment & Bank Details')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Clients will use these details to pay their deposit.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holder,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Account holder'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bank,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Bank name'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Account type'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _type,
                    items: [
                      for (final t in accountTypes) DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _type = v ?? _type),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(labelText: 'Account number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branch,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(labelText: 'Branch code'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reference,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Payment reference note',
                  helperText: 'For example: use your event name as the reference.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deposit,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(
                  labelText: 'Deposit percentage',
                  suffixText: '%',
                  helperText: 'Used for new quotes.',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 1 || n > 100) ? 'Enter a number from 1 to 100' : null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}