import 'package:flutter/material.dart';

import '../../../models/review.dart';
import '../../../services/customer/review_service.dart';
import '../../../theme/design_tokens.dart';

class ProductReviews extends StatelessWidget {
  final String productId;

  const ProductReviews({super.key, required this.productId});

  static const Color primary = ShopWiseColors.emerald;
  static const Color dark = ShopWiseColors.textPrimary;
  static const Color secondary = ShopWiseColors.textSecondary;
  static const Color border = ShopWiseColors.border;
  static const Color star = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductReview>>(
      stream: ReviewService().watchReviews(productId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState();
        }

        final reviews = snapshot.data ?? const <ProductReview>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Customer Reviews',
                    style: TextStyle(
                      color: dark,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _countBadge(reviews.length),
              ],
            ),
            const SizedBox(height: 14),
            if (reviews.isEmpty)
              _empty()
            else ...[
              _summary(reviews),
              const SizedBox(height: 16),
              ...reviews.take(5).map(_reviewCard),
            ],
          ],
        );
      },
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: dark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _summary(List<ProductReview> reviews) {
    final double average =
        reviews.fold<double>(0, (sum, review) => sum + review.rating) /
        reviews.length;

    final counts = List<int>.filled(5, 0);

    for (final review in reviews) {
      final int rating = review.rating.round().clamp(1, 5);
      counts[rating - 1]++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 82,
            child: Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    color: dark,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < average.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
                  style: const TextStyle(
                    color: secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final int rating = 5 - index;
                final int count = counts[rating - 1];
                final double fraction = count / reviews.length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$rating',
                          style: const TextStyle(
                            color: secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: star, size: 13),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: ShopWiseColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              star,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 18,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rate_review_outlined, color: primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'No reviews yet',
            style: TextStyle(
              color: dark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Be the first customer to share your experience.',
            style: TextStyle(color: secondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reviews are temporarily unavailable.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(ProductReview review) {
    final String name = review.userName.trim().isEmpty
        ? 'ShopWise User'
        : review.userName;

    final String initial = name.substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withValues(alpha: 0.10),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: star, size: 17),
                  const SizedBox(width: 3),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: dark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment.trim(),
              style: const TextStyle(
                color: secondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 10),
            Text(
              _formatDate(review.createdAt!),
              style: const TextStyle(
                color: ShopWiseColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
