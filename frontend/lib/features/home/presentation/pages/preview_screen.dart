import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  final int? missionId;
  final int? categoryId;
  final bool isProfilePicMode;

  const PreviewScreen({
    Key? key,
    required this.imagePath,
    this.missionId,
    this.categoryId,
    this.isProfilePicMode = false,
  }) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  String _selectedTag = 'Tree Planting';
  final List<String> _tags = [
    'Tree Planting',
    'Sustainable Transport',
    'Recycling',
    'Energy Saving',
    'Cleanup Drive'
  ];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      switch (widget.categoryId) {
        case 1: _selectedTag = 'Tree Planting'; break;
        case 2: _selectedTag = 'Sustainable Transport'; break;
        case 3: _selectedTag = 'Recycling'; break;
        case 4: _selectedTag = 'Energy Saving'; break;
        case 5: _selectedTag = 'Cleanup Drive'; break;
      }
    }
  }

  void _uploadPost() async {
    setState(() => _isUploading = true);

    try {
      int categoryId = 1;
      switch (_selectedTag) {
        case 'Tree Planting': categoryId = 1; break;
        case 'Sustainable Transport': categoryId = 2; break;
        case 'Recycling': categoryId = 3; break;
        case 'Energy Saving': categoryId = 4; break;
        case 'Cleanup Drive': categoryId = 5; break;
      }

      final Map<String, String> fields = {
        'caption': _captionController.text,
        'category_id': categoryId.toString(),
      };
      if (widget.missionId != null) {
        fields['mission_id'] = widget.missionId.toString();
      }

      final bytes = await File(widget.imagePath).readAsBytes();
      final response = await ApiService.uploadImageBytes(
        '/api/posts',
        bytes,
        'activity_image.jpg',
        fields,
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof uploaded successfully! +50 XP'),
            backgroundColor: Color(0xFF154212),
          ),
        );
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
      } else {
        final respBody = await response.stream.bytesToString();
        throw Exception('Failed to upload: $respBody');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _uploadProfilePicture() async {
    setState(() => _isUploading = true);

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final response = await ApiService.uploadImageBytes(
        '/api/users/profile-picture',
        bytes,
        'profile_pic.jpg',
        {},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Color(0xFF154212),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final respBody = await response.stream.bytesToString();
        throw Exception('Failed to upload: $respBody');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF191C1A)),
        title: Text(
          widget.isProfilePicMode ? 'Update Profile Picture' : 'New Activity',
          style: const TextStyle(color: Color(0xFF191C1A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(widget.imagePath),
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            if (!widget.isProfilePicMode) ...[
              const Text(
                'Caption',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191C1A)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your green activity...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFC2C9BB).withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFC2C9BB).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF154212), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191C1A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final isSelected = _selectedTag == tag;
                  final isLocked = widget.categoryId != null;
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: const Color(0xFF154212),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF42493E),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF154212) : const Color(0xFFC2C9BB).withOpacity(0.5),
                    ),
                    onSelected: isLocked
                        ? null
                        : (selected) {
                            if (selected) setState(() => _selectedTag = tag);
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ] else ...[
              const SizedBox(height: 40),
            ],

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : (widget.isProfilePicMode ? _uploadProfilePicture : _uploadPost),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154212),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.isProfilePicMode ? 'Set as Profile Picture' : 'Share to Community',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}