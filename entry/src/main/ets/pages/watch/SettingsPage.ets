import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import router from '@ohos.router'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { audioService } from '../../services/AudioService'
import { vibratorService } from '../../services/VibratorService'
import { LocalLearningSettings } from '../../store/LocalLearningSettings'

@Component
export struct SettingsPage {
  @State soundEnabled: boolean = true
  @State vibrationEnabled: boolean = true
  @State longPressThreshold: number = 300
  @State repetitionCount: number = 3
  @State pendingRepetitionCount: number = 3
  @State showRepetitionDialog: boolean = false
  
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
        // 更新震动服务状态
        vibratorService.setEnabled(this.vibrationEnabled)
      }
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.repetitionCount = await LocalLearningSettings.getRepetitionCount(context)
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
        // 立即更新震动服务状态
        vibratorService.setEnabled(enabled)
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

  private async saveRepetitionCount(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.repetitionCount = await LocalLearningSettings.setRepetitionCount(context, this.pendingRepetitionCount)
        this.showRepetitionDialog = false
      }
    } catch (error) {
      console.error('[SettingsPage] Failed to save repetition count:', error)
    }
  }

  @Builder
  private RepetitionSettingsDialog() {
    Column() {
      Text(LocalizationHelper.getString('learning_repetition_count'))
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${this.pendingRepetitionCount}`)
        .width('100%')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .textAlign(TextAlign.Center)
        .margin({ top: 4, bottom: 4 })

      Slider({
        value: this.pendingRepetitionCount,
        min: 1,
        max: 5,
        step: 1,
        style: SliderStyle.OutSet
      })
        .blockColor('#FFD700')
        .trackColor('#333333')
        .selectedColor('#FFD700')
        .trackThickness(5)
        .blockSize({ width: 18, height: 18 })
        .onChange((value: number) => {
          this.pendingRepetitionCount = value
        })
        .margin({ bottom: 14 })

      Button(LocalizationHelper.getString('confirm'))
        .width('100%')
        .height(36)
        .backgroundColor('#FFD700')
        .fontColor('#000000')
        .onClick(() => {
          void this.saveRepetitionCount()
        })
    }
    .width('76%')
      .padding(14)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
  }

  build() {
    Stack() {
      Column() {
      // 标题栏
      Text(LocalizationHelper.getString('watch_settings'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFD700')
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

          Row() {
            Text(LocalizationHelper.getString('learning_repetition_count'))
              .fontSize(15)
              .fontColor('#FFFFFF')
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`${this.repetitionCount}`)
              .fontSize(14)
              .fontColor('#AAAAAA')
              .margin({ right: 6 })
            Image($rawfile('ic_arrow_right.svg'))
              .width(12)
              .height(12)
              .fillColor('#666666')
          }
          .width('100%')
          .height(56)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .margin({ top: 6, bottom: 6 })
          .onClick(() => {
            this.pendingRepetitionCount = this.repetitionCount
            this.showRepetitionDialog = true
          })

          // 加群找同好 - 摩斯电码交流群
          Row() {
            Text('加群找同好')
              .fontSize(16)
              .fontColor('#FFFFFF')
            Row() {}.layoutWeight(1)
            Image($rawfile('ic_arrow_right.svg'))
              .width(12)
              .height(12)
              .fillColor('#666666')
          }
          .width('100%')
            .height(48)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('rgba(255, 255, 255, 0.1)')
            .borderRadius(8)
            .margin({ top: 6, bottom: 6 })
            .clickEffect({ level: ClickEffectLevel.LIGHT })
            .onClick(() => {
              console.info('[SettingsPage] JoinGroup entry clicked')
              router.pushUrl({ url: 'pages/watch/JoinGroupPage' })
            })

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

      if (this.showRepetitionDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.65)')
            .onClick(() => {
              this.showRepetitionDialog = false
            })
          Column() {
            this.RepetitionSettingsDialog()
          }
          .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
          .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
