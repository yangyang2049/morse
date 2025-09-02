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

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in difficulties) ...[
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                item['label']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              subtitle: Text(
                                item['desc']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppTheme.textSecondaryColor),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () =>
                                  _openPractice(context, item['label']!),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
