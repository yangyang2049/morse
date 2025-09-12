import { languageUtils } from '../utils/LanguageUtils'
import { Context } from '@kit.AbilityKit'

interface LanguageOption {
  code: string
  name: string
}

/**
 * LanguageService - 语言服务类
 * 这个类现在作为LanguageUtils的包装器，保持向后兼容性
 * 建议新代码直接使用languageUtils
 */
export class LanguageService {
  private static instance: LanguageService

  private constructor() {}

  static getInstance(): LanguageService {
    if (!LanguageService.instance) {
      LanguageService.instance = new LanguageService()
    }
    return LanguageService.instance
  }

  /**
   * 初始化语言服务
   * @param context 应用上下文
   */
  async init(context: Context): Promise<void> {
    return languageUtils.init(context)
  }

  /**
   * 获取当前语言
   * @returns 当前语言代码
   */
  getCurrentLanguage(): string {
    return languageUtils.getCurrentLanguage()
  }

  /**
   * 设置语言
   * @param language 目标语言代码
   */
  async setLanguage(language: string): Promise<void> {
    return languageUtils.setLanguage(language)
  }

  /**
   * 判断是否为中文
   * @returns 是否为中文
   */
  isChinese(): boolean {
    return languageUtils.isChinese()
  }

  /**
   * 判断是否为英文
   * @returns 是否为英文
   */
  isEnglish(): boolean {
    return languageUtils.isEnglish()
  }

  /**
   * 获取支持的语言列表
   * @returns 支持的语言选项数组
   */
  getSupportedLanguages(): LanguageOption[] {
    return languageUtils.getSupportedLanguages()
  }
}

// 导出单例实例，保持向后兼容性
export const languageService = LanguageService.getInstance()

// 同时导出languageUtils，推荐新代码使用
export { languageUtils }
