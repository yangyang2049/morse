import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/practice_provider.dart';

class PracticePage extends StatefulWidget {
  final String difficulty;
  final Function(String) onDifficultyChanged;

  const PracticePage({
    super.key,
    required this.difficulty,
    required this.onDifficultyChanged,
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  @override
  void initState() {
    super.initState();
    // Initialize practice with current difficulty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PracticeProvider>().initializePractice(widget.difficulty);
    });
  }

  @override
  void didUpdateWidget(PracticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.difficulty != widget.difficulty) {
      context.read<PracticeProvider>().changeDifficulty(widget.difficulty);
    }
  }

  void _showPracticeRecord(
      BuildContext context, PracticeProvider practiceProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PracticeRecordDialog(practiceProvider: practiceProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticeProvider>(
      builder: (context, practiceProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // 顶部导航栏
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.white),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '练习',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showPracticeRecord(context, practiceProvider),
                            icon: const Icon(
                              Icons.description_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 主要内容区域
                    Expanded(
                      child: Column(
                        children: [
                          // 上半部分内容
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 主字符显示
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(
                                      practiceProvider.currentCharacter),
                                  tween: Tween<double>(begin: 0.7, end: 1.0),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // 进度圆环 + 内圆使用同一补间值，确保在满圈后再变绿
                                          TweenAnimationBuilder<double>(
                                            key: ValueKey<int>(
                                                practiceProvider.correctCount),
                                            tween: Tween<double>(
                                              begin: practiceProvider
                                                          .hasIncorrectAttempt &&
                                                      practiceProvider
                                                              .correctCount >
                                                          0
                                                  ? (practiceProvider
                                                              .correctCount -
                                                          1) /
                                                      2.0
                                                  : 0.0,
                                              end: practiceProvider.progress,
                                            ),
                                            duration: const Duration(
                                                milliseconds: 320),
                                            curve: Curves.easeInOutCubic,
                                            builder: (context, value, child) {
                                              // 仅当需要两次时，在满圈完成后才变绿
                                              final bool shouldTurnGreen =
                                                  practiceProvider
                                                          .hasIncorrectAttempt &&
                                                      practiceProvider
                                                              .correctCount >=
                                                          2 &&
                                                      value >= 1.0;

                                              final Color ringColor =
                                                  shouldTurnGreen
                                                      ? Colors.green
                                                      : AppTheme.accentColor;

                                              final Color innerColor =
                                                  (practiceProvider
                                                              .showResult &&
                                                          !practiceProvider
                                                              .isCorrect)
                                                      ? Colors.red
                                                      : practiceProvider
                                                              .hasIncorrectAttempt
                                                          ? (shouldTurnGreen
                                                              ? Colors.green
                                                              : AppTheme
                                                                  .accentColor)
                                                          : (practiceProvider
                                                                  .isCorrect
                                                              ? Colors.green
                                                              : AppTheme
                                                                  .accentColor);

                                              return Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 200,
                                                    height: 200,
                                                    child: CustomPaint(
                                                      painter:
                                                          RoundedProgressPainter(
                                                        progress:
                                                            practiceProvider
                                                                    .hasIncorrectAttempt
                                                                ? value
                                                                : 0.0,
                                                        strokeWidth: 8,
                                                        backgroundColor:
                                                            practiceProvider
                                                                    .hasIncorrectAttempt
                                                                ? Colors.grey
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3)
                                                                : Colors
                                                                    .transparent,
                                                        progressColor:
                                                            ringColor,
                                                      ),
                                                    ),
                                                  ),
                                                  // 内层背景圆圈 (始终显示)
                                                  Container(
                                                    width: 180,
                                                    height: 180,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: innerColor,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          // 主字符
                                          Text(
                                            practiceProvider.currentCharacter,
                                            style: const TextStyle(
                                              fontSize: 72,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 40),

                                // 用户输入显示区域 (始终占位)
                                Container(
                                  height: 60,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 占位文本 (始终存在但透明)
                                      Text(
                                        '- - -',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.transparent,
                                          fontFamily: 'monospace',
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      // 主要输入文本
                                      Text(
                                        practiceProvider.showHint ||
                                                practiceProvider
                                                    .showCorrectAnswer
                                            ? practiceProvider.currentMorse
                                                .replaceAll('.', '·')
                                            : practiceProvider.userInput
                                                .replaceAll('.', '·'),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: practiceProvider
                                                  .showCorrectAnswer
                                              ? Colors.green
                                              : practiceProvider.showHint
                                                  ? Colors.white
                                                  : practiceProvider
                                                              .showResult &&
                                                          practiceProvider
                                                              .isCorrect
                                                      ? Colors.green
                                                      : practiceProvider
                                                                  .showResult &&
                                                              !practiceProvider
                                                                  .isCorrect
                                                          ? Colors.red
                                                          : practiceProvider
                                                                  .userInput
                                                                  .isEmpty
                                                              ? Colors
                                                                  .transparent
                                                              : AppTheme
                                                                  .accentColor,
                                          fontFamily: 'monospace',
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 工具按钮 - 紧贴在按键上方
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // 收藏按钮
                                IconButton(
                                  onPressed: practiceProvider.toggleFavorite,
                                  icon: Icon(
                                    practiceProvider.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: practiceProvider.isFavorite
                                        ? Colors.red
                                        : Colors.white,
                                    size: 28,
                                  ),
                                ),
                                // 提示按钮 (眼睛)
                                IconButton(
                                  onPressed: practiceProvider.flashHint,
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                // 下一个按钮
                                IconButton(
                                  onPressed: practiceProvider.passCharacter,
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 26),

                          // 底部控制按钮 - 固定在底部
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20.0, 0.0, 20.0, 20.0),
                            child: Row(
                              children: [
                                // 点 (短音)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: practiceProvider.addDot,
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.borderColor,
                                            width: 1),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.circle_rounded,
                                          size: 20,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // 划 (长音)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: practiceProvider.addDash,
                                    child: Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.borderColor,
                                            width: 1),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 40,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.accentColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 浮动错误提示
              if (practiceProvider.showResult && !practiceProvider.isCorrect)
                Positioned(
                  bottom: 200,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '再试一次',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PracticeRecordDialog extends StatefulWidget {
  final PracticeProvider practiceProvider;

  const _PracticeRecordDialog({required this.practiceProvider});

  @override
  State<_PracticeRecordDialog> createState() => _PracticeRecordDialogState();
}

class _PracticeRecordDialogState extends State<_PracticeRecordDialog> {
  @override
  void initState() {
    super.initState();
    // Listen to provider changes
    widget.practiceProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    widget.practiceProvider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<Widget> _buildLetterChips(double itemSize) {
    final allCodes = widget.practiceProvider.currentCodes ?? [];
    final completionCount = widget.practiceProvider.completionCount;
    final hadIncorrect = widget.practiceProvider.hadIncorrectOnCompletion;

    // Build square cells that render as perfect circles
    final List<Widget> items = [];
    final double fontSize = itemSize.clamp(24.0, 56.0) * 0.4; // scale with size
    for (int j = 0; j < allCodes.length; j++) {
      final code = allCodes[j];

      final bool hasBeenPracticed =
          completionCount.containsKey(j) && completionCount[j]! > 0;
      final Color chipColor = hasBeenPracticed
          ? Colors.green.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2);
      final Color textColor = hasBeenPracticed ? Colors.green : Colors.grey;

      final bool showIncorrectBadge = hadIncorrect[j] == true;

      items.add(
        AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                  border: showIncorrectBadge
                      ? Border.all(
                          color: AppTheme.accentColor.withValues(alpha: 0.8),
                          width: 1.2,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  code.character,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Dot indicator removed per request; subtle ring remains
            ],
          ),
        ),
      );
    }

    return items;
  }

  int _getPracticedCount() {
    final completionCount = widget.practiceProvider.completionCount;
    return completionCount.values.where((count) => count > 0).length;
  }

  int _getTotalCount() {
    return widget.practiceProvider.currentCodes?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double horizontalPadding = 20;
          const int cols = 5;
          const double spacing = 8.0;

          // Effective width for the grid area (minus horizontal padding)
          final double contentWidth =
              (constraints.maxWidth - horizontalPadding * 2)
                  .clamp(0.0, double.infinity);

          final int itemCount =
              (widget.practiceProvider.currentCodes?.length ?? 0);
          // For large sets (all letters + symbols), constrain grid width and allow vertical scroll
          final bool isLargeSet = itemCount > 40;
          final double gridMaxWidth = isLargeSet
              ? (contentWidth < 360.0 ? contentWidth : 360.0)
              : contentWidth;

          // Compute item size purely from width; do not shrink by height
          final double itemSize = (gridMaxWidth - (cols - 1) * spacing) / cols;

          final maxDialogHeight = MediaQuery.of(context).size.height * 0.9;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: Container(
              padding: const EdgeInsets.all(horizontalPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题 (fixed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '练习记录',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 可滚动的字母/数字网格区域（仅此部分滚动）
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: gridMaxWidth,
                        child: GridView.count(
                          crossAxisCount: cols,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1.0,
                          children: _buildLetterChips(itemSize),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 统计信息（固定）
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_getPracticedCount()}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '已练习',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_getTotalCount()}',
                              style: const TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              '总数',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RoundedProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  RoundedProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const startAngle = -90 * 3.14159 / 180; // 从顶部开始
      final sweepAngle = 2 * 3.14159 * progress; // 进度角度

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RoundedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
