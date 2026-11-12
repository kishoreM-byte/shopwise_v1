import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/image_upload_service.dart';
import '../../theme/design_tokens.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  bool get isEditMode => product != null;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _originalPriceController =
      TextEditingController();

  final TextEditingController _stockController = TextEditingController();

  final TextEditingController _offerController = TextEditingController();

  final ProductService _productService = ProductService();

  String _category = 'Furniture';

  bool _isAvailable = true;
  bool _hasOffer = false;
  bool _isSaving = false;
  bool _isUploadingImages = false;
  bool _hasImageUploadFailure = false;
  final List<String> _imageUrls = [];

  final List<String> _categories = const [
    'Furniture',
    'Electronics',
    'Fashion',
    'Grocery',
    'Home & Kitchen',
    'Sports',
    'Beauty',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final Product? product = widget.product;

    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();

    if (product.originalPrice != null) {
      _originalPriceController.text = product.originalPrice!.toString();
    }

    _stockController.text = product.stock.toString();

    _category = _categories.contains(product.category)
        ? product.category
        : 'Other';

    _isAvailable = product.isAvailable;
    _hasOffer = product.hasOffer;
    _offerController.text = product.offerText ?? '';
    _imageUrls.addAll(product.imageUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _offerController.dispose();

    super.dispose();
  }

  Future<void> _pickProductImages() async {
    if (_isUploadingImages || _imageUrls.length >= 6) {
      return;
    }

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final List<XFile> files =
          await ImageUploadService.pickMultipleFromGallery();

      if (files.isEmpty) {
        return;
      }

      final int remaining = 6 - _imageUrls.length;

      for (final XFile file in files.take(remaining)) {
        final String url = await ImageUploadService.uploadXFile(
          file: file,
          folder: 'product',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _imageUrls.add(url);
        });
      }

      if (files.length > remaining) {
        _showImageMessage('You can add up to 6 product images.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _hasImageUploadFailure = true;
      _showImageMessage(
        'Image upload failed. Check your connection and try again. No failed image was added.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
        });
      }
    }
  }

  Future<void> _pickProductImageFromCamera() async {
    if (_isUploadingImages || _imageUrls.length >= 6) {
      return;
    }

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final XFile? file = await ImageUploadService.pickFromCamera();

      if (file == null) {
        return;
      }

      final String url = await ImageUploadService.uploadXFile(
        file: file,
        folder: 'product',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _imageUrls.add(url);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _hasImageUploadFailure = true;
      _showImageMessage(
        'Image upload failed. Check your connection and try again. No failed image was added.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
        });
      }
    }
  }

  void _removeProductImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _showImageMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _showImageSourceSheet() {
    if (_imageUrls.length >= 6) {
      _showImageMessage('You can add up to 6 product images.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: ShopWiseColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add product images',
                    style: TextStyle(
                      color: ShopWiseColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose clear photos that help customers understand the product.',
                    style: TextStyle(
                      color: ShopWiseColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: ShopWiseColors.oliveSoft,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: ShopWiseColors.olive,
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProductImages();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: ShopWiseColors.oliveSoft,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: ShopWiseColors.olive,
                    ),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProductImageFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Product Images',
          'Add up to 6 clear images. The first image is the main product image.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ShopWiseColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ShopWiseColors.border),
          ),
          child: _imageUrls.isEmpty
              ? GestureDetector(
                  onTap: _isUploadingImages ? null : _showImageSourceSheet,
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ShopWiseColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ShopWiseColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isUploadingImages
                            ? const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: ShopWiseColors.olive,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 42,
                                color: ShopWiseColors.olive,
                              ),
                        const SizedBox(height: 10),
                        Text(
                          _isUploadingImages
                              ? 'Uploading image...'
                              : 'Add product photos',
                          style: const TextStyle(
                            color: ShopWiseColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Gallery or camera',
                          style: TextStyle(
                            color: ShopWiseColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _imageUrls[index],
                                  width: 118,
                                  height: 118,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;

                                    return const SizedBox(
                                      width: 118,
                                      height: 118,
                                      child: ColoredBox(
                                        color: ShopWiseColors.surfaceSoft,
                                        child: Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: ShopWiseColors.olive,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, _, _) {
                                    return Container(
                                      width: 118,
                                      height: 118,
                                      color: ShopWiseColors.surfaceSoft,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: ShopWiseColors.textMuted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  left: 7,
                                  bottom: 7,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ShopWiseColors.textPrimary
                                          .withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'MAIN',
                                      style: TextStyle(
                                        color: ShopWiseColors.surface,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: GestureDetector(
                                  onTap: () => _removeProductImage(index),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: ShopWiseColors.textPrimary
                                          .withValues(alpha: 0.88),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: ShopWiseColors.surface,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingImages
                            ? null
                            : _showImageSourceSheet,
                        icon: _isUploadingImages
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          _isUploadingImages ? 'Uploading...' : 'Add more',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ShopWiseColors.olive,
                          side: const BorderSide(color: ShopWiseColors.olive),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (_isUploadingImages) {
      _showImageMessage(
        'Please wait for image uploads to finish before saving.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final double price = double.parse(_priceController.text.trim());

      final String originalPriceText = _originalPriceController.text.trim();

      final double? originalPrice = originalPriceText.isEmpty
          ? null
          : double.tryParse(originalPriceText);

      final int stock = int.parse(_stockController.text.trim());

      final Product product = Product(
        id: widget.product?.id ?? '',
        shopId: widget.product?.shopId ?? '',
        ownerId: widget.product?.ownerId ?? '',
        name: _nameController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
        price: price,
        originalPrice: originalPrice,
        stock: stock,
        isAvailable: _isAvailable,
        imageUrls: List<String>.unmodifiable(_imageUrls),
        rating: widget.product?.rating ?? 0,
        reviewCount: widget.product?.reviewCount ?? 0,
        hasOffer: _hasOffer,
        offerText: _hasOffer ? _offerController.text.trim() : null,
        createdAt: widget.product?.createdAt,
        updatedAt: widget.product?.updatedAt,
      );

      if (widget.isEditMode) {
        await _productService.updateProduct(product);
      } else {
        await _productService.addProduct(product);
      }

      if (!mounted) {
        return;
      }

      final String message = _hasImageUploadFailure
          ? widget.isEditMode
                ? 'Product updated, but an image upload failed. Add the missing image again.'
                : 'Product added, but an image upload failed. Add the missing image by editing this product.'
          : widget.isEditMode
          ? 'Product updated successfully'
          : 'Product added successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Failed to update product: $e'
                : 'Failed to add product: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool editMode = widget.isEditMode;

    return Scaffold(
      backgroundColor: ShopWiseColors.background,
      appBar: AppBar(
        backgroundColor: ShopWiseColors.background,
        foregroundColor: ShopWiseColors.textPrimary,
        elevation: 0,
        title: Text(
          editMode ? 'Edit Product' : 'Add Product',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _buildHeader(editMode),

              const SizedBox(height: 24),

              _buildProductImagesSection(),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Basic Information',
                'Add the important details about your product.',
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _nameController,
                label: 'Product name',
                hint: 'Example: Premium Office Chair',
                icon: Icons.inventory_2_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter product name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _buildCategoryField(),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your product...',
                icon: Icons.notes_rounded,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter product description';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Pricing & Stock',
                'Keep your pricing and inventory information accurate.',
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Selling price',
                      hint: '₹ 0',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final double? price = double.tryParse(
                          value?.trim() ?? '',
                        );

                        if (price == null || price <= 0) {
                          return 'Enter valid price';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _originalPriceController,
                      label: 'Original price',
                      hint: '₹ 0',
                      icon: Icons.sell_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }

                        final double? originalPrice = double.tryParse(
                          value.trim(),
                        );

                        if (originalPrice == null || originalPrice <= 0) {
                          return 'Enter valid price';
                        }

                        final double? sellingPrice = double.tryParse(
                          _priceController.text.trim(),
                        );

                        if (sellingPrice != null &&
                            originalPrice <= sellingPrice) {
                          return 'Original price must exceed selling price';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _stockController,
                label: 'Stock quantity',
                hint: 'Example: 25',
                icon: Icons.inventory_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final int? stock = int.tryParse(value?.trim() ?? '');

                  if (stock == null || stock < 0) {
                    return 'Enter valid stock';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildAvailabilityCard(),

              const SizedBox(height: 30),

              _buildSectionTitle(
                'Offer',
                'Highlight a special offer for your customers.',
              ),

              const SizedBox(height: 14),

              _buildOfferCard(),

              const SizedBox(height: 34),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving || _isUploadingImages
                      ? null
                      : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShopWiseColors.olive,
                    foregroundColor: ShopWiseColors.surface,
                    disabledBackgroundColor: ShopWiseColors.textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: ShopWiseColors.surface,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              editMode ? Icons.save_rounded : Icons.add_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              editMode ? 'Save Changes' : 'Add Product',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool editMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShopWiseColors.surfaceSoft,
        border: Border.all(color: ShopWiseColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            editMode ? Icons.edit_note_rounded : Icons.add_business_rounded,
            color: ShopWiseColors.olive,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editMode ? 'Update your product' : 'Create a product',
                  style: const TextStyle(
                    color: ShopWiseColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  editMode
                      ? 'Keep your product information accurate and up to date.'
                      : 'Add accurate information so customers can make better decisions.',
                  style: const TextStyle(
                    color: ShopWiseColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ShopWiseColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: ShopWiseColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: ShopWiseColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ShopWiseColors.textMuted, size: 21),
        filled: true,
        fillColor: ShopWiseColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ShopWiseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ShopWiseColors.olive, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: ShopWiseColors.textMuted,
        ),
        filled: true,
        fillColor: ShopWiseColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ShopWiseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ShopWiseColors.border),
        ),
      ),
      items: _categories
          .map(
            (String category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: (String? value) {
        if (value == null) {
          return;
        }

        setState(() {
          _category = value;
        });
      },
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: ShopWiseColors.textMuted,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product available',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Text(
                  'Customers can see this product.',
                  style: TextStyle(
                    color: ShopWiseColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            activeThumbColor: ShopWiseColors.olive,
            onChanged: (bool value) {
              setState(() {
                _isAvailable = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShopWiseColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ShopWiseColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: ShopWiseColors.warning,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Special offer',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: _hasOffer,
                activeThumbColor: ShopWiseColors.olive,
                onChanged: (bool value) {
                  setState(() {
                    _hasOffer = value;
                  });
                },
              ),
            ],
          ),
          if (_hasOffer) ...[
            const SizedBox(height: 12),
            _buildTextField(
              controller: _offerController,
              label: 'Offer details',
              hint: 'Example: 10% off this week',
              icon: Icons.discount_outlined,
              validator: (String? value) {
                if (!_hasOffer) {
                  return null;
                }

                if (value == null || value.trim().isEmpty) {
                  return 'Enter offer details';
                }

                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
