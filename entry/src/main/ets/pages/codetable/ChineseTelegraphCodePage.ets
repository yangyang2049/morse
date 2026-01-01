
import util from '@ohos.util'
import { DialogManager } from '../../widgets/CustomDialog'
import { CustomDialog } from '../../widgets/CustomDialog'
import { router } from '@kit.ArkUI'

interface ChineseTelegraphCode {
  character: string
  code: string
}

// 实现 IDataSource 接口用于 LazyForEach
class ChineseTelegraphCodeDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []
  private originDataArray: ChineseTelegraphCode[] = []

  constructor(dataArray: ChineseTelegraphCode[]) {
    this.originDataArray = dataArray
  }

  totalCount(): number {
    return this.originDataArray.length
  }

  getData(index: number): ChineseTelegraphCode {
    return this.originDataArray[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  // 更新数据源
  updateData(dataArray: ChineseTelegraphCode[]): void {
    this.originDataArray = dataArray
    this.notifyDataReload()
  }

  // 通知数据变化
  private notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded()
    })
  }
}

@Entry
@Component
export struct ChineseTelegraphCodePage {
  @State codes: ChineseTelegraphCode[] = []
  @State searchText: string = ''
  @State filteredCodes: ChineseTelegraphCode[] = []
  @State isLoading: boolean = true
  @State isSearching: boolean = false
  private dataSource: ChineseTelegraphCodeDataSource = new ChineseTelegraphCodeDataSource([])

  // 分页相关状态
  @State currentPage: number = 0
  @State pageSize: number = 100
  @State hasMoreData: boolean = true
  @State isLoadingMore: boolean = false

  // 搜索相关状态
  @State searchResults: ChineseTelegraphCode[] = []
  @State isSearchMode: boolean = false

  // 语言检测
  @State isEnglish: boolean = false

  // 数据缓存
  private static allDataCache: ChineseTelegraphCode[] | null = null
  private static isDataLoaded: boolean = false

  // 搜索防抖定时器
  private searchDebounceTimer: number | null = null

  aboutToAppear() {
    console.log('ChineseTelegraphCodePage aboutToAppear called')

    // 检查语言设置
    this.checkLanguage()

    // 延迟加载数据，让页面先显示
    setTimeout(() => {
      console.log('Starting to load Chinese telegraph codes...')
      this.loadFirstPage()
    }, 100)
  }

  aboutToDisappear() {
    // 清理搜索防抖定时器
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer)
      this.searchDebounceTimer = null
    }
  }

  private checkLanguage() {
    // 使用 AppStorage 获取当前语言
    const currentLang: string = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    this.isEnglish = currentLang.startsWith('en')
  }

  // 加载第一页数据
  private loadFirstPage() {
    this.loadPage(0)
  }

  // 加载指定页面的数据
  private loadPage(page: number) {
    // 如果数据已缓存，直接使用缓存
    if (ChineseTelegraphCodePage.isDataLoaded && ChineseTelegraphCodePage.allDataCache) {
      this.processPageData(ChineseTelegraphCodePage.allDataCache, page)
      return
    }

    try {
      const context = this.getUIContext().getHostContext()
      if (context) {
        context.resourceManager.getRawFileContent('chinese_telegraph_codes_full.json')
          .then((data: ArrayBuffer) => {
            const decoder = new util.TextDecoder('utf-8')
            const uint8Array = new Uint8Array(data)
            const jsonString = decoder.decodeToString(uint8Array)
            const allData = JSON.parse(jsonString) as ChineseTelegraphCode[]

            // 缓存数据
            ChineseTelegraphCodePage.allDataCache = allData
            ChineseTelegraphCodePage.isDataLoaded = true

            this.processPageData(allData, page)
          })
          .catch((error: Error) => {
            console.error('Failed to load Chinese telegraph codes:', error.message ?? '')
            this.handleLoadError()
          })
      } else {
        console.error('Host context is undefined')
        this.handleLoadError()
      }
    } catch {
      this.handleLoadError()
    }
  }

  // 处理分页数据
  private processPageData(allData: ChineseTelegraphCode[], page: number) {
    // 计算分页数据
    const startIndex = page * this.pageSize
    const endIndex = Math.min(startIndex + this.pageSize, allData.length)
    const pageData = allData.slice(startIndex, endIndex)

    if (page === 0) {
      // 第一页，替换所有数据
      this.codes = pageData
      this.filteredCodes = pageData
      this.dataSource.updateData(this.filteredCodes)
      this.isLoading = false
    } else {
      // 后续页，追加数据
      this.codes = [...this.codes, ...pageData]
      if (!this.isSearchMode) {
        this.filteredCodes = [...this.filteredCodes, ...pageData]
        this.dataSource.updateData(this.filteredCodes)
      }
      this.isLoadingMore = false
    }

    // 检查是否还有更多数据
    this.hasMoreData = endIndex < allData.length
    this.currentPage = page

    console.log(`Loaded page ${page + 1}, total items: ${this.codes.length}`)
  }

  // 处理加载错误
  private handleLoadError() {
    this.codes = []
    this.filteredCodes = []
    this.dataSource.updateData([])
    this.isLoading = false
    this.isLoadingMore = false
  }

  // 加载更多数据
  private loadMoreData() {
    if (this.isLoadingMore || !this.hasMoreData || this.isSearchMode) {
      return
    }

    this.isLoadingMore = true
    this.loadPage(this.currentPage + 1)
  }

  // Removed onPageShow system bar re-application to avoid flicker

  private onSearchTextChange(text: string) {
    this.searchText = text
    
    // 清除之前的防抖定时器
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer)
      this.searchDebounceTimer = null
    }
    
    if (text.trim() === '') {
      // 清空搜索，恢复分页模式
      this.isSearchMode = false
      this.filteredCodes = this.codes
      this.dataSource.updateData(this.filteredCodes)
      this.searchResults = []
    } else {
      // 进入搜索模式
      this.isSearchMode = true
      this.isSearching = true

      // 防抖搜索：300ms内多次输入只执行最后一次搜索
      this.searchDebounceTimer = setTimeout(() => {
        this.performSearch(text)
        this.searchDebounceTimer = null
      }, 300)
    }
  }

  // 执行搜索
  private performSearch(text: string) {
    if (this.searchText !== text) {
      return // 搜索文本已改变，忽略此次搜索
    }

    // 如果数据已缓存，直接使用缓存进行搜索
    if (ChineseTelegraphCodePage.isDataLoaded && ChineseTelegraphCodePage.allDataCache) {
      this.performSearchOnData(ChineseTelegraphCodePage.allDataCache, text)
      return
    }

    // 如果数据未缓存，先加载数据
    try {
      const context = this.getUIContext().getHostContext()
      if (context) {
        context.resourceManager.getRawFileContent('chinese_telegraph_codes_full.json')
          .then((data: ArrayBuffer) => {
            const decoder = new util.TextDecoder('utf-8')
            const uint8Array = new Uint8Array(data)
            const jsonString = decoder.decodeToString(uint8Array)
            const allData = JSON.parse(jsonString) as ChineseTelegraphCode[]

            // 缓存数据
            ChineseTelegraphCodePage.allDataCache = allData
            ChineseTelegraphCodePage.isDataLoaded = true

            this.performSearchOnData(allData, text)
          })
          .catch((error: Error) => {
            console.error('Search failed:', error.message ?? '')
            this.searchResults = []
            this.filteredCodes = []
            this.dataSource.updateData([])
            this.isSearching = false
          })
      }
    } catch {
      this.searchResults = []
      this.filteredCodes = []
      this.dataSource.updateData([])
      this.isSearching = false
    }
  }

  // 在指定数据中执行搜索
  private performSearchOnData(allData: ChineseTelegraphCode[], text: string) {
    // 在全部数据中搜索
    const results = allData.filter(code =>
      code.character.includes(text) || code.code.includes(text)
    )

    this.searchResults = results
    this.filteredCodes = results
    this.dataSource.updateData(this.filteredCodes)
    this.isSearching = false

    console.log(`Search for "${text}" found ${results.length} results`)
  }

  @Builder
  TitleBar() {
    Row() {
      Button() {
        Image($rawfile('ic_back.svg'))
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

      Text('标准中文电码')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Info entrance at top-right (question mark) - 中文显示按钮，英文显示占位符
      if (!this.isEnglish) {
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
            // Use custom dialog to support proper line breaks
            DialogManager.show({
              title: '标准中文电码',
              message: '中文电码表（又称"汉字电报码"）是为了在电报传输时代能够准确、快速地发送和接收汉字而设计的编码系统。\n\n• 起源与标准化\n最早由清末盛宣怀主持制定，后来经过民国与新中国的多次修订，形成了较为统一的国家标准。常见的版本是《标准电码本》，收录 7000 余个常用汉字。\n\n• 编码方式\n每个汉字对应一个四位数字编码，范围一般是 0001–9999。\n例如：\n• "中" = 0029\n• "国" = 0049\n• "电" = 0168\n• "码" = 0203\n\n• 使用方式\n在电报传输中，发送方只需要发送对应的四位数字，接收方就能根据电码本查回原来的汉字。这样既能保证传输准确，也方便跨语言通信（数字是国际通用的）。\n\n本页面可按"汉字"或"电码"搜索，方便快速定位目标。',
              confirmText: '知道了',
              showCancel: false,
              showClose: false
            })
          })
      } else {
        // 英文环境下显示占位符，保持布局平衡
        Column()
          .width(40)
          .height(40)
      }
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
  }

  // System dialog used instead of custom dialog

  @Builder
  SearchBar() {
    Column() {
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

      // 搜索状态指示器
      if (this.isSearching) {
        Row() {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#FFD700')

          Text('搜索中...')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ left: 8 })
        }
        .margin({ left: 16, right: 16, bottom: 8 })
          .justifyContent(FlexAlign.Start)
      }
    }
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

  @Builder
  LoadMoreButton() {
    Button() {
      if (this.isLoadingMore) {
        Row() {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#FFD700')

          Text('加载中...')
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ left: 8 })
        }
        .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
      } else {
        Text('加载更多')
          .fontSize(14)
          .fontColor(Color.White)
      }
    }
    .width('100%')
      .height(48)
      .backgroundColor('#1A1A1A')
      .border({ width: 1, color: '#333333' })
      .borderRadius(8)
      .margin({ top: 8, bottom: 8 })
      .onClick(() => {
        this.loadMoreData()
      })
  }

  build() {
    Stack() {
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
                LazyForEach(this.dataSource, (code: ChineseTelegraphCode, index: number) => {
                  ListItem() {
                    this.TableRow(code, index)
                  }
                }, (code: ChineseTelegraphCode) => code.character + code.code)

                // 加载更多按钮（仅在分页模式且还有更多数据时显示）
                if (!this.isSearchMode && this.hasMoreData) {
                  ListItem() {
                    this.LoadMoreButton()
                  }
                }
              }
              .layoutWeight(1)
                .divider({ strokeWidth: 0 })
                .scrollBar(BarState.Auto)
                .onReachEnd(() => {
                  // 滚动到底部时自动加载更多
                  if (!this.isSearchMode && this.hasMoreData && !this.isLoadingMore) {
                    this.loadMoreData()
                  }
                })
            }
          }
        }
        .width('100%')
          .constraintSize({ maxWidth: 400 })
          .padding({ left: 20, right: 20 })
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 自定义对话框
      CustomDialog()
    }
  }
}
