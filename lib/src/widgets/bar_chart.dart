import 'package:flutter/material.dart';
import 'package:stac_framework/stac_framework.dart';

/// One bar of a [BarChart]. [value] is already in dollars.
class BarChartBar {
  const BarChartBar({required this.label, required this.value, this.color});

  final String label;
  final double value;
  final Color? color;

  factory BarChartBar.fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final value = json['value'];
    return BarChartBar(
      label: label is String ? label : '',
      value: value is num ? value.toDouble() : 0,
      color: _colorFromHex(json['color']),
    );
  }
}

class BarChartModel {
  const BarChartModel({required this.bars, required this.emptyLabel});

  final List<BarChartBar> bars;
  final String emptyLabel;

  factory BarChartModel.fromJson(Map<String, dynamic> json) {
    final rawBars = json['bars'];
    final bars = <BarChartBar>[];
    if (rawBars is List) {
      for (final item in rawBars) {
        if (item is Map<String, dynamic>) {
          bars.add(BarChartBar.fromJson(item));
        } else if (item is Map) {
          bars.add(BarChartBar.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final emptyLabel = json['emptyLabel'];
    return BarChartModel(
      bars: bars,
      emptyLabel: emptyLabel is String && emptyLabel.isNotEmpty
          ? emptyLabel
          : 'Sin movimientos',
    );
  }
}

/// Stac `barChart` → proportional bars. The client scales to the list maximum.
class BarChartParser implements StacParser<BarChartModel> {
  const BarChartParser();

  @override
  String get type => 'barChart';

  @override
  BarChartModel getModel(Map<String, dynamic> json) =>
      BarChartModel.fromJson(json);

  @override
  Widget parse(BuildContext context, BarChartModel model) {
    return BarChartView(model: model);
  }
}

/// Fixed-height bar row with labels underneath.
class BarChartView extends StatelessWidget {
  const BarChartView({super.key, required this.model});

  final BarChartModel model;

  static const double chartHeight = 160;

  @override
  Widget build(BuildContext context) {
    if (model.bars.isEmpty) {
      return Text(model.emptyLabel);
    }
    final maxValue = model.bars.fold<double>(
      0,
      (max, bar) => bar.value > max ? bar.value : max,
    );
    final fallback = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in model.bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: maxValue <= 0
                            ? 0
                            : chartHeight *
                                  (bar.value <= 0 ? 0 : bar.value) /
                                  maxValue,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bar.color ?? fallback,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [for (final bar in model.bars) Text(bar.label)],
        ),
      ],
    );
  }
}

Color? _colorFromHex(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  var hex = raw.startsWith('#') ? raw.substring(1) : raw;
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) {
    return null;
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    return null;
  }
  return Color.fromARGB(
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  );
}
