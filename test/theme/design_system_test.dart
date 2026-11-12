import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/screens/customer/widgets/home/home_section_title.dart';
import 'package:shopwise_v1/theme/app_theme.dart';
import 'package:shopwise_v1/theme/design_tokens.dart';

double _contrastRatio(Color first, Color second) {
  final values = <double>[first.computeLuminance(), second.computeLuminance()]
    ..sort();
  return (values[1] + 0.05) / (values[0] + 0.05);
}

void main() {
  test('muted text meets readable contrast on app surfaces', () {
    expect(
      _contrastRatio(ShopWiseColors.textMuted, ShopWiseColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(ShopWiseColors.textMuted, ShopWiseColors.background),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('home section heading uses the shared title typography', (
    tester,
  ) async {
    final theme = AppTheme.lightTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: HomeSectionTitle(title: 'Recommended')),
      ),
    );

    final text = tester.widget<Text>(find.text('Recommended'));
    expect(text.style?.fontSize, theme.textTheme.titleLarge?.fontSize);
    expect(text.style?.fontWeight, theme.textTheme.titleLarge?.fontWeight);
    expect(text.style?.color, theme.textTheme.titleLarge?.color);
    expect(tester.takeException(), isNull);
  });
}
