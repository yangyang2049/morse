import { LessonData } from '../data/LessonData'
import Context from '@ohos.app.ability.common'

export interface LessonNavParams {
  title?: string
  testType?: string
  testTitle?: string
  testCompletedKey?: string
  lessonCompletedKey?: string
}

@Observed
export class LessonViewModel {
  // 课程基本信息
  title: string = '摩斯密码基础'
  testType: string = 'intro'
  testTitle: string = '基础知识测试'
  testCompletedKey: string = 'intro_test_completed'
  lessonCompletedKey: string = 'intro_lesson_0'
  
  // 课程内容数据
  sections: Map<string, string[]> = new Map()
  currentPageIndex: number = 0
  
  // 初始化课程数据
  init(params: LessonNavParams): void {
    console.error(`[LessonViewModel] init: params=`, JSON.stringify(params))
    
    // 设置课程基本信息
    if (params.title) this.title = params.title
    if (params.testType) this.testType = params.testType
    if (params.testTitle) this.testTitle = params.testTitle
    if (params.testCompletedKey) this.testCompletedKey = params.testCompletedKey
    if (params.lessonCompletedKey) this.lessonCompletedKey = params.lessonCompletedKey
    
    // 根据课程类型加载对应的数据
    this.loadLessonData()
    
    console.error(`[LessonViewModel] init completed: title=${this.title}, testType=${this.testType}`)
  }
  
  // 加载课程数据
  private loadLessonData(): void {
    console.error(`[LessonViewModel] loadLessonData: testType=${this.testType}`)
    
    switch (this.testType) {
      case 'intro':
        this.sections = LessonData.introSections
        console.error(`[LessonViewModel] loadLessonData: Loaded intro sections`)
        break
      case 'chinese':
        this.sections = LessonData.chineseSections
        console.error(`[LessonViewModel] loadLessonData: Loaded chinese sections`)
        break
      default:
        console.error(`[LessonViewModel] loadLessonData: Unknown testType=${this.testType}, using default intro sections`)
        this.sections = LessonData.introSections
        break
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
}
