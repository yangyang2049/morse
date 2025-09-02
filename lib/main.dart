import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'pages/learn/learn_page.dart';
import 'pages/translate/translate_page.dart';
import 'pages/code_table/code_table_page.dart';
import 'pages/code_table/telegraph_code_page.dart';
import 'pages/practice/practice_difficulty_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '摩斯密码',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  final List<Map<String, dynamic>> _bottomNavItems = [
    {
      'icon': Icons.school,
      'label': '学习',
      'title': '摩斯密码',
      'description': '学习摩斯密码的基础知识',
    },
    {
      'icon': Icons.fitness_center,
      'label': '练习',
      'title': '练习',
      'description': '选择难度开始练习',
    },
    {
      'icon': Icons.translate,
      'label': '翻译',
      'title': '翻译',
      'description': '将文本转换为摩斯密码',
    },
    {
      'icon': Icons.table_chart,
      'label': '码表',
      'title': '码表',
      'description': '查看完整的摩斯密码对照表',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pages = const [
      LearnPage(),
      PracticeDifficultyPage(),
      TranslatePage(),
      CodeTablePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 2
          ? null
          : AppBar(
              // 翻译页面不显示AppBar
              title: Text(_bottomNavItems[_currentIndex]['title']),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.secondaryColor,
              elevation: 0,
              centerTitle: true,
              actions: _currentIndex == 3 // 码表页面
                  ? [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TelegraphCodePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.numbers),
                        tooltip: '汉字电报码',
                      ),
                    ]
                  : null,
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          enableFeedback: false,
          items: _bottomNavItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }
}
