import { MorseCode, MorseCodeData } from '../../models/MorseCode'
// System bar colors are set globally in EntryAbility
import { router } from '@kit.ArkUI'
import { audioService } from '../../services/AudioService'
import { i18nService } from '../../services/I18nService'
import { eventHub, Events } from '../../utils/EventHub'
// 使用$r()函数替代I18n
import { Context } from '@kit.AbilityKit'

interface Category {
  key: string
  name: string
}

@Component
export struct CodeTablePage {
  @State selected: string = 'all'
  @State playingCode: string = '' // 跟踪当前播放的摩尔斯码
  @State isEnglish: boolean = false // 语言检测
  @State refreshTrigger: number = 0
  // 使用 StorageLink 监听语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  private categories: Category[] = [
    { key: 'all', name: '' },
    { key: 'alphabet', name: '' },
    { key: 'numbers', name: '' },
    { key: 'punctuation', name: '' },
  ]

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
    this.checkLanguage()
  }

  aboutToDisappear() {
  }

  private checkLanguage() {
    const currentLang = i18nService.getCurrentLanguage()
    this.isEnglish = currentLang.startsWith('en')
  }

  private getCategoryLabel(key: string): Resource | string {
    switch (key) {
      case 'all':
        return i18nService.t('all_codes')
      case 'alphabet':
        return i18nService.t('letters')
      case 'numbers':
        return i18nService.t('numbers')
      case 'punctuation':
        return i18nService.t('punctuation')
      default:
        return i18nService.t('all_codes')
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

  // 播放摩尔斯码
  private async playMorseCode(morseCode: string): Promise<void> {
    this.playingCode = morseCode
    try {
      await audioService.playMorseSequence(morseCode)
    } catch (error) {
      console.error('Failed to play morse code:', error)
    } finally {
      // 播放完成后重置状态
      setTimeout(() => {
        this.playingCode = ''
      }, 1000)
    }
  }

  build() {
    // Flutter theme mapping:
    // primary/background: #000000, surface: #1A1A1A, text: #FFFFFF,
    // textSecondary: #B0B0B0, border: #333333, accent: #FFD700
    Column() {
      // Title bar
      Row() {
        Blank().width(40) // Balance the right button

        Text(i18nService.t('code_table'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 中按钮 - 只在中文环境下显示
        if (!this.isEnglish) {
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
            router.push({
              url: 'pages/codetable/ChineseTelegraphCodePage'
            })
          })
        } else {
          // 英文环境下显示占位符，保持布局平衡
          Column()
            .width(40)
            .height(40)
        }
      }
      .height(52)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#000000')

      // 内容区域 - 限制宽度为480vp
      Column() {
        // Category filter row (chips)
        Scroll() {
          Row() {
            ForEach(this.categories, (cat: Category) => {
              Button(this.getCategoryLabel(cat.key))
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
              // 第一列：字符 (30%) - 左对齐
              Row() {
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
              }
              .width('30%')
              .justifyContent(FlexAlign.Start)

              // 第二列：摩尔斯电码 (55%) - 右对齐
              Row() {
                Text(this.toDisplayMorse(code.morse))
                  .textAlign(TextAlign.End)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontFamily('monospace')
                  .fontColor('#FFFFFF')
              }
              .width('55%')
              .justifyContent(FlexAlign.End)

              // 第三列：空白间距 (5%)
              Row() {
                Blank()
              }
              .width('5%')

              // 第四列：播放按钮 (10%) - 左对齐
              Row() {
                Button() {
                  Image($rawfile('ic_play.svg'))
                    .width(20)
                    .height(20)
                    .scale({ 
                      x: this.playingCode === code.morse ? 0.9 : 1.0, 
                      y: this.playingCode === code.morse ? 0.9 : 1.0 
                    })
                    .opacity(this.playingCode === code.morse ? 0.7 : 1.0)
                    .animation({ duration: 150, curve: Curve.EaseInOut })
                }
                .width(40)
                .height(40)
                .backgroundColor(this.playingCode === code.morse ? 'rgba(255, 215, 0, 0.1)' : Color.Transparent)
                .borderRadius(20)
                .animation({ duration: 150, curve: Curve.EaseInOut })
                .onClick(async () => {
                  if (this.playingCode === code.morse) {
                    // 如果正在播放，停止播放
                    audioService.stopAudio()
                    this.playingCode = ''
                  } else {
                    // 播放摩尔斯码
                    await this.playMorseCode(code.morse)
                  }
                })
              }
              .width('10%')
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .alignItems(VerticalAlign.Center)
          }
        }, (code: MorseCode) => code.character + ':' + code.morse)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .constraintSize({ maxWidth: 480 })
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .backgroundColor('#000000')
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
