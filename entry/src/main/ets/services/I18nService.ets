import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
// 移除对已删除的 LanguageService 的依赖

/**
 * 语言选项接口
 */
export interface LanguageOption {
  code: string
  name: string
  nativeName: string
}

/**
 * 多语言字典类型
 */
type Dictionary = Record<string, string>
type LanguageDictionaries = Record<string, Dictionary>

/**
 * 模板参数类型
 */
type TemplateParams = Record<string, string | number>

/**
 * I18n服务类 - 应用内字典型多语言支持
 * 优势：立即生效、跨版本一致、不依赖资源系统热切换
 */
export class I18nService {
  private static instance: I18nService
  
  // 当前语言状态 - 单一数据源
  private currentLang: string = 'zh-CN'
  
  // 语言字典
  private dictionaries: LanguageDictionaries = {}
  
  // Preferences存储
  private preferences: preferences.Preferences | null = null
  
  // 支持的语言列表
  private supportedLanguages: LanguageOption[] = [
    { code: 'zh-CN', name: '简体中文', nativeName: '简体中文' },
    { code: 'en-US', name: 'English', nativeName: 'English' }
  ]

  private constructor() {
    this.initDictionaries()
  }

  static getInstance(): I18nService {
    if (!I18nService.instance) {
      I18nService.instance = new I18nService()
    }
    return I18nService.instance
  }

  /**
   * 初始化字典数据
   */
  private initDictionaries(): void {
    // 中文字典
    this.dictionaries['zh-CN'] = {
      // 应用基础
      'app_name': '摩斯电码通',
      'app_tagline': '让学习摩斯电码简单又有趣',
      
      // 主导航
      'learn': '学习',
      'practice': '练习', 
      'translate': '翻译',
      'code_table': '码表',
      'me': '我',
      
      // 通用操作
      'confirm': '确认',
      'cancel': '取消',
      'close': '确定',
      'back': '返回',
      'next': '下一步',
      'loading': '加载中...',
      'copied': '已复制到剪贴板',
      'got_it': '知道了',
      'settings': '设置',
      'sound': '声音',
      
      // 语言设置
      'language': '语言',
      'language_selection_title': '选择语言',
      'language_selection_content': '选择您偏好的应用界面语言',
      'chinese': '中文',
      'english': 'English',
      'language_switched': '语言已切换为中文',
      'language_switch_failed': '语言切换失败，请稍后重试',
      
      // 学习模块
      'morse_code_basics': '摩斯电码基础',
      'morse_code_intro': '摩斯电码是一种以"点（·）和划（-）"为基本元素的字符编码系统。通过不同的点划组合来表示字母、数字和符号。',
      'alphabet_lesson': '字母',
      'number_lesson': '数字',
      'punctuation_lesson': '符号',
      'word_lesson': '单词',
      'review_lesson': '复习',
      'lesson_completed': '完成',
      'next_lesson': '下一课',
      'start_test': '开始测试',
      'your_score': '你的分数',
      'congratulations_passed': '恭喜通过！',
      'keep_trying': '继续努力！',
      
      // 练习模块
      'easy': '简单',
      'medium': '中等', 
      'hard': '困难',
      'easy_desc': '仅字母',
      'medium_desc': '字母 + 数字',
      'hard_desc': '全部字符',
      'favorites': '收藏',
      'mistakes': '错题本',
      'practice_again': '再次练习',
      'practice_count': '练习次数',
      'congratulations_completed': '恭喜完成！',
      'favorite_added': '已收藏',
      'favorite_removed': '已取消收藏',
      'practice_records': '练习记录',
      'practiced': '已练习',
      'total': '总计',
      'learning_completed': '完成学习',
      'you_mastered_basics': '你已经掌握了摩斯电码的基础知识',
      'need_100_to_pass': '需要100分才能通过测试',
      'test_your_mastery': '测试你对本课程的掌握程度',
      'test_your_mastery_text': '测试你对{title}的掌握程度',
      'test_content': '测试内容',
      'test_format_1': '• 2道判断题（每题20分）',
      'test_format_2': '• 3道选择题（每题20分）',
      'retake_test': '重新测试',
      'next_question': '下一题',
      'view_results': '查看结果',
      'correct': '正确',
      'wrong': '错误',
        
        // 基础测试问题和选项
        'q1_question': '摩斯电码是以"点（·）和划（-）"为基本元素的字符编码系统。',
        'q1_options': '正确,错误',
        'q2_question': 'SOS信号的摩斯电码是 ··· --- ···，各字符之间需要保持正常的字符间隔。',
        'q2_options': '正确,错误',
        'q3_question': '摩斯电码的时序规则中，点、划、字符间隔的单位比例是：',
        'q3_options': '1 : 2 : 5,1 : 3 : 7,1 : 4 : 8,2 : 3 : 6',
        'q4_question': '摩斯电码是在哪个年代开发的？',
        'q4_options': '1820 年代,1830-1840 年代,1850 年代,1860 年代',
        'q5_question': '学习摩斯电码的建议顺序是：',
        'q5_options': '数字 → 字母 → 符号,符号 → 字母 → 数字,字母 → 数字 → 符号,随机学习',
        
        // 中文摩斯电码测试问题和选项
        'cq1_question': '中文摩尔斯电码是专门为中文汉字设计的摩尔斯电码系统。',
        'cq1_options': '正确,错误',
        'cq2_question': '中文摩尔斯电码的编码长度通常比英文摩尔斯电码短。',
        'cq2_options': '正确,错误',
        'cq3_question': '中文摩尔斯电码是在哪个年代开始制定的？',
        'cq3_options': '1900 年代,1920 年代,1950 年代,1980 年代',
        'cq4_question': '以下哪个不是中文摩尔斯电码的应用场景？',
        'cq4_options': '军事通信,航空通信,网络聊天,航海通信',
        'cq5_question': '学习中文摩尔斯电码的建议顺序是：',
        'cq5_options': '从复杂汉字开始,从基础汉字开始,随机学习,从标点符号开始',
        
        // 基础测试解释内容
        'exp1_title': '摩斯电码基本元素',
        'exp1_content': '• 摩斯电码以"点（·）和划（-）"为基本元素\n• 通过不同的点划组合表示字母、数字和符号\n• 这是所有摩斯电码的基础，必须熟练掌握',
        'exp2_title': 'SOS信号的特殊性',
        'exp2_content': '• SOS是紧急求救信号，需要快速识别\n• 紧凑发送：三个字符（··· --- ···）是紧凑发送的，没有正常的字符间隔\n• 标准间隔规则：正常情况下，摩斯电码字符之间应该有3个单位的间隔\n• SOS例外：但SOS作为紧急信号，会忽略这个规则，紧凑发送以提高识别速度',
        'exp3_title': '时序规则的重要性',
        'exp3_content': '• 1:3:7比例是摩斯电码的核心规则\n• 点=1单位，划=3单位，字符间隔=3单位，单词间隔=7单位\n• 这个精确的时序确保了信息传输的准确性和可读性',
        'exp4_title': '历史背景',
        'exp4_content': '• 塞缪尔·摩斯与阿尔弗雷德·韦尔在1830-1840 年代合作开发\n• 最初用于电报系统，后来演化为国际摩斯电码\n• 成为全球标准的无线电通信编码系统',
        'exp5_title': '学习策略',
        'exp5_content': '• 字母 → 数字 → 符号的学习顺序最科学\n• 先掌握基础字母，再学习数字和符号\n• 循序渐进，避免信息过载，提高学习效率',
        
        // 中文摩斯电码测试解释内容
        'cexp1_title': '中文摩尔斯电码的定义',
        'cexp1_content': '• 中文摩尔斯电码是专门为中文汉字设计的编码系统\n• 通过点（·）和划（-）的组合表示中文字符\n• 结合了传统摩尔斯电码原理和中文语言特点\n• 为中文通信提供了标准化的编码方案',
        'cexp2_title': '编码长度的特点',
        'cexp2_content': '• 中文摩尔斯电码的编码通常比英文更长\n• 这是因为中文字符数量庞大，需要更多点划组合\n• 每个汉字都有唯一的摩尔斯电码表示\n• 编码长度增加是为了确保字符的唯一性',
        'cexp3_title': '历史发展背景',
        'cexp3_content': '• 1920 年代：初步制定中文摩尔斯电码标准\n• 当时为了适应中文电报通信的需求\n• 国际电信联盟（ITU）参与制定\n• 经过多次优化形成现代标准',
        'cexp4_title': '应用场景分析',
        'cexp4_content': '• 军事通信：部队间的秘密通信\n• 航空通信：飞行员与地面控制塔通信\n• 航海通信：船舶间通信\n• 网络聊天不属于传统应用场景',
        'cexp5_title': '学习策略建议',
        'cexp5_content': '• 从基础汉字开始学习最科学\n• 基础汉字使用频率高，容易记忆\n• 循序渐进，避免信息过载\n• 建立学习信心，提高学习效率',
      
      // 翻译模块
      'text_to_morse': '文本 → 电码',
      'morse_to_text': '电码 → 文本',
      'input_text_placeholder': '在此输入文本，如: Hello World',
      'input_morse_placeholder': '在此输入电码，如: ··· --- ···',
      'output_text_placeholder': '电码将在此显示',
      'output_morse_placeholder': '文本将在此显示',
      
      // 码表模块
      'standard_chinese_telegraph_code': '标准中文电码',
      'chinese_characters': '汉字',
      'telegraph_code': '电码',
      'searching': '搜索中...',
      'no_data': '暂无数据',
      
      // 个人中心
      'rating_feedback': '评分和反馈',
      'share_app': '分享应用',
      'other_apps': '其他应用',
      'version': '版本',
      'copyright': '© 2025 重庆豆花科技有限公司',
      
      
      // 分享内容
      'share_text': '推荐一款学习摩尔斯电码的应用：\n《摩斯电码通》📡\n\n• 从零学习摩尔斯电码\n• 跟读练习与听力训练\n• 文本与摩斯互相翻译\n\n立即下载：\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode',
      'share_copied': '分享内容已复制到剪贴板',
      
      // 课程标题 - 每个单元内部编号
      'lesson_1': '第 1 课',
      'lesson_2': '第 2 课', 
      'lesson_3': '第 3 课',
      'lesson_4': '第 4 课',
      'lesson_5': '第 5 课',
      'lesson_6': '第 6 课',
      'lesson_7': '第 7 课',
      'lesson_8': '第 8 课',
      'lesson_9': '第 9 课',
      'alphabet_abc': 'A B C',
      'alphabet_def': 'D E F',
      'alphabet_ghij': 'G H I J',
      'alphabet_review_aj': '复习：A-J',
      'alphabet_klmn': 'K L M N',
      'alphabet_opqr': 'O P Q R',
      'alphabet_stuv': 'S T U V',
      'alphabet_wxyz': 'W X Y Z',
      'alphabet_review_kz': '复习：K-Z',
      'numbers_123': '1 2 3',
      'numbers_456': '4 5 6',
      'numbers_7890': '7 8 9 0',
      'numbers_review': '复习：0-9',
      'punctuation_basic': '. , ? ! : ;',
      'punctuation_advanced': '= + - _ " \' ( ) / @',
      'punctuation_review': '复习',
      'words_3letter': '3字母单词',
      'words_4letter': '4字母单词',
      'words_5letter': '5字母单词',
      'all_codes': '所有码',
      'letters': '字母',
      'numbers': '数字',
      'punctuation': '标点符号',
      'practice_favorites': '练习收藏的字母',
      'mistakes_desc': '复习做错的字母',
      'favorites_empty': '收藏夹为空，先去练习一些字母吧！',
      'mistakes_empty': '错题本为空，还没有错题哦！',
      // 其他应用/外链
      'periodic_table_app': '掌上元素周期表',
      // 其他页面用到的键
      'please_complete_previous_lessons': '请先完成前面的课程',
      'basics_test': '基础测试',
      'chinese_morse_code': '中文摩尔斯电码',
      'chinese_code_test': '中文电码测试'
    }

    // 英文字典
    this.dictionaries['en-US'] = {
      // 应用基础
      'app_name': 'Morse Code',
      'app_tagline': 'Make learning Morse code simple and fun',
      
      // 主导航
      'learn': 'Learn',
      'practice': 'Practice',
      'translate': 'Translate', 
      'code_table': 'Code Table',
      'me': 'Me',
      
      // 通用操作
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'close': 'OK',
      'back': 'Back',
      'next': 'Next',
      'loading': 'Loading...',
      'copied': 'Copied to clipboard',
      'got_it': 'Got it',
      'settings': 'Settings',
      'sound': 'Sound',
      
      // 语言设置
      'language': 'Language',
      'language_selection_title': 'Select Language',
      'language_selection_content': 'Choose your preferred language for the app interface',
      'chinese': '中文',
      'english': 'English',
      'language_switched': 'Language switched to English',
      'language_switch_failed': 'Language switch failed, please try again later',
      
      // 学习模块
      'morse_code_basics': 'Morse Code Basics',
      'morse_code_intro': 'Morse code is a character encoding system based on "dots (·) and dashes (-)". Different combinations of dots and dashes represent letters, numbers, and symbols.',
      'alphabet_lesson': 'Alphabet',
      'number_lesson': 'Number',
      'punctuation_lesson': 'Punctuation',
      'word_lesson': 'Word',
      'review_lesson': 'Review',
      'lesson_completed': 'Completed',
      'next_lesson': 'Next Lesson',
      'start_test': 'Start Test',
      'your_score': 'Your Score',
      'congratulations_passed': 'Congratulations!',
      'keep_trying': 'Keep trying!',
      
      // 练习模块
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'easy_desc': 'Letters Only',
      'medium_desc': 'Letters + Numbers',
      'hard_desc': 'All Characters',
      'favorites': 'Favorites',
      'mistakes': 'Mistakes',
      'practice_again': 'Practice Again',
      'practice_count': 'Practice Count',
      'favorite_added': 'Added to favorites',
      'favorite_removed': 'Removed from favorites',
        'practice_records': 'Practice Records',
        'practiced': 'Practiced',
        'total': 'Total',
        'learning_completed': 'Learning Completed',
        
        // 测试页面相关
        'you_mastered_basics': 'You have mastered the basics of Morse code',
        'need_100_to_pass': 'Need 100 points to pass the test',
        'test_your_mastery': 'Test your mastery of this lesson',
        'test_content': 'Test Content',
        'test_format_1': '• 2 True/False questions (20 points each)',
        'test_format_2': '• 3 Multiple choice questions (20 points each)',
        'retake_test': 'Retake Test',
        'next_question': 'Next Question',
        'view_results': 'View Results',
        'correct': 'Correct',
        'wrong': 'Wrong',
        
        // 基础测试问题和选项
        'q1_question': 'Morse code is a character encoding system based on "dots (·) and dashes (-)".',
        'q1_options': 'Correct,Wrong',
        'q2_question': 'The SOS signal in Morse code is ··· --- ···, and normal character spacing should be maintained between characters.',
        'q2_options': 'Correct,Wrong',
        'q3_question': 'In Morse code timing rules, the unit ratio of dots, dashes, and character spacing is:',
        'q3_options': '1 : 2 : 5,1 : 3 : 7,1 : 4 : 8,2 : 3 : 6',
        'q4_question': 'In which era was Morse code developed?',
        'q4_options': '1820s,1830-1840s,1850s,1860s',
        'q5_question': 'The recommended learning order for Morse code is:',
        'q5_options': 'Numbers → Letters → Symbols,Symbols → Letters → Numbers,Letters → Numbers → Symbols,Random learning',
        
        // 中文摩斯电码测试问题和选项
        'cq1_question': 'Chinese Morse code is a Morse code system specifically designed for Chinese characters.',
        'cq1_options': 'Correct,Wrong',
        'cq2_question': 'Chinese Morse code encoding is typically shorter than English Morse code.',
        'cq2_options': 'Correct,Wrong',
        'cq3_question': 'In which era was Chinese Morse code first established?',
        'cq3_options': '1900s,1920s,1950s,1980s',
        'cq4_question': 'Which of the following is NOT an application scenario for Chinese Morse code?',
        'cq4_options': 'Military communication,Aviation communication,Online chat,Maritime communication',
        'cq5_question': 'The recommended learning order for Chinese Morse code is:',
        'cq5_options': 'Start with complex characters,Start with basic characters,Random learning,Start with punctuation',
        
        // 基础测试解释内容
        'exp1_title': 'Basic Elements of Morse Code',
        'exp1_content': '• Morse code is based on "dots (·) and dashes (-)"\n• Different combinations of dots and dashes represent letters, numbers, and symbols\n• This is the foundation of all Morse code and must be mastered',
        'exp2_title': 'SOS Signal',
        'exp2_content': '• SOS is an emergency distress signal that needs quick recognition\n• Compact transmission: The three characters (··· --- ···) are sent compactly without normal character spacing\n• Standard spacing rules: Normally, Morse code characters should have 3-unit spacing between them\n• SOS exception: But SOS, as an emergency signal, ignores this rule and sends compactly for faster recognition',
        'exp3_title': 'Importance of Timing Rules',
        'exp3_content': '• The 1:3:7 ratio is the core rule of Morse code\n• Dot = 1 unit, Dash = 3 units, Character spacing = 3 units, Word spacing = 7 units\n• This precise timing ensures accuracy and readability of information transmission',
        'exp4_title': 'Historical Background',
        'exp4_content': '• Samuel Morse and Alfred Vail collaborated in the 1830-1840s\n• Initially used for telegraph systems, later evolved into international Morse code\n• Became the global standard for radio communication encoding',
        'exp5_title': 'Learning Strategy',
        'exp5_content': '• Letters → Numbers → Symbols is the most scientific learning order\n• Master basic letters first, then learn numbers and symbols\n• Progressive learning to avoid information overload and improve efficiency',
        
        // 中文摩斯电码测试解释内容
        'cexp1_title': 'Definition of Chinese Morse Code',
        'cexp1_content': '• Chinese Morse code is a coding system specifically designed for Chinese characters\n• Uses combinations of dots (·) and dashes (-) to represent Chinese characters\n• Combines traditional Morse code principles with Chinese language characteristics\n• Provides standardized encoding for Chinese communication',
        'cexp2_title': 'Characteristics of Encoding Length',
        'cexp2_content': '• Chinese Morse code encoding is typically longer than English Morse code\n• This is because Chinese characters are numerous and require more dot-dash combinations\n• Each Chinese character has a unique Morse code representation\n• Increased encoding length ensures character uniqueness',
        'cexp3_title': 'Historical Development Background',
        'cexp3_content': '• 1920s: Initial establishment of Chinese Morse code standards\n• Developed to meet the needs of Chinese telegraph communication\n• International Telecommunication Union (ITU) participated in development\n• Modern standards formed through multiple optimizations',
        'cexp4_title': 'Application Scenario Analysis',
        'cexp4_content': '• Military communication: Secret communication between troops\n• Aviation communication: Communication between pilots and ground control towers\n• Maritime communication: Communication between ships\n• Online chat is not a traditional application scenario',
        'cexp5_title': 'Learning Strategy Recommendations',
        'cexp5_content': '• Starting with basic characters is most scientific\n• Basic characters are used frequently and easy to remember\n• Progressive learning to avoid information overload\n• Build learning confidence and improve efficiency',
      
      // 翻译模块
      'text_to_morse': 'Text → Morse',
      'morse_to_text': 'Morse → Text',
      'input_text_placeholder': 'Enter text here, e.g., Hello World',
      'input_morse_placeholder': 'Enter Morse here, e.g., ··· --- ···',
      'output_text_placeholder': 'Morse will display here',
      'output_morse_placeholder': 'Text will display here',
      
      // 码表模块
      'standard_chinese_telegraph_code': 'Standard Chinese Telegraph Code',
      'chinese_characters': 'Chinese Characters',
      'telegraph_code': 'Telegraph Code',
      'searching': 'Searching...',
      'no_data': 'No Data',
      
      // 个人中心
      'rating_feedback': 'Rating & Feedback',
      'share_app': 'Share App',
      'other_apps': 'Other Apps',
      'version': 'Version',
      'copyright': '© 2025 Douhua Technology Co., Ltd.',
      
      
      // 分享内容
      'share_text': 'Recommend a Morse code learning app:\n《Morse Code Master》📡\n\n• Learn Morse code from scratch\n• Follow-along practice and listening training\n• Text and Morse code translation\n\nDownload now:\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode',
      'share_copied': 'Share content copied to clipboard',
      
      // 课程标题 - 每个单元内部编号
      'lesson_1': 'Lesson 1',
      'lesson_2': 'Lesson 2',
      'lesson_3': 'Lesson 3', 
      'lesson_4': 'Lesson 4',
      'lesson_5': 'Lesson 5',
      'lesson_6': 'Lesson 6',
      'lesson_7': 'Lesson 7',
      'lesson_8': 'Lesson 8',
      'lesson_9': 'Lesson 9',
      'alphabet_abc': 'A B C',
      'alphabet_def': 'D E F',
      'alphabet_ghij': 'G H I J',
      'alphabet_review_aj': 'Review: A - J',
      'alphabet_klmn': 'K L M N',
      'alphabet_opqr': 'O P Q R',
      'alphabet_stuv': 'S T U V',
      'alphabet_wxyz': 'W X Y Z',
      'alphabet_review_kz': 'Review: K - Z',
      'numbers_123': '1 2 3',
      'numbers_456': '4 5 6',
      'numbers_7890': '7 8 9 0',
      'numbers_review': 'Review: 0-9',
      'punctuation_basic': '. , ? ! : ;',
      'punctuation_advanced': '= + - _ " \' ( ) / @',
      'punctuation_review': 'Review',
      'words_3letter': '3-Letter Words',
      'words_4letter': '4-Letter Words',
      'words_5letter': '5-Letter Words',
      'all_codes': 'All',
      'letters': 'Letters',
      'numbers': 'Numbers',
      'punctuation': 'Punctuation',
      'practice_favorites': 'Practice favorite letters',
      'mistakes_desc': 'Review wrong letters',
      'favorites_empty': 'Favorites is empty, go practice some letters first!',
      'mistakes_empty': 'No mistakes yet!',
      // Other apps / external links
      'periodic_table_app': 'Periodic Table',
      // Keys used by pages
      'please_complete_previous_lessons': 'Please complete the previous lessons first',
      'basics_test': 'Basics Test',
      'chinese_morse_code': 'Chinese Morse Code',
      'chinese_code_test': 'Chinese Code Test'
    }
  }

  /**
   * 初始化I18n服务
   * @param context 应用上下文
   */
  async init(context: Context): Promise<void> {
    try {
      // 初始化Preferences
      this.preferences = await preferences.getPreferences(context, 'i18n_settings')
      
      // 读取保存的语言设置
      const savedLang = await this.preferences.get('current_language', 'zh-CN') as string
      
      // 验证语言代码有效性
      if (this.isLanguageSupported(savedLang)) {
        this.currentLang = savedLang
      } else {
        // 尝试从系统语言推断
        this.currentLang = this.detectSystemLanguage()
      }
      
      // 设置到AppStorage，供全局访问
      AppStorage.setOrCreate('currentLanguage', this.currentLang)
      
      console.log('[I18nService] Initialized with language:', this.currentLang)
    } catch (error) {
      console.error('[I18nService] Failed to initialize:', error)
      // 默认中文
      this.currentLang = 'zh-CN'
      AppStorage.setOrCreate('currentLanguage', this.currentLang)
    }
  }

  /**
   * 获取翻译文本
   * @param key 翻译键
   * @param params 模板参数（可选）
   * @returns 翻译后的文本
   */
  t(key: string, params?: TemplateParams): string {
    const dictionary = this.dictionaries[this.currentLang]
    if (!dictionary) {
      console.warn(`[I18nService] Dictionary not found for language: ${this.currentLang}`)
      return key
    }

    let text = dictionary[key]
    if (!text) {
      console.warn(`[I18nService] Translation key not found: ${key}`)
      return key
    }

    // 处理模板参数
    if (params) {
      const paramKeys = Object.keys(params)
      for (let i = 0; i < paramKeys.length; i++) {
        const paramKey = paramKeys[i]
        const placeholder = `{${paramKey}}`
        const paramValue = params[paramKey]
        text = text.replace(new RegExp(placeholder, 'g'), String(paramValue))
      }
    }

    return text
  }

  /**
   * 切换语言
   * @param languageCode 目标语言代码
   */
  async setLanguage(languageCode: string): Promise<void> {
    try {
      if (!this.isLanguageSupported(languageCode)) {
        console.error(`Unsupported language: ${languageCode}`)
        return
      }

      if (languageCode === this.currentLang) {
        return // 语言相同，无需切换
      }

      // 更新当前语言
      this.currentLang = languageCode
      
      // 语言切换已统一到 I18nService，无需同步其他服务
      
      // 更新AppStorage，触发UI重新渲染
      AppStorage.setOrCreate('currentLanguage', this.currentLang)
      
      // 强制触发UI刷新 - 通过临时改变再恢复的方式
      const tempKey = 'languageRefreshTrigger'
      const currentTrigger = AppStorage.get<number>(tempKey) || 0
      AppStorage.setOrCreate(tempKey, currentTrigger + 1)

      // 异步保存到Preferences
      if (this.preferences) {
        await this.preferences.put('current_language', languageCode)
        await this.preferences.flush()
      }
      
      console.log('[I18nService] Language switched to:', languageCode)
    } catch (error) {
      console.error('[I18nService] Failed to switch language:', error)
    }
  }

  /**
   * 获取当前语言
   * @returns 当前语言代码
   */
  getCurrentLanguage(): string {
    return this.currentLang
  }

  /**
   * 获取支持的语言列表
   * @returns 支持的语言选项数组
   */
  getSupportedLanguages(): LanguageOption[] {
    return [...this.supportedLanguages]
  }

  /**
   * 判断是否为中文
   * @returns 是否为中文
   */
  isChinese(): boolean {
    return this.currentLang.startsWith('zh')
  }

  /**
   * 判断是否为英文
   * @returns 是否为英文
   */
  isEnglish(): boolean {
    return this.currentLang.startsWith('en')
  }

  /**
   * 检查语言是否支持
   * @param languageCode 语言代码
   * @returns 是否支持
   */
  private isLanguageSupported(languageCode: string): boolean {
    return this.supportedLanguages.some(lang => lang.code === languageCode)
  }

  /**
   * 检测系统语言
   * @returns 系统语言代码
   */
  private detectSystemLanguage(): string {
    // 默认返回中文
    return 'zh-CN'
  }

  /**
   * 添加或更新字典条目
   * @param languageCode 语言代码
   * @param key 翻译键
   * @param value 翻译值
   */
  addTranslation(languageCode: string, key: string, value: string): void {
    if (!this.dictionaries[languageCode]) {
      this.dictionaries[languageCode] = {}
    }
    this.dictionaries[languageCode][key] = value
  }

  /**
   * 批量添加翻译
   * @param languageCode 语言代码
   * @param translations 翻译对象
   */
  addTranslations(languageCode: string, translations: Dictionary): void {
    if (!this.dictionaries[languageCode]) {
      this.dictionaries[languageCode] = {}
    }
    // 手动合并对象属性，避免使用 Object.assign 和 for...in
    const keys = Object.keys(translations)
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i]
      this.dictionaries[languageCode][key] = translations[key]
    }
  }
}

// 导出单例实例
export const i18nService = I18nService.getInstance()

// 导出全局翻译函数，方便使用
export const t = (key: string, params?: TemplateParams): string => {
  return i18nService.t(key, params)
}
