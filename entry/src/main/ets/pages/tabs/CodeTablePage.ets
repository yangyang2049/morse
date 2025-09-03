import { MorseCode, MorseCodeData } from '../../models/MorseCode'
import window from '@ohos.window'
import { router } from '@kit.ArkUI'

interface Category {
  key: string
  name: string
}

@Component
export struct CodeTablePage {
  @State selected: string = 'all'
  private categories: Category[] = [
    { key: 'all', name: '所有码' },
    { key: 'alphabet', name: '字母' },
    { key: 'numbers', name: '数字' },
    { key: 'punctuation', name: '标点' },
  ]

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
  }

  private getFiltered(): MorseCode[] {
    let list: MorseCode[]
    if (this.selected === 'alphabet') {
      list = MorseCodeData.englishAlphabet
    } else if (this.selected === 'numbers') {
      list = MorseCodeData.numbers
    } else if (this.selected === 'punctuation') {
      list = MorseCodeData.punctuation
    } else {
      list = MorseCodeData.getAllCodes()
    }
    return list
  }

  private toDisplayMorse(m: string): string {
    // Avoid replaceAll compatibility issues
    return m.split('.').join('·')
  }

  build() {
    // Flutter theme mapping:
    // primary/background: #000000, surface: #1A1A1A, text: #FFFFFF,
    // textSecondary: #B0B0B0, border: #333333, accent: #FFD700
    Column() {
      // Title bar
      Row() {
        Blank().width(40) // Balance the right button

        Text('码表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button() {
          Text('中')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ChineseTelegraphCodePage'
          })
        })
      }
      .height(52)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#000000')

      // Category filter row (chips)
      Scroll() {
        Row() {
          ForEach(this.categories, (cat: Category) => {
            Button(cat.name)
              .onClick(() => { this.selected = cat.key })
              .backgroundColor(this.selected === cat.key ? '#FFD700' : '#1A1A1A')
              .fontColor(this.selected === cat.key ? '#000000' : '#B0B0B0')
              .borderRadius(18)
              .padding({ left: 14, right: 14 })
              .margin({ right: 8 })
              .border({ width: 1, color: '#333333' })
          }, (cat: Category) => cat.key)
        }.padding(12)
      }.scrollable(ScrollDirection.Horizontal)

      // List of codes
      List() {
        ForEach(this.getFiltered(), (code: MorseCode) => {
          ListItem() {
            Row() {
              // Avatar circle with centered character
              Stack() {
                Text(code.character)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFD700')
                  .align(Alignment.Center)
              }
              .width(50)
              .height(50)
              .backgroundColor('#1A1A1A')
              .borderRadius(25)
              .margin({ right: 12 })

              // Morse text right aligned
              Text(this.toDisplayMorse(code.morse))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontFamily('monospace')
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          }
        }, (code: MorseCode) => code.character + ':' + code.morse)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .backgroundColor('#000000')
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
