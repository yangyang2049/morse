import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * 振动服务
 * 提供摩斯码播放时的振动反馈和答题反馈
 */
export class VibratorService {
  private static instance: VibratorService | null = null
  private isEnabled: boolean = true // 默认开启

  private constructor() {}

  static getInstance(): VibratorService {
    if (!VibratorService.instance) {
      VibratorService.instance = new VibratorService()
    }
    return VibratorService.instance
  }

  // 设置是否启用振动
  setEnabled(enabled: boolean): void {
    this.isEnabled = enabled
    console.log(`[VibratorService] Vibration ${enabled ? 'enabled' : 'disabled'}`)
  }

  // 检查是否启用
  isVibrationEnabled(): boolean {
    return this.isEnabled
  }

  // 短振动（点）- 遵循摩斯码标准，点的时长为基准单位
  async vibrateDit(): Promise<void> {
    if (!this.isEnabled) {
      console.log('[VibratorService] Vibration disabled, skipping dit')
      return
    }
    try {
      console.log('[VibratorService] Vibrating dit...')
      // 点：100ms（基准单位）
      vibrator.vibrate(100, (error: BusinessError) => {
        if (error) {
          console.error(`[VibratorService] Failed to vibrate dit: code=${error.code}, message=${error.message}`)
        } else {
          console.log('[VibratorService] Dit vibration completed')
        }
      })
    } catch (error) {
      const err = error as BusinessError
      console.error(`[VibratorService] Failed to vibrate dit: code=${err.code}, message=${err.message}`)
    }
  }

  // 长振动（划）- 摩斯码标准：划的时长 = 3倍点的时长
  async vibrateDah(): Promise<void> {
    if (!this.isEnabled) {
      console.log('[VibratorService] Vibration disabled, skipping dah')
      return
    }
    try {
      console.log('[VibratorService] Vibrating dah...')
      // 划：300ms（3倍点的时长）- 更明显的长振
      vibrator.vibrate(300, (error: BusinessError) => {
        if (error) {
          console.error(`[VibratorService] Failed to vibrate dah: code=${error.code}, message=${error.message}`)
        } else {
          console.log('[VibratorService] Dah vibration completed')
        }
      })
    } catch (error) {
      const err = error as BusinessError
      console.error(`[VibratorService] Failed to vibrate dah: code=${err.code}, message=${err.message}`)
    }
  }

  // 答对反馈（短促两次振动）
  async vibrateSuccess(): Promise<void> {
    if (!this.isEnabled) {
      console.log('[VibratorService] Vibration disabled, skipping success')
      return
    }
    try {
      console.log('[VibratorService] Vibrating success...')
      // 第一次短振
      vibrator.vibrate(50, (error: BusinessError) => {
        if (error) {
          console.error(`[VibratorService] Failed to vibrate success (1st): code=${error.code}, message=${error.message}`)
        } else {
          // 短暂间隔后第二次振动
          setTimeout(() => {
            vibrator.vibrate(50, (error2: BusinessError) => {
              if (error2) {
                console.error(`[VibratorService] Failed to vibrate success (2nd): code=${error2.code}, message=${error2.message}`)
              } else {
                console.log('[VibratorService] Success vibration completed')
              }
            })
          }, 80)
        }
      })
    } catch (error) {
      const err = error as BusinessError
      console.error(`[VibratorService] Failed to vibrate success: code=${err.code}, message=${err.message}`)
    }
  }

  // 答错反馈（长振动）
  async vibrateError(): Promise<void> {
    if (!this.isEnabled) {
      console.log('[VibratorService] Vibration disabled, skipping error')
      return
    }
    try {
      console.log('[VibratorService] Vibrating error...')
      // 答错：250ms 中长振动
      vibrator.vibrate(250, (error: BusinessError) => {
        if (error) {
          console.error(`[VibratorService] Failed to vibrate error: code=${error.code}, message=${error.message}`)
        } else {
          console.log('[VibratorService] Error vibration completed')
        }
      })
    } catch (error) {
      const err = error as BusinessError
      console.error(`[VibratorService] Failed to vibrate error: code=${err.code}, message=${err.message}`)
    }
  }
}

// 导出单例实例
export const vibratorService = VibratorService.getInstance()

