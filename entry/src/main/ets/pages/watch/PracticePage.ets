import router from '@ohos.router'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { FavoritesStore } from '../../store/FavoritesStore'
import { Context } from '@kit.AbilityKit'

@Component
export struct PracticePage {
  
  async aboutToAppear() {
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        await FavoritesStore.getInstance().init(context)
      }
    } catch (error) {
      console.error('[PracticePage] Failed to initialize FavoritesStore:', error)
    }
  }

  build() {
    Column() {
      // 标题栏
      Text(LocalizationHelper.getString('watch_practice'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })
      
      Column() {
        // 字母转代码
        Row() {
          Text(LocalizationHelper.getString('watch_text_to_code'))
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/watch/PracticeDetailPage',
            params: {
              mode: 'text_to_code'
            }
          })
        })
        .margin({ bottom: 10 })

        // 代码转字母
        Row() {
          Text(LocalizationHelper.getString('watch_code_to_text'))
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/watch/PracticeDetailPage',
            params: {
              mode: 'code_to_text'
            }
          })
        })
        .margin({ bottom: 10 })

        // 错题本
        Row() {
          Text(LocalizationHelper.getString('watch_mistakes'))
            .fontSize(16)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
        }
        .width('80%')
        .height(44)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(8)
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/watch/PracticeMistakesPage'
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#000000')
  }
}
