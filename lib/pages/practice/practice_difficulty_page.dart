import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/practice_provider.dart';
import 'practice_page.dart';

class PracticeDifficultyPage extends StatelessWidget {
  const PracticeDifficultyPage({super.key});

  void _openPractice(BuildContext context, String difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => PracticeProvider(),
          child: PracticePage(
            difficulty: difficulty,
            onDifficultyChanged: (_) {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const difficulties = [
      {'label': '简单', 'desc': '仅字母'},
      {'label': '中等', 'desc': '字母 + 数字'},
      {'label': '困难', 'desc': '全部字符'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Title bar
            Container(
              height: 52,
              width: double.infinity,
              color: Colors.black,
              alignment: Alignment.center,
              child: const Text(
                '练习',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            child: Column(
                              children: [
                                for (int i = 0; i < difficulties.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: i == difficulties.length - 1
                                            ? 0
                                            : 16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _openPractice(
                                          context, difficulties[i]['label']!),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceColor,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: AppTheme.borderColor,
                                              width: 1),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              difficulties[i]['label']!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: AppTheme.textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              difficulties[i]['desc']!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color:
                                                    AppTheme.textSecondaryColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
