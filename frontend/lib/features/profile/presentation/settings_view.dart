import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_service.dart';

class SettingsView extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const SettingsView({super.key, required this.userProfile});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _targetController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isReporting = false;

  @override
  void dispose() {
    _targetController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF154212),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitReport() async {
    final target = _targetController.text.trim();
    final reason = _reasonController.text.trim();

    if (target.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both fields.'),
          backgroundColor: Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isReporting = true);

    try {
      String resolvedUid = target;

      // Check if it's a UUID (8-4-4-4-12 pattern). If not, search for the user by username.
      final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (!uuidRegex.hasMatch(target)) {
        // Query user search buddy endpoint
        final searchRes = await ApiService.post('/api/users/search-buddy', {'query': target});
        if (searchRes.statusCode == 200) {
          final List<dynamic> results = jsonDecode(searchRes.body);
          if (results.isEmpty) {
            throw Exception('No user found matching that username.');
          }
          resolvedUid = results[0]['uid'].toString();
        } else {
          throw Exception('Failed to search for user.');
        }
      }

      // Submit the report
      final reportRes = await ApiService.post('/api/users/report', {
        'target_user_uid': resolvedUid,
        'reason': reason,
      });

      if (!mounted) return;

      if (reportRes.statusCode == 201) {
        _targetController.clear();
        _reasonController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report logged successfully.'),
            backgroundColor: Color(0xFF154212),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = jsonDecode(reportRes.body);
        throw Exception(err['error'] ?? 'Failed to submit report.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReporting = false);
      }
    }
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFEA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.support_agent, size: 64, color: Color(0xFF154212)),
            const SizedBox(height: 16),
            const Text(
              'Customer Support',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1A),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Have a question or run into issues? Email our support team directly or open a draft.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF42493E), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC2C9BB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF42493E))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Support draft opened: support@ecoecho.org'),
                          backgroundColor: Color(0xFF154212),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF154212),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Send Email'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFEA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1A),
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    Text(
                      'Welcome to EcoEcho! By accessing or using our application, you agree to comply with and be bound by the following Terms and Conditions and community policies.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF191C1A)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '1. Core Community Guidelines',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF154212)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'EcoEcho is a place for positive environmental action. Users are expected to log honest, authentic actions and engage with other buddies in a constructive and respectful manner. Spamming, posting fake action images, or abusing other members will result in immediate suspension.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF42493E)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '2. Account Security',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF154212)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You are responsible for maintaining the confidentiality of your login credentials. If you detect any unauthorized usage of your account, you should contact our support team immediately.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF42493E)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '3. Intellectual Property and Photo Submission',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF154212)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'By uploading photos as proof of green activities, you grant EcoEcho a non-exclusive license to host and display the content. You represent that you own the rights to the uploaded media and that it does not infringe on anyone else\'s rights.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF42493E)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '4. Modifications to Service',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF154212)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'EcoEcho reserves the right to modify, suspend, or discontinue any part of the service, including gamified scoring metrics or user tiers, at any time without prior warning.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF42493E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF154212),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userProfile['email'] ?? 'Not set';
    final uid = widget.userProfile['uid'] ?? 'Not set';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF154212)),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF154212),
            fontWeight: FontWeight.bold,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for Information Section
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF154212),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 12),

            // Information Block
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC2C9BB).withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildReadOnlyRow(
                    label: 'Email Address',
                    value: email,
                    onCopy: () => _copyToClipboard('Email address', email),
                  ),
                  const Divider(height: 24, thickness: 1, color: Color(0xFFECEFEA)),
                  _buildReadOnlyRow(
                    label: 'User UID',
                    value: uid,
                    onCopy: () => _copyToClipboard('UID', uid),
                  ),
                  const Divider(height: 24, thickness: 1, color: Color(0xFFECEFEA)),
                  _buildReadOnlyRow(
                    label: 'Password',
                    value: '••••••••',
                    isPassword: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Report Account Section
            const Text(
              'Safety & Moderation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF154212),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC2C9BB).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Buddy Account',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191C1A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Flag accounts logging fake actions, spamming, or violating community guidelines.',
                    style: TextStyle(color: Color(0xFF72796E), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetController,
                    decoration: InputDecoration(
                      labelText: 'Target Username or UID',
                      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF72796E)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Reason for reporting',
                      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF72796E)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isReporting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isReporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Additional Actions List
            const Text(
              'Support & Guidelines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF154212),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC2C9BB).withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.mail_outline, color: Color(0xFF154212)),
                    title: const Text('Send Help / Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF72796E)),
                    onTap: _showSupportModal,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFECEFEA)),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Color(0xFF154212)),
                    title: const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF72796E)),
                    onTap: _showTermsModal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    VoidCallback? onCopy,
    bool isPassword = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF72796E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191C1A),
                  fontFamily: isPassword ? null : 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isPassword)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.lock, size: 20, color: Color(0xFFC2C9BB)),
          )
        else if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Color(0xFF154212)),
            onPressed: onCopy,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            splashRadius: 20,
          ),
      ],
    );
  }
}
