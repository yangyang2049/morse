import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../models/morse_code.dart';
import '../../theme/app_theme.dart';

class FullscreenLessonPage extends StatefulWidget {
  final String title;
  final List<MorseCode> codes;
  final String? lessonId; // 课程ID，用于保存完成状态

  const FullscreenLessonPage({
    super.key,
    required this.title,
    required this.codes,
    this.lessonId,
  });

  @override
  State<FullscreenLessonPage> createState() => _FullscreenLessonPageState();
}

class _FullscreenLessonPageState extends State<FullscreenLessonPage> {
  int currentIndex = 0;
  PageController pageController = PageController();
  final ScrollController _letterScrollController = ScrollController();
  bool showMorseCode = true; // 控制是否显示摩斯电码
  String userInput = ''; // 用户输入的摩斯电码
  Timer? _checkTimer; // 自动检查计时器
  Map<int, int> _completionCount = {}; // 每个字母的完成次数
  bool _isCorrect = false; // 当前输入是否正确
  bool _showResult = false; // 是否显示结果
  Map<int, bool> _hintRevealed = {}; // 复习课中每个字母的提示是否已显示

  @override
  void initState() {
    super.initState();
    // 延迟执行初始滚动，确保widget已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLetter();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    pageController.dispose();
    _letterScrollController.dispose();
    super.dispose();
  }

  void _addDot() {
    // 添加轻微震动反馈
    Vibration.vibrate(duration: 50);
    setState(() {
      userInput += '.';
      _showResult = false;
    });
    _startAutoCheck();
  }

  void _addDash() {
    // 添加稍长的震动反馈
    Vibration.vibrate(duration: 100);
    setState(() {
      userInput += '-';
      _showResult = false;
    });
    _startAutoCheck();
  }

  void _clearInput() {
    _checkTimer?.cancel();
    setState(() {
      userInput = '';
      _showResult = false;
      _isCorrect = false;
    });
  }

  bool _shouldShowHint(int index) {
    final bool isReviewLesson = widget.codes.length > 10; // 复习课：超过10个字符
    if (isReviewLesson) {
      // 复习课：默认隐藏提示，只有在出错后才显示
      return _hintRevealed[index] ?? false;
    } else {
      // 普通课程：使用原来的显示逻辑
      return showMorseCode;
    }
  }

  void _scrollToCurrentLetter() {
    if (widget.codes.length <= 8) return; // 不需要滚动少于8个字母的情况

    // 复习课使用更小的间距
    final bool isReviewLesson = widget.codes.length > 10;
    final double letterWidth = isReviewLesson ? 24.0 : 36.0; // 复习课使用更小的宽度
    final double screenWidth = MediaQuery.of(context).size.width;
    final double centerOffset = screenWidth / 2 - letterWidth / 2;
    final double targetOffset = (currentIndex * letterWidth - centerOffset)
        .clamp(
            0.0,
            (widget.codes.length * letterWidth - screenWidth)
                .clamp(0.0, double.infinity));

    _letterScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startAutoCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer(const Duration(milliseconds: 800), () {
      _checkAnswer();
    });
  }

  void _checkAnswer() {
    final currentCode = widget.codes[currentIndex];
    final isCorrect = userInput == currentCode.morse;
    final bool isReviewLesson = widget.codes.length > 10;
    final int requiredCompletions = isReviewLesson ? 2 : 5;

    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
    });

    if (isCorrect) {
      // 增加完成次数
      _completionCount[currentIndex] =
          (_completionCount[currentIndex] ?? 0) + 1;

      // 检查是否完成所需次数
      if (_completionCount[currentIndex]! >= requiredCompletions) {
        Timer(const Duration(milliseconds: 1000), () {
          _moveToNext();
        });
      } else {
        // 1秒后清空输入，继续练习当前字母
        Timer(const Duration(milliseconds: 1000), () {
          _clearInput();
        });
      }
    } else {
      // 复习课：错误时显示提示
      if (isReviewLesson) {
        _hintRevealed[currentIndex] = true;
      }

      // 错误时1.5秒后清空输入
      Timer(const Duration(milliseconds: 1500), () {
        _clearInput();
      });
    }
  }

  void _moveToNext() {
    if (currentIndex < widget.codes.length - 1) {
      setState(() {
        currentIndex++;
        userInput = '';
        _showResult = false;
        _isCorrect = false;
      });
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 所有字母都完成了
      _showCompletionDialog();
    }
  }

  Future<void> _markLessonCompleted() async {
    if (widget.lessonId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.lessonId}_completed', true);
    }
  }

  void _showCompletionDialog() {
    // 标记课程为已完成
    _markLessonCompleted();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.green, width: 2),
        ),
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 成功图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '恭喜完成！',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // 统计信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '${widget.codes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '字母',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.borderColor,
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.codes.length * 5}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '练习次数',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondaryColor,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '返回',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 重新开始学习
                    setState(() {
                      currentIndex = 0;
                      _completionCount.clear();
                      userInput = '';
                      _showResult = false;
                      _isCorrect = false;
                    });
                    pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '再次练习',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor, // 使用应用主题背景色
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
                          child: widget.codes.length > 10
                              ? SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    controller: _letterScrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: widget.codes.length,
                                    itemBuilder: (context, index) {
                                      final isActive = index == currentIndex;
                                      final completionCount =
                                          _completionCount[index] ?? 0;
                                      final int requiredCompletions = 2;
                                      final isCompleted = completionCount >=
                                          requiredCompletions;

                                      return Container(
                                        width: 24,
                                        alignment: Alignment.center,
                                        child: Text(
                                          widget.codes[index].character,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? Colors.green
                                                : isActive
                                                    ? AppTheme.accentColor
                                                    : Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.codes.length,
                                      (index) {
                                        final isActive = index == currentIndex;
                                        final completionCount =
                                            _completionCount[index] ?? 0;
                                        final int requiredCompletions = 5;
                                        final isCompleted = completionCount >=
                                            requiredCompletions;

                                        return Container(
                                          width: 36,
                                          alignment: Alignment.center,
                                          child: Text(
                                            widget.codes[index].character,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isCompleted
                                                  ? Colors.green
                                                  : isActive
                                                      ? AppTheme.accentColor
                                                      : Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                        IconButton(
                          onPressed: widget.codes.length > 10
                              ? null
                              : () {
                                  setState(() {
                                    showMorseCode = !showMorseCode;
                                  });
                                },
                          icon: Icon(
                            showMorseCode
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: widget.codes.length > 10
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 主要内容区域
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                          userInput = ''; // 切换页面时清空输入
                        });
                        _scrollToCurrentLetter();
                      },
                      itemCount: widget.codes.length,
                      itemBuilder: (context, index) {
                        final code = widget.codes[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 大圆圈显示字符带进度条
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // 圆形进度条带动画
                                SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: (_completionCount[index] ?? 0) /
                                          (widget.codes.length > 10
                                              ? 2.0
                                              : 5.0),
                                    ),
                                    builder: (context, value, child) {
                                      return CustomPaint(
                                        size: const Size(220, 220),
                                        painter: RoundedProgressPainter(
                                          progress: value,
                                          strokeWidth: 8,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.2),
                                          progressColor: value >= 1.0
                                              ? Colors.green
                                              : AppTheme.accentColor,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // 内部圆圈
                                TweenAnimationBuilder<Color?>(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  tween: ColorTween(
                                    begin: AppTheme.accentColor,
                                    end: (_completionCount[index] ?? 0) >=
                                            (widget.codes.length > 10 ? 2 : 5)
                                        ? Colors.green
                                        : AppTheme.accentColor,
                                  ),
                                  builder: (context, color, child) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          code.character,
                                          style: TextStyle(
                                            fontSize: 80,
                                            fontWeight: FontWeight.bold,
                                            color: (_completionCount[index] ??
                                                        0) >=
                                                    (widget.codes.length > 10
                                                        ? 2
                                                        : 5)
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 60),

                            // 摩斯电码显示
                            Container(
                              height: 80,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                maxWidth: 150,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _shouldShowHint(index)
                                      ? code.morse.replaceAll('.', '·')
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _shouldShowHint(index)
                                        ? AppTheme.textColor
                                        : AppTheme.textSecondaryColor,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 用户输入显示区域
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
                                  // 主要输入文本
                                  Text(
                                    userInput.replaceAll('.', '·'),
                                    style: TextStyle(
                                      fontSize: 36, // 大字体
                                      fontWeight: FontWeight.bold,
                                      color: _showResult && _isCorrect
                                          ? Colors.green
                                          : userInput.isEmpty
                                              ? Colors.transparent
                                              : AppTheme.accentColor,
                                      fontFamily: 'monospace',
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  // 浮动的错误文本
                                  if (_showResult && !_isCorrect)
                                    Positioned(
                                      top: 0,
                                      child: Text(
                                        userInput.replaceAll('.', '·'),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontFamily: 'monospace',
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 底部控制按钮
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // 点 (短音)
                        Expanded(
                          child: GestureDetector(
                            onTap: _addDot,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.borderColor, width: 1),
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
                            onTap: _addDash,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.borderColor, width: 1),
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
            // 屏幕级浮动错误提示
            if (_showResult && !_isCorrect)
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
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
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
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
        ));
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
