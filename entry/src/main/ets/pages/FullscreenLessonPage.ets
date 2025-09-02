import { MorseCode, MorseCodeData } from '../models/MorseCode'

@Entry
@Component
export struct FullscreenLessonPage {
  // Practice over a set of codes (default A–J)
  private codes: MorseCode[] = MorseCodeData.englishAlphabet.slice(0, 10)
  @State current: number = 0
  @State userInput: string = ''
  @State showResult: boolean = false
  @State isCorrect: boolean = false
  @State showHint: boolean = false

  private addDot(): void { this.userInput += '.' }
  private addDash(): void { this.userInput += '-' }
  private clearInput(): void { this.userInput = ''; this.showResult = false; this.isCorrect = false }
  private toggleHint(): void { this.showHint = !this.showHint }
  private check(): void {
    const target = this.codes[this.current].morse
    this.isCorrect = this.userInput === target
    this.showResult = true
  }
  private next(): void {
    if (this.current < this.codes.length - 1) {
      this.current++
      this.clearInput()
    }
  }

  @Builder
  private TitleBar() {
    Row() {
      Text('练习课程')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.Black)
  }

  @Builder
  private ProgressCircle() {
    // Simple circle with character
    Stack({ alignContent: Alignment.Center }) {
      Column().width(200).height(200).backgroundColor('#1A1A1A').borderRadius(100).border({ width: 2, color: '#333333' })
      Text(this.codes[this.current].character).fontSize(72).fontWeight(FontWeight.Bold).fontColor(Color.White)
    }
  }

  @Builder
  private MorseDisplay() {
    Text(this.showHint ? this.codes[this.current].morse.split('.').join('·') : '—')
      .fontSize(28)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.showHint ? '#FFFFFF' : '#FFFFFF80')
      .fontFamily('monospace')
      .letterSpacing(2)
  }

  @Builder
  private InputDisplay() {
    Text(this.userInput.split('.').join('·'))
      .fontSize(36)
      .fontWeight(FontWeight.Bold)
      .fontColor(
        this.showResult ? (this.isCorrect ? Color.Green : Color.Red) : (this.userInput.length === 0 ? Color.Transparent : '#FFD700')
      )
      .fontFamily('monospace')
      .letterSpacing(4)
  }

  @Builder
  private Controls() {
    Row() {
      // Hint
      Button(this.showHint ? '隐藏' : '提示').onClick(() => this.toggleHint())
      Blank().width(8)
      // Check
      Button('检查').onClick(() => this.check())
      Blank().width(8)
      // Next
      Button('下一个').onClick(() => this.next())
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private BottomKeys() {
    Row() {
      // Dot
      Stack() {
        Column().height(80).backgroundColor('#1A1A1A').borderRadius(20).border({ width: 1, color: '#333333' })
        Column().width(20).height(20).backgroundColor('#FFD700').borderRadius(10).align(Alignment.Center)
      }.onClick(() => this.addDot()).layoutWeight(1)
      Blank().width(20)
      // Dash
      Stack() {
        Column().height(80).backgroundColor('#1A1A1A').borderRadius(20).border({ width: 1, color: '#333333' })
        Column().width(40).height(12).backgroundColor('#FFD700').align(Alignment.Center)
      }.onClick(() => this.addDash()).layoutWeight(1)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
  }

  build() {
    Column() {
      this.TitleBar()

      Blank().height(16)

      Column() {
        this.ProgressCircle()
        Blank().height(24)
        this.MorseDisplay()
        Blank().height(16)
        this.InputDisplay()
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      this.Controls()
      Blank().height(12)
      this.BottomKeys()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
