import 'package:flutter/material.dart';

import '../../../models/review.dart';
import '../../../services/customer/review_service.dart';
import '../../../theme/design_tokens.dart';

class ReviewComposer extends StatefulWidget {
  final String productId;
  final ProductReview? existingReview;
  final VoidCallback? onSaved;

  const ReviewComposer({
    super.key,
    required this.productId,
    this.existingReview,
    this.onSaved,
  });

  @override
  State<ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<ReviewComposer> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();

  double _rating = 0;
  bool _isSaving = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    final review = widget.existingReview;

    if (review != null) {
      _rating = review.rating;
      _commentController.text = review.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating <= 0) {
      _message('Please select a rating.');
      return;
    }

    if (_commentController.text.trim().length < 3) {
      _message('Please write a little more about your experience.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _reviewService.addReview(
        productId: widget.productId,
        rating: _rating,
        comment: _commentController.text,
      );

      if (!mounted) return;

      _message(
        _isEditing
            ? 'Your review has been updated.'
            : 'Your review has been published.',
      );

      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;

      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit your review' : 'Share your experience',
            style: const TextStyle(
              color: ShopWiseColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your feedback helps other customers make better decisions.',
            style: TextStyle(
              color: ShopWiseColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;

              return IconButton(
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _rating = value.toDouble()),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                icon: Icon(
                  value <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 32,
                  color: const Color(0xFFF59E0B),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${_rating.toStringAsFixed(0)} / 5',
              style: const TextStyle(
                color: ShopWiseColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            enabled: !_isSaving,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What did you like? What could be better?',
              hintStyle: const TextStyle(
                color: ShopWiseColors.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: ShopWiseColors.surfaceSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: ShopWiseColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: ShopWiseColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: ShopWiseColors.emerald,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: ShopWiseColors.emerald,
                disabledBackgroundColor: ShopWiseColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ShopWiseColors.surface,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Update Review' : 'Publish Review',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
