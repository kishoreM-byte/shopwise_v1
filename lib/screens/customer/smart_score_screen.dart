import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/smart_score_service.dart';
import 'product_details_screen.dart';

class SmartScoreScreen extends StatelessWidget {
  const SmartScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        title: const Text(
          'Smart Score',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Base ranking · excludes travel, delivery and installation costs',
                style: TextStyle(
                  fontSize: 11,
                  color: ShopWiseColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService().watchAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = [...(snapshot.data ?? const <Product>[])];
          const service = SmartScoreService();

          products.sort(
            (a, b) => service
                .calculate(b)
                .score
                .compareTo(service.calculate(a).score),
          );

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Add products to start using Smart Score.',
                style: TextStyle(color: ShopWiseColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final result = service.calculate(product);
              final score = result.score;

              return Card(
                elevation: 0,
                color: ShopWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: ShopWiseColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              score.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: ShopWiseColors.emerald,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                result.scoreLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ShopWiseColors.emerald,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: score / 100,
                                  minHeight: 6,
                                  backgroundColor: ShopWiseColors.border,
                                  valueColor: const AlwaysStoppedAnimation(
                                    ShopWiseColors.emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: ShopWiseColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
