import { QuestionItem, ExplanationItem, ButtonStyle } from '../types/LessonTypes'
import { progressStore } from '../store/ProgressStoreSingleton'
import Context from '@ohos.app.ability.common'
import { i18nService } from '../services/I18nService'

@Observed
export class QuizViewModel {
  // 测试基本信息
  pageTitle: string = '基础测试'
  lessonCompletedKey: string = 'intro_lesson_0'
  
  // 测试状态
  currentQuestionIndex: number = 0
  score: number = 0
  isAnswered: boolean = false
  selectedAnswer: number | null = null
  showResult: boolean = false
  showExplanation: boolean = false
  showDelayedContent: boolean = false
  showNextButton: boolean = false
  progressSaved: boolean = false
  isLessonCompleted: boolean = false
  
  // Context for immediate completion marking
  private context: Context | null = null

  // 测试数据
  questions: QuestionItem[] = []
  explanations: ExplanationItem[] = []

  // 初始化测试数据
  initializeTestData(pageTitle: string, context?: Context): void {
    console.error(`[QuizViewModel] initializeTestData: pageTitle=${pageTitle}`)
    
    // 存储context
    if (context) {
      this.context = context
    }
    
    if (pageTitle.includes('基础') || pageTitle.includes('intro') || pageTitle.includes('Intro') || pageTitle.includes('Basics') || pageTitle.includes('basics')) {
      this.questions = [
        {
          type: 'true_false',
          question: i18nService.t('q1_question'),
          options: i18nService.t('q1_options').split(','),
          answer: 0, // 正确
          points: 20,
        },
        {
          type: 'true_false',
          question: i18nService.t('q2_question'),
          options: i18nService.t('q2_options').split(','),
          answer: 1, // 错误，SOS是紧凑发送，无字符间隔
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: i18nService.t('q3_question'),
          options: i18nService.t('q3_options').split(','),
          answer: 1, // 1:3:7
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: i18nService.t('q4_question'),
          options: i18nService.t('q4_options').split(','),
          answer: 1, // 1830-1840 年代
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: i18nService.t('q5_question'),
          options: i18nService.t('q5_options').split(','),
          answer: 2, // 字母→数字→符号
          points: 20,
        },
      ]

      this.explanations = [
        {
          title: i18nService.t('exp1_title'),
          content: i18nService.t('exp1_content'),
        },
        {
          title: i18nService.t('exp2_title'),
          content: i18nService.t('exp2_content'),
        },
        {
          title: i18nService.t('exp3_title'),
          content: i18nService.t('exp3_content'),
        },
        {
          title: i18nService.t('exp4_title'),
          content: i18nService.t('exp4_content'),
        },
        {
          title: i18nService.t('exp5_title'),
          content: i18nService.t('exp5_content'),
        },
      ]
    } else {
      // 中文摩斯电码测试
      this.questions = [
        {
          type: 'true_false',
          question: i18nService.t('cq1_question'),
          options: i18nService.t('cq1_options').split(','),
          answer: 0, // 正确
          points: 20,
        },
        {
          type: 'true_false',
          question: i18nService.t('cq2_question'),
          options: i18nService.t('cq2_options').split(','),
          answer: 1, // 错误，中文编码通常更长
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: i18nService.t('cq3_question'),
          options: i18nService.t('cq3_options').split(','),
          answer: 1, // 1920 年代
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: i18nService.t('cq4_question'),
          options: i18nService.t('cq4_options').split(','),
          answer: 2, // 网络聊天
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: i18nService.t('cq5_question'),
          options: i18nService.t('cq5_options').split(','),
          answer: 1, // 从基础汉字开始
          points: 20,
        },
      ]

      this.explanations = [
        {
          title: i18nService.t('cexp1_title'),
          content: i18nService.t('cexp1_content'),
        },
        {
          title: i18nService.t('cexp2_title'),
          content: i18nService.t('cexp2_content'),
        },
        {
          title: i18nService.t('cexp3_title'),
          content: i18nService.t('cexp3_content'),
        },
        {
          title: i18nService.t('cexp4_title'),
          content: i18nService.t('cexp4_content'),
        },
        {
          title: i18nService.t('cexp5_title'),
          content: i18nService.t('cexp5_content'),
        },
      ]
    }
  }

  // 选择答案
  selectAnswer(answer: number): void {
    if (this.isAnswered) return

    this.selectedAnswer = answer
    this.isAnswered = true

    // 检查答案
    const correctAnswer = this.questions[this.currentQuestionIndex].answer as number
    const isCorrect = (answer === correctAnswer)

    if (isCorrect) {
      this.score += this.questions[this.currentQuestionIndex].points
    }
    console.error(`[QuizViewModel] selectAnswer: qIdx=${this.currentQuestionIndex} type=${this.questions[this.currentQuestionIndex].type} selected=${this.selectedAnswer} correct=${isCorrect} score=${this.score}`)

    // 检查是否达到100分，如果是则立即标记课程完成
    if (this.score >= 100 && !this.isLessonCompleted) {
      this.markLessonCompletedImmediately()
    }

    // 显示解释
    this.showExplanation = true
    // 延迟内容显示
    setTimeout(() => {
      this.showDelayedContent = true
    }, 300)
    // 延迟下一题按钮
    setTimeout(() => {
      this.showNextButton = true
    }, 900)
  }

  // 显示测试结果
  showTestResult(): void {
    this.showResult = true
    const willSave = this.score >= 100
    console.error(`[QuizViewModel] showTestResult: score=${this.score} willPersist=${willSave}`)
  }

  // 立即标记课程完成 - 简化逻辑
  private async markLessonCompletedImmediately(): Promise<void> {
    if (this.lessonCompletedKey && !this.isLessonCompleted && this.context) {
      try {
        const lessonNumber = parseInt(this.lessonCompletedKey) || 0
        console.error(`[QuizViewModel] markLessonCompletedImmediately: Starting for lessonNumber=${lessonNumber}`)
        
        // 使用存储的context立即标记课程完成 - 这会自动发送事件
        await progressStore.saveLessonCompleted(lessonNumber, this.context)
        this.isLessonCompleted = true
        this.progressSaved = true
        console.error(`[QuizViewModel] markLessonCompletedImmediately: Completed for lessonNumber=${lessonNumber}`)
        
      } catch (error) {
        console.error(`[QuizViewModel] markLessonCompletedImmediately: Error: ${error}`)
      }
    } else {
      console.error(`[QuizViewModel] markLessonCompletedImmediately: Cannot complete - lessonCompletedKey=${this.lessonCompletedKey}, isLessonCompleted=${this.isLessonCompleted}, context=${!!this.context}`)
    }
  }

  // 重新开始测试
  restartTest(): void {
    this.currentQuestionIndex = 0
    this.score = 0
    this.isAnswered = false
    this.selectedAnswer = null
    this.showResult = false
    this.showExplanation = false
    this.showDelayedContent = false
    this.showNextButton = false
  }

  // 下一题
  nextQuestion(): void {
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.currentQuestionIndex++
      this.isAnswered = false
      this.selectedAnswer = null
      this.showExplanation = false
      this.showDelayedContent = false
      this.showNextButton = false
    } else {
      this.showTestResult()
    }
  }


  // 获取多选题按钮样式
  getButtonStyle(isSelected: boolean, isCorrect: boolean, isWrong: boolean, isTrueFalse: boolean = false): ButtonStyle {
    if (this.isAnswered) {
      if (isCorrect) {
        return {
          backgroundColor: '#E8F5E8',
          textColor: '#2E7D32',
          borderColor: '#4CAF50'
        }
      } else if (isWrong) {
        return {
          backgroundColor: '#FFEBEE',
          textColor: '#C62828',
          borderColor: '#F44336'
        }
      }
      // 已作答但既不是正确也不是错误（即未被选择的错误项）时，统一灰显
      return {
        backgroundColor: '#F5F5F5',
        textColor: '#9E9E9E',
        borderColor: '#E0E0E0'
      }
    } else if (isSelected) {
      return {
        backgroundColor: '#E3F2FD',
        textColor: '#1A1A1A',
        borderColor: '#2196F3'
      }
    }
    return {
      backgroundColor: '#F5F5F5',
      textColor: '#1A1A1A',
      borderColor: '#E0E0E0'
    }
  }
}

