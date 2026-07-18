import router from '@ohos.router'
import { LessonData } from '../../data/LessonData'
import { Context } from '@kit.AbilityKit'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { progressStore } from '../../store/ProgressStoreSingleton'

@Entry
@Component
struct KnowledgeLessonPage {
  @State sections: Map<string, string[]> = new Map()
  @State title: ResourceStr = ''
  @State isCompleted: boolean = false
  @State isCompleting: boolean = false

  private completeTimers: number[] = []

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && params['title']) {
      const titleParam = params['title']
      if (typeof titleParam === 'string') {
        this.title = titleParam
      } else {
        this.title = LocalizationHelper.getString('watch_morse_code_basics_title')
      }
    } else {
      this.title = LocalizationHelper.getString('watch_morse_code_basics_title')
    }

    this.sections = LessonData.getIntroSections()

    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        await progressStore.load(context)
        this.isCompleted = progressStore.isBasicsCompleted()
      }
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to load progress:', error)
    }
  }

  aboutToDisappear() {
    this.completeTimers.forEach(id => clearTimeout(id))
    this.completeTimers = []
  }

  private getButtonText(): ResourceStr {
    return LocalizationHelper.getString('watch_back')
  }

  @Builder
  private SectionItem(sectionTitle: string, sectionContent: string[], index: number) {
    Column() {
      Text(sectionTitle)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFD700')
        .width('100%')
        .margin({ top: index === 0 ? 0 : 24, bottom: 12 })
        .textAlign(TextAlign.Center)

      Column() {
        ForEach(sectionContent, (line: string) => {
          if (line.trim() === '') {
            Blank()
              .height(8)
          } else {
            Text(line)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .width('100%')
              .margin({ bottom: 8 })
              .lineHeight(20)
          }
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(255, 255, 255, 0.1)')
      .borderRadius(8)
    }
    .width('80%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Scroll() {
      Column() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .width('80%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16, bottom: 16 })

        ForEach(Array.from(this.sections.entries()), (item: [string, string[]], index: number) => {
          this.SectionItem(item[0], item[1], index)
        })

        Blank().height(16)

        Button(this.getButtonText())
          .width('80%')
          .height(44)
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24, bottom: 32 })
          .enabled(true)
          .focusable(true)
          .onClick(() => {
            if (!this.isCompleted && !this.isCompleting) {
              this.handleComplete()
            } else {
              router.back()
            }
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .scrollBar(BarState.Off)
    .focusable(true)
    .defaultFocus(true)
  }

  private handleComplete(): void {
    if (this.isCompleting || this.isCompleted) {
      return
    }

    this.isCompleting = true
    this.completeTimers.forEach(id => clearTimeout(id))
    this.completeTimers = []

    this.markLessonCompleted().then(() => {
      const timerId = setTimeout(() => {
        router.back()
      }, 500)
      this.completeTimers.push(timerId)
    }).catch((error: Error) => {
      console.error('[KnowledgeLessonPage] Error in markLessonCompleted:', error)
      const timerId = setTimeout(() => {
        router.back()
      }, 500)
      this.completeTimers.push(timerId)
    })
  }

  private async markLessonCompleted(): Promise<void> {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (!context) {
        throw new Error('host context is null')
      }
      await progressStore.saveLessonCompleted(1, context)
      this.isCompleted = true
      console.log('[KnowledgeLessonPage] Lesson 1 saved to progressStore')
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to mark lesson as completed:', error)
      if (error instanceof Error) {
        throw error
      }
      throw new Error('Unknown error occurred while marking lesson as completed')
    }
  }
}
