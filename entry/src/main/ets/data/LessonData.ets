import { languageService } from '../services/LanguageService'

export class LessonData {
  // 摩斯密码基础课程数据
  static readonly introSections: Map<string, string[]> = new Map([
    ['什么是摩斯密码？', [
      '摩斯密码是一种以"点（·）和划（-）"为基本元素的字符编码系统，用于传输文本信息。它将字母、数字及标点符号用标准化的长短信号序列来表示，是早期数字通信形式之一。',
      '',
      '官方名称说明',
      '• Morse Code - 英文原名',
      '• 摩尔斯电码 - 中文官方标准名称',
      '• 摩斯电码 - 民间简称，口语常用',
      '• 莫尔斯电码 - 港台地区译名'
    ]],
    ['历史与起源', [
      '19世纪30–40 年代，塞缪尔·摩斯与阿尔弗雷德·韦尔合作开发了电报系统，并为此设计了最初的摩斯密码。此后，为适应无线电通信需求，该编码逐步演化为国际摩斯密码，成为全球标准。',
      '',
      '国际模式',
      '以严格的点划与间隔单位为核心，适合音频/载波开断（Continuous Wave，连续波）等无线电通信方式。',
      '',
      '美式模式',
      '早期电报码，字符长短与间隔较不规则，现已较少使用。'
    ]],
    ['时序与间隔（单位制）', [
      '点（·）= 1 单位；划（-）= 3 单位。',
      '点/划之间间隔 = 1 单位；字符之间 = 3 单位；单词之间 = 7 单位。',
      '这个精确的1:3:7时序规则是摩斯密码的核心，确保了信息传输的准确性。'
    ]],
    ['字符构成规律', [
      '• 字母构成规律：常见如 A = ·-，N = -·，S = ···，O = --- 等，按照点与划的不同组合形成字符。',
      '• 数字构成规律：1~5 为逐渐增加的点后跟划，6~0 为逐渐增加的划后跟点（如 1 = ·----，0 = -----）。',
      '• 标点构成规律：通过更长的点划序列表示（如 , = --··--，? = ··--··），区分度更高。'
    ]],
    ['常用信号与通联礼仪', [
      '• SOS：··· --- ···，全球公认的紧急求救信号，由三个点、三个划、三个点紧凑发送，无字符间隔。',
      '• Prosign（通联指示）：如AR（·-·-·，信息结束）、SK（···-·-，通联结束）等是业余无线电中常用的通信礼节。'
    ]],
    ['应用场景', [
      '无线电通信：在低信噪比、远距离条件下仍具可达性与抗干扰能力，常用于 CW（Continuous Wave，连续波）。',
      '',
      '航海/航空：历史上用于灯光信号与无线电台呼，现代系统中仍可作为补充手段。',
      '',
      '应急与求救：通过光、声、敲击等节奏方式快速传达求救信息（如 SOS）。'
    ]],
    ['学习顺序（建议）', [
      '1）理解点/划与间隔单位的节奏。',
      '2）字母单元：按课时顺序学习，每课后做"简单练习"。',
      '3）数字单元：完成字母后学习数字，并在"中等练习"巩固。',
      '4）符号单元：最后学习常用标点与符号，配合"困难练习"。',
      '5）翻译互练：在"翻译"中进行文本⇄电码双向练习，交替巩固。',
      '6）综合强化：定期回顾已学课时，穿插全码表浏览加深印象。'
    ]],
    ['实用技巧', [
      '1）先"听形"后"记形"：培养节奏感，不要逐个数点划。',
      '2）Koch 方法：保持较高字符速度（如 20 WPM），加大字符间隔入门。',
      '3）Farnsworth 间隔：在高字符速下拉大字间距，减轻初学压力。',
      '4）分块与间隔复习：小批量高频练，隔天回顾抗遗忘。',
      '5）节拍器/固定WPM：用稳定节奏训练，提高一致性。',
      '6）听抄优先：少依赖"看图表"，以耳朵建立模式。',
      '7）短时高频：每天 10–20 分钟，高频次比长时间更有效。'
    ]]
  ])

  // 英文摩斯密码课程数据
  static readonly introSectionsEn: Map<string, string[]> = new Map([
    ['What is Morse Code?', [
      'Morse code is a character encoding system using "dots (·) and dashes (-)" as basic elements for transmitting text information. It represents letters, numbers, and punctuation marks with standardized sequences of long and short signals, making it one of the early forms of digital communication.',
    ]],
    ['History and Origin', [
      'In the 1830s-1840s, Samuel Morse and Alfred Vail collaborated to develop the telegraph system and designed the original Morse code for it. Later, to meet the needs of radio communication, this encoding gradually evolved into International Morse Code, becoming a global standard.',
      '',
      'International Mode',
      'Based on strict dot-dash and interval units, suitable for audio/carrier on-off (Continuous Wave) and other radio communication methods.',
      '',
      'American Mode',
      'Early telegraph code with irregular character lengths and intervals, now rarely used.'
    ]],
    ['Timing and Intervals (Unit System)', [
      'Dot (·) = 1 unit; Dash (-) = 3 units.',
      'Interval between dots/dashes = 1 unit; between characters = 3 units; between words = 7 units.',
      'This precise 1:3:7 timing rule is the core of Morse code, ensuring accuracy in information transmission.'
    ]],
    ['Character Formation Rules', [
      '• Letter formation rules: Common patterns like A = ·-, N = -·, S = ···, O = ---, etc., formed by different combinations of dots and dashes.',
      '• Number formation rules: 1-5 gradually increase dots followed by dashes, 6-0 gradually increase dashes followed by dots (e.g., 1 = ·----, 0 = -----).',
      '• Punctuation formation rules: Represented by longer dot-dash sequences (e.g., , = --··--, ? = ··--··) for higher distinction.'
    ]],
    ['Common Signals and Communication Etiquette', [
      '• SOS: ··· --- ···, globally recognized emergency distress signal, sent compactly with three dots, three dashes, three dots, no character intervals.',
      '• Prosigns (Communication indicators): Like AR (·-·-·, end of message), SK (···-·-, end of communication), etc., commonly used in amateur radio communication etiquette.'
    ]],
    ['Application Scenarios', [
      'Radio Communication: Still accessible and interference-resistant under low signal-to-noise ratio and long-distance conditions, commonly used in CW (Continuous Wave).',
      '',
      'Maritime/Aviation: Historically used for light signals and radio station calls, still serves as supplementary means in modern systems.',
      '',
      'Emergency and Rescue: Quickly convey distress information through rhythmic methods like light, sound, tapping (e.g., SOS).'
    ]],
    ['Learning Sequence (Recommended)', [
      '1) Understand the rhythm of dots/dashes and interval units.',
      '2) Letter unit: Learn in lesson order, do "simple practice" after each lesson.',
      '3) Number unit: Learn numbers after completing letters, consolidate in "medium practice".',
      '4) Symbol unit: Finally learn common punctuation and symbols, combined with "difficult practice".',
      '5) Translation practice: Practice text⇄code bidirectional conversion in "Translate", alternating consolidation.',
      '6) Comprehensive reinforcement: Regularly review learned lessons, intersperse with full code table browsing for deeper impression.'
    ]],
    ['Practical Tips', [
      '1) "Listen to shape" before "remember shape": Develop rhythm sense, don\'t count dots and dashes one by one.',
      '2) Koch method: Maintain high character speed (e.g., 20 WPM), increase character intervals for beginners.',
      '3) Farnsworth spacing: Increase character spacing at high character speed to reduce beginner pressure.',
      '4) Chunked and interval review: Small batch high-frequency practice, review every other day to resist forgetting.',
      '5) Metronome/fixed WPM: Train with stable rhythm for consistency.',
      '6) Listening priority: Less reliance on "looking at charts", build patterns with ears.',
      '7) Short frequent sessions: 10-20 minutes daily, high frequency is more effective than long sessions.'
    ]]
  ])

  // 中文摩斯密码课程数据
  static readonly chineseSections: Map<string, string[]> = new Map([
    ['什么是中文摩尔斯电码？', [
      '中文摩尔斯电码并不是国际标准摩尔斯电码的一部分，因为标准摩尔斯电码只收录了26个英文字母、0-9数字和少量标点符号。汉字数量庞大（几千上万），无法逐一分配独立的摩尔斯电码。'
    ]],
    ['标准摩尔斯电码的限制', [
      '国际摩尔斯电码（ITU Standard）只包含：',
      '• 26个英文字母（A-Z）',
      '• 10个数字（0-9）',
      '• 少量标点符号',
      '• 汉字数量太大，无法逐一分配独立码',
      '• 需要采用其他编码方案来表示中文字符'
    ]],
    ['中文摩尔斯电码的三种方案', [
      '由于标准摩尔斯电码的限制，中文摩尔斯电码发展出了几种不同的解决方案：',
      '1. 拼音法（最常见）',
      '2. 电报码法（历史上真正使用过）',
      '3. 现代编码法（数字化方案）'
    ]],
    ['方案A：拼音法（最常见）', [
      '拼音法是目前最常用的中文摩尔斯电码方案：',
      '• 把汉字转换为拼音',
      '• 再用摩尔斯电码表示拼音字母',
      '• 例如："你" → "ni" → 摩斯码 -· ··',
      '• 优点：简单直观，容易学习',
      '• 缺点：同音字需要上下文区分',
      '• 适用：日常练习、业余爱好'
    ]],
    ['方案B：电报码法', [
      '电报码法是中国历史上真正使用过的方案：',
      '• 19世纪末至20世纪80 年代在中国大陆使用',
      '• 每个汉字对应一个四位数字（0001-9999）',
      '• 先把汉字查出电报码，再把数字转成摩尔斯',
      '• 例如："你" = 4451 → 摩斯 ····- ····- ····· ·----',
      '• 优点：每个汉字有唯一编码，无歧义',
      '• 缺点：需要查表，记忆量大',
      '• 适用：历史电报、档案研究'
    ]],
    ['方案C：现代编码法（数字化）', [
      '现代编码法适合数字通信：',
      '• 把汉字转为UTF-8/Unicode编码值',
      '• 再转换成二进制或十进制串',
      '• 最后转换为摩尔斯电码',
      '• 例如："你"(U+4F60 = 20320) → 二进制 → 摩尔斯',
      '• 优点：标准化，适合计算机处理',
      '• 缺点：编码长，不适合人工手抄',
      '• 适用：数字化实验、编程项目'
    ]],
    ['实际应用场景', [
      '不同方案适用于不同场景：',
      '• 日常练习/业余爱好：拼音法（简单直观）',
      '• 历史电报/档案研究：电报码法（四位数字）',
      '• 数字化实验/编程项目：Unicode法',
      '• 军事通信：根据具体需求选择合适方案',
      '• 应急通信：优先使用拼音法（快速识别）'
    ]],
    ['学习建议', [
      '建议的学习顺序：',
      '1）先掌握标准摩尔斯电码（字母、数字、标点）',
      '2）学习拼音法（最实用）',
      '3）了解电报码法（历史文化价值）',
      '4）尝试现代编码法（技术探索）',
      '5）根据实际需求选择合适方案'
    ]],
    ['注意事项', [
      '使用中文摩尔斯电码时需要注意：',
      '• 拼音法：注意同音字的上下文区分',
      '• 电报码法：需要准备完整的编码表',
      '• 现代编码法：编码较长，发送时间久',
      '• 在实际通信中，建议先发送方案标识',
      '• 保持发送的稳定性和一致性',
      '• 在紧急情况下优先使用标准求救信号'
    ]]
  ])

  // 获取字母分组
  static getAlphabetGroups(): string[][] {
    const alphabet = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
    return [
      alphabet.slice(0, 3),   // ABC
      alphabet.slice(3, 6),   // DEF
      alphabet.slice(6, 10),  // GHIJ
      alphabet.slice(0, 10),  // 复习课：前10个字母 (A-J)
      alphabet.slice(10, 14), // KLMN
      alphabet.slice(14, 18), // OPQR
      alphabet.slice(18, 22), // STUV
      alphabet.slice(22, 26), // WXYZ
      alphabet.slice(10, 26)  // 复习课：后16个字母 (K-Z)
    ]
  }

  // 获取数字分组
  static getNumberGroups(): string[][] {
    const numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    return [
      numbers.slice(0, 3),  // 123
      numbers.slice(3, 6),  // 456
      numbers.slice(6, 10), // 7890
      numbers              // 复习课：所有数字
    ]
  }

  // 获取符号分组
  static getPunctuationGroups(): string[][] {
    const punctuation = ['.', ',', '?', '!', ':', ';', '=', '+', '-', '_', '"', "'", '(', ')', '/', '@']
    const groups: string[][] = []
    const itemsPerGroup = Math.ceil(punctuation.length / 3)
    
    for (let i = 0; i < 3; i++) {
      const start = i * itemsPerGroup
      const end = Math.min((i + 1) * itemsPerGroup, punctuation.length)
      if (start < punctuation.length) {
        groups.push(punctuation.slice(start, end))
      }
    }
    
    return groups
  }

  // 获取单词分组
  static getWordGroups(): string[][] {
    const words = ['THE', 'AND', 'FOR', 'ARE', 'BUT', 'NOT', 'YOU', 'ALL', 'CAN', 'HAD', 'HER', 'WAS', 'ONE', 'OUR', 'OUT', 'THAT', 'WITH', 'HAVE', 'THIS', 'WILL', 'YOUR', 'FROM', 'THEY', 'KNOW', 'WANT', 'BEEN', 'GOOD', 'MUCH', 'SOME', 'TIME', 'WOULD', 'THERE', 'COULD', 'OTHER', 'AFTER', 'FIRST', 'NEVER', 'THESE', 'THINK', 'WHERE', 'BEING', 'EVERY', 'GREAT', 'MIGHT', 'SHALL']
    
    return [
      words.filter(word => word.length === 3), // 3字母单词
      words.filter(word => word.length === 4), // 4字母单词
      words.filter(word => word.length === 5)  // 5字母单词
    ]
  }

  // 根据语言获取介绍课程数据
  static getIntroSections(): Map<string, string[]> {
    return languageService.isEnglish() ? LessonData.introSectionsEn : LessonData.introSections
  }

  // 根据语言获取中文摩尔斯电码课程数据（英文版本不包含）
  static getChineseSections(): Map<string, string[]> | null {
    return languageService.isEnglish() ? null : LessonData.chineseSections
  }
}
