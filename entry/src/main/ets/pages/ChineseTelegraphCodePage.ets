import { router } from '@kit.ArkUI'
import window from '@ohos.window'
import util from '@ohos.util'

interface ChineseTelegraphCode {
  character: string
  code: string
}

@Entry
@Component
export struct ChineseTelegraphCodePage {
  @State codes: ChineseTelegraphCode[] = []
  @State searchText: string = ''
  @State filteredCodes: ChineseTelegraphCode[] = []

  aboutToAppear() {
    // Set status bar color
    window.getLastWindow(getContext(this)).then((windowClass) => {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#000000',
        statusBarContentColor: '#FFFFFF'
      })
    })

    this.loadChineseTelegraphCodes()
  }

  private loadChineseTelegraphCodes() {
    try {
      // Load from rawfile
      const context = getContext(this)
      context.resourceManager.getRawFileContent('chinese_telegraph_codes_full.json')
        .then((data: ArrayBuffer) => {
          const decoder = new util.TextDecoder('utf-8')
          const uint8Array = new Uint8Array(data)
          const jsonString = decoder.decodeWithStream(uint8Array)
          const parsedData = JSON.parse(jsonString) as ChineseTelegraphCode[]
          this.codes = parsedData
          this.filteredCodes = parsedData
          console.log(`Loaded ${this.codes.length} Chinese telegraph codes`)
        })
        .catch(() => {
          console.error('Failed to load Chinese telegraph codes')
          // Fallback to empty array
          this.codes = []
          this.filteredCodes = []
        })
    } catch {
      console.error('Error loading Chinese telegraph codes')
      this.codes = []
      this.filteredCodes = []
    }
  }

  private onSearchTextChange(text: string) {
    this.searchText = text
    if (text.trim() === '') {
      this.filteredCodes = this.codes
    } else {
      this.filteredCodes = this.codes.filter(code => 
        code.character.includes(text) || code.code.includes(text)
      )
    }
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
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back()
      })

      Text('标准中文电码')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank().width(40) // Balance the back button
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  SearchBar() {
    Row() {
      TextInput({ placeholder: '搜索汉字或电码...' })
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#1A1A1A')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .fontColor(Color.White)
        .placeholderColor('#666666')
        .onChange((value: string) => {
          this.onSearchTextChange(value)
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  @Builder
  TableHeader() {
    Row() {
      Text('汉字')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .width('25%')
        .textAlign(TextAlign.Center)

      Text('电码')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFD700')
        .width('75%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(48)
    .backgroundColor('#1A1A1A')
    .padding({ left: 16, right: 16 })
    .border({ width: 1, color: '#333333' })
  }

  @Builder
  TableRow(code: ChineseTelegraphCode, index: number) {
    Row() {
      Text(code.character)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .width('25%')
        .textAlign(TextAlign.Center)

      Text(code.code)
        .fontSize(16)
        .fontWeight(FontWeight.Normal)
        .fontColor('#CCCCCC')
        .width('75%')
        .textAlign(TextAlign.Center)
        .fontFamily('monospace')
    }
    .width('100%')
    .height(48)
    .backgroundColor(index % 2 === 0 ? '#0A0A0A' : '#111111')
    .padding({ left: 16, right: 16 })
    .border({ width: 1, color: '#333333' })
  }

  build() {
    Column() {
      this.TitleBar()
      this.SearchBar()
      this.TableHeader()

      List() {
        ForEach(this.filteredCodes, (code: ChineseTelegraphCode, index: number) => {
          ListItem() {
            this.TableRow(code, index)
          }
        }, (code: ChineseTelegraphCode) => code.character + code.code)
      }
      .layoutWeight(1)
      .divider({ strokeWidth: 0 })
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
