import router from '@ohos.router'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { LessonGroups } from '../../data/LessonGroups'
import { eventHub, Events } from '../../utils/EventHub'

@Component
export struct LearnPage {
  @State alphabetProgress: number = 0
  @State numbersProgress: number = 0
  @State punctuationProgress: number = 0
  @State basicLessonCompleted: boolean = false

  private preferencesStore: preferences.Preferences | null = null
  private lessonCompletedCallback: ((data?: Object) => void) | null = null

  async aboutToAppear() {
    await this.initPreferences()
    await this.loadLessonProgress()

    // 监听课程完成事件
    this.lessonCompletedCallback = (data?: Object) => {
      console.log('[LearnPage] Lesson completed event received, reloading progress')
      this.loadLessonProgress()
    }
    eventHub.on(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
  }

  onPageShow() {
    // 页面显示时重新加载进度
    this.loadLessonProgress()
  }

  aboutToDisappear() {
    // 取消监听课程完成事件
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'lesson_progress')
      }
    } catch (error) {
      console.error('[LearnPage] Failed to initialize preferences:', error)
    }
  }

  // 加载课程进度
  private async loadLessonProgress(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.alphabetProgress = await this.preferencesStore.get('alphabet_progress', 0) as number
        this.numbersProgress = await this.preferencesStore.get('numbers_progress', 0) as number
        this.punctuationProgress = await this.preferencesStore.get('punctuation_progress', 0) as number
        this.basicLessonCompleted = await this.preferencesStore.get('basic_lesson_completed', false) as boolean

        // 验证进度值的有效性
        const alphabetMax = LessonGroups.getAlphabetGroups().length
        if (this.alphabetProgress < 0 || this.alphabetProgress > alphabetMax) {
          this.alphabetProgress = 0
        }

        const numbersMax = LessonGroups.getNumberGroups().length
        if (this.numbersProgress < 0 || this.numbersProgress > numbersMax) {
          this.numbersProgress = 0
        }
      }
    } catch (error) {
      console.error('[LearnPage] Failed to load lesson progress:', error)
    }
  }

  build() {
    Column() {
      // 标题栏
      Text(LocalizationHelper.getString('watch_learn'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })

      Scroll() {
        Column() {
          // 基础课程
          Row() {
            Image($rawfile('ic_article.svg'))
              .width(24)
              .height(24)
              .fillColor('#FFD700')
              .margin({ right: 12 })

            Text(LocalizationHelper.getString('watch_basics'))
              .fontSize(16)
              .fontColor('#FFFFFF')

            Blank()

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
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          // 获取本地化标题字符串
          router.pushUrl({
            url: 'pages/watch/KnowledgeLessonPage'
          })
        })
          .margin({ bottom: 10 })

          // 字母课程
          Row() {
            Text('A')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD728')
              .textAlign(TextAlign.Center)
              .width(24)
              .margin({ right: 12 })

            Text(LocalizationHelper.getString('watch_alphabet'))
              .fontSize(16)
              .fontColor('#FFFFFF')

            Blank()

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
          .clickEffect({ level: ClickEffectLevel.LIGHT })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/watch/LessonDetailPage',
              params: {
                lessonType: 'alphabet',
                lessonIndex: this.alphabetProgress
              }
            })
          })
          .margin({ bottom: 10 })

          // 数字课程
          Row() {
            Text('1')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD728')
              .textAlign(TextAlign.Center)
              .width(24)
              .margin({ right: 12 })

            Text(LocalizationHelper.getString('watch_numbers'))
              .fontSize(16)
              .fontColor('#FFFFFF')

            Blank()

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
          .clickEffect({ level: ClickEffectLevel.LIGHT })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/watch/LessonDetailPage',
              params: {
                lessonType: 'numbers',
                lessonIndex: this.numbersProgress
              }
            })
          })
          .margin({ bottom: 10 })

          // 标点课程
          Row() {
            Text('.')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD728')
              .textAlign(TextAlign.Center)
              .width(24)
              .margin({ right: 12 })

            Text('标点')
              .fontSize(16)
              .fontColor('#FFFFFF')

            Blank()

            Text(`${this.punctuationProgress}/3`)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          .width('80%')
          .height(44)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(8)
          .clickEffect({ level: ClickEffectLevel.LIGHT })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/watch/LessonDetailPage',
              params: {
                lessonType: 'punctuation',
                lessonIndex: this.punctuationProgress
              }
            })
          })
          .margin({ bottom: 40 }) // Add extra bottom margin for scrolling space
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Vertical)
      .focusable(true)
      .defaultFocus(true)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#000000')
  }
}
