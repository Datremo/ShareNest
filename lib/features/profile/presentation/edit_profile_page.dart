import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/profile_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileRepo = ProfileRepository();
  final _userId = Supabase.instance.client.auth.currentUser?.id;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _newAvatarUrl;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestController = TextEditingController();
  
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;
    final profile = await _profileRepo.getProfile(_userId!);
    if (profile != null) {
      _nameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _locationController.text = profile.locationName ?? '';
      _newAvatarUrl = profile.photoUrl;
      if (profile.interests != null) {
        _interests = List<String>.from(profile.interests!);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    
    if (image == null) return;

    setState(() => _isSaving = true);
    
    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final filePath = '$userId/$fileName';
      
      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(
            filePath, 
            bytes, 
            fileOptions: FileOptions(contentType: 'image/$fileExt')
          );
          
      final publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath);
          
      setState(() {
        _newAvatarUrl = publicUrl;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _profileRepo.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: _newAvatarUrl,
        locationName: _locationController.text.trim(),
              );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addInterest(String value) {
    final interest = value.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
      });
      _interestController.clear();
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isSaving ? null : _pickAndUploadImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _newAvatarUrl != null && _newAvatarUrl!.isNotEmpty
                                    ? NetworkImage(_newAvatarUrl!)
                                    : null,
                                child: _newAvatarUrl == null || _newAvatarUrl!.isEmpty
                                    ? const Icon(Icons.person, size: 56, color: Colors.grey)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    label: 'Full Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Location',
                    controller: _locationController,
                    hintText: 'e.g. Sainagar, Old Panvel',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Bio (optional)',
                    controller: _bioController,
                    maxLines: 3,
                    counterText: 'Max 200 chars',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Interests (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _interestController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Add an interest and press enter',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        onPressed: () => _addInterest(_interestController.text),
                      ),
                    ),
                    onFieldSubmitted: _addInterest,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests.map((interest) => _buildInterestChip(interest)).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? counterText,
    String? hintText,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryDark, size: 22) : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        if (counterText != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              counterText,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInterestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeInterest(label),
            child: const Icon(Icons.close, size: 16, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
