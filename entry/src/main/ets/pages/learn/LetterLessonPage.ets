import { MorseCode, MorseCodeData } from '../../models/MorseCode'
import { router } from '@kit.ArkUI'
import { LetterLessonViewModel } from '../../viewmodel/LetterLessonViewModel'
import { LessonData } from '../../data/LessonData'
import { promptAction } from '@kit.ArkUI'
import window from '@ohos.window'

@Entry
@Component
struct LetterLessonPage {
  @State viewModel: LetterLessonViewModel = new LetterLessonViewModel()

  aboutToAppear() {
    // 设置状态栏颜色
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

    // 从路由参数获取课程数据
    const params = router.getParams() as Record<string, Object>
    const lessonId = params['lessonId'] as string || ''
    const title = params['title'] as string || '练习课程'
    
    console.log(`[LetterLessonPage] Received lessonId: ${lessonId}, title: ${title}`)
    
    // 根据lessonId设置课程数据
    const codes = this.setupLessonData(lessonId)
    
    // 初始化ViewModel
    if (hostContext) {
      this.viewModel.init(hostContext, lessonId, title, codes)
    }
  }

  aboutToDisappear() {
    this.viewModel.destroy()
  }

  private setupLessonData(lessonId: string): MorseCode[] {
    console.log(`[LetterLessonPage] setupLessonData: lessonId=${lessonId}`)
    
    if (lessonId.includes('alpha_')) {
      const lessonIndex = parseInt(lessonId.split('_')[1]) || 0
      const alphabetGroups = LessonData.getAlphabetGroups()
      if (lessonIndex < alphabetGroups.length) {
        const targetLetters = alphabetGroups[lessonIndex]
        return MorseCodeData.englishAlphabet.filter(code => 
          targetLetters.includes(code.character)
        )
      } else {
        return MorseCodeData.englishAlphabet.slice(0, 3)
      }
    } else if (lessonId.includes('num_')) {
      const lessonIndex = parseInt(lessonId.split('_')[1]) || 0
      const numberGroups = LessonData.getNumberGroups()
      if (lessonIndex < numberGroups.length) {
        const targetNumbers = numberGroups[lessonIndex]
        return MorseCodeData.numbers.filter(code => 
          targetNumbers.includes(code.character)
        )
      } else {
        return MorseCodeData.numbers.slice(0, 3)
      }
    } else if (lessonId.includes('pun_')) {
      const lessonIndex = parseInt(lessonId.split('_')[1]) || 0
      const punctuationGroups = LessonData.getPunctuationGroups()
      if (lessonIndex < punctuationGroups.length) {
        const targetPunctuation = punctuationGroups[lessonIndex]
        return MorseCodeData.punctuation.filter(code => 
          targetPunctuation.includes(code.character)
        )
      } else {
        return MorseCodeData.punctuation.slice(0, 3)
      }
    } else if (lessonId.includes('word_')) {
      const lessonIndex = parseInt(lessonId.split('_')[1]) || 0
      const wordGroups = LessonData.getWordGroups()
      if (lessonIndex < wordGroups.length) {
        const targetWords = wordGroups[lessonIndex]
        return targetWords.map(word => new MorseCode(word, '', ''))
      } else {
        return [new MorseCode('THE', '', ''), new MorseCode('AND', '', ''), new MorseCode('FOR', '', '')]
      }
    } else {
      return MorseCodeData.englishAlphabet.slice(0, 3)
    }
  }

  @Builder
  private TitleBar() {
    Column() {
      Row() {
        Button() {
          Image($rawfile('ic_back.svg')).width(24).height(24).fillColor(Color.White)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

        Row() {
          ForEach(this.viewModel.codes, (code: MorseCode, index: number) => {
            Text(code.character)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.viewModel.getLetterStatusColor(index))
              .margin({ right: 8 })
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        if (this.viewModel.codes.length <= 10) {
          Button() {
            Image(this.viewModel.showMorseCode ? $rawfile('ic_eye.svg') : $rawfile('ic_eye_closed.svg'))
              .width(22).height(22).fillColor(Color.White)
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.viewModel.showMorseCode = !this.viewModel.showMorseCode
          })
        } else {
          Blank().width(48)
        }
      }
      .height(52)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .backgroundColor(Color.Black)
  }

  @Builder
  private ProgressCircle() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 220, height: 220 })
        .fill(Color.Transparent)
        .strokeWidth(8)
        .stroke('#333333')
      
      Circle({ width: 220, height: 220 })
        .fill(Color.Transparent)
        .strokeWidth(8)
        .stroke(this.viewModel.getProgressColor())
        .strokeDashArray([this.viewModel.getProgressVisualLength(), this.viewModel.getCircumference() - this.viewModel.getProgressVisualLength()])
        .strokeDashOffset(this.viewModel.getCircumference() / 4)
        .strokeLineCap(LineCapStyle.Round)
        .opacity(this.viewModel.progressVisual > 0 ? 1 : 0)
      
      Circle({ width: 200, height: 200 })
        .fill(this.viewModel.getProgressColor())
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      
      Text(this.viewModel.codes[this.viewModel.currentIndex]?.character || '')
        .fontSize(80)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
  }

  @Builder
  private MorseDisplay() {
    Column() {
      Text(this.viewModel.shouldShowHint(this.viewModel.currentIndex) ? 
        (this.viewModel.codes[this.viewModel.currentIndex]?.morse || '').replace(/\./g, '·') : '?')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.viewModel.shouldShowHint(this.viewModel.currentIndex) ? Color.White : '#FFFFFF80')
        .fontFamily('monospace')
        .letterSpacing(2)
    }
    .height(80)
    .width(150)
    .backgroundColor('#1A1A1A')
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private InputDisplay() {
    Column() {
      Text(this.viewModel.userInput.replace(/\./g, '·').trim())
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(
          this.viewModel.showResult && this.viewModel.isCorrect ? Color.Green :
          this.viewModel.userInput.trim().length === 0 ? Color.Transparent : '#FFD700'
        )
        .fontFamily('monospace')
        .letterSpacing(4)
        .textAlign(TextAlign.Center)
        .width('100%')
      
      if (this.viewModel.showResult && !this.viewModel.isCorrect) {
        Text(this.viewModel.userInput.replace(/\./g, '·').trim())
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
          .fontFamily('monospace')
          .letterSpacing(4)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .height(60)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private BottomKeys() {
    Row() {
      Button() {
        Circle({ width: 20, height: 20 })
          .fill('#FFD700')
      }
      .height(80)
      .backgroundColor('#1A1A1A')
      .borderRadius(20)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.viewModel.addDot())
      .layoutWeight(1)

      Blank().width(20)

      Button() {
        Rect({ width: 40, height: 12 })
          .fill('#FFD700')
      }
      .height(80)
      .backgroundColor('#1A1A1A')
      .borderRadius(20)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.viewModel.addDash())
      .layoutWeight(1)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
  }

  @Builder
  private CompletionDialog() {
    // 全屏覆盖层，用于居中显示对话框
    Column() {
      Blank().layoutWeight(1)
      
      // 对话框内容
      Column() {
        Column()
          .width(80)
          .height(80)
          .backgroundColor(Color.Green)
          .borderRadius(40)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 20, color: 'rgba(0, 255, 0, 0.3)', offsetX: 0, offsetY: 8 })
        {
          Text('✓')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }

        Blank().height(16)

        Text('恭喜完成！')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)

        Blank().height(20)

        Row() {
          Column() {
            Text(`${this.viewModel.codes.length}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('字母')
              .fontSize(10)
              .fontColor('#B0B0B0')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Blank().width(1).height(40).backgroundColor('#333333')

          Column() {
            Text(`${this.viewModel.codes.length * this.viewModel.REQUIRED_PRACTICE_COUNT}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('练习次数')
              .fontSize(10)
              .fontColor('#B0B0B0')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#1A1A1A')
        .border({ width: 1, color: '#333333' })
        .borderRadius(12)

        Blank().height(20)

        Row() {
          Button() {
            Text('返回')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .layoutWeight(1)
          .height(44)
          .backgroundColor(Color.Transparent)
          .border({ width: 2, color: Color.White })
          .borderRadius(8)
          .onClick(async () => {
            this.viewModel.closeCompletionDialog()
            const uiContext = this.getUIContext()
            const hostContext = uiContext.getHostContext()
            if (hostContext) {
              await this.viewModel.markLessonCompleted(hostContext)
            }
            router.back()
          })

          Blank().width(12)

          Button() {
            Text('再次练习')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .layoutWeight(1)
          .height(44)
          .backgroundColor(Color.Green)
          .borderRadius(8)
          .onClick(async () => {
            this.viewModel.closeCompletionDialog()
            const uiContext = this.getUIContext()
            const hostContext = uiContext.getHostContext()
            if (hostContext) {
              await this.viewModel.markLessonCompleted(hostContext)
            }
            this.viewModel.restartLesson()
          })
        }
        .width('100%')
      }
      .width(400)
      .padding(20)
      .backgroundColor('#000000')
      .border({ width: 2, color: Color.Green })
      .borderRadius(16)
      .shadow({ radius: 24, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 12 })
      
      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Column() {
        this.TitleBar()

        Blank().height(20)

        Column() {
          this.ProgressCircle()
          Blank().height(60)
          this.MorseDisplay()
          Blank().height(20)
          this.InputDisplay()
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        this.BottomKeys()
      }
      .width(480)
      .height('100%')
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .bindContentCover(this.viewModel.showCompletionDialog, this.CompletionDialog(), {
      modalTransition: ModalTransition.NONE,
      backgroundColor: 'rgba(0, 0, 0, 0.5)',
      onWillAppear: () => {
        console.log('Completion dialog will appear')
      }
    })
  }
}