import { QuestionItem, ExplanationItem, ButtonStyle } from '../types/Types'
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

  // 当前语言
  private currentLanguage: string = 'zh-CN'

  // 获取本地化字符串
  private getLocalizedString(key: string): string {
    const isChinese = this.currentLanguage.startsWith('zh')

    const localizedStrings: Record<string, Record<string, string>> = {
      'zh-CN': {
        // Basics quiz - Chinese
        'q1_question': '摩斯电码使用点（·）和划（—）两种基本信号',
        'q1_options': '正确,错误',
        'q2_question': 'SOS信号的摩斯码是 · · · — — — · · ·，每个字母之间有标准间隔',
        'q2_options': '正确,错误',
        'q3_question': '摩斯电码中，点、划和间隔的时长比例是',
        'q3_options': '1:2:3,1:3:7,1:4:8,1:5:10',
        'q4_question': '摩斯电码是在哪个年代发明的？',
        'q4_options': '1790-1800年代,1830-1840年代,1870-1880年代,1900-1910年代',
        'q5_question': '学习摩斯电码的推荐顺序是',
        'q5_options': '数字→字母→符号,符号→数字→字母,字母→数字→符号,随机学习',

        'exp1_title': '正确！',
        'exp1_content': '摩斯电码确实只使用点（·）和划（—）两种基本信号，通过它们的组合来表示字母、数字和符号。',
        'exp2_title': '错误',
        'exp2_content': 'SOS是紧急求救信号，为了快速识别，它的三个字母是连续发送的，没有字符间的标准间隔。正确的发送方式是：···———···（连续发送）',
        'exp3_title': '正确！',
        'exp3_content': '在摩斯电码中，标准的时长比例是：\n• 点（·）= 1个单位\n• 划（—）= 3个单位\n• 字符间隔 = 3个单位\n• 单词间隔 = 7个单位',
        'exp4_title': '正确！',
        'exp4_content': '摩斯电码由塞缪尔·摩尔斯（Samuel Morse）在1830-1840年代发明，最初用于电报通信。',
        'exp5_title': '正确！',
        'exp5_content': '推荐的学习顺序是：先学字母（特别是常用字母），再学数字，最后学习标点符号。这样可以循序渐进地掌握摩斯电码。',

        // Chinese Morse Code quiz - Chinese
        'cq1_question': '中文摩斯电码主要使用电报码（四位数字）来表示汉字',
        'cq1_options': '正确,错误',
        'cq2_question': '中文字符的摩斯编码通常比英文字符短',
        'cq2_options': '正确,错误',
        'cq3_question': '中文电报码系统大约在什么时候开始使用？',
        'cq3_options': '1850年代,1920年代,1950年代,1980年代',
        'cq4_question': '现代中文摩斯电码主要用于',
        'cq4_options': '日常通信,应急通信和业余无线电,商业广告,网络聊天',
        'cq5_question': '学习中文摩斯电码的最佳方法是',
        'cq5_options': '直接背诵电报码表,从基础汉字开始练习,只学习拼音,随机学习',

        'cexp1_title': '正确！',
        'cexp1_content': '中文摩斯电码确实使用四位数字的电报码来表示每个汉字，然后将这些数字转换为摩斯码发送。',
        'cexp2_title': '错误',
        'cexp2_content': '中文字符需要先转换为四位数字的电报码，因此编码通常比英文单个字母更长。例如："你"的电报码是5152，需要发送四个数字的摩斯码。',
        'cexp3_title': '正确！',
        'cexp3_content': '中文电报码系统在1920年代开始广泛使用，主要用于电报通信。',
        'cexp4_title': '正确！',
        'cexp4_content': '现代中文摩斯电码主要用于应急通信和业余无线电爱好者之间的交流，在紧急情况下可以作为备用通信手段。',
        'cexp5_title': '正确！',
        'cexp5_content': '学习中文摩斯电码最好从常用的基础汉字开始，逐步积累经验，而不是一开始就背诵整个电报码表。'
      },
      'en-US': {
        // Basics quiz - English
        'q1_question': 'Morse code uses two basic signals: dots (·) and dashes (—)',
        'q1_options': 'True,False',
        'q2_question': 'The SOS signal in Morse code is · · · — — — · · ·, with standard spacing between each letter',
        'q2_options': 'True,False',
        'q3_question': 'In Morse code, the duration ratio of dots, dashes, and spaces is',
        'q3_options': '1:2:3,1:3:7,1:4:8,1:5:10',
        'q4_question': 'In which decade was Morse code invented?',
        'q4_options': '1790-1800s,1830-1840s,1870-1880s,1900-1910s',
        'q5_question': 'The recommended order for learning Morse code is',
        'q5_options': 'Numbers→Letters→Symbols,Symbols→Numbers→Letters,Letters→Numbers→Symbols,Random learning',

        'exp1_title': 'Correct!',
        'exp1_content': 'Morse code indeed uses only two basic signals: dots (·) and dashes (—), which are combined to represent letters, numbers, and symbols.',
        'exp2_title': 'Incorrect',
        'exp2_content': 'SOS is an emergency distress signal. For quick recognition, its three letters are sent continuously without standard character spacing. The correct way is: ···———··· (sent continuously)',
        'exp3_title': 'Correct!',
        'exp3_content': 'In Morse code, the standard duration ratio is:\n• Dot (·) = 1 unit\n• Dash (—) = 3 units\n• Character spacing = 3 units\n• Word spacing = 7 units',
        'exp4_title': 'Correct!',
        'exp4_content': 'Morse code was invented by Samuel Morse in the 1830-1840s, originally used for telegraph communication.',
        'exp5_title': 'Correct!',
        'exp5_content': 'The recommended learning order is: learn letters first (especially common ones), then numbers, and finally punctuation. This allows gradual mastery of Morse code.',

        // Chinese Morse Code quiz - English
        'cq1_question': 'Chinese Morse code mainly uses telegraph codes (four-digit numbers) to represent Chinese characters',
        'cq1_options': 'True,False',
        'cq2_question': 'Chinese character Morse encoding is usually shorter than English characters',
        'cq2_options': 'True,False',
        'cq3_question': 'When did the Chinese telegraph code system start being used?',
        'cq3_options': '1850s,1920s,1950s,1980s',
        'cq4_question': 'Modern Chinese Morse code is mainly used for',
        'cq4_options': 'Daily communication,Emergency communication and amateur radio,Commercial advertising,Online chat',
        'cq5_question': 'The best way to learn Chinese Morse code is',
        'cq5_options': 'Memorize the telegraph code table directly,Practice starting with basic Chinese characters,Only learn pinyin,Random learning',

        'cexp1_title': 'Correct!',
        'cexp1_content': 'Chinese Morse code does use four-digit telegraph codes to represent each Chinese character, which are then converted to Morse code for transmission.',
        'cexp2_title': 'Incorrect',
        'cexp2_content': 'Chinese characters need to be converted to four-digit telegraph codes first, so the encoding is usually longer than single English letters. For example: "你" has telegraph code 5152, requiring four digits of Morse code.',
        'cexp3_title': 'Correct!',
        'cexp3_content': 'The Chinese telegraph code system began widespread use in the 1920s, mainly for telegraph communication.',
        'cexp4_title': 'Correct!',
        'cexp4_content': 'Modern Chinese Morse code is mainly used for emergency communication and among amateur radio enthusiasts, serving as a backup communication method in emergency situations.',
        'cexp5_title': 'Correct!',
        'cexp5_content': 'Learning Chinese Morse code is best started with commonly used basic Chinese characters, gradually building experience, rather than memorizing the entire telegraph code table at the beginning.'
      }
    }

    const langKey = isChinese ? 'zh-CN' : 'en-US'
    return localizedStrings[langKey]?.[key] || key
  }

  // 初始化测试数据
  initializeTestData(pageTitle: string, context?: Context, language?: string): void {
    console.error(`[QuizViewModel] initializeTestData: pageTitle=${pageTitle}, language=${language}`)

    // 更新语言
    if (language) {
      this.currentLanguage = language
    }

    // 存储context
    if (context) {
      this.context = context
    }

    if (pageTitle.includes('基础') || pageTitle.includes('intro') || pageTitle.includes('Intro') || pageTitle.includes('Basics') || pageTitle.includes('basics')) {
      this.questions = [
        {
          type: 'true_false',
          question: this.getLocalizedString('q1_question'),
          options: this.getLocalizedString('q1_options').split(','),
          answer: 0, // 正确
          points: 20,
        },
        {
          type: 'true_false',
          question: this.getLocalizedString('q2_question'),
          options: this.getLocalizedString('q2_options').split(','),
          answer: 1, // 错误，SOS是紧凑发送，无字符间隔
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: this.getLocalizedString('q3_question'),
          options: this.getLocalizedString('q3_options').split(','),
          answer: 1, // 1:3:7
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: this.getLocalizedString('q4_question'),
          options: this.getLocalizedString('q4_options').split(','),
          answer: 1, // 1830-1840 年代
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: this.getLocalizedString('q5_question'),
          options: this.getLocalizedString('q5_options').split(','),
          answer: 2, // 字母→数字→符号
          points: 20,
        },
      ]

      this.explanations = [
        {
          title: this.getLocalizedString('exp1_title'),
          content: this.getLocalizedString('exp1_content'),
        },
        {
          title: this.getLocalizedString('exp2_title'),
          content: this.getLocalizedString('exp2_content'),
        },
        {
          title: this.getLocalizedString('exp3_title'),
          content: this.getLocalizedString('exp3_content'),
        },
        {
          title: this.getLocalizedString('exp4_title'),
          content: this.getLocalizedString('exp4_content'),
        },
        {
          title: this.getLocalizedString('exp5_title'),
          content: this.getLocalizedString('exp5_content'),
        },
      ]
    } else {
      // 中文摩斯电码测试
      this.questions = [
        {
          type: 'true_false',
          question: this.getLocalizedString('cq1_question'),
          options: this.getLocalizedString('cq1_options').split(','),
          answer: 0, // 正确
          points: 20,
        },
        {
          type: 'true_false',
          question: this.getLocalizedString('cq2_question'),
          options: this.getLocalizedString('cq2_options').split(','),
          answer: 1, // 错误，中文编码通常更长
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: this.getLocalizedString('cq3_question'),
          options: this.getLocalizedString('cq3_options').split(','),
          answer: 1, // 1920 年代
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: this.getLocalizedString('cq4_question'),
          options: this.getLocalizedString('cq4_options').split(','),
          answer: 1, // 应急通信和业余无线电
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: this.getLocalizedString('cq5_question'),
          options: this.getLocalizedString('cq5_options').split(','),
          answer: 1, // 从基础汉字开始
          points: 20,
        },
      ]

      this.explanations = [
        {
          title: this.getLocalizedString('cexp1_title'),
          content: this.getLocalizedString('cexp1_content'),
        },
        {
          title: this.getLocalizedString('cexp2_title'),
          content: this.getLocalizedString('cexp2_content'),
        },
        {
          title: this.getLocalizedString('cexp3_title'),
          content: this.getLocalizedString('cexp3_content'),
        },
        {
          title: this.getLocalizedString('cexp4_title'),
          content: this.getLocalizedString('cexp4_content'),
        },
        {
          title: this.getLocalizedString('cexp5_title'),
          content: this.getLocalizedString('cexp5_content'),
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

