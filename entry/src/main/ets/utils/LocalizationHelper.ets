import { i18n } from '@kit.LocalizationKit'

/** 应用支持的语言代码 */
export type AppLanguageCode = 'zh-CN' | 'zh-HK' | 'en-US'

/**
 * 本地化工具类
 * 用于获取本地化字符串资源，以及按系统语言解析应用语言
 */
export class LocalizationHelper {
  /** 无法识别系统语言时的默认语言 */
  static readonly DEFAULT_LANGUAGE: AppLanguageCode = 'en-US'

  /**
   * 获取本地化字符串
   * @param key 资源键名
   * @returns 本地化字符串
   */
  static getString(key: string): Resource {
    return $r(`app.string.${key}`)
  }

  /**
   * 将系统 / 应用偏好 locale 映射为应用语言代码。
   * 简中 → zh-CN，繁中（Hant/HK/TW/MO）→ zh-HK，英文 → en-US，其余 → en-US。
   */
  static resolveLanguageFromLocale(locale: string): AppLanguageCode {
    if (!locale || locale.length === 0) {
      return LocalizationHelper.DEFAULT_LANGUAGE
    }
    const normalized = locale.replace(/_/g, '-')
    if (normalized.startsWith('zh')) {
      if (normalized.includes('Hant') ||
        normalized.includes('HK') ||
        normalized.includes('TW') ||
        normalized.includes('MO')) {
        return 'zh-HK'
      }
      return 'zh-CN'
    }
    if (normalized.startsWith('en')) {
      return 'en-US'
    }
    return LocalizationHelper.DEFAULT_LANGUAGE
  }

  /**
   * 根据应用偏好语言（若有）或系统语言检测应用语言。
   */
  static detectPreferredLanguage(): AppLanguageCode {
    try {
      const appPreferredLanguage = i18n.System.getAppPreferredLanguage()
      const systemLocale = i18n.System.getSystemLocale()
      const languageToCheck = (appPreferredLanguage && appPreferredLanguage.length > 0)
        ? appPreferredLanguage
        : systemLocale
      console.log(`[LocalizationHelper] appPreferred=${appPreferredLanguage}, system=${systemLocale}, check=${languageToCheck}`)
      return LocalizationHelper.resolveLanguageFromLocale(languageToCheck)
    } catch (error) {
      console.error('[LocalizationHelper] Failed to detect preferred language:', error)
      return LocalizationHelper.DEFAULT_LANGUAGE
    }
  }

  /**
   * 应用语言代码 → setAppPreferredLanguage 所需的 BCP47 标签
   */
  static toAppPreferredLanguageTag(languageCode: string): string {
    if (languageCode === 'zh-CN') {
      return 'zh-Hans-CN'
    }
    if (languageCode === 'zh-HK') {
      return 'zh-Hant-HK'
    }
    if (languageCode === 'en-US') {
      return 'en-Latn-US'
    }
    return 'en-Latn-US'
  }

  /**
   * 同步系统应用偏好语言（影响 $r 资源选择）
   */
  static applyAppPreferredLanguage(languageCode: string): void {
    try {
      const preferredLanguage = LocalizationHelper.toAppPreferredLanguageTag(languageCode)
      i18n.System.setAppPreferredLanguage(preferredLanguage)
      console.log(`[LocalizationHelper] App preferred language set to: ${preferredLanguage}`)
    } catch (error) {
      console.error('[LocalizationHelper] Failed to set app preferred language:', error)
    }
  }

  /**
   * 冷启动：按系统/偏好语言写入 AppStorage，并同步应用偏好语言。
   */
  static initializeAppLanguage(): AppLanguageCode {
    const languageCode = LocalizationHelper.detectPreferredLanguage()
    AppStorage.setOrCreate('currentLanguage', languageCode)
    LocalizationHelper.applyAppPreferredLanguage(languageCode)
    console.log(`[LocalizationHelper] Initialized app language: ${languageCode}`)
    return languageCode
  }

  /**
   * 获取当前语言（AppStorage），未设置时回退为默认英文
   */
  static getCurrentLanguage(): string {
    try {
      return AppStorage.get<string>('currentLanguage') || LocalizationHelper.DEFAULT_LANGUAGE
    } catch (error) {
      console.error('[LocalizationHelper] Failed to get current language:', error)
      return LocalizationHelper.DEFAULT_LANGUAGE
    }
  }
}
