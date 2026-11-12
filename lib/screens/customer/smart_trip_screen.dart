import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_details_screen.dart';

class SmartTripScreen extends StatelessWidget {
  const SmartTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        title: const Text(
          'Smart Trip',
          style: TextStyle(fontWeight: FontWeight.w800),
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

          final products = (snapshot.data ?? const <Product>[])
              .where((product) => product.isAvailable)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ShopWiseColors.emeraldDeep, ShopWiseColors.olive],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: ShopWiseColors.surface,
                      size: 30,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Buy smarter. Travel smarter.',
                      style: TextStyle(
                        color: ShopWiseColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Open a product to calculate the real driving route and travel cost to its shop.',
                      style: TextStyle(
                        color: ShopWiseColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose a product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'No products available for trip planning.',
                      style: TextStyle(color: ShopWiseColors.textSecondary),
                    ),
                  ),
                )
              else
                ...products.map(
                  (product) => _buildProductTile(context, product),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: ShopWiseColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ShopWiseColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ShopWiseColors.oliveSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: product.imageUrls.isEmpty
              ? const Icon(
                  Icons.inventory_2_outlined,
                  color: ShopWiseColors.olive,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    product.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.inventory_2_outlined,
                      color: ShopWiseColors.olive,
                    ),
                  ),
                ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '₹${product.price.toStringAsFixed(0)}  •  View route & travel cost',
          style: const TextStyle(
            fontSize: 12,
            color: ShopWiseColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: ShopWiseColors.olive,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
      ),
    );
  }
}
