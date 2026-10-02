import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models/urgent_request.dart';
import 'package:path/path.dart' as p;
import '../../../core/location/location_autocomplete_field.dart';

class SendOfferWizardPage extends StatefulWidget {
  final UrgentRequest request;
  final String offerType;

  const SendOfferWizardPage({super.key, required this.request, required this.offerType});

  @override
  State<SendOfferWizardPage> createState() => _SendOfferWizardPageState();
}

class _SendOfferWizardPageState extends State<SendOfferWizardPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isSubmitting = false;

  // Step 1: Item Details
  String? _itemCondition;
  final _extraDetailsController = TextEditingController();
  final List<File> _photos = [];

  // Step 2: Handover Details
  final _locationController = TextEditingController();
  LocationSuggestion? _selectedLocation;
  String? _availabilityDate; // 'Today', 'Tomorrow'
  String? _availabilityTime; // 'Anytime', 'Specific'
  String? _handoverMethod; // 'Meet nearby', 'At my home', 'Other'
  String? _windowStart;
  String? _windowEnd;
  String? _lendDuration; // '1 week', '2 weeks', '1 month'
  final _noteController = TextEditingController();

  final List<String> _conditions = [
    'Brand New',
    'Like New',
    'Good - Fully working',
    'Fair - Some wear',
    'Needs Repair'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _extraDetailsController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex == 0) {
      if (_itemCondition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select item condition.')));
        return;
      }
    } else if (_currentIndex == 1) {
      if (_locationController.text.isEmpty || _handoverMethod == null || _availabilityDate == null || (widget.offerType == 'Lend' && _lendDuration == null)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required details.')));
        return;
      }
    }
    
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _submitOffer() async {
    setState(() => _isSubmitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      List<String> uploadedPhotoUrls = [];
      for (var photo in _photos) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(photo.path)}';
        final path = '${user.id}/$fileName';
        await Supabase.instance.client.storage.from('offer_photos').upload(path, photo);
        final url = Supabase.instance.client.storage.from('offer_photos').getPublicUrl(path);
        uploadedPhotoUrls.add(url);
      }

      String finalDetails = _extraDetailsController.text;
      if (widget.offerType == 'Lend' && _lendDuration != null) {
        finalDetails += (finalDetails.isEmpty ? '' : '\n') + 'Lend Duration: $_lendDuration';
      }

      final newListing = await Supabase.instance.client.from('listings').insert({
        'owner_id': user.id,
        'title': widget.request.title,
        'mode': widget.offerType.toUpperCase(),
        'category_id': 'urgent_category',
        'description': 'Offer details: $finalDetails\nCondition: $_itemCondition',
        'status': 'UNAVAILABLE',
        'is_urgent_fulfillment': true,
        'image_url': uploadedPhotoUrls.isNotEmpty ? uploadedPhotoUrls.first : null,
      }).select('id').single();
      final listingId = newListing['id'] as String;

      final jsonPayload = jsonEncode({
        'type': widget.offerType.toUpperCase(),
        'listing_id': listingId,
        'item_condition': _itemCondition,
        'extra_details': finalDetails,
        'photos': uploadedPhotoUrls,
        'handover_location': _selectedLocation?.displayName ?? _locationController.text,
        'handover_method': _handoverMethod,
        'availability_date': _availabilityDate,
        'window_start': _windowStart,
        'window_end': _windowEnd,
        'note': _noteController.text,
      });

      await Supabase.instance.client.from('urgent_request_offers').insert({
        'urgent_request_id': widget.request.id,
        'helper_id': user.id,
        'status': 'PENDING',
        'available_for_duration': jsonPayload,
      });

      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit offer: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentIndex == 3 ? const SizedBox() : IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentIndex > 0) _prevPage();
            else context.pop();
          },
        ),
        title: Text(
          _currentIndex == 0 ? 'Send Offer (${widget.offerType})' :
          _currentIndex == 1 ? 'Handover Details' :
          _currentIndex == 2 ? 'Review Offer' : '',
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildStep1ItemDetails(),
          _buildStep2HandoverDetails(),
          _buildStep3Review(),
          _buildStep4Success(),
        ],
      ),
    );
  }

  Widget _buildStep1ItemDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item Details', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Confirm the item you are offering and add a few details.', style: GoogleFonts.inter(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2, color: Colors.black26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.offerType.toUpperCase(), style: GoogleFonts.inter(color: const Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.request.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Condition *', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _itemCondition,
                hint: const Text('Select Condition'),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _itemCondition = val),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Extra Details (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _extraDetailsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Well maintained. All attachments included...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Photos (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              ..._photos.map((f) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb 
                        ? Image.network(f.path, width: 80, height: 80, fit: BoxFit.cover)
                        : Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: -4, top: -4,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _photos.remove(f)),
                    ),
                  )
                ],
              )),
              if (_photos.length < 3)
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: const Center(child: Icon(Icons.add, color: Colors.black54)),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Next →', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2HandoverDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Handover Details', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Let them know where and when you can give the item.', style: GoogleFonts.inter(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 24),
          
          _buildSectionTitle(Icons.location_on, 'Where will you hand it over? *'),
          const SizedBox(height: 12),
          LocationAutocompleteField(
            controller: _locationController,
            onSelected: (suggestion) {
              setState(() {
                _selectedLocation = suggestion;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter address or use map...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(Icons.access_time, 'When are you available? *'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSelectableTile('Today', '', _availabilityDate == 'Today', () => setState(() => _availabilityDate = 'Today')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectableTile('Tomorrow', '', _availabilityDate == 'Tomorrow', () => setState(() => _availabilityDate = 'Tomorrow')),
              ),
            ],
          ),
          
          if (widget.offerType == 'Lend') ...[
            const SizedBox(height: 24),
            _buildSectionTitle(Icons.timelapse, 'How long can you lend it for? *'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _lendDuration,
                  hint: const Text('Select Duration'),
                  items: ['1 week', '2 weeks', '1 month', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _lendDuration = val),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          _buildSectionTitle(Icons.handshake, 'Handover method *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildPill('Meet nearby', _handoverMethod == 'Meet nearby', () => setState(() => _handoverMethod = 'Meet nearby')),
              _buildPill('At my home', _handoverMethod == 'At my home', () => setState(() => _handoverMethod = 'At my home')),
              _buildPill('Other', _handoverMethod == 'Other', () => setState(() => _handoverMethod = 'Other')),
            ],
          ),

          const SizedBox(height: 24),
          Text('Anything else? (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Call me before coming...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevPage,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Back', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Next →', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isHighlight ? const Color(0xFF00C853) : Colors.black87,
                fontSize: 15,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Offer', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          
          Text('Request Summary', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 12),
          
          _buildGlassCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.request.imageUrl != null
                      ? Image.network(widget.request.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                      : Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('URGENT', style: TextStyle(color: const Color(0xFFE53935), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.request.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Needed by: ${widget.request.neededBy ?? 'Anytime'}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Your Offer Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 12),
          
          _buildGlassCard(
            child: Column(
              children: [
                _buildDataRow('Offer Type', widget.offerType, isHighlight: true),
                const Divider(),
                _buildDataRow('Condition', _itemCondition ?? 'N/A'),
                const Divider(),
                _buildDataRow('Location', _selectedLocation?.displayName ?? _locationController.text),
                if (widget.offerType == 'Lend' && _lendDuration != null) ...[
                  const Divider(),
                  _buildDataRow('Duration', _lendDuration!),
                ],
                const Divider(),
                _buildDataRow('Available', _availabilityDate ?? 'N/A'),
                const Divider(),
                _buildDataRow('Method', _handoverMethod ?? 'N/A'),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _prevPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Back', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853), 
                    padding: const EdgeInsets.symmetric(vertical: 16), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Send Offer', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Success() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.send, color: Color(0xFF00C853), size: 50),
          ),
          const SizedBox(height: 24),
          Text('Offer Sent!', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Your offer to help has been sent. They will be notified and can accept your offer.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 15, color: Colors.black54)),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(), // Pop wizard, go back to map
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('Back to Map', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildSelectableTile(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C853).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF00C853) : Colors.black87)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                  ],
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00C853)),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C853).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300),
        ),
        child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF00C853) : Colors.black87)),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
