import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/animated_checkmark.dart';
import '../../../core/presentation/widgets/liquid_glass_container.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/widgets/animated_flying_button.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/repositories/listing_repository.dart';

class CreateLendPostPage extends StatefulWidget {
  const CreateLendPostPage({super.key});

  @override
  State<CreateLendPostPage> createState() => _CreateLendPostPageState();
}

class _CreateLendPostPageState extends State<CreateLendPostPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isPublishing = false;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final ListingRepository _listingRepository = ListingRepository();

  // Categories
  final List<String> _categories = [
    'DIY & Power Tools',
    'Camping & Outdoors',
    'Kitchen & Party',
    'Books & Games',
    'Sports & Fitness',
    'Electronics',
    'Clothing',
    'Others',
  ];

  // Step 1 State
  final List<XFile> _pickedImages = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String? _selectedCategory;
  String _selectedCondition = 'Good';

  // Step 2 State
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  final _locationController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _includedInputController = TextEditingController();
  final List<String> _tags = [];
  final List<String> _includedItems = [];
  
  // Return Period State
  final _returnPeriodNumberController = TextEditingController(text: '1');
  String _returnPeriodUnit = 'Week(s)';

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _tagInputController.dispose();
    _includedInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(limit: 5);
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images);
      });
    }
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _availableFrom != null && _availableUntil != null
          ? DateTimeRange(start: _availableFrom!, end: _availableUntil!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _availableFrom = picked.start;
        _availableUntil = picked.end;
      });
    }
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _addIncludedItem() {
    final item = _includedInputController.text.trim();
    if (item.isNotEmpty && !_includedItems.contains(item)) {
      setState(() {
        _includedItems.add(item);
        _includedInputController.clear();
      });
    }
  }

  Future<void> _publishPost() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null ||
        _locationController.text.isEmpty ||
        _availableFrom == null ||
        _availableUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('You must be logged in to post.');

      List<String> photoUrls = [];
      if (_pickedImages.isNotEmpty) {
        for (final image in _pickedImages) {
          final bytes = await image.readAsBytes();
          final ext = image.name.split('.').last;
          final url = await _listingRepository.uploadListingImage(bytes, ext);
          photoUrls.add(url);
        }
      }

      final listing = Listing(
        id: '',
        ownerId: user.id,
        mode: 'LEND',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory!.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_'),
        photoUrls: photoUrls,
        status: 'ACTIVE',
        condition: _selectedCondition,
        brand: _brandController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 1,
        locationName: _locationController.text.trim(),
        availability: [
          _availableFrom!.toIso8601String(),
          _availableUntil!.toIso8601String(),
        ],
        preferences: {
          'tags': _tags,
          'includedItems': _includedItems,
          'returnPeriod': '${_returnPeriodNumberController.text.trim()} $_returnPeriodUnit',
        },
      );

      await _listingRepository.createListing(listing);
      
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Lend an Item',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentStep = idx),
        children: [
          _buildStep1(),
          _buildStep2(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item Details',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add clear photos and describe what you are lending.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            
            // Photos
            _buildLabel('Photos *'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._pickedImages.asMap().entries.map((entry) => _buildPickedPhotoThumbnail(entry.value, entry.key)),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.primary.withValues(alpha: 0.05),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            _buildLabel('Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              decoration: _inputDecoration('What is the item?'),
            ),
            const SizedBox(height: 24),
            
            // Category
            _buildLabel('Category *'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _inputDecoration('Select category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            
            // Quantity & Brand
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Quantity *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        decoration: _inputDecoration('Qty'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Brand (Optional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _brandController,
                        decoration: _inputDecoration('e.g. Bosch, Sony'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Condition
            _buildLabel('Condition *'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildConditionChip('Like New'),
                const SizedBox(width: 12),
                _buildConditionChip('Good'),
                const SizedBox(width: 12),
                _buildConditionChip('Fair'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Description
            _buildLabel('Description *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              decoration: _inputDecoration('Provide helpful details about the item...'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Availability & Logistics',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set when and where neighbors can pick up the item.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            
            // Dates
            _buildLabel('Availability Dates *'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _availableFrom != null && _availableUntil != null
                          ? '${DateFormat('MMM d, yyyy').format(_availableFrom!)} - ${DateFormat('MMM d, yyyy').format(_availableUntil!)}'
                          : 'Select date range',
                      style: TextStyle(
                        fontSize: 16,
                        color: _availableFrom != null ? AppColors.primaryDark : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Return Period
            _buildLabel('Return Period *'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _returnPeriodNumberController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    decoration: _inputDecoration('e.g. 1'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _returnPeriodUnit,
                    items: ['Day(s)', 'Week(s)', 'Month(s)'].map((u) {
                      return DropdownMenuItem(value: u, child: Text(u));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _returnPeriodUnit = val);
                    },
                    decoration: _inputDecoration(''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location
            _buildLabel('Pickup Location *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              decoration: _inputDecoration('e.g. My house, Coffee shop on 5th Ave', prefixIcon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 24),

            // Tags
            _buildLabel('Tags (Optional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagInputController,
                    decoration: _inputDecoration('Add a tag (e.g. Heavy, Fragile)'),
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 32),
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 8,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  )).toList(),
                ),
              ),
            const SizedBox(height: 24),

            // Included Items
            _buildLabel('Included in the box (Optional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _includedInputController,
                    decoration: _inputDecoration('e.g. Charger, Manual'),
                    onFieldSubmitted: (_) => _addIncludedItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addIncludedItem,
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 32),
                ),
              ],
            ),
            if (_includedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 8,
                  children: _includedItems.map((item) => Chip(
                    label: Text(item),
                    onDeleted: () => setState(() => _includedItems.remove(item)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: AppColors.primaryDark.withValues(alpha: 0.05),
                    side: BorderSide.none,
                  )).toList(),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Listing',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure everything looks good.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          
          LiquidGlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            sigma: 10,
            opacity: 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pickedImages.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: kIsWeb ? NetworkImage(_pickedImages.first.path) as ImageProvider : FileImage(File(_pickedImages.first.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(_titleController.text.isNotEmpty ? _titleController.text : 'Untitled', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedCategory ?? 'No Category', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Qty: ${_quantityController.text}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_descriptionController.text.isNotEmpty ? _descriptionController.text : 'No description provided.', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                
                const Divider(color: AppColors.grey200),
                const SizedBox(height: 16),
                
                _buildReviewRow(Icons.calendar_month, 'Availability', 
                  _availableFrom != null && _availableUntil != null 
                    ? '${_availableFrom!.toString().substring(0, 10)} - ${_availableUntil!.toString().substring(0, 10)}' 
                    : 'Not Set'),
                const SizedBox(height: 12),
                _buildReviewRow(Icons.timer, 'Return Period', '${_returnPeriodNumberController.text} $_returnPeriodUnit'),
                const SizedBox(height: 12),
                _buildReviewRow(Icons.location_on, 'Location', _locationController.text.isNotEmpty ? _locationController.text : 'Not set'),
                const SizedBox(height: 12),
                _buildReviewRow(Icons.star, 'Condition', _selectedCondition),
                if (_brandController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildReviewRow(Icons.branding_watermark, 'Brand', _brandController.text),
                ],
                
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _tags.map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)), 
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    )).toList(),
                  )
                ],
                if (_includedItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Includes:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: _includedItems.map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)), 
                      backgroundColor: Colors.grey[200],
                      side: BorderSide.none,
                    )).toList(),
                  )
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const AnimatedCheckmark(color: AppColors.success, size: 80),
        ),
        const SizedBox(height: 32),
        const Text(
          'Post Published!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your item is now available for neighbors to borrow.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Go to Home', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: LiquidGlassContainer(sigma: 15, opacity: 0.7, padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: () {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                child: const Text('Back', style: TextStyle(fontSize: 16, color: AppColors.primaryDark)),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  if ((_formKey1.currentState?.validate() ?? false)) {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                } else if (_currentStep == 1) {
                  if ((_formKey2.currentState?.validate() ?? false)) {
                    if (_availableFrom == null || _availableUntil == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select availability dates.')));
                      return;
                    }
                    final listing = Listing(
                      id: '',
                      ownerId: '',
                      mode: 'LEND',
                      title: _titleController.text.trim(),
                      description: _descriptionController.text.trim(),
                      categoryId: _selectedCategory!.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_'),
                      photoUrls: [],
                      status: 'ACTIVE',
                      condition: _selectedCondition,
                      brand: _brandController.text.trim(),
                      quantity: int.tryParse(_quantityController.text) ?? 1,
                      locationName: _locationController.text.trim(),
                      availability: [
                        _availableFrom!.toIso8601String(),
                        _availableUntil!.toIso8601String(),
                      ],
                      preferences: {
                        'tags': _tags,
                        'includedItems': _includedItems,
                        'returnPeriod': '${_returnPeriodNumberController.text.trim()} $_returnPeriodUnit',
                      },
                    );
                    context.push('/review_post', extra: {
                      'listing': listing,
                      'images': _pickedImages,
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Text(_currentStep == 1 ? 'Review' : 'Next', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.grey400) : null,
      filled: true,
      fillColor: AppColors.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildConditionChip(String label) {
    final isSelected = _selectedCondition == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCondition = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey300),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickedPhotoThumbnail(XFile file, int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: kIsWeb ? NetworkImage(file.path) as ImageProvider : FileImage(File(file.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => _removePickedImage(index),
          ),
        ),
      ],
    );
  }
}
