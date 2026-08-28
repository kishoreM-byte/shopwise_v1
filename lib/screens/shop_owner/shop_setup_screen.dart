import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/shop.dart';
import '../../services/shop_service.dart';
import 'widgets/shop_service_options_card.dart';

class ShopSetupScreen extends StatefulWidget {
  final Shop? shop;

  const ShopSetupScreen({super.key, this.shop});

  bool get isEditMode => shop != null;

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final ShopService _shopService = ShopService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  String _category = 'Furniture';
  bool _isOpen = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;

  bool _deliveryAvailable = false;
  double _deliveryCharge = 0;

  bool _installationAvailable = false;
  double _installationCharge = 0;

  // Customer service settings

  final List<String> _categories = [
    'Furniture',
    'Electronics',
    'Clothing',
    'Grocery',
    'Mobile & Accessories',
    'Sports',
    'Beauty',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final Shop? shop = widget.shop;

    if (shop != null) {
      _nameController.text = shop.name;
      _descriptionController.text = shop.description;
      _addressController.text = shop.address;
      _phoneController.text = shop.phone;
      _latitude = shop.latitude;
      _longitude = shop.longitude;

      if (_categories.contains(shop.category)) {
        _category = shop.category;
      }

      _isOpen = shop.isOpen;

      // Load existing customer service settings.
      _deliveryAvailable = shop.deliveryAvailable;
      _deliveryCharge = shop.deliveryCharge;

      _installationAvailable = shop.installationAvailable;
      _installationCharge = shop.installationCharge;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getShopLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Please turn on location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. Enable it from Settings.',
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _showMessage('Shop location captured successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to get shop location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _saveShop() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your shop name.');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showMessage('Please enter your shop address.');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Please enter your phone number.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Shop shop = Shop(
        id: widget.shop?.id ?? '',
        ownerId: widget.shop?.ownerId ?? '',
        name: _nameController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: widget.shop?.imageUrl,
        rating: widget.shop?.rating ?? 0,
        reviewCount: widget.shop?.reviewCount ?? 0,
        isOpen: _isOpen,

        deliveryAvailable: _deliveryAvailable,
        deliveryCharge: _deliveryCharge,

        installationAvailable: _installationAvailable,
        installationCharge: _installationCharge,

        createdAt: widget.shop?.createdAt,
        updatedAt: widget.shop?.updatedAt,
      );

      if (widget.isEditMode) {
        await _shopService.updateShop(shop);
      } else {
        await _shopService.createShop(shop);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Shop updated successfully'
                : 'Shop created successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to save shop: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          widget.isEditMode ? 'Edit Shop' : 'Shop Setup',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.white, size: 34),
                  SizedBox(height: 14),
                  Text(
                    'Set up your shop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add your shop details so customers can discover and trust your business.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Basic information',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(
                label: 'Shop name',
                hint: 'Example: Kishore Furniture',
                icon: Icons.store_rounded,
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _decoration(
                label: 'Category',
                icon: Icons.category_outlined,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _category = value;
                });
              },
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                label: 'Description',
                hint: 'Tell customers about your shop...',
                icon: Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Contact details',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _addressController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                label: 'Shop address',
                hint: 'Enter your complete shop address',
                icon: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.my_location_rounded, color: Color(0xFF10B981)),
                      SizedBox(width: 10),
                      Text(
                        'Shop location',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _latitude != null && _longitude != null
                        ? 'Location captured successfully'
                        : 'Use your current location to help customers find your shop.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(6)}  •  '
                      'Lng: ${_longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFECFDF5), Color(0xFFEFF6FF)],
                      ),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 18,
                          top: 18,
                          child: Icon(
                            Icons.map_rounded,
                            size: 38,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        Positioned(
                          left: 70,
                          top: 18,
                          right: 16,
                          child: Text(
                            _latitude != null && _longitude != null
                                ? 'Shop location is ready'
                                : 'Add your shop location',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 70,
                          top: 48,
                          right: 16,
                          child: SizedBox(
                            height: 32,
                            child: Text(
                              _latitude != null && _longitude != null
                                  ? 'Customers can use this location for directions.'
                                  : 'Capture your current location for accurate directions.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: _isGettingLocation
                                ? null
                                : _getShopLocation,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _isGettingLocation
                                  ? 'Getting location...'
                                  : _latitude != null
                                  ? 'Update Location'
                                  : 'Use Current Location',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF10B981)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _decoration(
                label: 'Phone number',
                hint: 'Enter shop contact number',
                icon: Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 24),

            ShopServiceOptionsCard(
              deliveryAvailable: _deliveryAvailable,
              deliveryCharge: _deliveryCharge,
              installationAvailable: _installationAvailable,
              installationCharge: _installationCharge,
              onDeliveryChanged: (value) {
                setState(() {
                  _deliveryAvailable = value;
                });
              },
              onDeliveryChargeChanged: (value) {
                setState(() {
                  _deliveryCharge = value;
                });
              },
              onInstallationChanged: (value) {
                setState(() {
                  _installationAvailable = value;
                });
              },
              onInstallationChargeChanged: (value) {
                setState(() {
                  _installationCharge = value;
                });
              },
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Shop is open',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  _isOpen
                      ? 'Customers can see your shop as open'
                      : 'Your shop will appear closed',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                value: _isOpen,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (value) {
                  setState(() {
                    _isOpen = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveShop,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : widget.isEditMode
                      ? 'Update Shop'
                      : 'Create Shop',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
