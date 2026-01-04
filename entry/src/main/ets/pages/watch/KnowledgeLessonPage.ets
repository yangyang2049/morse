import router from '@ohos.router'
import { LessonData } from '../../data/LessonData'
import preferences from '@ohos.data.preferences'
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
  
  private preferencesStore: preferences.Preferences | null = null
  private completeTimers: number[] = []

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && params['title']) {
      const titleParam = params['title']
      // 如果传入的是字符串，直接使用
      if (typeof titleParam === 'string') {
        this.title = titleParam
      } else {
        // 如果是 Resource，使用默认标题资源
        this.title = LocalizationHelper.getString('watch_morse_code_basics_title')
      }
    } else {
      this.title = LocalizationHelper.getString('watch_morse_code_basics_title')
    }
    
    // 加载课程数据
    this.sections = LessonData.getIntroSections()
    
    // 初始化偏好设置并检查完成状态
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'lesson_progress')
        await this.loadCompletionStatus()
      }
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to initialize preferences:', error)
    }
  }

  aboutToDisappear() {
    this.completeTimers.forEach(id => clearTimeout(id))
    this.completeTimers = []
  }

  // 加载完成状态
  private async loadCompletionStatus(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.isCompleted = await this.preferencesStore.get('basic_lesson_completed', false) as boolean
      }
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to load completion status:', error)
    }
  }

  // 获取进度文本
  private getProgressText(): string {
    return this.isCompleted ? '1/1' : '0/1'
  }

  // 章节内容 Builder
  @Builder
  private SectionItem(sectionTitle: string, sectionContent: string[], index: number) {
    Column() {
      // 章节标题
      Text(sectionTitle)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFD700')
        .width('100%')
        .margin({ top: index === 0 ? 0 : 24, bottom: 12 })
        .textAlign(TextAlign.Center)

      // 章节内容
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
        // 标题
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

        // 完成按钮
        Button(this.isCompleting ? LocalizationHelper.getString('watch_already_completed') : (this.isCompleted ? LocalizationHelper.getString('watch_already_completed') : LocalizationHelper.getString('watch_complete_learning')))
          .width('80%')
          .height(44)
          .backgroundColor(this.isCompleting || this.isCompleted ? '#4CAF50' : '#FFD700')
          .fontColor('#000000')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24, bottom: 32 })
          .enabled(!this.isCompleting && !this.isCompleted)
          .focusable(true)
          .onClick(() => {
            console.log('[KnowledgeLessonPage] Complete button onClick triggered')
            if (!this.isCompleting && !this.isCompleted) {
              console.log('[KnowledgeLessonPage] Calling handleComplete')
              this.handleComplete()
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
    .focusable(true)
    .defaultFocus(true)
  }

  // 处理完成按钮点击
  private handleComplete(): void {
    if (this.isCompleting || this.isCompleted) {
      return
    }

    this.isCompleting = true
    
    // 清理之前的定时器
    this.completeTimers.forEach(id => clearTimeout(id))
    this.completeTimers = []
    
    // 标记课程完成（异步操作）
    if (this.preferencesStore) {
      this.markLessonCompleted().then(() => {
        // 等待500ms后退出页面
        const timerId = setTimeout(() => {
          router.back()
        }, 500)
        this.completeTimers.push(timerId)
      }).catch((error: Error) => {
        console.error('[KnowledgeLessonPage] Error in markLessonCompleted:', error)
        // 即使出错也退出
        const timerId = setTimeout(() => {
          router.back()
        }, 500)
        this.completeTimers.push(timerId)
      })
    } else {
      console.error('[KnowledgeLessonPage] preferencesStore is null, cannot save but will still exit')
      // 即使无法保存，也显示反馈并退出
      this.isCompleted = true
      const timerId = setTimeout(() => {
        router.back()
      }, 500)
      this.completeTimers.push(timerId)
    }
  }

  // 标记课程完成
  private async markLessonCompleted(): Promise<void> {
    console.log('[KnowledgeLessonPage] markLessonCompleted called, preferencesStore:', !!this.preferencesStore)
    try {
      if (this.preferencesStore) {
        // 保存基础课程完成状态到 lesson_progress 存储
        await this.preferencesStore.put('basic_lesson_completed', true)
        await this.preferencesStore.flush()
        this.isCompleted = true
        console.log('[KnowledgeLessonPage] Lesson marked as completed and saved')
        
        // 同时保存到 ProgressStoreSingleton（课程编号为1）
        const context = this.getUIContext()?.getHostContext() as Context
        if (context) {
          await progressStore.saveLessonCompleted(1, context)
          console.log('[KnowledgeLessonPage] Lesson 1 also saved to ProgressStoreSingleton')
        }
      } else {
        console.error('[KnowledgeLessonPage] preferencesStore is null, cannot save')
        throw new Error('preferencesStore is null')
      }
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to mark lesson as completed:', error)
      if (error instanceof Error) {
        throw error
      } else {
        throw new Error('Unknown error occurred while marking lesson as completed')
      }
    }
  }
}

