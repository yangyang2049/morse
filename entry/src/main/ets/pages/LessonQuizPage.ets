import { router } from '@kit.ArkUI'
import preferences from '@ohos.data.preferences'
import window from '@ohos.window'
import { ExplanationTipsCard } from '../widgets/ExplanationTipsCard'
import { LearnViewModel } from '../viewmodel/LearnViewModel'

interface QuizNavParams {
  testType?: string
  pageTitle?: string
  testCompletedKey?: string
}

interface QuestionItem {
  type: string
  question: string
  answer: boolean | number
  points: number
  options?: string[]
}

interface ExplanationItem {
  title: string
  content: string
}

interface ButtonStyle {
  backgroundColor: string
  textColor: string
  borderColor: string
}

@Entry
@Component
struct LessonQuizPage {
  @State testType: string = 'intro'
  @State pageTitle: string = '基础测试'
  @State testCompletedKey: string = 'intro_test_completed'
  @State learnViewModel: LearnViewModel = new LearnViewModel()
  @State currentQuestionIndex: number = 0
  @State score: number = 0
  @State isAnswered: boolean = false
  @State selectedAnswer: number | null = null
  @State showResult: boolean = false
  @State showExplanation: boolean = false
  @State showDelayedContent: boolean = false
  @State showNextButton: boolean = false
  @State progressSaved: boolean = false

  @State questions: QuestionItem[] = []
  @State explanations: ExplanationItem[] = []

  aboutToAppear() {
    // Set status bar color
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      window.getLastWindow(hostContext).then((windowClass) => {
        windowClass.setWindowSystemBarProperties({
          statusBarColor: '#000000',
          statusBarContentColor: '#FFFFFF'
        })
      })
    }

    // Load route params, if any
    try {
      const params = (router.getParams?.() as QuizNavParams) ?? {}
      if (params) {
        if (params.testType) this.testType = params.testType
        if (params.pageTitle) this.pageTitle = params.pageTitle
        if (params.testCompletedKey) this.testCompletedKey = params.testCompletedKey
      }
      console.error(`[QUIZ] aboutToAppear params: testType=${this.testType}, pageTitle=${this.pageTitle}, testCompletedKey=${this.testCompletedKey}`)
    } catch (e) {
      console.warn('No params or failed to read params for LessonQuizPage:', e)
    }

    // Initialize ViewModel and questions for selected test type
    const uiContext2 = this.getUIContext()
    const hostContext2 = uiContext2.getHostContext()
    if (hostContext2) {
      this.learnViewModel.init(hostContext2)
    }
    console.error('[QUIZ] aboutToAppear: init ViewModel called')
    this.initializeTestData()
  }

  initializeTestData() {
    console.error(`[QUIZ] initializeTestData: testType=${this.testType}`)
    if (this.testType === 'intro') {
      this.questions = [
        {
          type: 'true_false',
          question: '摩斯密码是以"点（·）和划（-）"为基本元素的字符编码系统。',
          answer: true,
          points: 20,
        },
        {
          type: 'true_false',
          question: 'SOS信号的摩斯密码是 ··· --- ···，各字符之间需要保持正常的字符间隔。',
          answer: false, // SOS是紧凑发送，无字符间隔
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
          question: '摩斯密码是在哪个年代开发的？',
          options: ['1820 年代', '1830-1840 年代', '1850 年代', '1860 年代'],
          answer: 1, // 1830-1840年代
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
          content: '• 塞缪尔·摩斯与阿尔弗雷德·韦尔在1830-1840年代合作开发\n• 最初用于电报系统，后来演化为国际摩斯密码\n• 成为全球标准的无线电通信编码系统',
        },
        {
          title: '学习策略',
          content: '• 字母 → 数字 → 符号的学习顺序最科学\n• 先掌握基础字母，再学习数字和符号\n• 循序渐进，避免信息过载，提高学习效率',
        },
      ]
    } else {
      // chinese
      this.questions = [
        {
          type: 'true_false',
          question: '中文摩尔斯电码是专门为中文汉字设计的摩尔斯电码系统。',
          answer: true,
          points: 20,
        },
        {
          type: 'true_false',
          question: '中文摩尔斯电码的编码长度通常比英文摩尔斯电码短。',
          answer: false, // 中文编码通常更长
          points: 20,
        },
        {
          type: 'multiple_choice',
          question: '中文摩尔斯电码是在哪个年代开始制定的？',
          options: ['1900年代', '1920年代', '1950年代', '1980年代'],
          answer: 1, // 1920年代
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
          content: '• 1920年代：初步制定中文摩尔斯电码标准\n• 当时为了适应中文电报通信的需求\n• 国际电信联盟（ITU）参与制定\n• 经过多次优化形成现代标准',
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

  selectAnswer(answer: boolean | number) {
    if (this.isAnswered) return

    this.selectedAnswer = answer === true ? 1 : (answer === false ? 0 : answer as number)
    this.isAnswered = true

    // Check answer
    let isCorrect = false
    if (this.questions[this.currentQuestionIndex].type === 'true_false') {
      const correctAnswer = this.questions[this.currentQuestionIndex].answer as boolean
      isCorrect = (answer === correctAnswer)
    } else {
      const correctAnswer = this.questions[this.currentQuestionIndex].answer as number
      isCorrect = (answer === correctAnswer)
    }

    if (isCorrect) {
      this.score += this.questions[this.currentQuestionIndex].points
    }
    console.error(`[QUIZ] selectAnswer: qIdx=${this.currentQuestionIndex} type=${this.questions[this.currentQuestionIndex].type} selected=${this.selectedAnswer} correct=${isCorrect} score=${this.score}`)

    // Show explanation immediately, but delay opacity animation for content
    this.showExplanation = true
    // Delay the opacity animation for 300ms
    setTimeout(() => {
      this.showDelayedContent = true
    }, 300)
    // Delay the next button for additional 600ms (total 1200ms)
    setTimeout(() => {
      this.showNextButton = true
    }, 900)
  }

  showTestResult() {
    this.showResult = true

    const willSave = this.score >= 100
    console.error(`[QUIZ] showTestResult: score=${this.score} willPersist=${willSave}`)
    if (willSave) {
      this.markLessonCompleted()
    }
  }

  async markLessonCompleted() {
    try {
      // 使用 ViewModel 来标记测试完成，这会自动解锁下一课
      const uiContext = this.getUIContext()
      const hostContext = uiContext.getHostContext()
      if (hostContext) { //change the key plz
        await this.learnViewModel.markLessonCompleted(this.testCompletedKey, hostContext)
      }
      
      this.progressSaved = true
    } catch (err) {
    }
  }

  restartTest() {
    this.currentQuestionIndex = 0
    this.score = 0
    this.isAnswered = false
    this.selectedAnswer = null
    this.showResult = false
    this.showExplanation = false
    this.showDelayedContent = false
    this.showNextButton = false
  }

  async goToNextLesson() {
    console.error(`[QUIZ] goToNextLesson: score=${this.score} progressSaved=${this.progressSaved}`)
    // Ensure progress is persisted before leaving so Learn tab sees the unlocks
    if (this.score >= 100 && !this.progressSaved) {
      console.error('[QUIZ] goToNextLesson: awaiting persist...')
      await this.markLessonCompleted()
    }
    // 弹出两次返回到学习页面
    console.error('[QUIZ] goToNextLesson: navigating back twice')
    router.back()
    router.back()
  }

  async backAfterPersist() {
    console.error(`[QUIZ] backAfterPersist: score=${this.score} progressSaved=${this.progressSaved}`)
    if (this.score >= 100 && !this.progressSaved) {
      console.error('[QUIZ] backAfterPersist: awaiting persist...')
      await this.markLessonCompleted()
    }
    console.error('[QUIZ] backAfterPersist: navigating back once')
    router.back()
  }

  @Builder
  TitleBar() {
    Row() {
      Button() {
        Image($rawfile('ic_back.svg'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back()
      })

      Text(this.pageTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text(`${this.currentQuestionIndex + 1}/${this.questions.length}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ right: 16 })
    }
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.Transparent)
  }

  @Builder
  ResultScreen() {
    Column() {
      Text(this.score >= 100 ? '👏' : '😢')
        .fontSize(80)
        .margin({ bottom: 16 })

      Text('你的分数')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFFB3')
        .margin({ bottom: 4 })

      Text(`${this.score}`)
        .fontSize(128)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.score >= 100 ? '#4CAF50' : '#FF8C00')
        .margin({ bottom: 8 })

      Column() {
        Text(this.score >= 100 ? '🎉 恭喜通过！' : '继续努力！')
          .fontSize(28)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })

        if (this.score >= 100) {
          Text('你已经掌握了摩斯密码的基础知识')
            .fontSize(16)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 8 })
        } else {
          Text('需要100分才能通过测试')
            .fontSize(16)
            .fontColor('#FFFFFFB3')
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
        }
      }
      .margin({ bottom: 48 })

      Row() {
        Button() {
          Row() {
            Image($rawfile('ic_back.svg')).width(16).height(16).fillColor('#1A1A1A').margin({ right: 8 })
            Text('返回')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
          }
        }
        .layoutWeight(1)
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .onClick(() => {
          this.backAfterPersist()
        })

        if (this.score >= 100) {
          Button() {
            Row() {
              Text('下一课')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
              Image($rawfile('ic_forward.svg')).width(16).height(16).fillColor('#1A1A1A').margin({ left: 8 })
            }
          }
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#FFD700')
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.goToNextLesson()
          })
        } else {
          Button() {
            Row() {
              Text('重新测试')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Image($rawfile('ic_forward.svg')).width(16).height(16).fillColor(Color.White).margin({ left: 8 })
            }
          }
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#FF8C00')
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.restartTest()
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }

  @Builder
  QuestionScreen() {

    Column() {
      // Top spacing - 当已回答时减少间距
      Blank()
        .layoutWeight(this.isAnswered ? 0.5 : 1)

      // Main content area
      Column() {
        // Question card
        Column() {
          Text(this.questions[this.currentQuestionIndex].question)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .lineHeight(27)
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .width('100%')
        .height(160)
        .padding({ left: 16, right: 16, top: 24, bottom: 24 })
        .backgroundColor('#FFF8DC')
        .borderRadius(16)
        .margin({ bottom: 32 })
        .justifyContent(FlexAlign.Center)
        .animation({
          duration: 600,
          curve: Curve.EaseInOut
        })

        // Answer options
        if (this.questions[this.currentQuestionIndex].type === 'true_false') {
          this.buildTrueFalseOptions()
        } else {
          this.buildMultipleChoiceOptions()
        }

        // Explanation card - 立即显示，使用透明度动画
        if (this.isAnswered && this.showExplanation) {
          ExplanationTipsCard({
            title: this.explanations[this.currentQuestionIndex].title,
            content: this.explanations[this.currentQuestionIndex].content,
            color: '#FF8C00'
          })
          .margin({ top: 24 })
          .opacity(this.showDelayedContent ? 1 : 0)
          .animation({
            duration: 600,
            curve: Curve.EaseInOut
          })
        }

        // Next button - 延迟显示，使用透明度动画
        if (this.isAnswered) {
          Column() {
            this.NextButton()
          }
          .margin({ top: 24 })
          .opacity(this.showNextButton ? 1 : 0)
          .animation({
            duration: 600,
            curve: Curve.EaseInOut
          })
        }
      }

      // Bottom spacing - 当已回答时减少间距
      Blank()
        .layoutWeight(this.isAnswered ? 0.5 : 1)
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .animation({
      duration: 600,
      curve: Curve.EaseInOut
    })
  }

  @Builder
  buildTrueFalseOptions() {
    Column() {
      this.buildTFAnswerButton('正确', true, this.selectedAnswer === 1)

      Column() {
        this.buildTFAnswerButton('错误', false, this.selectedAnswer === 0)
      }
      .margin({ top: 16 })
    }
  }

  getTFButtonStyle(choiceValue: boolean, isSelected: boolean): ButtonStyle {
    if (this.isAnswered) {
      const correct = this.questions[this.currentQuestionIndex].answer as boolean
      if (choiceValue === correct) {
        return { backgroundColor: '#E8F5E8', textColor: '#2E7D32', borderColor: '#4CAF50' }
      }
      if (isSelected) {
        return { backgroundColor: '#FFEBEE', textColor: '#C62828', borderColor: '#F44336' }
      }
      return { backgroundColor: '#F5F5F5', textColor: '#9E9E9E', borderColor: '#E0E0E0' }
    }
    if (isSelected) {
      return { backgroundColor: '#E3F2FD', textColor: '#1A1A1A', borderColor: '#2196F3' }
    }
    return { backgroundColor: '#F5F5F5', textColor: '#1A1A1A', borderColor: '#E0E0E0' }
  }

  @Builder
  buildTFAnswerButton(text: string, value: boolean, isSelected: boolean) {
    Button() {
      Text(text)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTFButtonStyle(value, isSelected).textColor)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(48)
    .backgroundColor(this.getTFButtonStyle(value, isSelected).backgroundColor)
    .border({ width: 2, color: this.getTFButtonStyle(value, isSelected).borderColor })
    .borderRadius(12)
    .onClick(() => {
      this.selectAnswer(value)
    })
  }

  @Builder
  buildMultipleChoiceOptions() {
    Column() {
      ForEach(this.questions[this.currentQuestionIndex].options || [], (option: string, index: number) => {
        // 如果已回答，只显示正确答案和用户选择的错误答案
        if (this.isAnswered) {
          // 只显示正确答案或用户选择的错误答案
          if (this.questions[this.currentQuestionIndex].answer === index || this.selectedAnswer === index) {
            Column() {
              this.buildAnswerButton(
                option,
                index,
                this.selectedAnswer === index,
                this.isAnswered && this.questions[this.currentQuestionIndex].answer === index,
                this.isAnswered && this.selectedAnswer === index && this.questions[this.currentQuestionIndex].answer !== index,
                false
              )
            }
            .margin({ top: 16 })
          }
        } else {
          // 未回答时显示所有选项
          Column() {
            this.buildAnswerButton(
              option,
              index,
              this.selectedAnswer === index,
              this.isAnswered && this.questions[this.currentQuestionIndex].answer === index,
              this.isAnswered && this.selectedAnswer === index && this.questions[this.currentQuestionIndex].answer !== index,
              false
            )
          }
          .margin({ top: index > 0 ? 16 : 0 })
        }
      }, (option: string, index: number) => `q${this.currentQuestionIndex}-opt${index}-${option.substring(0, 10)}`)
    }
  }

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

  @Builder
  buildAnswerButton(
    text: string,
    value: boolean | number,
    isSelected: boolean,
    isCorrect: boolean,
    isWrong: boolean,
    isTrueFalse: boolean = false
  ) {
    Button() {
      Text(text)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).textColor)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(48)
    .backgroundColor(this.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).backgroundColor)
    .border({ width: 2, color: this.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).borderColor })
    .borderRadius(12)
    .onClick(() => {
      this.selectAnswer(value)
    })
  }

  @Builder
  NextButton() {
    if (this.isAnswered) {
      Button() {
        Text(this.currentQuestionIndex < this.questions.length - 1 ? '下一题' : '查看结果')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFD700')
      .borderRadius(12)
      .onClick(() => {
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
      })
    }
  }

  build() {
    Column() {
      this.TitleBar()

      if (this.showResult) {
        this.ResultScreen()
      } else {
        Column() {
          this.QuestionScreen()
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
