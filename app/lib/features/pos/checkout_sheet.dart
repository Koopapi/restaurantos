import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../models/account.dart';
import '../../models/app_config.dart';
import '../../state/providers.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';

/// Abre la hoja de cobro y, al pagar, libera la selección y vuelve a Mesas.
Future<void> openCheckout(
    BuildContext context, WidgetRef ref, Account account) async {
  final paid = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CheckoutSheet(account: account),
  );
  if (paid == true) {
    ref.read(currentAccountIdProvider.notifier).state = null;
    ref.invalidate(tablesProvider);
    ref.invalidate(openAccountsProvider);
  }
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  final Account account;
  const _CheckoutSheet({required this.account});

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  String _method = 'efectivo';
  final _received = TextEditingController();
  final _tip = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _received.dispose();
    _tip.dispose();
    super.dispose();
  }

  num get _tipValue => num.tryParse(_tip.text) ?? 0;
  num get _grandTotal => widget.account.total + _tipValue;
  num? get _received_ => num.tryParse(_received.text);
  num? get _change => (_received_ != null) ? _received_! - _grandTotal : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cobrar', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Total a cobrar: ${money(_grandTotal)}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'efectivo',
                  label: Text('Efectivo'),
                  icon: Icon(Icons.payments)),
              ButtonSegment(
                  value: 'tarjeta',
                  label: Text('Tarjeta'),
                  icon: Icon(Icons.credit_card)),
              ButtonSegment(
                  value: 'transferencia',
                  label: Text('Transfer.'),
                  icon: Icon(Icons.swap_horiz)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tip,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Propina (opcional)', prefixText: '\$'),
            onChanged: (_) => setState(() {}),
          ),
          if (_method == 'efectivo') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _received,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Efectivo recibido', prefixText: '\$'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_change != null)
              Text(
                _change! >= 0
                    ? 'Cambio: ${money(_change!)}'
                    : 'Falta ${money(-_change!)}',
                style: TextStyle(
                  color: _change! >= 0
                      ? context.semanticSuccess
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy || !_canPay ? null : _pay,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Cobrar ${money(_grandTotal)}'),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canPay {
    if (_method == 'efectivo')
      return _received_ != null && _received_! >= _grandTotal;
    return true;
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      await ref.read(serviceRepositoryProvider).pay(
            widget.account.id,
            method: _method,
            amountReceived: _method == 'efectivo' ? _received_ : null,
            tip: _tipValue,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, 'No se pudo procesar el cobro');
      }
    }
  }
}

extension on BuildContext {
  Color get semanticSuccess => semantic.success;
}
