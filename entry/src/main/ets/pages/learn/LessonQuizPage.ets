import { router } from '@kit.ArkUI'
import preferences from '@ohos.data.preferences'
import window from '@ohos.window'
import { ExplanationTipsCard } from '../../widgets/ExplanationTipsCard'
import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { globalProgressState } from '../../store/GlobalProgressState'
import { QuizViewModel } from '../../viewmodel/QuizViewModel'
import { QuizNavParams, QuestionItem, ExplanationItem, ButtonStyle } from '../../types/LessonTypes'

@Entry
@Component
struct LessonQuizPage {
  @State quizViewModel: QuizViewModel = new QuizViewModel()
  @State learnViewModel: LearnViewModel = new LearnViewModel()

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
      const params = (router.getParams() as QuizNavParams) ?? {}
      if (params) {
        if (params.pageTitle) this.quizViewModel.pageTitle = params.pageTitle
        if (params.lessonCompletedKey) this.quizViewModel.lessonCompletedKey = params.lessonCompletedKey
      }
      console.error(`[QUIZ] aboutToAppear params: pageTitle=${this.quizViewModel.pageTitle}, lessonCompletedKey=${this.quizViewModel.lessonCompletedKey}`)
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
    this.quizViewModel.initializeTestData(this.quizViewModel.pageTitle)
  }


  selectAnswer(answer: number) {
    this.quizViewModel.selectAnswer(answer)
  }

  showTestResult() {
    this.quizViewModel.showTestResult()
    const willSave = this.quizViewModel.score >= 100
    if (willSave) {
      this.markLessonCompleted()
    }
  }

  async markLessonCompleted() {
    try {
      // 使用 ViewModel 来标记测试完成，这会自动解锁下一课
      const uiContext = this.getUIContext()
      const hostContext = uiContext.getHostContext()
      if (hostContext) {
        const lessonNumber = parseInt(this.quizViewModel.lessonCompletedKey) || 0
        // 使用全局状态标记课程完成
        await globalProgressState.markLessonCompleted(lessonNumber, hostContext)
        
        console.error(`[QUIZ] markLessonCompleted: Completed for lessonNumber=${lessonNumber}`)
      }
      
      this.quizViewModel.progressSaved = true
    } catch (err) {
    }
  }

  restartTest() {
    this.quizViewModel.restartTest()
  }

  async goToNextLesson() {
    console.error(`[QUIZ] goToNextLesson: score=${this.quizViewModel.score} progressSaved=${this.quizViewModel.progressSaved}`)
    // Ensure progress is persisted before leaving so Learn tab sees the unlocks
    if (this.quizViewModel.score >= 100 && !this.quizViewModel.progressSaved) {
      console.error('[QUIZ] goToNextLesson: awaiting persist...')
      await this.markLessonCompleted()
    }
    // 弹出两次返回到学习页面
    console.error('[QUIZ] goToNextLesson: navigating back twice')
    router.back()
    router.back()
  }

  async backAfterPersist() {
    console.error(`[QUIZ] backAfterPersist: score=${this.quizViewModel.score} progressSaved=${this.quizViewModel.progressSaved}`)
    if (this.quizViewModel.score >= 100 && !this.quizViewModel.progressSaved) {
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

      Text(this.quizViewModel.pageTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text(`${this.quizViewModel.currentQuestionIndex + 1}/${this.quizViewModel.questions.length}`)
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
      Text(this.quizViewModel.score >= 100 ? '👏' : '😢')
        .fontSize(80)
        .margin({ bottom: 16 })

      Text('你的分数')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFFB3')
        .margin({ bottom: 4 })

      Text(`${this.quizViewModel.score}`)
        .fontSize(128)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.quizViewModel.score >= 100 ? '#4CAF50' : '#FF8C00')
        .margin({ bottom: 8 })

      Column() {
        Text(this.quizViewModel.score >= 100 ? '🎉 恭喜通过！' : '继续努力！')
          .fontSize(28)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })

        if (this.quizViewModel.score >= 100) {
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

        if (this.quizViewModel.score >= 100) {
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
    .constraintSize({ maxWidth: 480 })
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
        .layoutWeight(this.quizViewModel.isAnswered ? 0.5 : 1)

      // Main content area
      Column() {
        // Question card
        Column() {
          Text(this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].question)
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
        if (this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].type === 'true_false') {
          this.buildTrueFalseOptions()
        } else {
          this.buildMultipleChoiceOptions()
        }

        // Explanation card - 立即显示，使用透明度动画
        if (this.quizViewModel.isAnswered && this.quizViewModel.showExplanation) {
          ExplanationTipsCard({
            title: this.quizViewModel.explanations[this.quizViewModel.currentQuestionIndex].title,
            content: this.quizViewModel.explanations[this.quizViewModel.currentQuestionIndex].content,
            color: '#FF8C00'
          })
          .margin({ top: 24 })
          .opacity(this.quizViewModel.showDelayedContent ? 1 : 0)
          .animation({
            duration: 600,
            curve: Curve.EaseInOut
          })
        }

        // Next button - 延迟显示，使用透明度动画
        if (this.quizViewModel.isAnswered) {
          Column() {
            this.NextButton()
          }
          .margin({ top: 24 })
          .opacity(this.quizViewModel.showNextButton ? 1 : 0)
          .animation({
            duration: 600,
            curve: Curve.EaseInOut
          })
        }
      }

      // Bottom spacing - 当已回答时减少间距
      Blank()
        .layoutWeight(this.quizViewModel.isAnswered ? 0.5 : 1)
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
      ForEach(this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].options || [], (option: string, index: number) => {
        // 如果已回答，只显示正确答案和用户选择的错误答案
        if (this.quizViewModel.isAnswered) {
          // 只显示正确答案或用户选择的错误答案
          if (this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer === index || this.quizViewModel.selectedAnswer === index) {
            Column() {
              this.buildAnswerButton(
                option,
                index,
                this.quizViewModel.selectedAnswer === index,
                this.quizViewModel.isAnswered && this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer === index,
                this.quizViewModel.isAnswered && this.quizViewModel.selectedAnswer === index && this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer !== index,
                true // isTrueFalse = true
              )
            }
            .margin({ top: 16 })
          }
        } else {
          // 未作答时显示所有选项
          Column() {
            this.buildAnswerButton(
              option,
              index,
              this.quizViewModel.selectedAnswer === index,
              false, // isCorrect
              false, // isWrong
              true // isTrueFalse = true
            )
          }
          .margin({ top: 16 })
        }
      })
    }
  }



  @Builder
  buildMultipleChoiceOptions() {
    Column() {
      ForEach(this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].options || [], (option: string, index: number) => {
        // 如果已回答，只显示正确答案和用户选择的错误答案
        if (this.quizViewModel.isAnswered) {
          // 只显示正确答案或用户选择的错误答案
          if (this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer === index || this.quizViewModel.selectedAnswer === index) {
            Column() {
              this.buildAnswerButton(
                option,
                index,
                this.quizViewModel.selectedAnswer === index,
                this.quizViewModel.isAnswered && this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer === index,
                this.quizViewModel.isAnswered && this.quizViewModel.selectedAnswer === index && this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer !== index,
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
              this.quizViewModel.selectedAnswer === index,
              this.quizViewModel.isAnswered && this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer === index,
              this.quizViewModel.isAnswered && this.quizViewModel.selectedAnswer === index && this.quizViewModel.questions[this.quizViewModel.currentQuestionIndex].answer !== index,
              false
            )
          }
          .margin({ top: index > 0 ? 16 : 0 })
        }
      }, (option: string, index: number) => `q${this.quizViewModel.currentQuestionIndex}-opt${index}-${option.substring(0, 10)}`)
    }
  }


  @Builder
  buildAnswerButton(
    text: string,
    value: number,
    isSelected: boolean,
    isCorrect: boolean,
    isWrong: boolean,
    isTrueFalse: boolean = false
  ) {
    Button() {
      Row() {
        Text(text)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.quizViewModel.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).textColor)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        if (isSelected) {
          Circle({ width: 8, height: 8 })
            .fill(this.quizViewModel.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).textColor)
            .margin({ right: 16 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(48)
    .backgroundColor(this.quizViewModel.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).backgroundColor)
    .border({ width: 2, color: this.quizViewModel.getButtonStyle(isSelected, isCorrect, isWrong, isTrueFalse).borderColor })
    .borderRadius(12)
    .onClick(() => {
      this.selectAnswer(value)
    })
  }

  @Builder
  NextButton() {
    if (this.quizViewModel.isAnswered) {
      Button() {
        Text(this.quizViewModel.currentQuestionIndex < this.quizViewModel.questions.length - 1 ? '下一题' : '查看结果')
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
        this.quizViewModel.nextQuestion()
        if (this.quizViewModel.showResult) {
          this.showTestResult()
        }
      })
    }
  }

  build() {
    Column() {
      this.TitleBar()

      if (this.quizViewModel.showResult) {
        this.ResultScreen()
      } else {
        Column() {
          this.QuestionScreen()
        }
        .layoutWeight(1)
        .constraintSize({ maxWidth: 480 })
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
