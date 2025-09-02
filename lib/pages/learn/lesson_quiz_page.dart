import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../widgets/explanation_tips_card.dart';

class LessonQuizPage extends StatefulWidget {
  final String testType; // 'intro' 或 'chinese'
  final String pageTitle;
  final String testCompletedKey;

  const LessonQuizPage({
    super.key,
    required this.testType,
    required this.pageTitle,
    required this.testCompletedKey,
  });

  @override
  State<LessonQuizPage> createState() => _LessonQuizPageState();
}

class _LessonQuizPageState extends State<LessonQuizPage> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  int? selectedAnswer;
  bool showResult = false;
  bool showExplanation = false;

  late final List<Map<String, dynamic>> questions;
  late final List<Map<String, dynamic>> explanations;

  @override
  void initState() {
    super.initState();
    _initializeTestData();
  }

  void _initializeTestData() {
    if (widget.testType == 'intro') {
      questions = [
        {
          'type': 'true_false',
          'question': '摩斯密码是以"点（·）和划（-）"为基本元素的字符编码系统。',
          'answer': true,
          'points': 20,
        },
        {
          'type': 'true_false',
          'question': 'SOS信号的摩斯密码是 ··· --- ···，各字符之间需要保持正常的字符间隔。',
          'answer': false, // SOS是紧凑发送，无字符间隔
          'points': 20,
        },
        {
          'type': 'multiple_choice',
          'question': '摩斯密码的时序规则中，点、划、字符间隔的单位比例是：',
          'options': ['1:2:5', '1:3:7', '1:4:8', '2:3:6'],
          'answer': 1, // 1:3:7
          'points': 20,
        },
        {
          'type': 'multiple_choice',
          'question': '摩斯密码是在哪个年代开发的？',
          'options': ['1820年代', '1830-1840年代', '1850年代', '1860年代'],
          'answer': 1, // 1830-1840年代
          'points': 20,
        },
        {
          'type': 'multiple_choice',
          'question': '学习摩斯密码的建议顺序是：',
          'options': ['数字 → 字母 → 符号', '符号 → 字母 → 数字', '字母 → 数字 → 符号', '随机学习'],
          'answer': 2, // 字母→数字→符号
          'points': 20,
        },
      ];

      explanations = [
        {
          'title': '摩斯密码基本元素',
          'content': '• 摩斯密码以"点（·）和划（-）"为基本元素\n'
              '• 通过不同的点划组合表示字母、数字和符号\n'
              '• 这是所有摩斯密码的基础，必须熟练掌握',
        },
        {
          'title': 'SOS信号的特殊性',
          'content': '• SOS是紧急求救信号，需要快速识别\n'
              '• 紧凑发送：三个字符（··· --- ···）是紧凑发送的，没有正常的字符间隔\n'
              '• 标准间隔规则：正常情况下，摩斯密码字符之间应该有3个单位的间隔\n'
              '• SOS例外：但SOS作为紧急信号，会忽略这个规则，紧凑发送以提高识别速度',
        },
        {
          'title': '时序规则的重要性',
          'content': '• 1:3:7比例是摩斯密码的核心规则\n'
              '• 点=1单位，划=3单位，字符间隔=3单位，单词间隔=7单位\n'
              '• 这个精确的时序确保了信息传输的准确性和可读性',
        },
        {
          'title': '历史背景',
          'content': '• 塞缪尔·摩斯与阿尔弗雷德·韦尔在1830-1840年代合作开发\n'
              '• 最初用于电报系统，后来演化为国际摩斯密码\n'
              '• 成为全球标准的无线电通信编码系统',
        },
        {
          'title': '学习策略',
          'content': '• 字母 → 数字 → 符号的学习顺序最科学\n'
              '• 先掌握基础字母，再学习数字和符号\n'
              '• 循序渐进，避免信息过载，提高学习效率',
        },
      ];
    } else {
      // chinese
      questions = [
        {
          'type': 'true_false',
          'question': '中文摩尔斯电码是专门为中文汉字设计的摩尔斯电码系统。',
          'answer': true,
          'points': 20,
        },
        {
          'type': 'true_false',
          'question': '中文摩尔斯电码的编码长度通常比英文摩尔斯电码短。',
          'answer': false, // 中文编码通常更长
          'points': 20,
        },
        {
          'type': 'multiple_choice',
          'question': '中文摩尔斯电码是在哪个年代开始制定的？',
          'options': ['1900年代', '1920年代', '1950年代', '1980年代'],
          'answer': 1, // 1920年代
          'points': 20,
        },
        {
          'type': 'multiple_choice',
          'question': '以下哪个不是中文摩尔斯电码的应用场景？',
          'options': ['军事通信', '航空通信', '网络聊天', '航海通信'],
          'answer': 2, // 网络聊天
          'points': 20,
        },
        {
          'type': 'multiple_choice',
          'question': '学习中文摩尔斯电码的建议顺序是：',
          'options': ['从复杂汉字开始', '从基础汉字开始', '随机学习', '从标点符号开始'],
          'answer': 1, // 从基础汉字开始
          'points': 20,
        },
      ];

      explanations = [
        {
          'title': '中文摩尔斯电码的定义',
          'content': '• 中文摩尔斯电码是专门为中文汉字设计的编码系统\n'
              '• 通过点（·）和划（-）的组合表示中文字符\n'
              '• 结合了传统摩尔斯电码原理和中文语言特点\n'
              '• 为中文通信提供了标准化的编码方案',
        },
        {
          'title': '编码长度的特点',
          'content': '• 中文摩尔斯电码的编码通常比英文更长\n'
              '• 这是因为中文字符数量庞大，需要更多点划组合\n'
              '• 每个汉字都有唯一的摩尔斯电码表示\n'
              '• 编码长度增加是为了确保字符的唯一性',
        },
        {
          'title': '历史发展背景',
          'content': '• 1920年代：初步制定中文摩尔斯电码标准\n'
              '• 当时为了适应中文电报通信的需求\n'
              '• 国际电信联盟（ITU）参与制定\n'
              '• 经过多次优化形成现代标准',
        },
        {
          'title': '应用场景分析',
          'content': '• 军事通信：部队间的秘密通信\n'
              '• 航空通信：飞行员与地面控制塔通信\n'
              '• 航海通信：船舶间通信\n'
              '• 网络聊天不属于传统应用场景',
        },
        {
          'title': '学习策略建议',
          'content': '• 从基础汉字开始学习最科学\n'
              '• 基础汉字使用频率高，容易记忆\n'
              '• 循序渐进，避免信息过载\n'
              '• 建立学习信心，提高学习效率',
        },
      ];
    }
  }

  void _selectAnswer(dynamic answer) {
    if (isAnswered) return;

    setState(() {
      selectedAnswer = answer is bool ? (answer ? 1 : 0) : answer;
      isAnswered = true;
    });

    // 检查答案
    bool isCorrect = false;
    if (questions[currentQuestionIndex]['type'] == 'true_false') {
      bool correctAnswer = questions[currentQuestionIndex]['answer'];
      isCorrect = (answer == correctAnswer);
    } else {
      int correctAnswer = questions[currentQuestionIndex]['answer'];
      isCorrect = (answer == correctAnswer);
    }

    if (isCorrect) {
      score += questions[currentQuestionIndex]['points'] as int;
    }

    // 显示解释卡片
    setState(() {
      showExplanation = true;
    });
  }

  void _showResult() {
    setState(() {
      showResult = true;
    });

    if (score >= 100) {
      _markTestCompleted();
    }
  }

  Future<void> _markTestCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.testCompletedKey, true);
  }

  void _restartTest() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      isAnswered = false;
      selectedAnswer = null;
      showResult = false;
      showExplanation = false;
    });
  }

  void _goToNextLesson() {
    // 下一课：返回主界面，由主界面负责解锁逻辑
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    if (showResult) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('测试结果'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score >= 100 ? '👏' : '😢',
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  '你的分数',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 128,
                    fontWeight: FontWeight.bold,
                    color: score >= 100 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Text(
                      score >= 100 ? '🎉 恭喜通过！' : '继续努力！',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.5,
                      ),
                    ),
                    if (score >= 100) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '你已经掌握了摩斯密码的基础知识',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (score < 100) ...[
                      const SizedBox(height: 8),
                      Text(
                        '需要100分才能通过测试',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text(
                          '返回',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    if (score >= 100) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _goToNextLesson,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(
                            '下一课',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _restartTest,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            '重新测试',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('基础测试'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, isSmallScreen ? 8 : 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 得分显示移到右上角
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '当前得分: $score',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 32),

                // 问题卡片
                Container(
                  width: double.infinity,
                  height: 160, // 固定高度
                  padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange[50]!,
                        Colors.orange[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange[100]!.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      currentQuestion['question'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 32),

                // 答案选项
                if (currentQuestion['type'] == 'true_false') ...[
                  _buildTrueFalseOptions(isSmallScreen),
                ] else ...[
                  _buildMultipleChoiceOptions(
                    currentQuestion['options'] as List<String>,
                    isSmallScreen,
                  ),
                ],

                // 解释卡片
                if (isAnswered && showExplanation) ...[
                  SizedBox(height: isSmallScreen ? 12 : 24),
                  _buildExplanationCard(currentQuestionIndex),
                ],
              ],
            ),
          ),

          // 浮动在底部的下一题按钮
          if (isAnswered)
            Positioned(
              bottom: isSmallScreen ? 24 : 40,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: () {
                  if (currentQuestionIndex < questions.length - 1) {
                    setState(() {
                      currentQuestionIndex++;
                      isAnswered = false;
                      selectedAnswer = null;
                      showExplanation = false;
                    });
                  } else {
                    _showResult();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    currentQuestionIndex < questions.length - 1
                        ? '下一题'
                        : '查看结果',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(int questionIndex) {
    final explanation = explanations[questionIndex];

    return ExplanationTipsCard(
      title: explanation['title'] as String,
      content: explanation['content'] as String,
      color: Colors.orange,
    );
  }

  Widget _buildTrueFalseOptions(bool isSmall) {
    return Column(
      children: [
        _buildAnswerButton(
          text: '正确',
          value: true,
          isSelected: selectedAnswer == 1,
          isCorrect:
              isAnswered && questions[currentQuestionIndex]['answer'] == true,
          isWrong: isAnswered &&
              selectedAnswer == 1 &&
              questions[currentQuestionIndex]['answer'] != true,
          verticalPadding: isSmall ? 12 : 16,
        ),
        SizedBox(height: isSmall ? 10 : 16),
        _buildAnswerButton(
          text: '错误',
          value: false,
          isSelected: selectedAnswer == 0,
          isCorrect:
              isAnswered && questions[currentQuestionIndex]['answer'] == false,
          isWrong: isAnswered &&
              selectedAnswer == 0 &&
              questions[currentQuestionIndex]['answer'] != false,
          verticalPadding: isSmall ? 12 : 16,
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceOptions(List<String> options, bool isSmall) {
    // 如果已答题且显示解释卡片，只显示正确答案和用户选择的错误答案
    if (isAnswered && showExplanation) {
      final correctAnswer = questions[currentQuestionIndex]['answer'] as int;
      final userAnswer = selectedAnswer;

      List<MapEntry<int, String>> filteredOptions = [];

      // 总是显示正确答案
      filteredOptions.add(MapEntry(correctAnswer, options[correctAnswer]));

      // 如果用户选择了错误答案，也显示它
      if (userAnswer != null && userAnswer != correctAnswer) {
        filteredOptions.add(MapEntry(userAnswer, options[userAnswer]));
      }

      return Column(
        children: filteredOptions.map((entry) {
          int index = entry.key;
          String option = entry.value;

          return Padding(
            padding: EdgeInsets.only(bottom: isSmall ? 10 : 16),
            child: _buildAnswerButton(
              text: option,
              value: index,
              isSelected: selectedAnswer == index,
              isCorrect: questions[currentQuestionIndex]['answer'] == index,
              isWrong: selectedAnswer == index &&
                  questions[currentQuestionIndex]['answer'] != index,
              verticalPadding: isSmall ? 12 : 16,
            ),
          );
        }).toList(),
      );
    }

    // 正常显示所有选项
    return Column(
      children: options.asMap().entries.map((entry) {
        int index = entry.key;
        String option = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: isSmall ? 10 : 16),
          child: _buildAnswerButton(
            text: option,
            value: index,
            isSelected: selectedAnswer == index,
            isCorrect: isAnswered &&
                questions[currentQuestionIndex]['answer'] == index,
            isWrong: isAnswered &&
                selectedAnswer == index &&
                questions[currentQuestionIndex]['answer'] != index,
            verticalPadding: isSmall ? 12 : 16,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnswerButton({
    required String text,
    required dynamic value,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    double verticalPadding = 16,
  }) {
    Color backgroundColor = Colors.grey[100]!;
    Color textColor = Colors.black87;
    Color borderColor = Colors.grey[300]!;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        borderColor = Colors.green;
      } else if (isWrong) {
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = AppTheme.primaryColor.withAlpha(25);
      textColor = AppTheme.primaryColor;
      borderColor = AppTheme.primaryColor;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _selectAnswer(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 2),
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
