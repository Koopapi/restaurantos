import 'package:intl/intl.dart';

/// Configuración de negocio + marca blanca (`docs/api.md`).
class AppConfig {
  final String brandName;
  final String? primaryColor;
  final String taxLabel;
  final num taxRate;
  final int urgencyMinutes;
  final int maxQtyPerLine;
  final String currency;

  const AppConfig({
    required this.brandName,
    required this.taxLabel,
    required this.taxRate,
    required this.urgencyMinutes,
    required this.maxQtyPerLine,
    required this.currency,
    this.primaryColor,
  });

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        brandName: (j['brandName'] as String?) ?? 'RestaurantOS',
        primaryColor: j['primaryColor'] as String?,
        taxLabel: (j['taxLabel'] as String?) ?? 'IVA',
        taxRate: (j['taxRate'] as num?) ?? 0,
        urgencyMinutes: (j['urgencyMinutes'] as num?)?.toInt() ?? 15,
        maxQtyPerLine: (j['maxQtyPerLine'] as num?)?.toInt() ?? 20,
        currency: (j['currency'] as String?) ?? 'MXN',
      );

  static const fallback = AppConfig(
    brandName: 'RestaurantOS',
    taxLabel: 'IVA',
    taxRate: 0.085,
    urgencyMinutes: 15,
    maxQtyPerLine: 20,
    currency: 'MXN',
  );
}

/// Formatea un monto como moneda mexicana: `$1,234.50`.
String money(num value) =>
    NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2)
        .format(value);
