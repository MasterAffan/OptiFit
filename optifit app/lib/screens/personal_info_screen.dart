import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/data_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/validators.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  String? _profileImagePath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DataService().getUserProfile();
    if (!mounted) return;
    setState(() {
      _nameController.text = profile['name'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _ageController.text = profile['age']?.toString() ?? '';
      _gender = profile['gender'] ?? null;
      _profileImagePath = profile['profileImage'] ?? null;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = {
      'name': _nameController.text,
      'email': _emailController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _gender,
      'profileImage': _profileImagePath,
    };
    await DataService().saveUserProfile(profile);
    setState(() => _saving = false);
    final snackBar = SnackBar(
      content: const Text('Profile updated!'),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await Future.delayed(const Duration(seconds: 2));
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _profileImagePath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: AppTheme.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage:
                                _profileImagePath != null &&
                                    _profileImagePath!.isNotEmpty
                                ? FileImage(File(_profileImagePath!))
                                : const AssetImage('assets/profile.png')
                                      as ImageProvider,
                          ),
                          // Edit icon (bottom right, offset down)
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // Delete icon (bottom left, offset down)
                          Positioned(
                            left: -6,
                            bottom: -6,
                            child: GestureDetector(
                              onTap: () async {
                                final profile = await DataService()
                                    .getUserProfile();
                                profile['profileImage'] = null;
                                await DataService().saveUserProfile(profile);
                                setState(() {
                                  _profileImagePath = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => Validators.validateNotEmpty(value, 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.validateNumber(
                        value, 
                        'Age',
                        min: 10,
                        max: 120,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                      decoration: const InputDecoration(labelText: 'Gender'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select gender' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
