import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../models/morse_code.dart';
import '../../theme/app_theme.dart';

class TranslatePage extends StatefulWidget {
  const TranslatePage({super.key});

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _morseController = TextEditingController();
  bool _isTextToMorse = true; // 默认为文本转电码模式

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _morseController.addListener(_onMorseChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _morseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // 文本→电码自动转换
    if (_isTextToMorse) {
      final morse = MorseCodeData.textToMorse(_textController.text) ?? '';
      if (morse != _morseController.text) {
        _morseController.text = morse;
      }
    }
    setState(() {}); // 触发重建以更新清除按钮的显示状态
  }

  void _onMorseChanged() {
    // 电码→文本自动转换
    if (!_isTextToMorse) {
      final text = MorseCodeData.morseToText(_morseController.text);
      if (text != null && text != _textController.text) {
        _textController.text = text;
      }
    }
    setState(() {}); // 触发重建以更新清除按钮的显示状态
  }

  void _clearAll() {
    _textController.clear();
    _morseController.clear();
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('$type 已复制');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Container(
            width: 200,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTextToMorse = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isTextToMorse
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '文本 → 电码',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isTextToMorse
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight: _isTextToMorse
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTextToMorse = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isTextToMorse
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '电码 → 文本',
                          style: TextStyle(
                            fontSize: 12,
                            color: !_isTextToMorse
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight: !_isTextToMorse
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 输入区域
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller:
                            _isTextToMorse ? _textController : _morseController,
                        maxLines: null,
                        expands: true,
                        cursorColor: Colors.white,
                        enableInteractiveSelection: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _isTextToMorse
                              ? '在此输入文本，如: Hello World'
                              : '在此输入电码，如: ··· --- ···',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: _isTextToMorse ? null : 'monospace',
                        ),
                      ),
                      // 清除按钮 - 右上角
                      if ((_isTextToMorse
                              ? _textController.text
                              : _morseController.text)
                          .isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: _clearAll,
                            icon: const Icon(Icons.clear_rounded),
                            tooltip: '清除',
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ),
                      // 快速输入按钮 - 浮动在底部
                      if (_isTextToMorse)
                        Positioned(
                          bottom: 4,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildQuickInputButton('SOS', 'SOS'),
                                  const SizedBox(width: 6),
                                  _buildQuickInputButton('Hello', 'Hello'),
                                  const SizedBox(width: 6),
                                  _buildQuickInputButton('World', 'World'),
                                  const SizedBox(width: 6),
                                  _buildQuickInputButton('Test', 'Test'),
                                  const SizedBox(width: 6),
                                  _buildQuickInputButton('中国', '中国'),
                                  const SizedBox(width: 6),
                                  _buildQuickInputButton('你好', '你好'),
                                  const SizedBox(width: 6),
                                  _buildQuickInputButton('学习', '学习'),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 摩尔斯电码输入按键
              if (!_isTextToMorse)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: _buildDeleteButton()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMorseInputButton('·', '·')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMorseInputButton('-', '-')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMorseInputButton('␣', ' ')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMorseInputButton('/', '/')),
                    ],
                  ),
                ),

              // 轻触/长按输入键（短按输入·，长按输入-）
              if (!_isTextToMorse)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: _buildTapHoldKey()),
                ),

              const SizedBox(height: 16),

              // 输出区域
              Expanded(
                child: Container(
                  margin:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            _getOutputText().isEmpty
                                ? '输出将在此显示'
                                : _getOutputText(),
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'monospace',
                              color: _getOutputText().isEmpty
                                  ? AppTheme.textSecondaryColor
                                  : AppTheme.textColor,
                            ),
                          ),
                        ),
                      ),
                      // 复制按钮 - 右下角
                      if (_getOutputText().isNotEmpty)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed: () => _copyToClipboard(
                              _getOutputText(),
                              _isTextToMorse ? '电码' : '文本',
                            ),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.copy_rounded, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildQuickInputButton(String label, String text) {
    return OutlinedButton(
      onPressed: () {
        _textController.text = text;
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.7),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.transparent,
        minimumSize: const Size(60, 28),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMorseInputButton(String label, String text) {
    return OutlinedButton(
      onPressed: () {
        // 根据不同的输入类型提供不同的震动反馈
        if (text == '·') {
          Vibration.vibrate(duration: 50); // 点：短震动
        } else if (text == '-') {
          Vibration.vibrate(duration: 100); // 划：长震动
        } else {
          Vibration.vibrate(duration: 30); // 其他按钮：轻微震动
        }
        _morseController.text += text;
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        backgroundColor: Colors.black,
        fixedSize: const Size.fromHeight(40),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _getMorseButtonFontSize(label),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _getMorseButtonFontSize(String label) {
    // 前3个按钮（点、横、空格）使用更大的字体
    switch (label) {
      case '·':
      case '-':
      case '␣':
        return 24; // 更大的字体
      default:
        return 16; // 其他按钮保持原来的大小
    }
  }

  String _getOutputText() {
    if (_isTextToMorse) {
      // 文本 → 电码：输出显示电码
      return _morseController.text;
    } else {
      // 电码 → 文本：输出显示转换后的文本
      return _textController.text;
    }
  }

  Widget _buildDeleteButton() {
    return OutlinedButton(
      onPressed: (() {
        final controller = _isTextToMorse ? _textController : _morseController;
        return controller.text.isNotEmpty
            ? () {
                if (controller.text.isNotEmpty) {
                  controller.text =
                      controller.text.substring(0, controller.text.length - 1);
                }
              }
            : null;
      })(),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red, // 文字/图标使用红色
        side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        backgroundColor: Colors.black, // 背景与其他按键一致为黑色
        fixedSize: const Size.fromHeight(40),
      ),
      child: const Icon(
        Icons.backspace_rounded,
        color: Colors.red,
        size: 20,
      ),
    );
  }

  Widget _buildTapHoldKey() {
    return SizedBox(
      width: 120,
      height: 40, // 与上方按键相同高度（fixedSize: 40）
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Vibration.vibrate(duration: 50); // 短按：短震动
          _morseController.text += '·'; // 短按输入点（中点）
        },
        onLongPress: () {
          Vibration.vibrate(duration: 100); // 长按：长震动
          _morseController.text += '-'; // 长按输入划
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.7), width: 1),
          ),
          child: const Text(
            '轻触  ·   长按 -',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
