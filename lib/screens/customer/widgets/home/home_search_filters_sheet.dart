import 'package:flutter/material.dart';

import '../../../../theme/design_tokens.dart';

class HomeSearchFiltersSheet extends StatefulWidget {
  const HomeSearchFiltersSheet({
    super.key,
    required this.categories,
    required this.initialCategory,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialAvailableOnly,
    required this.onReset,
    required this.onApply,
  });

  final List<String> categories;
  final String? initialCategory;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final bool initialAvailableOnly;

  final VoidCallback onReset;
  final void Function({
    required String? category,
    required double? minPrice,
    required double? maxPrice,
    required bool availableOnly,
  }) onApply;

  @override
  State<HomeSearchFiltersSheet> createState() =>
      _HomeSearchFiltersSheetState();
}

class _HomeSearchFiltersSheetState extends State<HomeSearchFiltersSheet> {
  late String? _category = widget.initialCategory;
  late double? _minPrice = widget.initialMinPrice;
  late double? _maxPrice = widget.initialMaxPrice;
  late bool _availableOnly = widget.initialAvailableOnly;

  String? _priceRangeLabel(double? min, double? max) {
    if (min == null && max == null) return 'Any price';
    if (min == 0 && max == 1000) return 'Under ₹1,000';
    if (min == 1000 && max == 5000) return '₹1,000 – ₹5,000';
    if (min == 5000 && max == 10000) return '₹5,000 – ₹10,000';
    if (min == 10000 && max == null) return 'Above ₹10,000';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      'All',
      ...widget.categories,
    }.toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search filters',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ShopWiseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Refine products by category, price and availability.',
                style: TextStyle(
                  fontSize: 13,
                  color: ShopWiseColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ShopWiseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((item) {
                  final selected = item == 'All'
                      ? _category == null
                      : _category == item;

                  return ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _category = item == 'All' ? null : item;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Price range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ShopWiseColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _priceRangeLabel(_minPrice, _maxPrice),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ShopWiseColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ShopWiseRadius.small,
                    ),
                    borderSide: const BorderSide(
                      color: ShopWiseColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ShopWiseRadius.small,
                    ),
                    borderSide: const BorderSide(
                      color: ShopWiseColors.border,
                    ),
                  ),
                ),
                hint: const Text('Any price'),
                items: const [
                  DropdownMenuItem(
                    value: 'Any price',
                    child: Text('Any price'),
                  ),
                  DropdownMenuItem(
                    value: 'Under ₹1,000',
                    child: Text('Under ₹1,000'),
                  ),
                  DropdownMenuItem(
                    value: '₹1,000 – ₹5,000',
                    child: Text('₹1,000 – ₹5,000'),
                  ),
                  DropdownMenuItem(
                    value: '₹5,000 – ₹10,000',
                    child: Text('₹5,000 – ₹10,000'),
                  ),
                  DropdownMenuItem(
                    value: 'Above ₹10,000',
                    child: Text('Above ₹10,000'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    switch (value) {
                      case 'Under ₹1,000':
                        _minPrice = 0;
                        _maxPrice = 1000;
                        break;
                      case '₹1,000 – ₹5,000':
                        _minPrice = 1000;
                        _maxPrice = 5000;
                        break;
                      case '₹5,000 – ₹10,000':
                        _minPrice = 5000;
                        _maxPrice = 10000;
                        break;
                      case 'Above ₹10,000':
                        _minPrice = 10000;
                        _maxPrice = null;
                        break;
                      default:
                        _minPrice = null;
                        _maxPrice = null;
                    }
                  });
                },
              ),

              const SizedBox(height: 12),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Available products only',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Hide products that are out of stock.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _availableOnly,
                onChanged: (value) {
                  setState(() {
                    _availableOnly = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onReset();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ShopWiseRadius.small,
                          ),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(
                          category: _category,
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          availableOnly: _availableOnly,
                        );
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: ShopWiseColors.emerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ShopWiseRadius.small,
                          ),
                        ),
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
