import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/morse_code.dart';
import '../../theme/app_theme.dart';
import '../../services/morse_audio_service.dart';
// Telegraph codes are accessible via the separate page entry (top-right action)

class CodeTablePage extends StatefulWidget {
  const CodeTablePage({super.key});

  @override
  State<CodeTablePage> createState() => _CodeTablePageState();
}

class _CodeTablePageState extends State<CodeTablePage> {
  String _selectedCategory = 'all';
  final MorseAudioService _audioService = MorseAudioService();

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'name': '所有码'},
    {'key': 'alphabet', 'name': '字母'},
    {'key': 'numbers', 'name': '数字'},
    {'key': 'punctuation', 'name': '标点'},
  ];

  List<MorseCode> get _filteredCodes {
    switch (_selectedCategory) {
      case 'alphabet':
        return MorseCodeData.englishAlphabet;
      case 'numbers':
        return MorseCodeData.numbers;
      case 'punctuation':
        return MorseCodeData.punctuation;
      default:
        // 只包含字母、数字和标点
        return [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers,
          ...MorseCodeData.punctuation,
        ];
    }
  }

  String _getCharacterTypeLabel(String character) {
    if (RegExp(r'^[A-Z]$').hasMatch(character)) {
      return '字母';
    } else if (RegExp(r'^[0-9]$').hasMatch(character)) {
      return '数字';
    } else if (RegExp(r'[\u4e00-\u9fff]').hasMatch(character)) {
      return '中文';
    } else {
      return '符号';
    }
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

  Future<void> _playMorseCode(String morseCode) async {
    if (_audioService.isPlaying) {
      await _audioService.stop();
    } else {
      await _audioService.playMorseCode(morseCode);
    }
    setState(() {}); // 更新播放按钮状态
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            // 类别筛选器
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Center(
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category['key'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 72),
                                child: FilterChip(
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -0.5, vertical: -2),
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                                  label: Text(
                                    category['name']!,
                                    style: TextStyle(
                                      // Selected uses white chip with dark text for contrast
                                      color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category['key']!;
                                    });
                                  },
                                  // Selected chip uses white background
                                  selectedColor: Colors.white,
                                  backgroundColor: AppTheme.surfaceColor,
                                  // Rounded pill shape to allow wider chips
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: isSelected ? Colors.white : AppTheme.borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  showCheckmark: false,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 码表内容
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredCodes.length,
                itemBuilder: (context, index) {
                  final code = _filteredCodes[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppTheme.accentColor.withValues(alpha: 0.7),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          code.character,
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 摩斯电码文本
                        Expanded(
                          child: Text(
                            code.morse.replaceAll('.', '·'),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  color: AppTheme.textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 播放按钮
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  AppTheme.accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _playMorseCode(code.morse),
                            icon: Icon(
                              _audioService.isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppTheme.accentColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _audioService.isPlaying
                                ? '停止播放'
                                : '播放摩斯电码',
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showCodeDetail(code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCodeDetail(MorseCode code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        title: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.accentColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                code.character,
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            // 字符条目
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  // 第一列：类型 (30%)
                  Expanded(
                    flex: 3,
                    child: Text(
                      _getCharacterTypeLabel(code.character),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  // 第二列：字符 (40%)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Text(
                        code.character,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 第三列：复制按钮 (30%)
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: code.character));
                            _showToast('字符已复制');
                          },
                          icon: Icon(Icons.copy_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20),
                          tooltip: '复制字符',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 摩斯电码条目
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  // 第一列：类型 (30%)
                  const Expanded(
                    flex: 3,
                    child: Text(
                      '电码',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  // 第二列：摩斯电码 (40%)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Text(
                        code.morse.replaceAll('.', '·'),
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 28,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 第三列：播放和复制按钮 (30%)
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => _playMorseCode(code.morse),
                          icon: Icon(
                            _audioService.isPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: AppTheme.accentColor.withValues(alpha: 0.8),
                            size: 20,
                          ),
                          tooltip: _audioService.isPlaying ? '停止播放' : '播放摩斯电码',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: code.morse.replaceAll('.', '·')));
                            _showToast('摩斯电码已复制');
                          },
                          icon: Icon(Icons.copy_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20),
                          tooltip: '复制摩斯电码',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (code.description != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    // 第一列：描述 (20%)
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '描述',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    // 第二列：描述内容 (60%)
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Text(
                          code.description!,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    // 第三列：留空 (20%)
                    const Expanded(
                      flex: 2,
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
