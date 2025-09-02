import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KnowledgeLessonPage extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget>? customSections;

  const KnowledgeLessonPage({
    super.key,
    required this.title,
    required this.content,
    this.customSections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),

            // 自定义部分
            if (customSections != null) ...[
              const SizedBox(height: 20),
              ...customSections!,
            ],

            const SizedBox(height: 40),

            // 完成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '完成学习',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
