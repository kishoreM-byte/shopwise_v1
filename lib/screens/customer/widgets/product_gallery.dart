import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/design_tokens.dart';

class ProductGallery extends StatefulWidget {
  final List<String> imageUrls;

  const ProductGallery({super.key, required this.imageUrls});

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      _usableImageUrlsFor(oldWidget.imageUrls),
      _usableImageUrls,
    )) {
      _currentIndex = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _usableImageUrls => _usableImageUrlsFor(widget.imageUrls);

  List<String> _usableImageUrlsFor(List<String> urls) => urls
      .map((url) => url.trim())
      .where((url) {
        final Uri? uri = Uri.tryParse(url);
        return uri != null &&
            url.isNotEmpty &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final double galleryHeight = (MediaQuery.sizeOf(context).width * 0.82)
        .clamp(250.0, 410.0);
    final images = _usableImageUrls;

    if (images.isEmpty) {
      return _buildPlaceholder(galleryHeight);
    }

    return Column(
      children: [
        Container(
          height: galleryHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ShopWiseColors.surfaceSoft,
            borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return _buildPlaceholder(galleryHeight);
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ShopWiseColors.emerald,
                        ),
                      );
                    },
                  );
                },
              ),

              if (images.length > 1)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: index == _currentIndex ? 20 : 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: index == _currentIndex ? 0.95 : 0.55,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == _currentIndex;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    height: 62,
                    padding: EdgeInsets.all(selected ? 2 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? ShopWiseColors.emerald
                            : ShopWiseColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const ColoredBox(
                            color: ShopWiseColors.surfaceSoft,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ShopWiseColors.emerald,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) {
                          return Container(
                            color: ShopWiseColors.surfaceSoft,
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: ShopWiseColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        borderRadius: BorderRadius.circular(ShopWiseRadius.xLarge),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: ShopWiseColors.textMuted,
        ),
      ),
    );
  }
}
