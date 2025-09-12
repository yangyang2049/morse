import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

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
  private currentLang: string = 'zh'
  
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
      'app_name': '摩斯密码',
      'app_tagline': '让学习摩斯密码简单又有趣',
      
      // 主导航
      'learn': '学习',
      'practice': '练习', 
      'translate': '翻译',
      'code_table': '码表',
      'me': '我',
      
      // 通用操作
      'confirm': '确认',
      'cancel': '取消',
      'close': '关闭',
      'back': '返回',
      'next': '下一步',
      'loading': '加载中...',
      'copied': '已复制到剪贴板',
      'got_it': '知道了',
      
      // 语言设置
      'language': '语言',
      'language_selection_title': '选择语言',
      'language_selection_content': '选择您偏好的应用界面语言',
      'chinese': '中文',
      'english': 'English',
      'language_switched': '语言已切换为中文',
      'language_switch_failed': '语言切换失败，请稍后重试',
      
      // 学习模块
      'morse_code_basics': '摩斯密码基础',
      'alphabet_lesson': '字母',
      'number_lesson': '数字',
      'punctuation_lesson': '符号',
      'word_lesson': '单词',
      'review_lesson': '复习',
      'lesson_completed': '完成',
      'next_lesson': '下一课',
      'start_test': '开始测试',
      'your_score': '你的分数',
      'congratulations_passed': '🎉 恭喜通过！',
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
      'favorite_added': '已收藏',
      'favorite_removed': '已取消收藏',
      'practice_records': '练习记录',
      'practiced': '已练习',
      'total': '总计',
      
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
      'instructions': '使用说明',
      'rating_feedback': '评分和反馈',
      'share_app': '分享应用',
      'other_apps': '其他应用',
      'version': '版本',
      'copyright': '© 2025 重庆豆花科技有限公司',
      
      // 使用说明
      'instructions_title': '使用说明',
      'instructions_content': '1. 学习：从基础课程开始，逐步掌握摩斯密码\n2. 练习：通过不同难度的练习巩固学习成果\n3. 翻译：将文字转换为摩斯密码或反向转换\n4. 码表：查看完整的摩斯密码对照表\n\n点击播放按钮可以听到摩斯密码的声音',
      
      // 分享内容
      'share_text': '推荐一款学习摩尔斯密码的应用：\n《摩斯密码 2025》📡\n\n• 从零学习摩尔斯电码\n• 跟读练习与听力训练\n• 文本与摩斯互相翻译\n\n立即下载：\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode',
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
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'loading': 'Loading...',
      'copied': 'Copied to clipboard',
      'got_it': 'Got it',
      
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
      'alphabet_lesson': 'Alphabet',
      'number_lesson': 'Number',
      'punctuation_lesson': 'Punctuation',
      'word_lesson': 'Word',
      'review_lesson': 'Review',
      'lesson_completed': 'Completed',
      'next_lesson': 'Next Lesson',
      'start_test': 'Start Test',
      'your_score': 'Your Score',
      'congratulations_passed': '🎉 Congratulations! You passed!',
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
      'instructions': 'Instructions',
      'rating_feedback': 'Rating & Feedback',
      'share_app': 'Share App',
      'other_apps': 'Other Apps',
      'version': 'Version',
      'copyright': '© 2025 Douhua Technology Co., Ltd.',
      
      // 使用说明
      'instructions_title': 'Instructions',
      'instructions_content': '1. Learn: Start with basic courses to master Morse code\n2. Practice: Consolidate learning through different difficulty levels\n3. Translate: Convert text to Morse code or vice versa\n4. Code Table: View the complete Morse code reference table\n\nClick the play button to hear the Morse code sound',
      
      // 分享内容
      'share_text': 'Recommend a Morse code learning app:\n《Morse Code 2025》📡\n\n• Learn Morse code from scratch\n• Follow-along practice and listening training\n• Text and Morse code translation\n\nDownload now:\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode',
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
      Object.keys(params).forEach(paramKey => {
        const placeholder = `{${paramKey}}`
        text = text.replace(new RegExp(placeholder, 'g'), String(params[paramKey]))
      })
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
      
      // 更新AppStorage，触发UI重新渲染
      AppStorage.setOrCreate('currentLanguage', this.currentLang)
      
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
