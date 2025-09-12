import { LessonData } from '../data/LessonData'
import { LessonNavParams } from '../types/LessonTypes'
import { progressStore } from '../store/ProgressStoreSingleton'
import { LessonConfig } from '../data/LessonConfig'
import Context from '@ohos.app.ability.common'

@Observed
export class KnowledgeLessonViewModel {
  // 课程基本信息
  title: string = '摩斯密码基础'
  testTitle: string = '基础知识测试'
  lessonCompletedKey: string = 'intro_lesson_0'
  
  // 课程内容数据
  sections: Map<string, string[]> = new Map()
  currentPageIndex: number = 0
  
  // 课程完成状态
  isLessonCompleted: boolean = false
  private context: Context | null = null
  
  // 初始化课程数据
  init(params: LessonNavParams, context?: Context): void {
    console.error(`[KnowledgeLessonViewModel] init: params=`, JSON.stringify(params))
    
    // 设置课程基本信息
    if (params.title) this.title = params.title
    if (params.testTitle) this.testTitle = params.testTitle
    if (params.lessonCompletedKey) this.lessonCompletedKey = params.lessonCompletedKey
    
    // 存储context
    if (context) {
      this.context = context
    }
    
    // 根据课程类型加载对应的数据
    this.loadLessonData()
    
    console.error(`[KnowledgeLessonViewModel] init completed: title=${this.title}`)
  }
  
  // 加载课程数据
  private loadLessonData(): void {
    console.error(`[KnowledgeLessonViewModel] loadLessonData: title=${this.title}`)
    
    // 根据课程标题判断课程类型
    if (this.title.includes('中文') || this.title.includes('Chinese')) {
      const chineseSections = LessonData.getChineseSections()
      this.sections = chineseSections || new Map()
      console.error(`[KnowledgeLessonViewModel] loadLessonData: Loaded chinese sections`)
    } else if (this.title.includes('基础') || this.title.includes('intro') || this.title.includes('Intro') || this.title.includes('Basics') || this.title.includes('Morse Code Basics')) {
      this.sections = LessonData.getIntroSections()
      console.error(`[KnowledgeLessonViewModel] loadLessonData: Loaded intro sections, sections count=${this.sections.size}`)
      // 调试：打印章节标题
      const titles = Array.from(this.sections.keys())
      console.error(`[KnowledgeLessonViewModel] loadLessonData: Section titles=${titles.join(', ')}`)
    } else {
      console.error(`[KnowledgeLessonViewModel] loadLessonData: Unknown title=${this.title}, using default intro sections`)
      this.sections = LessonData.getIntroSections()
    }
  }
  
  // 获取课程章节列表
  getSectionTitles(): string[] {
    return Array.from(this.sections.keys())
  }
  
  // 获取指定章节的内容
  getSectionContent(sectionTitle: string): string[] {
    return this.sections.get(sectionTitle) || []
  }
  
  // 获取当前章节标题
  getCurrentSectionTitle(): string {
    const titles = this.getSectionTitles()
    return titles[this.currentPageIndex] || ''
  }
  
  // 获取当前章节内容
  getCurrentSectionContent(): string[] {
    const currentTitle = this.getCurrentSectionTitle()
    return this.getSectionContent(currentTitle)
  }
  
  // 切换到下一页
  nextPage(): void {
    const totalPages = this.getSectionTitles().length
    if (this.currentPageIndex < totalPages - 1) {
      this.currentPageIndex++
    }
  }
  
  // 切换到上一页
  previousPage(): void {
    if (this.currentPageIndex > 0) {
      this.currentPageIndex--
    }
  }
  
  // 检查是否有下一页
  hasNextPage(): boolean {
    return this.currentPageIndex < this.getSectionTitles().length - 1
  }
  
  // 检查是否有上一页
  hasPreviousPage(): boolean {
    return this.currentPageIndex > 0
  }
  
  // 获取总页数
  getTotalPages(): number {
    return this.getSectionTitles().length
  }
  
  // 获取当前页码（从1开始）
  getCurrentPageNumber(): number {
    return this.currentPageIndex + 1
  }
  
  // 刷新课程内容（语言切换时调用）
  refreshContent(): void {
    console.error(`[KnowledgeLessonViewModel] refreshContent: Refreshing lesson content for title=${this.title}`)
    
    // 重新加载课程数据以适应新语言
    this.loadLessonData()
    
    // 重置页面索引到第一页
    this.currentPageIndex = 0
    
    console.error(`[KnowledgeLessonViewModel] refreshContent: Content refreshed, sections count=${this.sections.size}`)
  }
  
  // 立即标记课程完成
  async markLessonCompletedImmediately(): Promise<void> {
    if (this.lessonCompletedKey && !this.isLessonCompleted && this.context) {
      try {
        // 使用LessonConfig获取正确的课程编号
        const lessonNumber = LessonConfig.getLessonNumber(this.lessonCompletedKey)
        console.error(`[KnowledgeLessonViewModel] markLessonCompletedImmediately: Starting for lessonId=${this.lessonCompletedKey}, lessonNumber=${lessonNumber}`)                                                      
        
        if (lessonNumber > 0) {
          // 使用存储的context立即标记课程完成
          await progressStore.saveLessonCompleted(lessonNumber, this.context)
          this.isLessonCompleted = true
          console.error(`[KnowledgeLessonViewModel] markLessonCompletedImmediately: Completed for lessonNumber=${lessonNumber}`)                                                                                        
        } else {
          console.error(`[KnowledgeLessonViewModel] markLessonCompletedImmediately: Invalid lessonId=${this.lessonCompletedKey}`)                                                                                       
        }
      } catch (error) {
        console.error(`[KnowledgeLessonViewModel] markLessonCompletedImmediately: Error: ${error}`)
      }
    } else {
      console.error(`[KnowledgeLessonViewModel] markLessonCompletedImmediately: Cannot complete - lessonCompletedKey=${this.lessonCompletedKey}, isLessonCompleted=${this.isLessonCompleted}, context=${!!this.context}`)                                                                                                           
    }
  }
}
