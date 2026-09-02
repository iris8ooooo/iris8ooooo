import 'package:flutter/material.dart';

import 'privacy_text.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('개인정보처리방침')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Text(
        kPrivacyPolicyText,
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
    ),
  );
}
