import 'package:flutter/material.dart';
import '../theme/theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faq = [
    {
      'q': 'How do I track my workouts?',
      'a': 'To track your workouts, go to the Workouts tab, select or start a workout, and your progress will be automatically recorded in your history.'
    },
    {
      'q': 'How do I contact support?',
      'a': 'You can contact support by filling out the form below. Our team will respond to your query within 24 hours via your registered email.'
    },
    {
      'q': 'How do I change my password?',
      'a': 'To change your password, navigate to your Profile, select Privacy & Security, and use the Change Password section.'
    },
    {
      'q': 'How do I delete my account?',
      'a': 'To delete your account, go to Profile > Privacy & Security, and tap the Delete Account button at the bottom. This action is permanent.'
    },
  ];
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    _expanded = List.filled(_faq.length, false);
  }

  Future<void> _sendSupportMessage() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    setState(() => _sending = true);
    // TODO: Connect to backend or email service
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _sending = false);
    _subjectController.clear();
    _messageController.clear();
    final snackBar = SnackBar(
      content: const Text('Message sent!'),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await Future.delayed(const Duration(seconds: 2));
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequently Asked Questions', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Column(
              children: _faq.map((faq) => ExpansionTile(
                title: Text(faq['q']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(faq['a']!),
                  ),
                ],
              )).toList(),
            ),
            const SizedBox(height: 32),
            Text('Contact Support', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendSupportMessage,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Message'),
              ),
            ),
            const SizedBox(height: 32),
            Divider(),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'App Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 