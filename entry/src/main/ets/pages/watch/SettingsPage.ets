import router from '@ohos.router'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { audioService } from '../../services/AudioService'

@Component
export struct SettingsPage {
  @State soundEnabled: boolean = true
  @State vibrationEnabled: boolean = true
  @State longPressThreshold: number = 300
  
  private practiceSettingsStore: preferences.Preferences | null = null

  async aboutToAppear() {
    await this.initPreferences()
    await this.loadSettings()
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.practiceSettingsStore = await preferences.getPreferences(context, 'practice_settings')
      }
    } catch (error) {
      console.error('[SettingsPage] Failed to initialize preferences:', error)
    }
  }

  // 加载设置
  private async loadSettings(): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        this.longPressThreshold = await this.practiceSettingsStore.get('long_press_threshold', 300) as number
        this.vibrationEnabled = await this.practiceSettingsStore.get('vibration_enabled', true) as boolean
        this.soundEnabled = await this.practiceSettingsStore.get('sound_enabled', true) as boolean
        
        // 更新音频服务状态
        audioService.setSoundEnabled(this.soundEnabled)
      }
    } catch (error) {
      console.error('[SettingsPage] Failed to load settings:', error)
    }
  }

  // 保存长按时间阈值
  private async saveLongPressThreshold(value: number): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        await this.practiceSettingsStore.put('long_press_threshold', value)
        await this.practiceSettingsStore.flush()
      }
    } catch (error) {
      console.error('[SettingsPage] Failed to save longPressThreshold:', error)
    }
  }

  // 保存振动设置
  private async saveVibrationEnabled(enabled: boolean): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        await this.practiceSettingsStore.put('vibration_enabled', enabled)
        await this.practiceSettingsStore.flush()
      }
    } catch (error) {
      console.error('[SettingsPage] Failed to save vibration enabled:', error)
    }
  }

  // 保存声音设置
  private async saveSoundEnabled(enabled: boolean): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        await this.practiceSettingsStore.put('sound_enabled', enabled)
        await this.practiceSettingsStore.flush()
        audioService.setSoundEnabled(enabled)
      }
    } catch (error) {
      console.error('[SettingsPage] Failed to save sound enabled:', error)
    }
  }

  build() {
    Column() {
      // 标题栏
      Text(LocalizationHelper.getString('watch_settings'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 15, bottom: 10 })
      
      Scroll() {
        Column() {
          // 声音设置
          Row() {
            Text(LocalizationHelper.getString('sound'))
              .fontSize(16)
              .fontColor('#FFFFFF')

              Row() {}.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.soundEnabled })
              .selectedColor('#FFD700')
              .onChange(async (isOn: boolean) => {
                this.soundEnabled = isOn
                await this.saveSoundEnabled(isOn)
              })
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .margin({ top: 6, bottom: 6 })

          // 振动反馈设置
          Row() {
            Text(LocalizationHelper.getString('watch_vibration_feedback'))
              .fontSize(16)
              .fontColor('#FFFFFF')

              Row() {}.layoutWeight(1)

            
            Toggle({ type: ToggleType.Switch, isOn: this.vibrationEnabled })
              .selectedColor('#FFD700')
              .onChange(async (isOn: boolean) => {
                this.vibrationEnabled = isOn
                await this.saveVibrationEnabled(isOn)
              })
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .margin({ top: 6, bottom: 6 })

          // 长按时间阈值设置
          Column() {
            Row() {
              Text(LocalizationHelper.getString('watch_long_press_duration'))
                .fontSize(16)
                .fontColor('#FFFFFF')
              Row() {}.layoutWeight(1)
              Text(`${this.longPressThreshold}ms`)
                .fontSize(14)
                .fontColor('#FFD700')
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            Slider({
              value: this.longPressThreshold,
              min: 100,
              max: 600,
              step: 25
            })
            .blockColor('#FFD700')
            .trackColor('#333333')
            .selectedColor('#FFD700')
            .trackThickness(4)
            .blockSize({ width: 16, height: 16 })
            .onChange(async (value: number) => {
              this.longPressThreshold = value
              await this.saveLongPressThreshold(value)
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .margin({ top: 6, bottom: 6 })

          // 应用推荐 - 指尖找茬
          Row() {
            Image($r('app.media.appicon_zhaocha'))
              .width(32)
              .height(32)
              .borderRadius(16)
              .objectFit(ImageFit.Contain)

            Text($r('app.string.app_recommendation_zhaocha_name'))
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ left: 12 })
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('›')
              .fontSize(18)
              .fontColor('rgba(255, 255, 255, 0.6)')
          }
          .width('100%')
          .height(56)
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .margin({ top: 6, bottom: 6 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/watch/AppRecommendationDetail',
              params: { appType: 'zhaocha' }
            }).catch((err: Error) => {
              console.error(`[SettingsPage] Navigation failed: ${err.message}`)
            })
          })

          // 应用推荐 - 全能计分器
          Row() {
            Image($r('app.media.appicon_quannengjifenqi'))
              .width(32)
              .height(32)
              .borderRadius(16)
              .objectFit(ImageFit.Contain)

            Text($r('app.string.app_recommendation_quannengjifenqi_name'))
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ left: 12 })
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('›')
              .fontSize(18)
              .fontColor('rgba(255, 255, 255, 0.6)')
          }
          .width('100%')
          .height(56)
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .margin({ top: 6, bottom: 6 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/watch/AppRecommendationDetail',
              params: { appType: 'quannengjifenqi' }
            }).catch((err: Error) => {
              console.error(`[SettingsPage] Navigation failed: ${err.message}`)
            })
          })

          // 底部文本
          Column() {
            Text(LocalizationHelper.getString('watch_phone_version_richer'))
              .fontSize(12)
              .fontColor('rgba(255, 255, 255, 0.6)')
              .textAlign(TextAlign.Center)
              .margin({ top: 16, bottom: 8 })
            
            Text(LocalizationHelper.getString('watch_company_name'))
              .fontSize(11)
              .fontColor('rgba(255, 255, 255, 0.5)')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('80%')
        .padding({ left: 8, right: 16, top: 8, bottom: 40 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .focusable(true)
      .defaultFocus(true)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}

