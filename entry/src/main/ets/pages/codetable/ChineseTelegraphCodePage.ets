import { router, promptAction } from '@kit.ArkUI'
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

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
    console.log('ChineseTelegraphCodePage aboutToAppear called')
    
    // 延迟加载数据，让页面先显示
    setTimeout(() => {
      console.log('Starting to load Chinese telegraph codes...')
      this.loadChineseTelegraphCodes()
    }, 100)
  }

  private loadChineseTelegraphCodes() {
    try {
      // Load from rawfile using the correct context access method
      const context = this.getUIContext().getHostContext()
      if (context) {
        context.resourceManager.getRawFileContent('chinese_telegraph_codes_full.json')
        .then((data: ArrayBuffer) => {
          const decoder = new util.TextDecoder('utf-8')
          const uint8Array = new Uint8Array(data)
          const jsonString = decoder.decode(uint8Array)
          const parsedData = JSON.parse(jsonString) as ChineseTelegraphCode[]
          this.codes = parsedData
          this.filteredCodes = parsedData
          this.isLoading = false
          console.log(`Loaded ${this.codes.length} Chinese telegraph codes`)
        })
        .catch((error: Error) => {
          console.error('Failed to load Chinese telegraph codes:', error.message ?? '')
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

      // Info entrance at top-right (question mark)
      Button() {
        Text('?')
          .fontSize(20)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        // Use system dialog via promptAction
        promptAction.showDialog({
          title: '标准中文电码表说明',
          message: '中文电码表（又称"汉字电报码"）是为了在电报传输时代能够准确、快速地发送和接收汉字而设计的编码系统。\n\n• 起源与标准化\n最早由清末盛宣怀主持制定，后来经过民国与新中国的多次修订，形成了较为统一的国家标准。常见的版本是《标准电码本》，收录 7000 余个常用汉字。\n\n• 编码方式\n每个汉字对应一个四位数字编码，范围一般是 0001–9999。\n例如：\n• "中" = 0029\n• "国" = 0049\n• "电" = 0168\n• "码" = 0203\n\n• 使用方式\n在电报传输中，发送方只需要发送对应的四位数字，接收方就能根据电码本查回原来的汉字。这样既能保证传输准确，也方便跨语言通信（数字是国际通用的）。\n\n本页面可按"汉字"或"电码"搜索，方便快速定位目标。',
          buttons: [
            { text: '知道了', color: '#0A59F7' }
          ]
        })
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  // System dialog used instead of custom dialog

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
        // 加载中：只显示加载指示器，不显示搜索与表头
        if (this.isLoading) {
          this.LoadingIndicator()
        } else {
          // 加载完成后再显示搜索与表头
          this.SearchBar()
          this.TableHeader()

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
