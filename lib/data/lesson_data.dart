import 'package:flutter/material.dart';

class LessonData {
  // 摩斯密码基础课程数据
  static const Map<String, List<String>> introSections = {
    '什么是摩斯密码？': [
      '摩斯密码是一种以"点（·）和划（-）"为基本元素的字符编码系统，用于传输文本信息。它将字母、数字及标点符号用标准化的长短信号序列来表示，是早期数字通信形式之一。',
    ],
    '历史与起源': [
      '19世纪30–40年代，塞缪尔·摩斯与阿尔弗雷德·韦尔合作开发了电报系统，并为此设计了最初的摩斯密码。此后，为适应无线电通信需求，该编码逐步演化为国际摩斯密码，成为全球标准。',
    ],
    '时序与间隔（单位制）': [
      '点（·）= 1 单位；划（-）= 3 单位。',
      '点/划之间间隔 = 1 单位；字符之间 = 3 单位；单词之间 = 7 单位。',
      '这个精确的1:3:7时序规则是摩斯密码的核心，确保了信息传输的准确性。',
    ],
    '字符构成规律': [],
    '常用信号与通联礼仪': [
      'SOS：··· --- ···，全球公认的紧急求救信号，由三个点、三个划、三个点紧凑发送，无字符间隔。',
      'Prosign（通联指示）：如AR（·-·-·，信息结束）、SK（···-·-，通联结束）等是业余无线电中常用的通信礼节。',
    ],
    '应用场景': [],
    '学习顺序（建议）': [
      '1）理解点/划与间隔单位的节奏。',
      '2）字母单元：按课时顺序学习，每课后做"简单练习"。',
      '3）数字单元：完成字母后学习数字，并在"中等练习"巩固。',
      '4）符号单元：最后学习常用标点与符号，配合"困难练习"。',
      '5）翻译互练：在"翻译"中进行文本⇄电码双向练习，交替巩固。',
      '6）综合强化：定期回顾已学课时，穿插全码表浏览加深印象。',
    ],
    '实用技巧': [
      '1）先"听形"后"记形"：培养节奏感，不要逐个数点划。',
      '2）Koch 方法：保持较高字符速度（如 20 WPM），加大字符间隔入门。',
      '3）Farnsworth 间隔：在高字符速下拉大字间距，减轻初学压力。',
      '4）分块与间隔复习：小批量高频练，隔天回顾抗遗忘。',
      '5）节拍器/固定WPM：用稳定节奏训练，提高一致性。',
      '6）听抄优先：少依赖"看图表"，以耳朵建立模式。',
      '7）短时高频：每天 10–20 分钟，高频次比长时间更有效。',
    ],
  };

  // 中文摩斯密码课程数据
  static const Map<String, List<String>> chineseSections = {
    '什么是中文摩尔斯电码？': [
      '中文摩尔斯电码并不是国际标准摩尔斯电码的一部分，因为标准摩尔斯电码只收录了26个英文字母、0-9数字和少量标点符号。汉字数量庞大（几千上万），无法逐一分配独立的摩尔斯电码。',
    ],
    '标准摩尔斯电码的限制': [
      '国际摩尔斯电码（ITU Standard）只包含：',
      '• 26个英文字母（A-Z）',
      '• 10个数字（0-9）',
      '• 少量标点符号',
      '• 汉字数量太大，无法逐一分配独立码',
      '• 需要采用其他编码方案来表示中文字符',
    ],
    '中文摩尔斯电码的三种方案': [
      '由于标准摩尔斯电码的限制，中文摩尔斯电码发展出了几种不同的解决方案：',
      '1. 拼音法（最常见）',
      '2. 电报码法（历史上真正使用过）',
      '3. 现代编码法（数字化方案）',
    ],
    '方案A：拼音法（最常见）': [
      '拼音法是目前最常用的中文摩尔斯电码方案：',
      '• 把汉字转换为拼音',
      '• 再用摩尔斯电码表示拼音字母',
      '• 例如："你" → "ni" → 摩斯码 -· ··',
      '• 优点：简单直观，容易学习',
      '• 缺点：同音字需要上下文区分',
      '• 适用：日常练习、业余爱好',
    ],
    '方案B：电报码法': [
      '电报码法是中国历史上真正使用过的方案：',
      '• 19世纪末至20世纪80年代在中国大陆使用',
      '• 每个汉字对应一个四位数字（0001-9999）',
      '• 先把汉字查出电报码，再把数字转成摩尔斯',
      '• 例如："你" = 4451 → 摩斯 ····- ····- ····· ·----',
      '• 优点：每个汉字有唯一编码，无歧义',
      '• 缺点：需要查表，记忆量大',
      '• 适用：历史电报、档案研究',
    ],
    '方案C：现代编码法（数字化）': [
      '现代编码法适合数字通信：',
      '• 把汉字转为UTF-8/Unicode编码值',
      '• 再转换成二进制或十进制串',
      '• 最后转换为摩尔斯电码',
      '• 例如："你"(U+4F60 = 20320) → 二进制 → 摩尔斯',
      '• 优点：标准化，适合计算机处理',
      '• 缺点：编码长，不适合人工手抄',
      '• 适用：数字化实验、编程项目',
    ],
    '实际应用场景': [
      '不同方案适用于不同场景：',
      '• 日常练习/业余爱好：拼音法（简单直观）',
      '• 历史电报/档案研究：电报码法（四位数字）',
      '• 数字化实验/编程项目：Unicode法',
      '• 军事通信：根据具体需求选择合适方案',
      '• 应急通信：优先使用拼音法（快速识别）',
    ],
    '学习建议': [
      '建议的学习顺序：',
      '1）先掌握标准摩尔斯电码（字母、数字、标点）',
      '2）学习拼音法（最实用）',
      '3）了解电报码法（历史文化价值）',
      '4）尝试现代编码法（技术探索）',
      '5）根据实际需求选择合适方案',
    ],
    '注意事项': [
      '使用中文摩尔斯电码时需要注意：',
      '• 拼音法：注意同音字的上下文区分',
      '• 电报码法：需要准备完整的编码表',
      '• 现代编码法：编码较长，发送时间久',
      '• 在实际通信中，建议先发送方案标识',
      '• 保持发送的稳定性和一致性',
      '• 在紧急情况下优先使用标准求救信号',
    ],
  };

  // 自定义章节构建器
  static Map<String, Widget Function(String, List<String>)>
      getIntroCustomBuilders(BuildContext context) {
    return {
      '什么是摩斯密码？': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contents.first),
              const SizedBox(height: 24),
              Text(
                '官方名称说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '• Morse Code - 英文原名\n• 摩尔斯电码 - 中文官方标准名称\n• 摩斯电码 - 民间简称，口语常用\n• 莫尔斯电码 - 港台地区译名',
              ),
            ],
          ),
      '历史与起源': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contents.first),
              const SizedBox(height: 20),
              Text(
                '国际模式',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '以严格的点划与间隔单位为核心，适合音频/载波开断（Continuous Wave，连续波）等无线电通信方式。',
              ),
              const SizedBox(height: 20),
              Text(
                '美式模式',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '早期电报码，字符长短与间隔较不规则，现已较少使用。',
              ),
            ],
          ),
      '字符构成规律': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '字母构成规律',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '常见如 A = ·-，N = -·，S = ···，O = --- 等，按照点与划的不同组合形成字符。',
              ),
              const SizedBox(height: 20),
              Text(
                '数字构成规律',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '1~5 为逐渐增加的点后跟划，6~0 为逐渐增加的划后跟点（如 1 = ·----，0 = -----）。',
              ),
              const SizedBox(height: 20),
              Text(
                '标点构成规律',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '通过更长的点划序列表示（如 , = --··--，? = ··--··），区分度更高。',
              ),
            ],
          ),
      '应用场景': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '无线电通信',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '在低信噪比、远距离条件下仍具可达性与抗干扰能力，常用于 CW（Continuous Wave，连续波）。',
              ),
              const SizedBox(height: 12),
              Text(
                '航海/航空',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '历史上用于灯光信号与无线电台呼，现代系统中仍可作为补充手段。',
              ),
              const SizedBox(height: 12),
              Text(
                '应急与求生',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 0),
              const Text(
                '通过光、声、敲击等节奏方式快速传达求救信息（如 SOS）。',
              ),
            ],
          ),
    };
  }

  static Map<String, Widget Function(String, List<String>)>
      getChineseCustomBuilders(BuildContext context) {
    Widget buildBulletLine(String text) {
      final numberPrefix = RegExp(r'^(\d+)[）).．\.]\s*');
      String display = text;
      bool isNumbered = numberPrefix.hasMatch(text);
      if (isNumbered) {
        display = text.replaceFirst(numberPrefix, '');
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNumbered) const Text('• '),
          Expanded(child: Text(display)),
        ],
      );
    }

    Widget buildDefaultSection(List<String> contents) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, i) => buildBulletLine(contents[i]),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: contents.length,
      );
    }

    return {
      '什么是中文摩尔斯电码？': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contents.first),
              const SizedBox(height: 24),
              Text(
                '重要说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 中文摩尔斯电码不是国际标准\n• 需要采用特殊的编码方案\n• 主要有三种实现方式\n• 每种方案都有其适用场景',
              ),
            ],
          ),
      '标准摩尔斯电码的限制': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '为什么需要特殊方案？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 汉字数量庞大（几千上万）\n• 无法为每个汉字分配独立码\n• 需要采用编码转换方案\n• 每种方案都有优缺点',
              ),
            ],
          ),
      '中文摩尔斯电码的三种方案': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '方案选择建议',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 初学者：选择拼音法\n• 历史研究：了解电报码法\n• 技术探索：尝试现代编码法\n• 根据实际需求选择',
              ),
            ],
          ),
      '方案A：拼音法（最常见）': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '实际示例',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• "你好" → "ni hao" → -· ·· / ···· ·- ---\n• "中国" → "zhong guo" → --·· ···· --- -. --. / --. ··- ---\n• 注意：同音字需要上下文区分',
              ),
            ],
          ),
      '方案B：电报码法': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '历史背景',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 中国电报局19世纪末推行\n• 在大陆使用到1980年代\n• 类似于"区位码/电报码表"\n• 具有重要的历史文化价值',
              ),
            ],
          ),
      '方案C：现代编码法（数字化）': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '技术特点',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 基于Unicode标准\n• 适合计算机处理\n• 编码较长但无歧义\n• 主要用于技术实验',
              ),
            ],
          ),
      '实际应用场景': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '选择建议',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 日常使用：拼音法\n• 历史研究：电报码法\n• 技术项目：现代编码法\n• 应急情况：优先拼音法',
              ),
            ],
          ),
      '学习建议': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '学习路径',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 基础：标准摩尔斯电码\n• 入门：拼音法练习\n• 进阶：了解其他方案\n• 实践：根据需求应用',
              ),
            ],
          ),
      '注意事项': (title, contents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDefaultSection(contents),
              const SizedBox(height: 20),
              Text(
                '安全提醒',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 遵守通信法规\n• 注意通信安全\n• 避免干扰其他系统\n• 紧急情况用标准信号',
              ),
            ],
          ),
    };
  }
}
