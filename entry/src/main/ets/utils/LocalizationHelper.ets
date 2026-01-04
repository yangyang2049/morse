// AppStorage is globally available, no need to import

/**
 * 本地化工具类
 * 用于获取本地化字符串资源
 */
export class LocalizationHelper {
  /**
   * 获取本地化字符串
   * @param key 资源键名
   * @returns 本地化字符串
   */
  static getString(key: string): Resource {
    return $r(`app.string.${key}`)
  }

  /**
   * 获取当前语言
   * @returns 当前语言代码
   */
  static getCurrentLanguage(): string {
    try {
      return AppStorage.get<string>('currentLanguage') || 'zh-CN'
    } catch (error) {
      console.error('[LocalizationHelper] Failed to get current language:', error)
      return 'zh-CN'
    }
  }

  /**
   * 判断是否为中文
   * @returns 是否为中文
   */
  static isChinese(): boolean {
    const lang = LocalizationHelper.getCurrentLanguage()
    return lang.startsWith('zh')
  }

  /**
   * 判断是否为英文
   * @returns 是否为英文
   */
  static isEnglish(): boolean {
    const lang = LocalizationHelper.getCurrentLanguage()
    return lang.startsWith('en')
  }
}

