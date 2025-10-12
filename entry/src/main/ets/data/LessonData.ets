
export class LessonData {
  // 摩斯电码基础课程数据
  static readonly introSections: Map<string, string[]> = new Map([
    ['什么是摩斯电码？', [
      '摩斯电码是一种以"点（·）和划（-）"为基本元素的字符编码系统，用于传输文本信息。它将字母、数字及标点符号用标准化的长短信号序列来表示，是早期数字通信形式之一。',
      '',
      '官方名称说明',
      '• Morse Code - 英文原名',
      '• 摩尔斯电码 - 中文官方标准名称',
      '• 摩斯电码 - 民间简称，口语常用',
      '• 莫尔斯电码 - 港台地区译名'
    ]],
    ['历史与起源', [
      '19世纪30–40 年代，塞缪尔·摩斯与阿尔弗雷德·韦尔合作开发了电报系统，并为此设计了最初的摩斯电码。此后，为适应无线电通信需求，该编码逐步演化为国际摩斯电码，成为全球标准。',
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
      '这个精确的1:3:7时序规则是摩斯电码的核心，确保了信息传输的准确性。'
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

  // 英文摩斯电码课程数据
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

  // 中文摩斯电码课程数据
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

  // 繁體中文摩斯電碼基礎課程數據
  static readonly introSectionsZhHK: Map<string, string[]> = new Map([
    ['什麼是摩斯電碼？', [
      '摩斯電碼是一種以「點（·）和劃（-）」為基本元素的字元編碼系統，用於傳輸文字資訊。它將字母、數字及標點符號用標準化的長短訊號序列來表示，是早期數位通訊形式之一。',
      '',
      '官方名稱說明',
      '• Morse Code - 英文原名',
      '• 摩爾斯電碼 - 中文官方標準名稱',
      '• 摩斯電碼 - 民間簡稱，口語常用',
      '• 莫爾斯電碼 - 港台地區譯名'
    ]],
    ['歷史與起源', [
      '19世紀30–40 年代，塞繆爾·摩斯與阿爾弗雷德·韋爾合作開發了電報系統，並為此設計了最初的摩斯電碼。此後，為適應無線電通訊需求，該編碼逐步演化為國際摩斯電碼，成為全球標準。',
      '',
      '國際模式',
      '以嚴格的點劃與間隔單位為核心，適合音訊/載波開斷（Continuous Wave，連續波）等無線電通訊方式。',
      '',
      '美式模式',
      '早期電報碼，字元長短與間隔較不規則，現已較少使用。'
    ]],
    ['時序與間隔（單位制）', [
      '點（·）= 1 單位；劃（-）= 3 單位。',
      '點/劃之間間隔 = 1 單位；字元之間 = 3 單位；單詞之間 = 7 單位。',
      '這個精確的1:3:7時序規則是摩斯電碼的核心，確保了資訊傳輸的準確性。'
    ]],
    ['字元構成規律', [
      '• 字母構成規律：常見如 A = ·-，N = -·，S = ···，O = --- 等，按照點與劃的不同組合形成字元。',
      '• 數字構成規律：1~5 為逐漸增加的點後跟劃，6~0 為逐漸增加的劃後跟點（如 1 = ·----，0 = -----）。',
      '• 標點構成規律：透過更長的點劃序列表示（如 , = --··--，? = ··--··），區分度更高。'
    ]],
    ['常用訊號與通聯禮儀', [
      '• SOS：··· --- ···，全球公認的緊急求救訊號，由三個點、三個劃、三個點緊湊發送，無字元間隔。',
      '• Prosign（通聯指示）：如AR（·-·-·，資訊結束）、SK（···-·-，通聯結束）等是業餘無線電中常用的通訊禮節。'
    ]],
    ['應用場景', [
      '無線電通訊：在低訊噪比、遠距離條件下仍具可達性與抗干擾能力，常用於 CW（Continuous Wave，連續波）。',
      '',
      '航海/航空：歷史上用於燈光訊號與無線電台呼，現代系統中仍可作為補充手段。',
      '',
      '應急與求救：透過光、聲、敲擊等節奏方式快速傳達求救資訊（如 SOS）。'
    ]],
    ['學習順序（建議）', [
      '1）理解點/劃與間隔單位的節奏。',
      '2）字母單元：按課時順序學習，每課後做「簡單練習」。',
      '3）數字單元：完成字母後學習數字，並在「中等練習」鞏固。',
      '4）符號單元：最後學習常用標點與符號，配合「困難練習」。',
      '5）翻譯互練：在「翻譯」中進行文字⇄電碼雙向練習，交替鞏固。',
      '6）綜合強化：定期回顧已學課時，穿插全碼表瀏覽加深印象。'
    ]],
    ['實用技巧', [
      '1）先「聽形」後「記形」：培養節奏感，不要逐個數點劃。',
      '2）Koch 方法：保持較高字元速度（如 20 WPM），加大字元間隔入門。',
      '3）Farnsworth 間隔：在高字元速下拉大字間距，減輕初學壓力。',
      '4）分塊與間隔複習：小批量高頻練，隔天回顧抗遺忘。',
      '5）節拍器/固定WPM：用穩定節奏訓練，提高一致性。',
      '6）聽抄優先：少依賴「看圖表」，以耳朵建立模式。',
      '7）短時高頻：每天 10–20 分鐘，高頻次比長時間更有效。'
    ]]
  ])

  // 繁體中文摩爾斯電碼課程數據
  static readonly chineseSectionsZhHK: Map<string, string[]> = new Map([
    ['什麼是中文摩爾斯電碼？', [
      '中文摩爾斯電碼並不是國際標準摩爾斯電碼的一部分，因為標準摩爾斯電碼只收錄了26個英文字母、0-9數字和少量標點符號。漢字數量龐大（幾千上萬），無法逐一分配獨立的摩爾斯電碼。'
    ]],
    ['標準摩爾斯電碼的限制', [
      '國際摩爾斯電碼（ITU Standard）只包含：',
      '• 26個英文字母（A-Z）',
      '• 10個數字（0-9）',
      '• 少量標點符號',
      '• 漢字數量太大，無法逐一分配獨立碼',
      '• 需要採用其他編碼方案來表示中文字元'
    ]],
    ['中文摩爾斯電碼的三種方案', [
      '由於標準摩爾斯電碼的限制，中文摩爾斯電碼發展出了幾種不同的解決方案：',
      '1. 拼音法（最常見）',
      '2. 電報碼法（歷史上真正使用過）',
      '3. 現代編碼法（數位化方案）'
    ]],
    ['方案A：拼音法（最常見）', [
      '拼音法是目前最常用的中文摩爾斯電碼方案：',
      '• 把漢字轉換為拼音',
      '• 再用摩爾斯電碼表示拼音字母',
      '• 例如：「你」 → 「ni」 → 摩斯碼 -· ··',
      '• 優點：簡單直觀，容易學習',
      '• 缺點：同音字需要上下文區分',
      '• 適用：日常練習、業餘愛好'
    ]],
    ['方案B：電報碼法', [
      '電報碼法是中國歷史上真正使用過的方案：',
      '• 19世紀末至20世紀80 年代在中國大陸使用',
      '• 每個漢字對應一個四位數字（0001-9999）',
      '• 先把漢字查出電報碼，再把數字轉成摩爾斯',
      '• 例如：「你」 = 4451 → 摩斯 ····- ····- ····· ·----',
      '• 優點：每個漢字有唯一編碼，無歧義',
      '• 缺點：需要查表，記憶量大',
      '• 適用：歷史電報、檔案研究'
    ]],
    ['方案C：現代編碼法（數位化）', [
      '現代編碼法適合數位通訊：',
      '• 把漢字轉為UTF-8/Unicode編碼值',
      '• 再轉換成二進位或十進位串',
      '• 最後轉換為摩爾斯電碼',
      '• 例如：「你」(U+4F60 = 20320) → 二進位 → 摩爾斯',
      '• 優點：標準化，適合電腦處理',
      '• 缺點：編碼長，不適合人工手抄',
      '• 適用：數位化實驗、編程專案'
    ]],
    ['實際應用場景', [
      '不同方案適用於不同場景：',
      '• 日常練習/業餘愛好：拼音法（簡單直觀）',
      '• 歷史電報/檔案研究：電報碼法（四位數字）',
      '• 數位化實驗/編程專案：Unicode法',
      '• 軍事通訊：根據具體需求選擇合適方案',
      '• 應急通訊：優先使用拼音法（快速識別）'
    ]],
    ['學習建議', [
      '建議的學習順序：',
      '1）先掌握標準摩爾斯電碼（字母、數字、標點）',
      '2）學習拼音法（最實用）',
      '3）了解電報碼法（歷史文化價值）',
      '4）嘗試現代編碼法（技術探索）',
      '5）根據實際需求選擇合適方案'
    ]],
    ['注意事項', [
      '使用中文摩爾斯電碼時需要注意：',
      '• 拼音法：注意同音字的上下文區分',
      '• 電報碼法：需要準備完整的編碼表',
      '• 現代編碼法：編碼較長，發送時間久',
      '• 在實際通訊中，建議先發送方案標識',
      '• 保持發送的穩定性和一致性',
      '• 在緊急情況下優先使用標準求救訊號'
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
    // 使用 AppStorage 获取当前语言
    const currentLang: string = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    if (currentLang.startsWith('en')) {
      return LessonData.introSectionsEn
    } else if (currentLang === 'zh-HK' || currentLang === 'zh-TW') {
      return LessonData.introSectionsZhHK
    } else {
      return LessonData.introSections
    }
  }

  // 根据语言获取中文摩尔斯电码课程数据（英文环境下不显示）
  static getChineseSections(): Map<string, string[]> | null {
    // 使用 AppStorage 获取当前语言
    const currentLang: string = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    if (currentLang.startsWith('en')) {
      return null
    } else if (currentLang === 'zh-HK' || currentLang === 'zh-TW') {
      return LessonData.chineseSectionsZhHK
    } else {
      return LessonData.chineseSections
    }
  }
}
