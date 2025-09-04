import { QuestionItem, ExplanationItem, ButtonStyle } from '../types/LessonTypes'
import { progressStore } from '../store/ProgressStoreSingleton'
import Context from '@ohos.app.ability.common'

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
    
    if (pageTitle.includes('基础') || pageTitle.includes('intro') || pageTitle.includes('Intro')) {
      this.questions = [
        {
          type: 'true_false',
          question: '摩斯密码是以"点（·）和划（-）"为基本元素的字符编码系统。',
          options: ['正确', '错误'],
          answer: 0, // 正确
          points: 20,
        },
        {
          type: 'true_false',
          question: 'SOS信号的摩斯密码是 ··· --- ···，各字符之间需要保持正常的字符间隔。',
          options: ['正确', '错误'],
          answer: 1, // 错误，SOS是紧凑发送，无字符间隔
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '摩斯密码的时序规则中，点、划、字符间隔的单位比例是：',
          options: ['1 : 2 : 5', '1 : 3 : 7', '1 : 4 : 8', '2 : 3 : 6'],
          answer: 1, // 1:3:7
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '摩斯密码是在哪个 年代开发的？',
          options: ['1820 年代', '1830-1840 年代', '1850 年代', '1860 年代'],
          answer: 1, // 1830-1840 年代
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '学习摩斯密码的建议顺序是：',
          options: ['数字 → 字母 → 符号', '符号 → 字母 → 数字', '字母 → 数字 → 符号', '随机学习'],
          answer: 2, // 字母→数字→符号
          points: 20,
        },
      ]

      this.explanations = [
        {
          title: '摩斯密码基本元素',
          content: '• 摩斯密码以"点（·）和划（-）"为基本元素\n• 通过不同的点划组合表示字母、数字和符号\n• 这是所有摩斯密码的基础，必须熟练掌握',
        },
        {
          title: 'SOS信号的特殊性',
          content: '• SOS是紧急求救信号，需要快速识别\n• 紧凑发送：三个字符（··· --- ···）是紧凑发送的，没有正常的字符间隔\n• 标准间隔规则：正常情况下，摩斯密码字符之间应该有3个单位的间隔\n• SOS例外：但SOS作为紧急信号，会忽略这个规则，紧凑发送以提高识别速度',
        },
        {
          title: '时序规则的重要性',
          content: '• 1:3:7比例是摩斯密码的核心规则\n• 点=1单位，划=3单位，字符间隔=3单位，单词间隔=7单位\n• 这个精确的时序确保了信息传输的准确性和可读性',
        },
        {
          title: '历史背景',
          content: '• 塞缪尔·摩斯与阿尔弗雷德·韦尔在1830-1840 年代合作开发\n• 最初用于电报系统，后来演化为国际摩斯密码\n• 成为全球标准的无线电通信编码系统',
        },
        {
          title: '学习策略',
          content: '• 字母 → 数字 → 符号的学习顺序最科学\n• 先掌握基础字母，再学习数字和符号\n• 循序渐进，避免信息过载，提高学习效率',
        },
      ]
    } else {
      // 中文摩斯密码测试
      this.questions = [
        {
          type: 'true_false',
          question: '中文摩尔斯电码是专门为中文汉字设计的摩尔斯电码系统。',
          options: ['正确', '错误'],
          answer: 0, // 正确
          points: 20,
        },
        {
          type: 'true_false',
          question: '中文摩尔斯电码的编码长度通常比英文摩尔斯电码短。',
          options: ['正确', '错误'],
          answer: 1, // 错误，中文编码通常更长
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '中文摩尔斯电码是在哪个 年代开始制定的？',
          options: ['1900 年代', '1920 年代', '1950 年代', '1980 年代'],
          answer: 1, // 1920 年代
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '以下哪个不是中文摩尔斯电码的应用场景？',
          options: ['军事通信', '航空通信', '网络聊天', '航海通信'],
          answer: 2, // 网络聊天
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '学习中文摩尔斯电码的建议顺序是：',
          options: ['从复杂汉字开始', '从基础汉字开始', '随机学习', '从标点符号开始'],
          answer: 1, // 从基础汉字开始
          points: 20,
        },
      ]

      this.explanations = [
        {
          title: '中文摩尔斯电码的定义',
          content: '• 中文摩尔斯电码是专门为中文汉字设计的编码系统\n• 通过点（·）和划（-）的组合表示中文字符\n• 结合了传统摩尔斯电码原理和中文语言特点\n• 为中文通信提供了标准化的编码方案',
        },
        {
          title: '编码长度的特点',
          content: '• 中文摩尔斯电码的编码通常比英文更长\n• 这是因为中文字符数量庞大，需要更多点划组合\n• 每个汉字都有唯一的摩尔斯电码表示\n• 编码长度增加是为了确保字符的唯一性',
        },
        {
          title: '历史发展背景',
          content: '• 1920 年代：初步制定中文摩尔斯电码标准\n• 当时为了适应中文电报通信的需求\n• 国际电信联盟（ITU）参与制定\n• 经过多次优化形成现代标准',
        },
        {
          title: '应用场景分析',
          content: '• 军事通信：部队间的秘密通信\n• 航空通信：飞行员与地面控制塔通信\n• 航海通信：船舶间通信\n• 网络聊天不属于传统应用场景',
        },
        {
          title: '学习策略建议',
          content: '• 从基础汉字开始学习最科学\n• 基础汉字使用频率高，容易记忆\n• 循序渐进，避免信息过载\n• 建立学习信心，提高学习效率',
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

  // 立即标记课程完成
  private async markLessonCompletedImmediately(): Promise<void> {
    if (this.lessonCompletedKey && !this.isLessonCompleted && this.context) {
      try {
        const lessonNumber = parseInt(this.lessonCompletedKey) || 0
        console.error(`[QuizViewModel] markLessonCompletedImmediately: Starting for lessonNumber=${lessonNumber}`)
        
        // 使用存储的context立即标记课程完成
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

