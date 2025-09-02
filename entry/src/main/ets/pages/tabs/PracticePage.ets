import { PracticeViewModel } from '../../viewmodel/PracticeViewModel'

@Component
export struct PracticePage {
  private vm: PracticeViewModel = new PracticeViewModel()

  aboutToAppear(): void {
    this.vm.init()
  }

  aboutToDisappear(): void {
    this.vm.destroy()
  }

  @Builder
  private TitleBar() {
    Row() {
      Blank().width(48).height(48)
      Text('练习')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('≡').fontSize(20).fontColor(Color.White).width(48).height(48).textAlign(TextAlign.Center)
    }
    .height(52)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  private ProgressCircle() {
    Stack({ alignContent: Alignment.Center }) {
      // Progress ring (only visible when there are incorrect attempts)
      if (this.vm.hasIncorrectAttempt) {
        Column()
          .width(200)
          .height(200)
          .backgroundColor(Color.Transparent)
          .border({ 
            width: 8, 
            color: this.vm.progress >= 1.0 ? Color.Green : '#FFD700' 
          })
          .borderRadius(100)
      }

      // Inner circle (always visible)
      Column()
        .width(180)
        .height(180)
        .backgroundColor(
          this.vm.showResult && !this.vm.isCorrect ? Color.Red : 
          (this.vm.isCorrect ? Color.Green : '#FFD700')
        )
        .borderRadius(90)

      // Main character
      Text(this.vm.currentCharacter)
        .fontSize(72)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
    }
    .width(200)
    .height(200)
  }

  @Builder
  private InputDisplay() {
    Stack({ alignContent: Alignment.Center }) {
      // Placeholder text (always present but transparent)
      Text('- - -')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Transparent)
        .fontFamily('monospace')
        .letterSpacing(4)

      // Main input text
      Text(
        this.vm.showHint || this.vm.showCorrectAnswer ? 
        this.vm.currentMorse.replaceAll('.', '·') : 
        this.vm.userInput.replaceAll('.', '·')
      )
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontFamily('monospace')
        .letterSpacing(4)
        .fontColor(
          this.vm.showCorrectAnswer ? Color.Green :
          (this.vm.showHint ? Color.White :
          (this.vm.showResult && this.vm.isCorrect ? Color.Green :
          (this.vm.showResult && !this.vm.isCorrect ? Color.Red :
          (this.vm.userInput.length === 0 ? Color.Transparent : '#FFD700'))))
        )
    }
    .width('100%')
    .height(60)
  }

  @Builder
  private ToolButtons() {
    Row() {
      // Favorite button
      Button(this.vm.isFavorite ? '❤' : '♡')
        .onClick(() => this.vm.toggleFavorite())
        .fontColor(this.vm.isFavorite ? Color.Red : Color.White)
        .width(48).height(48)
        .backgroundColor(Color.Transparent)

      // Hint button (eye)
      Button('👁')
        .onClick(() => this.vm.flashHint())
        .fontColor(Color.White)
        .width(48).height(48)
        .backgroundColor(Color.Transparent)

      // Next button
      Button('⏭')
        .onClick(() => this.vm.passCharacter())
        .fontColor(Color.White)
        .width(48).height(48)
        .backgroundColor(Color.Transparent)
    }
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  private BottomKeys() {
    Row() {
      // Dot key
      Stack() {
        Column()
          .height(80)
          .backgroundColor('#1A1A1A')
          .borderRadius(20)
          .border({ width: 1, color: '#333333' })
        Column().width(20).height(20).backgroundColor('#FFD700').borderRadius(10).align(Alignment.Center)
      }
      .onClick(() => this.vm.addDot())
      .layoutWeight(1)

      Blank().width(20)

      // Dash key
      Stack() {
        Column()
          .height(80)
          .backgroundColor('#1A1A1A')
          .borderRadius(20)
          .border({ width: 1, color: '#333333' })
        Column().width(40).height(12).backgroundColor('#FFD700').align(Alignment.Center)
      }
      .onClick(() => this.vm.addDash())
      .layoutWeight(1)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
  }

  // PracticeRecordDialog omitted

  private getPracticedCount(): number { return 0 }
  private getTotalCount(): number { return 0 }

  build() {
    Stack() {
      Column() {
        this.TitleBar()

        Blank().height(20)

        // Main content
        Column() {
          // Character with progress circle
          this.ProgressCircle()

          Blank().height(40)

          this.InputDisplay()
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        this.ToolButtons()
        Blank().height(26)
        this.BottomKeys()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      // Floating error tip
      if (this.vm.showResult && !this.vm.isCorrect) {
        Column() {
          Text('再试一次')
            .fontColor(Color.White)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .backgroundColor(Color.Red)
        .borderRadius(20)
        .align(Alignment.Bottom)
        .margin({ bottom: 200 })
      }
    }
  }
}
