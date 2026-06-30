import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../models/account.dart';
import '../../models/app_config.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

/// Abre la hoja de cobro y, al pagar, libera la selección y vuelve a Mesas.
Future<void> openCheckout(
    BuildContext context, WidgetRef ref, Account account) async {
  final paid = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BrandColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.xl)),
    ),
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
    return Padding(
      padding: EdgeInsets.only(
        left: Sp.xl,
        right: Sp.xl,
        top: Sp.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Sp.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cobrar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Sp.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1DE), Color(0xFFFFE2BD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Rad.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total a cobrar',
                    style: TextStyle(
                        color: BrandColors.orangeInk,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(money(_grandTotal),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.orangeInk)),
              ],
            ),
          ),
          const SizedBox(height: Sp.lg),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'efectivo',
                  label: Text('Efectivo'),
                  icon: Icon(Icons.payments_outlined)),
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
          const SizedBox(height: Sp.lg),
          TextField(
            controller: _tip,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Propina (opcional)', prefixText: '\$ '),
            onChanged: (_) => setState(() {}),
          ),
          if (_method == 'efectivo') ...[
            const SizedBox(height: Sp.md),
            TextField(
              controller: _received,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Efectivo recibido', prefixText: '\$ '),
              onChanged: (_) => setState(() {}),
            ),
            if (_change != null) ...[
              const SizedBox(height: Sp.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: _change! >= 0
                      ? const Color(0x1A22C55E)
                      : const Color(0x1AD92D20),
                  borderRadius: BorderRadius.circular(Rad.md),
                ),
                child: Text(
                  _change! >= 0
                      ? 'Cambio: ${money(_change!)}'
                      : 'Falta ${money(-_change!)}',
                  style: TextStyle(
                    color: _change! >= 0
                        ? const Color(0xFF1E7D34)
                        : const Color(0xFFD92D20),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: Sp.xl),
          _busy
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(Sp.md),
                    child: CircularProgressIndicator(),
                  ),
                )
              : GradientButton(
                  label: 'Cobrar ${money(_grandTotal)}',
                  icon: Icons.check_rounded,
                  onTap: _canPay ? _pay : null,
                ),
        ],
      ),
    );
  }

  bool get _canPay {
    if (_method == 'efectivo') {
      return _received_ != null && _received_! >= _grandTotal;
    }
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
