import { advertising } from '@kit.AdsKit'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * 广告服务
 * 管理广告初始化和配置
 */
export class AdService {
  private static instance: AdService | null = null
  private isInitialized: boolean = false
  private appId: string = '' // 需要替换为实际的 App ID

  private constructor() {}

  static getInstance(): AdService {
    if (!AdService.instance) {
      AdService.instance = new AdService()
    }
    return AdService.instance
  }

  /**
   * 初始化广告服务
   * @param appId 应用ID（从华为广告平台获取）
   * @param debug 是否开启调试模式
   */
  async init(appId: string, debug: boolean = false): Promise<void> {
    if (this.isInitialized) {
      console.log('[AdService] Already initialized')
      return
    }

    try {
      this.appId = appId
      await advertising.init({
        appId: appId,
        debug: debug
      })
      this.isInitialized = true
      console.log('[AdService] Initialized successfully')
    } catch (error) {
      const err = error as BusinessError
      console.error(`[AdService] Initialization failed: code=${err.code}, message=${err.message}`)
      throw error
    }
  }

  /**
   * 检查是否已初始化
   */
  isServiceInitialized(): boolean {
    return this.isInitialized
  }

  /**
   * 获取应用ID
   */
  getAppId(): string {
    return this.appId
  }
}

// 导出单例实例
export const adService = AdService.getInstance()




