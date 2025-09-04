import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility
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
  @State isLoading: boolean = true
  private infoDialog: CustomDialogController = new CustomDialogController({
    builder: this.InfoDialog(),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  })

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility

    // 延迟加载数据，让页面先显示
    setTimeout(() => {
      this.loadChineseTelegraphCodes()
    }, 100)
  }

  private loadChineseTelegraphCodes() {
    try {
      // Load from rawfile
      const uiContext = this.getUIContext()
      const hostContext = uiContext.getHostContext()
      if (hostContext) {
        hostContext.resourceManager.getRawFileContent('chinese_telegraph_codes_full.json')
        .then((data: ArrayBuffer) => {
          const decoder = new util.TextDecoder('utf-8')
          const uint8Array = new Uint8Array(data)
          const jsonString = decoder.decodeWithStream(uint8Array)
          const parsedData = JSON.parse(jsonString) as ChineseTelegraphCode[]
          this.codes = parsedData
          this.filteredCodes = parsedData
          this.isLoading = false
          console.log(`Loaded ${this.codes.length} Chinese telegraph codes`)
        })
        .catch(() => {
          console.error('Failed to load Chinese telegraph codes')
          // Fallback to empty array
          this.codes = []
          this.filteredCodes = []
          this.isLoading = false
        })
      } else {
        console.error('Host context is undefined')
        this.codes = []
        this.filteredCodes = []
        this.isLoading = false
      }
    } catch {
      console.error('Error loading Chinese telegraph codes')
      this.codes = []
      this.filteredCodes = []
      this.isLoading = false
    }
  }

  // Removed onPageShow system bar re-application to avoid flicker

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

      // Info entrance at top-right (emoji memo)
      Button() {
        Text('📝')
          .fontSize(20)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.infoDialog.open()
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  private InfoDialog() {
    // 简要说明标准中文电码表
    Column() {
      Text('标准中文电码表说明')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)

      Blank().height(12)

      Scroll() {
        Column() {
          Text('• 标准中文电码（Chinese Telegraph Code, CTC）是一套用四位数字表示常用汉字的编码体系，最早用于电报传输。')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Start)
            .width('100%')

          Blank().height(8)

          Text('• 每个汉字对应一个唯一的四位数字（0001–9999），便于在通信中准确传递。')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Start)
            .width('100%')

          Blank().height(8)

          Text('• 本页面可按“汉字”或“电码”搜索，方便快速定位目标。')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
      }
      .height(140)

      Blank().height(16)

      Row() {
        Button() {
          Text('知道了')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .height(44)
        .layoutWeight(1)
        .backgroundColor('#FFD700')
        .borderRadius(10)
        .onClick(() => this.infoDialog.close())
      }
      .width('100%')
    }
    .width(420)
    .padding(20)
    .backgroundColor('#000000')
    .border({ width: 1, color: '#333333' })
    .borderRadius(16)
  }

  @Builder
  SearchBar() {
    Search({
      value: this.searchText,
      placeholder: '搜索汉字或电码...'
    })
    .placeholderColor('#666666')
    .fontColor(Color.White)
    .backgroundColor('#1A1A1A')
    .borderRadius(20)
    .height(40)
    .searchIcon({ color: Color.White })
    .onChange((value: string) => {
      this.onSearchTextChange(value)
    })
    .onSubmit((value: string) => {
      this.onSearchTextChange(value)
    })
    .width('100%')
    .margin({ left: 16, right: 16, top: 16, bottom: 8 })
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

  @Builder
  LoadingIndicator() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#FFD700')
      
      Blank().height(16)
      
      Text('加载中...')
        .fontSize(16)
        .fontColor('#CCCCCC')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      this.TitleBar()
      
      // 内容区域 - 响应式宽度，最大480vp
      Column() {
        // 搜索与表头始终可见
        this.SearchBar()
        this.TableHeader()

        // 列表或加载中
        if (this.isLoading) {
          this.LoadingIndicator()
        } else {
          if (this.filteredCodes.length === 0) {
            // 空数据提示
            Column() {
              Text('暂无数据')
                .fontSize(14)
                .fontColor('#888888')
                .textAlign(TextAlign.Center)
            }
            .layoutWeight(1)
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
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
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: 480 })
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
