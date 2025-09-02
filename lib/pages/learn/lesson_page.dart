import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'lesson_quiz_page.dart';

class LessonPage extends StatefulWidget {
  final String title;
  final Map<String, List<String>> sections;
  final String testType;
  final String testTitle;
  final String testCompletedKey;
  final String lessonCompletedKey;
  final Map<String, Widget Function(String, List<String>)>?
      customSectionBuilders;

  const LessonPage({
    super.key,
    required this.title,
    required this.sections,
    required this.testType,
    required this.testTitle,
    required this.testCompletedKey,
    required this.lessonCompletedKey,
    this.customSectionBuilders,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  Widget _buildBulletLine(BuildContext context, String text) {
    final numberPrefix = RegExp(r'^(\d+)[）).．\.]\s*');
    String display = text;
    bool isNumbered = numberPrefix.hasMatch(text);
    if (isNumbered) {
      display = text.replaceFirst(numberPrefix, '');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNumbered) const Text('• '),
        Expanded(child: Text(display)),
      ],
    );
  }

  Widget _buildDefaultSection(String title, List<String> contents) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) => _buildBulletLine(context, contents[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: contents.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageController = PageController(viewportFraction: 0.9);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: PageView.builder(
              controller: pageController,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.sections.length + 1, // +1 for test card
              itemBuilder: (context, index) {
                // Check if this is the test card (last index)
                if (index == widget.sections.length) {
                  return _buildTestCard();
                }

                final title = widget.sections.keys.elementAt(index);
                final contents = widget.sections[title]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Stack(children: [
                        // Big faded number at bottom right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.withValues(alpha: 0.1),
                              height: 0.8,
                            ),
                          ),
                        ),
                        // Main content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: SingleChildScrollView(
                                child: widget.customSectionBuilders?[title]
                                        ?.call(title, contents) ??
                                    _buildDefaultSection(title, contents),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        color: Colors.orange[50], // Different color for test card
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16), // 内容水平边距16，垂直边距16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.testTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32), // 增加间距
              Text(
                '测试你对${widget.title}的掌握程度',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange[800], // Changed to dark orange
                ),
              ),
              const SizedBox(height: 32), // 增加间距
              Text(
                '测试内容',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 2道判断题（每题20分）',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              const Text(
                '• 3道选择题（每题20分）',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              const Text(
                '• 需要100分才能通过',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32), // 开始测试按钮的底部边距
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonQuizPage(
                          testType: widget.testType,
                          pageTitle: widget.testTitle,
                          testCompletedKey: widget.testCompletedKey,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    '开始测试',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), // 按钮底部边距
            ],
          ),
        ),
      ),
    );
  }
}
