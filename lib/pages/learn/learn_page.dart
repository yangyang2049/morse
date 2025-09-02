import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/morse_code.dart';
import '../../theme/app_theme.dart';

import 'fullscreen_lesson_page.dart';
import '../../data/lesson_data.dart';
import 'lesson_page.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final ScrollController _hScrollController = ScrollController();
  GlobalKey? _targetLessonKey;
  int? _targetUnitIdx;
  int? _targetLessonIdx;
  final Map<String, bool> _unitUnlocked = {
    'intro': true,
    'alphabet': false,
    'numbers': false,
    'punctuation': false,
    'words': false,
  };

  bool _introCompleted = false;
  bool _chineseCompleted = false;
  bool _introTestCompleted = false;
  bool _chineseTestCompleted = false;

  // 字母课程完成状态
  Map<String, bool> _alphabetLessonsCompleted = {};
  // 数字课程完成状态
  Map<String, bool> _numberLessonsCompleted = {};
  // 符号课程完成状态
  Map<String, bool> _punctuationLessonsCompleted = {};
  // 单词课程完成状态
  Map<String, bool> _wordLessonsCompleted = {};

  @override
  void initState() {
    super.initState();
    _loadUnlockState();
  }

  Future<void> _loadUnlockState() async {
    final prefs = await SharedPreferences.getInstance();
    final introCompleted = prefs.getBool('intro_completed') ?? false;
    final chineseCompleted = prefs.getBool('chinese_completed') ?? false;
    final introTestCompleted = prefs.getBool('intro_test_completed') ?? false;
    final chineseTestCompleted =
        prefs.getBool('chinese_test_completed') ?? false;

    // 加载字母课程完成状态
    final alphabetLessonsCompleted = <String, bool>{};
    for (int i = 0; i < 9; i++) {
      final lessonId = 'alphabet_lesson_$i';
      alphabetLessonsCompleted[lessonId] =
          prefs.getBool('${lessonId}_completed') ?? false;
    }

    // 加载数字课程完成状态
    final numberLessonsCompleted = <String, bool>{};
    for (int i = 0; i < 4; i++) {
      final lessonId = 'number_lesson_$i';
      numberLessonsCompleted[lessonId] =
          prefs.getBool('${lessonId}_completed') ?? false;
    }

    // 加载符号课程完成状态
    final punctuationLessonsCompleted = <String, bool>{};
    for (int i = 0; i < 3; i++) {
      final lessonId = 'punctuation_lesson_$i';
      punctuationLessonsCompleted[lessonId] =
          prefs.getBool('${lessonId}_completed') ?? false;
    }

    // 加载单词课程完成状态
    final wordLessonsCompleted = <String, bool>{};
    for (int i = 0; i < 3; i++) {
      final lessonId = 'word_lesson_$i';
      wordLessonsCompleted[lessonId] =
          prefs.getBool('${lessonId}_completed') ?? false;
    }

    // 检查各单元的完成状态
    final isIntroUnitCompleted = introCompleted &&
        chineseCompleted &&
        introTestCompleted &&
        chineseTestCompleted;

    final isAlphabetUnitCompleted =
        alphabetLessonsCompleted.values.every((completed) => completed);

    final isNumberUnitCompleted =
        numberLessonsCompleted.values.every((completed) => completed);

    setState(() {
      _introCompleted = introCompleted;
      _chineseCompleted = chineseCompleted;
      _introTestCompleted = introTestCompleted;
      _chineseTestCompleted = chineseTestCompleted;
      _alphabetLessonsCompleted = alphabetLessonsCompleted;
      _numberLessonsCompleted = numberLessonsCompleted;
      _punctuationLessonsCompleted = punctuationLessonsCompleted;
      _wordLessonsCompleted = wordLessonsCompleted;

      // 单元解锁逻辑：当前单元完成后解锁下一单元
      _unitUnlocked['alphabet'] = isIntroUnitCompleted;
      _unitUnlocked['numbers'] = isAlphabetUnitCompleted;
      // 数字单元完成后同时解锁符号和单词单元
      _unitUnlocked['punctuation'] = isNumberUnitCompleted;
      _unitUnlocked['words'] = isNumberUnitCompleted;
    });

    // 计算目标单元和课次，并在构建后滚动到位
    _computeTargetUnitAndLesson();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetUnitAndLesson();
    });
  }

  int _computeTargetUnitIndex() {
    // 单元顺序: 0 基础(两课), 1 字母, 2 数字, 3 符号, 4 单词
    // 如果基础未完成或测试未通过，停留在基础单元
    if (!_introCompleted ||
        !_introTestCompleted ||
        !_chineseCompleted ||
        !_chineseTestCompleted) {
      return 0;
    }

    // 如果字母单元未解锁或未完成，跳到字母单元
    if (!_unitUnlocked['numbers']!) {
      return 1;
    }

    // 如果数字单元未解锁或未完成，跳到数字单元
    if (!_unitUnlocked['punctuation']! || !_unitUnlocked['words']!) {
      return 2;
    }

    // 数字完成后，符号和单词都解锁，优先跳到符号单元
    final isPunctuationCompleted =
        _punctuationLessonsCompleted.values.every((completed) => completed);
    final isWordCompleted =
        _wordLessonsCompleted.values.every((completed) => completed);

    if (!isPunctuationCompleted) {
      return 3; // 符号单元
    } else if (!isWordCompleted) {
      return 4; // 单词单元
    }

    // 都完成了，停留在单词单元
    return 4;
  }

  // 构造一个不可见但占位的课程卡片，用于对齐
  Widget _buildPlaceholderLessonCard() {
    return Opacity(
      opacity: 0.0,
      child: _buildLockableLessonCard(
        title: '占位',
        subtitle: null,
        onTap: () {},
        isUnlocked: false,
        unitUnlocked: false,
        isCompleted: false,
      ),
    );
  }

  // 若不足4项，补齐至4项以保持顶部对齐的一致高度
  List<Widget> _padToFour(List<Widget> items) {
    final list = List<Widget>.from(items);
    while (list.length < 4) {
      list.add(_buildPlaceholderLessonCard());
    }
    return list;
  }

  void _computeTargetUnitAndLesson() {
    final unitIdx = _computeTargetUnitIndex();
    int? lessonIdx;

    if (unitIdx == 0) {
      // 基础单元：两课，按测验通过情况定位
      if (!_introTestCompleted) {
        lessonIdx = 0;
      } else if (!_chineseTestCompleted) {
        lessonIdx = 1;
      }
    } else if (unitIdx == 1) {
      // 字母：9课，定位到第一节未完成
      for (int i = 0; i < 9; i++) {
        if (!(_alphabetLessonsCompleted['alphabet_lesson_$i'] ?? false)) {
          lessonIdx = i;
          break;
        }
      }
    } else if (unitIdx == 2) {
      // 数字：4课
      for (int i = 0; i < 4; i++) {
        if (!(_numberLessonsCompleted['number_lesson_$i'] ?? false)) {
          lessonIdx = i;
          break;
        }
      }
    } else if (unitIdx == 3) {
      // 符号：3课
      for (int i = 0; i < 3; i++) {
        if (!(_punctuationLessonsCompleted['punctuation_lesson_$i'] ?? false)) {
          lessonIdx = i;
          break;
        }
      }
    } else if (unitIdx == 4) {
      // 单词：3课
      for (int i = 0; i < 3; i++) {
        if (!(_wordLessonsCompleted['word_lesson_$i'] ?? false)) {
          lessonIdx = i;
          break;
        }
      }
    }

    setState(() {
      _targetUnitIdx = unitIdx;
      _targetLessonIdx = lessonIdx;
      _targetLessonKey = lessonIdx != null ? GlobalKey() : null;
    });
  }

  Future<void> _scrollToTargetUnitAndLesson() async {
    final targetIndex = _targetUnitIdx ?? 0;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double cardWidth = isTablet ? 420.0 : 320.0;
    const gap = 16.0; // 右侧间距
    const outerPadding = 16.0; // Row 外层水平 padding
    final maxExtent = _hScrollController.hasClients
        ? _hScrollController.position.maxScrollExtent
        : 0.0;
    final offset =
        (targetIndex * (cardWidth + gap) + outerPadding).clamp(0.0, maxExtent);
    if (_hScrollController.hasClients) {
      await _hScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }

    // 再滚动到课卡片（如果有）
    if (_targetLessonKey?.currentContext != null) {
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        await Scrollable.ensureVisible(
          _targetLessonKey!.currentContext!,
          alignment: 0.1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        // ignore
      }
    }
  }

  List<List<MorseCode>> _alphabetGroups() {
    const a = MorseCodeData.englishAlphabet;
    return [
      a.sublist(0, 3), // 3 - ABC
      a.sublist(3, 6), // 3 - DEF
      a.sublist(6, 10), // 4 - GHIJ
      a.sublist(0, 10), // 10 - 复习课：前10个字母 (A-J)
      a.sublist(10, 14), // 4 - KLMN
      a.sublist(14, 18), // 4 - OPQR
      a.sublist(18, 22), // 4 - STUV
      a.sublist(22, 26), // 4 - WXYZ
      a.sublist(10, 26), // 16 - 复习课：后16个字母 (K-Z)
    ];
  }

  Widget _buildLockableLessonCard({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isUnlocked,
    required bool unitUnlocked,
    bool isCompleted = false,
  }) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return Card(
      elevation: 1, // Reduced elevation
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isUnlocked
                                      ? AppTheme.textColor
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 22 : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isUnlocked
                                  ? AppTheme.textSecondaryColor
                                  : Colors.grey[500],
                              fontSize: isTablet ? 16 : null,
                            ),
                      ),
                    ],
                    // Removed inline unlock hint text per request
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                )
              else if (isUnlocked)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                )
              else if (unitUnlocked)
                Icon(
                  Icons.lock_rounded,
                  color: Colors.grey[500],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard({
    required String title,
    required List<Widget> lessons,
    required bool isUnlocked,
    required int unitNumber,
  }) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double titleFont = isTablet ? 40 : 32;
    final double bigNumFont = isTablet ? 96 : 80;
    return Card(
      elevation: 1, // Reduced elevation
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Big faded number at bottom right
            Positioned(
              bottom: 0,
              right: 0,
              child: Text(
                '$unitNumber',
                style: TextStyle(
                  fontSize: bigNumFont,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.withValues(alpha: 0.1),
                  height: 0.8,
                ),
              ),
            ),
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w900,
                                fontSize: titleFont,
                              ),
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Icon(
                        Icons.lock_rounded,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: lessons
                          .map((lesson) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Opacity(
                                  opacity: isUnlocked ? 1.0 : 0.45,
                                  child: lesson,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alphabetLessons = _alphabetGroups();

    // 重新分组数字课程为4组: 123, 456, 7890, 复习课
    final numberLessons4 = <List<MorseCode>>[];
    if (MorseCodeData.numbers.isNotEmpty &&
        MorseCodeData.numbers.length >= 10) {
      // 第1课: 1, 2, 3
      numberLessons4.add(MorseCodeData.numbers.sublist(0, 3));
      // 第2课: 4, 5, 6
      numberLessons4.add(MorseCodeData.numbers.sublist(3, 6));
      // 第3课: 7, 8, 9, 0
      numberLessons4.add(MorseCodeData.numbers.sublist(6, 10));
      // 第4课: 复习课 - 所有数字
      numberLessons4.add(MorseCodeData.numbers);
    }

    // 重新分组符号课程为3组
    final punctLessons3 = <List<MorseCode>>[];
    if (MorseCodeData.punctuation.isNotEmpty) {
      final totalPunct = MorseCodeData.punctuation.length;
      final itemsPerLesson = (totalPunct / 3).ceil();

      for (int i = 0; i < 3; i++) {
        final start = i * itemsPerLesson;
        final end = (i + 1) * itemsPerLesson;
        if (start < totalPunct) {
          punctLessons3.add(MorseCodeData.punctuation
              .sublist(start, end > totalPunct ? totalPunct : end));
        }
      }
    }

    final units = <Widget>[
      // 摩斯密码基础（包含两节课）
      _buildUnitCard(
        title: '摩斯密码基础',
        lessons: _padToFour([
          // 第1课
          KeyedSubtree(
            key: (_targetUnitIdx == 0 && _targetLessonIdx == 0)
                ? _targetLessonKey
                : null,
            child: _buildLockableLessonCard(
              title: '第1课：摩斯密码基础',
              subtitle: '点划、间隔、历史与应用',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (_) => LessonPage(
                      title: '摩斯密码基础',
                      sections: LessonData.introSections,
                      testType: 'intro',
                      testTitle: '基础知识测试',
                      testCompletedKey: 'intro_test_completed',
                      lessonCompletedKey: 'intro_completed',
                      customSectionBuilders:
                          LessonData.getIntroCustomBuilders(context),
                    ),
                  ))
                  .then((_) => _loadUnlockState()),
              isUnlocked: true,
              unitUnlocked: true,
              isCompleted: _introCompleted && _introTestCompleted,
            ),
          ),
          // 第2课
          KeyedSubtree(
            key: (_targetUnitIdx == 0 && _targetLessonIdx == 1)
                ? _targetLessonKey
                : null,
            child: _buildLockableLessonCard(
              title: '第2课：中文摩尔斯电码',
              subtitle: '汉字编码、标点符号、应用场景',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LessonPage(
                  title: '中文摩尔斯电码',
                  sections: LessonData.chineseSections,
                  testType: 'chinese',
                  testTitle: '中文摩尔斯电码测验',
                  testCompletedKey: 'chinese_test_completed',
                  lessonCompletedKey: 'chinese_completed',
                  customSectionBuilders:
                      LessonData.getChineseCustomBuilders(context),
                ),
              )),
              // 解锁条件：第一课测验通过（100分）
              isUnlocked: _introTestCompleted,
              unitUnlocked: true,
              isCompleted: _chineseCompleted && _chineseTestCompleted,
            ),
          ),
        ]),
        isUnlocked: true,
        unitNumber: 1,
      ),

      _buildUnitCard(
        title: '字母',
        lessons: List.generate(alphabetLessons.length, (i) {
          final lessonId = 'alphabet_lesson_$i';
          final isCompleted = _alphabetLessonsCompleted[lessonId] ?? false;

          String title;
          String subtitle;

          if (i == 3) {
            title = '第${i + 1}课：复习';
            subtitle = '前10个字母 A-J';
          } else if (i == 8) {
            title = '第${i + 1}课：复习';
            subtitle = '后16个字母 K-Z';
          } else {
            title = '第${i + 1}课';
            subtitle = alphabetLessons[i].map((e) => e.character).join('  ');
          }

          // Lesson unlocking: first lesson unlocked when unit is unlocked; subsequent lessons require previous lesson completion
          final bool baseUnitUnlocked = _unitUnlocked['alphabet'] == true;
          final bool prevCompleted = i == 0
              ? true
              : (_alphabetLessonsCompleted['alphabet_lesson_${i - 1}'] ??
                  false);
          final bool lessonUnlocked = baseUnitUnlocked && prevCompleted;

          final card = _buildLockableLessonCard(
            title: title,
            subtitle: subtitle,
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenLessonPage(
                      title: title,
                      codes: alphabetLessons[i],
                      lessonId: lessonId,
                    ),
                  ),
                )
                .then((_) => _loadUnlockState()), // 返回时重新加载状态
            isUnlocked: lessonUnlocked,
            unitUnlocked: baseUnitUnlocked,
            isCompleted: isCompleted,
          );
          if (_targetUnitIdx == 1 &&
              _targetLessonIdx == i &&
              _targetLessonKey != null) {
            return KeyedSubtree(key: _targetLessonKey, child: card);
          }
          return card;
        }),
        isUnlocked: _unitUnlocked['alphabet'] == true,
        unitNumber: 2,
      ),

      _buildUnitCard(
        title: '数字',
        lessons: _padToFour(List.generate(numberLessons4.length, (i) {
          final lessonId = 'number_lesson_$i';
          final isCompleted = _numberLessonsCompleted[lessonId] ?? false;
          final isReviewLesson = i == 3; // 第4课是复习课

          String title;
          String subtitle;

          if (isReviewLesson) {
            title = '第${i + 1}课：复习';
            subtitle = '所有数字 0-9';
          } else {
            title = '第${i + 1}课';
            subtitle = numberLessons4[i].map((e) => e.character).join('  ');
          }

          // Lesson unlocking: sequential within unit
          final bool baseUnitUnlocked = _unitUnlocked['numbers'] == true;
          final bool prevCompleted = i == 0
              ? true
              : (_numberLessonsCompleted['number_lesson_${i - 1}'] ?? false);
          final bool lessonUnlocked = baseUnitUnlocked && prevCompleted;

          final card = _buildLockableLessonCard(
            title: title,
            subtitle: subtitle,
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenLessonPage(
                      title: '第${i + 1}课',
                      codes: numberLessons4[i],
                      lessonId: lessonId,
                    ),
                  ),
                )
                .then((_) => _loadUnlockState()),
            isUnlocked: lessonUnlocked,
            unitUnlocked: baseUnitUnlocked,
            isCompleted: isCompleted,
          );
          if (_targetUnitIdx == 2 &&
              _targetLessonIdx == i &&
              _targetLessonKey != null) {
            return KeyedSubtree(key: _targetLessonKey, child: card);
          }
          return card;
        })),
        isUnlocked: _unitUnlocked['numbers'] == true,
        unitNumber: 3,
      ),

      _buildUnitCard(
        title: '符号',
        lessons: _padToFour(List.generate(punctLessons3.length, (i) {
          final lessonId = 'punctuation_lesson_$i';
          final isCompleted = _punctuationLessonsCompleted[lessonId] ?? false;
          final bool numbersCompleted =
              _numberLessonsCompleted.values.every((c) => c == true);
          final bool baseUnitUnlocked = _unitUnlocked['punctuation'] == true;
          final bool prevCompleted = i == 0
              ? true
              : (_punctuationLessonsCompleted['punctuation_lesson_${i - 1}'] ??
                  false);
          // If unit 3 (numbers) done, unlock all lessons; otherwise sequential
          final bool lessonUnlocked =
              numbersCompleted || (baseUnitUnlocked && prevCompleted);

          final card = _buildLockableLessonCard(
            title: '第${i + 1}课',
            subtitle: punctLessons3[i].map((e) => e.character).join('  '),
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenLessonPage(
                      title: '第${i + 1}课',
                      codes: punctLessons3[i],
                      lessonId: lessonId,
                    ),
                  ),
                )
                .then((_) => _loadUnlockState()),
            isUnlocked: lessonUnlocked,
            unitUnlocked: numbersCompleted ? true : baseUnitUnlocked,
            isCompleted: isCompleted,
          );
          if (_targetUnitIdx == 3 &&
              _targetLessonIdx == i &&
              _targetLessonKey != null) {
            return KeyedSubtree(key: _targetLessonKey, child: card);
          }
          return card;
        })),
        isUnlocked: _unitUnlocked['punctuation'] == true,
        unitNumber: 4,
      ),

      // 单词单元
      _buildUnitCard(
        title: '单词',
        lessons: () {
          // 将单词分为3组：3字母、4字母、5字母
          final wordLessons3 = <List<MorseCode>>[];
          final words = MorseCodeData.commonWords;

          // 第1课: 3字母单词 (THE, AND, FOR, ARE, BUT, NOT, YOU, ALL, CAN, HAD, HER, WAS, ONE, OUR, OUT)
          wordLessons3
              .add(words.where((word) => word.character.length == 3).toList());

          // 第2课: 4字母单词 (THAT, WITH, HAVE, THIS, WILL, YOUR, FROM, THEY, KNOW, WANT, BEEN, GOOD, MUCH, SOME, TIME)
          wordLessons3
              .add(words.where((word) => word.character.length == 4).toList());

          // 第3课: 5字母单词 (WOULD, THERE, COULD, OTHER, AFTER, FIRST, NEVER, THESE, THINK, WHERE, BEING, EVERY, GREAT, MIGHT, SHALL)
          wordLessons3
              .add(words.where((word) => word.character.length == 5).toList());

          return _padToFour(List.generate(wordLessons3.length, (i) {
            final lessonId = 'word_lesson_$i';
            final isCompleted = _wordLessonsCompleted[lessonId] ?? false;
            final lessonWords = wordLessons3[i];

            String subtitle;
            switch (i) {
              case 0:
                subtitle =
                    '3字母单词: ${lessonWords.take(5).map((e) => e.character).join(' ')}...';
                break;
              case 1:
                subtitle =
                    '4字母单词: ${lessonWords.take(4).map((e) => e.character).join(' ')}...';
                break;
              case 2:
                subtitle =
                    '5字母单词: ${lessonWords.take(3).map((e) => e.character).join(' ')}...';
                break;
              default:
                subtitle = lessonWords.map((e) => e.character).join(' ');
            }

            final bool numbersCompleted =
                _numberLessonsCompleted.values.every((c) => c == true);
            final bool baseUnitUnlocked = _unitUnlocked['words'] == true;
            final bool prevCompleted = i == 0
                ? true
                : (_wordLessonsCompleted['word_lesson_${i - 1}'] ?? false);
            final bool lessonUnlocked =
                numbersCompleted || (baseUnitUnlocked && prevCompleted);

            final card = _buildLockableLessonCard(
              title: '第${i + 1}课',
              subtitle: subtitle,
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => FullscreenLessonPage(
                        title: '第${i + 1}课',
                        codes: lessonWords,
                        lessonId: lessonId,
                      ),
                    ),
                  )
                  .then((_) => _loadUnlockState()),
              isUnlocked: lessonUnlocked,
              unitUnlocked: numbersCompleted ? true : baseUnitUnlocked,
              isCompleted: isCompleted,
            );
            if (_targetUnitIdx == 5 - 1 &&
                _targetLessonIdx == i &&
                _targetLessonKey != null) {
              return KeyedSubtree(key: _targetLessonKey, child: card);
            }
            return card;
          }));
        }(),
        isUnlocked: _unitUnlocked['words'] == true,
        unitNumber: 5,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: null,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double viewportHeight = constraints.maxHeight;
            final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
            final double cardWidth = isTablet ? 420 : 320;
            final double cardHeight = isTablet ? 600 : 500;
            return SingleChildScrollView(
              controller: _hScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: viewportHeight - 32, // account for vertical padding
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // keep card content top-aligned
                    children: units
                        .map(
                          (unit) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: unit,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
