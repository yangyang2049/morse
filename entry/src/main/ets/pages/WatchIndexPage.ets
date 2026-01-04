import { MorseCodeData, MorseCode } from '../models/MorseCode'
import { ArcSwiper, ArcSwiperController, ArcSwiperAttribute } from '@kit.ArkUI'
import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'
import { audioService } from '../services/AudioService'
import { Context } from '@kit.AbilityKit'
import router from '@ohos.router'
import preferences from '@ohos.data.preferences'
import { LessonGroups } from '../data/LessonGroups'
import { eventHub, Events } from '../utils/EventHub'

@Component
export struct WatchIndexPage {
  @State currentTab: number = 0 // 0: 学习, 1: 练习, 2: 码表, 3: 设置
  
  // 设置相关状态
  @State vibrationEnabled: boolean = true
  @State longPressThreshold: number = 300 // 长按时间阈值（毫秒）
  
  // 课程进度
  @State alphabetProgress: number = 0
  @State numbersProgress: number = 0
  @State basicLessonCompleted: boolean = false
  
  private arcSwiperController: ArcSwiperController = new ArcSwiperController()
  private preferencesStore: preferences.Preferences | null = null
  private practiceSettingsStore: preferences.Preferences | null = null
  private vibrationTimers: number[] = [] // 存储振动定时器 ID，用于清理
  private lessonCompletedCallback: ((data?: Object) => void) | null = null

  // 学习模式
  @Builder LearnTab() {
    Column() {
      // 标题栏
      Text('学习')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })
      
      Column() {
        // 基础课程
        Row() {
          Text('基础')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)

          Text(this.basicLessonCompleted ? '1/1' : '0/1')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .onClick(() => {
          let title = '摩斯电码基础'
          try {
            const currentLanguage: string = AppStorage.get<string>('currentLanguage') || 'zh-CN'
            if (currentLanguage.startsWith('en')) {
              title = 'Morse Code Basics'
            }
          } catch (error) {
            console.error('[WatchIndexPage] Failed to get language:', error)
          }
          router.pushUrl({
            url: 'pages/KnowledgeLessonPage',
            params: {
              title: title
            }
          })
        })
        .margin({ bottom: 10 })

        // 字母课程
        Row() {
          Text('字母')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)

          Text(`${this.alphabetProgress}/${LessonGroups.getAlphabetGroups().length}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/LessonDetailPage',
            params: {
              lessonType: 'alphabet',
              lessonIndex: this.alphabetProgress
            }
          })
        })
        .margin({ bottom: 10 })

        // 数字课程
        Row() {
          Text('数字')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)

          Text(`${this.numbersProgress}/${LessonGroups.getNumberGroups().length}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/LessonDetailPage',
            params: {
              lessonType: 'numbers',
              lessonIndex: this.numbersProgress
            }
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#000000')
  }

  // 练习模式
  @Builder PracticeTab() {
    Column() {
      // 标题栏
      Text('练习')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })
      
      Column() {
        // 字母转代码
        Row() {
          Text('字母 → 代码')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/PracticeDetailPage',
            params: {
              mode: 'text_to_code'
            }
          })
        })
        .margin({ bottom: 10 })

        // 代码转字母
        Row() {
          Text('代码 → 字母')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/PracticeDetailPage',
            params: {
              mode: 'code_to_text'
            }
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#000000')
  }

  // 码表查询
  @Builder CodeTableTab() {
    Column() {
      // 标题栏
      Text('码表')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })
      
      List() {
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
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#000000')
  }

  // 设置页面
  @Builder SettingsTab() {
    Column() {
      // 标题栏
      Text('设置')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 15, bottom: 10 })
      
      Scroll() {
        Column() {
          // 振动反馈设置
          Row() {
            Text('振动反馈')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .layoutWeight(1)
            
            Toggle({ type: ToggleType.Switch, isOn: this.vibrationEnabled })
              .selectedColor('#FFD700')
              .onChange((isOn: boolean) => {
                this.vibrationEnabled = isOn
              })
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .margin({ top: 14, bottom: 6 })

          // 长按时间阈值设置
          Column() {
            Row() {
              Text('长按时间')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .layoutWeight(1)
              
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
            .onChange((value: number) => {
              this.longPressThreshold = value
              this.saveLongPressThreshold(value)
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .margin({ top: 6, bottom: 6 })
        }
        .width('80%')
        .padding(16)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  // 清理所有振动定时器
  private clearVibrationTimers(): void {
    this.vibrationTimers.forEach((timerId: number) => {
      clearTimeout(timerId)
    })
    this.vibrationTimers = []
  }

  // 通过振动播放摩斯码
  private playMorseVibration(morse: string): void {
    if (!morse || !this.vibrationEnabled) return

    // 清理之前的振动定时器，防止定时器泄漏
    this.clearVibrationTimers()

    let delay = 0
    for (let i = 0; i < morse.length; i++) {
      const char = morse[i]
      if (char === '·' || char === '.') {
        const timerId = setTimeout(() => {
          if (this.vibrationEnabled) {
            vibrator.vibrate(100, (error: BusinessError) => {
              if (error) {
                console.error(`[WatchIndexPage] Failed to vibrate: ${error.message}`)
              }
            })
          }
        }, delay)
        this.vibrationTimers.push(timerId)
        delay += 200
      } else if (char === '-') {
        const timerId = setTimeout(() => {
          if (this.vibrationEnabled) {
            vibrator.vibrate(300, (error: BusinessError) => {
              if (error) {
                console.error(`[WatchIndexPage] Failed to vibrate: ${error.message}`)
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
      setTimeout(() => resolve(), totalDelay)
    })

    // 等待音频和振动都完成
    await Promise.all([audioPromise, vibrationPromise])
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'lesson_progress')
        this.practiceSettingsStore = await preferences.getPreferences(context, 'practice_settings')
        console.log('[WatchIndexPage] Preferences stores initialized')
        // 加载设置
        await this.loadSettings()
      }
    } catch (error) {
      console.error('[WatchIndexPage] Failed to initialize preferences:', error)
    }
  }

  // 加载设置
  private async loadSettings(): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        this.longPressThreshold = await this.practiceSettingsStore.get('long_press_threshold', 300) as number
        console.log(`[WatchIndexPage] Loaded settings: longPressThreshold=${this.longPressThreshold}`)
      }
    } catch (error) {
      console.error('[WatchIndexPage] Failed to load settings:', error)
    }
  }

  // 保存长按时间阈值
  private async saveLongPressThreshold(value: number): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        await this.practiceSettingsStore.put('long_press_threshold', value)
        await this.practiceSettingsStore.flush()
        console.log(`[WatchIndexPage] Saved longPressThreshold: ${value}`)
      }
    } catch (error) {
      console.error('[WatchIndexPage] Failed to save longPressThreshold:', error)
    }
  }

  // 加载课程进度
  private async loadLessonProgress(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.alphabetProgress = await this.preferencesStore.get('alphabet_progress', 0) as number
        this.numbersProgress = await this.preferencesStore.get('numbers_progress', 0) as number
        this.basicLessonCompleted = await this.preferencesStore.get('basic_lesson_completed', false) as boolean
        console.log(`[WatchIndexPage] Loaded progress: alphabet=${this.alphabetProgress}, numbers=${this.numbersProgress}, basic=${this.basicLessonCompleted}`)
      }
    } catch (error) {
      console.error('[WatchIndexPage] Failed to load lesson progress:', error)
    }
  }

  async aboutToAppear() {
    // 初始化音频服务
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        await audioService.init(context)
      }
    } catch (error) {
      console.error('[WatchIndexPage] Failed to initialize audio service:', error)
    }
    
    // 初始化偏好设置并加载进度
    await this.initPreferences()
    await this.loadLessonProgress()
    
    // 监听课程完成事件
    this.lessonCompletedCallback = (data?: Object) => {
      console.log('[WatchIndexPage] Lesson completed event received, reloading progress')
      this.loadLessonProgress()
    }
    eventHub.on(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
  }

  onPageShow() {
    // 页面显示时重新加载进度
    this.loadLessonProgress()
  }

  aboutToDisappear() {
    // 清理所有振动定时器，防止内存泄漏
    this.clearVibrationTimers()
    
    // 取消监听课程完成事件
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
  }

  build() {
    // 使用 ArcSwiper 进行标签页切换
    ArcSwiper(this.arcSwiperController) {
      // 学习
      this.LearnTab()

      // 练习
      this.PracticeTab()

      // 码表
      this.CodeTableTab()

      // 设置
      this.SettingsTab()
    }
    .index(this.currentTab)
    .onChange((index: number) => {
      this.currentTab = index
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}

