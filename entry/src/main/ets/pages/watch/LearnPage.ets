import router from '@ohos.router'
import { Context } from '@kit.AbilityKit'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { LessonGroups } from '../../data/LessonGroups'
import { eventHub, Events } from '../../utils/EventHub'
import { progressStore } from '../../store/ProgressStoreSingleton'

@Component
export struct LearnPage {
  @State alphabetProgress: number = 0
  @State numbersProgress: number = 0
  @State punctuationProgress: number = 0
  @State basicLessonCompleted: boolean = false

  private lessonCompletedCallback: ((data?: Object) => void) | null = null

  async aboutToAppear() {
    await this.loadLessonProgress()

    this.lessonCompletedCallback = (_data?: Object) => {
      console.log('[LearnPage] Lesson completed event received, reloading progress')
      void this.loadLessonProgress()
    }
    eventHub.on(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
  }

  onPageShow() {
    void this.loadLessonProgress()
  }

  aboutToDisappear() {
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
  }

  private async loadLessonProgress(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        await progressStore.load(context)
      }
      this.basicLessonCompleted = progressStore.isBasicsCompleted()
      this.alphabetProgress = progressStore.getWatchGroupProgress('alphabet')
      this.numbersProgress = progressStore.getWatchGroupProgress('numbers')
      this.punctuationProgress = progressStore.getWatchGroupProgress('punctuation')
    } catch (error) {
      console.error('[LearnPage] Failed to load lesson progress:', error)
    }
  }

  build() {
    Column() {
      Text(LocalizationHelper.getString('watch_learn'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFD700')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })

      Scroll() {
        Column() {
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
            router.pushUrl({
              url: 'pages/watch/KnowledgeLessonPage'
            })
          })
          .margin({ bottom: 10 })

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
            const nextIndex = Math.min(this.alphabetProgress, LessonGroups.getAlphabetGroups().length - 1)
            router.pushUrl({
              url: 'pages/watch/LessonDetailPage',
              params: {
                lessonType: 'alphabet',
                lessonIndex: nextIndex
              }
            })
          })
          .margin({ bottom: 10 })

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
            const nextIndex = Math.min(this.numbersProgress, LessonGroups.getNumberGroups().length - 1)
            router.pushUrl({
              url: 'pages/watch/LessonDetailPage',
              params: {
                lessonType: 'numbers',
                lessonIndex: nextIndex
              }
            })
          })
          .margin({ bottom: 10 })

          Row() {
            Text('.')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD728')
              .textAlign(TextAlign.Center)
              .width(24)
              .margin({ right: 12 })

            Text(LocalizationHelper.getString('punctuation'))
              .fontSize(16)
              .fontColor('#FFFFFF')

            Blank()

            Text(`${this.punctuationProgress}/${LessonGroups.getPunctuationGroups().length}`)
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
            const nextIndex = Math.min(this.punctuationProgress, LessonGroups.getPunctuationGroups().length - 1)
            router.pushUrl({
              url: 'pages/watch/LessonDetailPage',
              params: {
                lessonType: 'punctuation',
                lessonIndex: nextIndex
              }
            })
          })
          .margin({ bottom: 40 })
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
