import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flags.dart';

/// One currency pair shown on the board.
class PairInfo {
  const PairInfo(this.key, this.from, this.to, this.unitLabel);
  final String key;
  final Currency from;
  final Currency to;
  final String unitLabel;
}

const usdIqd = PairInfo('usd_iqd', Currency.usd, Currency.iqd, 'لكل 100 دولار');
const eurIqd = PairInfo('eur_iqd', Currency.eur, Currency.iqd, 'لكل 100 يورو');
const usdEur = PairInfo('usd_eur', Currency.usd, Currency.eur, 'لكل 1 دولار');
const allPairs = [usdIqd, eurIqd, usdEur];

class Quote {
  const Quote(this.buy, this.sell);
  static const empty = Quote(null, null);

  final double? buy;
  final double? sell;

  Map<String, dynamic> toJson() => {'buy': buy, 'sell': sell};

  factory Quote.fromJson(Object? json) {
    if (json is Map) return Quote(_num(json['buy']), _num(json['sell']));
    return empty;
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;
}

class RatesData {
  const RatesData(this.quotes, this.updatedAt);
  static const empty = RatesData(<String, Quote>{}, null);

  final Map<String, Quote> quotes;
  final DateTime? updatedAt;

  Quote of(PairInfo pair) => quotes[pair.key] ?? Quote.empty;

  Map<String, dynamic> toJson() => {
        'quotes': quotes.map((k, v) => MapEntry(k, v.toJson())),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory RatesData.fromJson(Object? json) {
    if (json is! Map) return empty;
    final q = <String, Quote>{};
    final raw = json['quotes'];
    if (raw is Map) {
      raw.forEach((k, v) => q[k.toString()] = Quote.fromJson(v));
    }
    final u = json['updatedAt'];
    return RatesData(q, u is String ? DateTime.tryParse(u) : null);
  }
}

/// Keeps the rates on this TV only (Android SharedPreferences, through the
/// "perbeha/store" channel in MainActivity.kt). Survives restarts and power cuts.
class RatesStore {
  RatesStore._();
  static final RatesStore instance = RatesStore._();

  static const _channel = MethodChannel('perbeha/store');
  static const _key = 'rates_v1';

  final ValueNotifier<RatesData> data = ValueNotifier<RatesData>(RatesData.empty);

  Future<void> load() async {
    try {
      final raw = await _channel.invokeMethod<String>('get', {'key': _key});
      if (raw != null && raw.isNotEmpty) {
        data.value = RatesData.fromJson(jsonDecode(raw));
      }
    } catch (e) {
      debugPrint('Could not load rates: $e');
    }
  }

  /// Updates the board immediately; returns false if writing to storage failed.
  Future<bool> save(RatesData next) async {
    data.value = next;
    try {
      final ok = await _channel.invokeMethod<bool>('set', {'key': _key, 'value': jsonEncode(next.toJson())});
      return ok ?? false;
    } catch (e) {
      debugPrint('Could not save rates: $e');
      return false;
    }
  }
}
