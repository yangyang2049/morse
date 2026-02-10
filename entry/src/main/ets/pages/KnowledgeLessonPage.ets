import router from '@ohos.router'
import { LessonData } from '../data/LessonData'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'

@Entry
@Component
struct KnowledgeLessonPage {
  @State sections: Map<string, string[]> = new Map()
  @State title: string = '摩斯电码基础'
  @State isCompleted: boolean = false
  @State isCompleting: boolean = false
  
  private preferencesStore: preferences.Preferences | null = null

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.title = (params['title'] as string) || '摩斯电码基础'
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
        Button(this.isCompleting ? '已完成' : (this.isCompleted ? '已完成' : '完成学习'))
          .width('80%')
          .height(44)
          .backgroundColor(this.isCompleting || this.isCompleted ? '#00FF00' : '#FFD700')
          .fontColor('#000000')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24, bottom: 32 })
          .enabled(!this.isCompleting && !this.isCompleted)
          .focusable(true)
          .onClick(() => {
            console.log('[KnowledgeLessonPage] Complete button onClick triggered')
            console.log('[KnowledgeLessonPage] Current state - isCompleting:', this.isCompleting, 'isCompleted:', this.isCompleted, 'enabled:', !this.isCompleting && !this.isCompleted)
            if (!this.isCompleting && !this.isCompleted) {
              console.log('[KnowledgeLessonPage] Calling handleComplete')
              this.handleComplete()
            } else {
              console.log('[KnowledgeLessonPage] Button disabled, not calling handleComplete')
            }
          })
          .onTouch((event) => {
            console.log('[KnowledgeLessonPage] Complete button onTouch event:', event.type)
            if (event.type === TouchType.Up && !this.isCompleting && !this.isCompleted) {
              console.log('[KnowledgeLessonPage] Complete button onTouch Up triggered, calling handleComplete')
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
  }

  // 处理完成按钮点击
  private handleComplete(): void {
    console.log('[KnowledgeLessonPage] handleComplete called')
    console.log('[KnowledgeLessonPage] State - isCompleting:', this.isCompleting, 'isCompleted:', this.isCompleted)
    console.log('[KnowledgeLessonPage] preferencesStore:', !!this.preferencesStore)
    
    if (this.isCompleting || this.isCompleted) {
      console.log('[KnowledgeLessonPage] Already completing or completed, returning')
      return
    }

    // 立即设置完成状态，显示视觉反馈
    this.isCompleting = true
    console.log('[KnowledgeLessonPage] Set isCompleting to true, button should show feedback now')
    
    // 标记课程完成（异步操作）
    if (this.preferencesStore) {
      this.markLessonCompleted().then(() => {
        console.log('[KnowledgeLessonPage] Lesson marked as completed successfully')
        // 等待500ms后退出页面
        setTimeout(() => {
          console.log('[KnowledgeLessonPage] Exiting page after 500ms')
          router.back()
        }, 500)
      }).catch((error: Error) => {
        console.error('[KnowledgeLessonPage] Error in markLessonCompleted:', error)
        // 即使出错也退出
        setTimeout(() => {
          router.back()
        }, 500)
      })
    } else {
      console.error('[KnowledgeLessonPage] preferencesStore is null, cannot save but will still exit')
      // 即使无法保存，也显示反馈并退出
      this.isCompleted = true
      setTimeout(() => {
        router.back()
      }, 500)
    }
  }

  // 标记课程完成
  private async markLessonCompleted(): Promise<void> {
    console.log('[KnowledgeLessonPage] markLessonCompleted called, preferencesStore:', !!this.preferencesStore)
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('basic_lesson_completed', true)
        await this.preferencesStore.flush()
        this.isCompleted = true
        console.log('[KnowledgeLessonPage] Lesson marked as completed and saved')
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

