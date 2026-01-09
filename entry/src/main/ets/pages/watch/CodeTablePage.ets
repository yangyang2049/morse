import { MorseCodeData, MorseCode } from '../../models/MorseCode'
import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'
import { audioService } from '../../services/AudioService'
import { vibratorService } from '../../services/VibratorService'
import { Context } from '@kit.AbilityKit'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import preferences from '@ohos.data.preferences'

@Component
export struct CodeTablePage {
  @State vibrationEnabled: boolean = true
  
  private vibrationTimers: number[] = []
  private playMorseCodeTimer: number | null = null

  async aboutToAppear() {
    // 初始化音频服务
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        await audioService.init(context)
      }
    } catch (error) {
      console.error('[CodeTablePage] Failed to initialize audio service:', error)
    }
    
    // 加载振动设置
    await this.loadVibrationPreference()
  }

  aboutToDisappear() {
    this.clearVibrationTimers()
    if (this.playMorseCodeTimer) {
      clearTimeout(this.playMorseCodeTimer)
      this.playMorseCodeTimer = null
    }
  }

  // 加载振动偏好设置
  private async loadVibrationPreference(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        const preferencesStore = await preferences.getPreferences(context, 'practice_settings')
        this.vibrationEnabled = await preferencesStore.get('vibration_enabled', true) as boolean
      }
    } catch (error) {
      console.error('[CodeTablePage] Failed to load vibration preference:', error)
    }
  }

  // 清理振动定时器
  private clearVibrationTimers() {
    this.vibrationTimers.forEach(id => clearTimeout(id))
    this.vibrationTimers = []
  }

  // 通过振动播放摩斯码
  private playMorseVibration(morse: string): void {
    if (!morse || !vibratorService.isVibrationEnabled()) return

    this.clearVibrationTimers()

    let delay = 0
    for (let i = 0; i < morse.length; i++) {
      const char = morse[i]
      if (char === '·' || char === '.') {
        const timerId = setTimeout(() => {
          if (vibratorService.isVibrationEnabled()) {
            vibrator.vibrate(100, (error: BusinessError) => {
              if (error) {
                console.error(`[CodeTablePage] Failed to vibrate: ${error.message}`)
              }
            })
          }
        }, delay)
        this.vibrationTimers.push(timerId)
        delay += 200
      } else if (char === '-') {
        const timerId = setTimeout(() => {
          if (vibratorService.isVibrationEnabled()) {
            vibrator.vibrate(300, (error: BusinessError) => {
              if (error) {
                console.error(`[CodeTablePage] Failed to vibrate: ${error.message}`)
              }
            })
          }
        }, delay)
        this.vibrationTimers.push(timerId)
        delay += 400
      } else if (char === ' ') {
        delay += 200
      } else if (char === '/') {
        delay += 600
      }
    }
  }

  // 播放摩斯码（音频 + 振动）
  private async playMorseCode(morse: string): Promise<void> {
    if (!morse) return

    if (this.playMorseCodeTimer) {
      clearTimeout(this.playMorseCodeTimer)
      this.playMorseCodeTimer = null
    }

    // 将 · 替换为 . 以便音频服务识别
    const normalizedMorse = morse.replace(/·/g, '.')

    // 同时播放音频和振动
    const audioPromise = audioService.playMorseSequence(normalizedMorse)
    const vibrationPromise = new Promise<void>((resolve) => {
      this.playMorseVibration(morse)
      // 估算振动播放时间
      let totalDelay = 0
      for (let i = 0; i < morse.length; i++) {
        const char = morse[i]
        if (char === '·' || char === '.') {
          totalDelay += 200
        } else if (char === '-') {
          totalDelay += 400
        } else if (char === ' ') {
          totalDelay += 200
        } else if (char === '/') {
          totalDelay += 600
        }
      }
      this.playMorseCodeTimer = setTimeout(() => {
        resolve()
        this.playMorseCodeTimer = null
      }, totalDelay)
    })

    // 等待音频和振动都完成
    await Promise.all([audioPromise, vibrationPromise])
  }

  build() {
    Column() {
      // 标题栏
      Text(LocalizationHelper.getString('watch_code_table'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })
      
      List() {
        ListItem() {
          Text(LocalizationHelper.getString('click_to_play_vibrate'))
            .fontSize(12)
            .fontColor('#AAAAAA')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 12 })
        }

        ForEach(MorseCodeData.getAllCodes(), (code: MorseCode) => {
          ListItem() {
            Row() {
              Text(code.character)
                .fontSize(20)
                .fontColor('#FFD700')
                .fontWeight(FontWeight.Bold)
                .width(50)
                .textAlign(TextAlign.Center)

              Text(code.morse)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .layoutWeight(1)
            }
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('rgba(255, 255, 255, 0.1)')
            .borderRadius(8)
            .clickEffect({ level: ClickEffectLevel.LIGHT })
          }
          .onClick(() => {
            // 播放摩斯码（音频 + 振动）
            const morse = code.morse.replace(/\./g, '·')
            this.playMorseCode(morse)
          })
          .margin({ bottom: 8 })
        })
      }
      .width('80%')
      .layoutWeight(1)
      .cachedCount(10)
      .focusable(true)
      .defaultFocus(true)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
  }
}

