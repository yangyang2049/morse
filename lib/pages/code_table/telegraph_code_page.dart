import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/telegraph_code_service.dart';

class TelegraphCodePage extends StatefulWidget {
  const TelegraphCodePage({super.key});

  @override
  State<TelegraphCodePage> createState() => _TelegraphCodePageState();
}

class _TelegraphCodePageState extends State<TelegraphCodePage> {
  List<TelegraphCodeEntry> _telegraphCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTelegraphCodes();
  }

  Future<void> _loadTelegraphCodes() async {
    try {
      final data = await TelegraphCodeService().loadAll();
      if (!mounted) return;
      setState(() {
        _telegraphCodes = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('汉字电报码'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            )
          : Container(
              color: Colors.white,
              child: Column(
                children: [
                  // 表格头部
                  Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                right:
                                    BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '汉字',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: const Center(
                              child: Text(
                                '电报码',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 表格内容
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _telegraphCodes.length,
                      itemBuilder: (context, index) {
                        final code = _telegraphCodes[index];

                        return Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color(0xFFD0D0D0), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              // 汉字列
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: Color(0xFFD0D0D0), width: 0.5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      code.character,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 电报码列
                              Expanded(
                                child: Container(
                                  child: Center(
                                    child: Text(
                                      code.code,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
