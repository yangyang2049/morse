import { generateBarcode, scanCore } from '@kit.ScanKit'
import { image } from '@kit.ImageKit'
import router from '@ohos.router'
import { LocalizationHelper } from '../../utils/LocalizationHelper'

@Entry
@Component
export struct AppRecommendationDetail {
  @State qrCode: image.PixelMap | null = null
  @State qrCodeGenerating: boolean = false
  @State appType: string = 'quannengjifenqi' // 默认为全能计分器
  private appLink: string = 'https://douhua.fan/jifenqi/harmonyos'

  aboutToAppear(): void {
    // 从路由参数获取应用类型
    const params = router.getParams() as Record<string, Object> | undefined
    if (params && params['appType']) {
      this.appType = params['appType'] as string
      this.updateAppInfo()
    }
    void this.generateQRCode()
  }

  private updateAppInfo(): void {
    if (this.appType === 'zhaocha') {
      this.appLink = 'https://douhua.fan/zhaocha'
    } else if (this.appType === 'quannengjifenqi') {
      this.appLink = 'https://douhua.fan/jifenqi/harmonyos'
    } else {
      // 默认全能计分器
      this.appLink = 'https://douhua.fan/jifenqi/harmonyos'
    }
  }

  private getAppIcon(): Resource {
    if (this.appType === 'zhaocha') {
      return $r('app.media.appicon_zhaocha')
    } else if (this.appType === 'quannengjifenqi') {
      return $r('app.media.appicon_quannengjifenqi')
    }
    return $r('app.media.appicon_quannengjifenqi') // 默认全能计分器
  }

  private getAppName(): Resource {
    if (this.appType === 'zhaocha') {
      return LocalizationHelper.getString('app_recommendation_zhaocha_name')
    } else if (this.appType === 'quannengjifenqi') {
      return LocalizationHelper.getString('app_recommendation_quannengjifenqi_name')
    }
    return LocalizationHelper.getString('app_recommendation_quannengjifenqi_name')
  }

  private getAppDesc(): Resource {
    if (this.appType === 'zhaocha') {
      return LocalizationHelper.getString('app_recommendation_zhaocha_desc')
    } else if (this.appType === 'quannengjifenqi') {
      return LocalizationHelper.getString('app_recommendation_quannengjifenqi_desc')
    }
    return LocalizationHelper.getString('app_recommendation_quannengjifenqi_desc')
  }

  private getSearchText(): Resource {
    if (this.appType === 'zhaocha') {
      return LocalizationHelper.getString('search_zhaocha_in_appgallery')
    } else if (this.appType === 'quannengjifenqi') {
      return LocalizationHelper.getString('search_quannengjifenqi_in_appgallery')
    }
    return LocalizationHelper.getString('search_quannengjifenqi_in_appgallery')
  }

  private async generateQRCode(): Promise<void> {
    this.qrCodeGenerating = true
    try {
      const pixelMap: image.PixelMap = await generateBarcode.createBarcode(this.appLink, {
        scanType: scanCore.ScanType.QR_CODE,
        width: 300,
        height: 300
      })
      this.qrCode = pixelMap
      console.info('[AppRecommendationDetail] QR code generated successfully')
    } catch (err) {
      console.error('[AppRecommendationDetail] Failed to generate QR code:', err)
      this.qrCode = null
      try {
        const uiContext = this.getUIContext()
        if (uiContext) {
          const promptActionInstance = uiContext.getPromptAction()
          promptActionInstance.showToast({
            message: LocalizationHelper.getString('qr_code_generation_failed'),
            duration: 2000
          })
        }
      } catch (toastErr) {
        console.error('[AppRecommendationDetail] Failed to show toast:', toastErr)
      }
    } finally {
      this.qrCodeGenerating = false
    }
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 应用图标
          Image(this.getAppIcon())
            .width(80)
            .height(80)
            .borderRadius(40)
            .objectFit(ImageFit.Contain)
            .margin({ top: 20, bottom: 12 })

          // 应用名称
          Text(this.getAppName())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })

          // 应用描述
          Text(this.getAppDesc())
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
            .margin({ bottom: 20 })

          // 搜索提示
          Text(this.getSearchText())
            .fontSize(11)
            .fontColor('rgba(255, 255, 255, 0.6)')
            .margin({ bottom: 20 })

          // 二维码
          Column() {
            if (this.qrCode) {
              Image(this.qrCode)
                .width(150)
                .height(150)
                .backgroundColor(Color.White)
                .borderRadius(12)
                .padding(12)
            } else {
              Column() {
                LoadingProgress()
                  .width(32)
                  .height(32)
                  .color('#FFD700')
                Text(this.qrCodeGenerating ? LocalizationHelper.getString('qr_code_generating') : LocalizationHelper.getString('watch_loading_failed'))
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 8 })
              }
              .width(150)
              .height(150)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .margin({ bottom: 20 })

          // 关闭提示
          Text(LocalizationHelper.getString('click_to_close'))
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.8)')
            .padding({ top: 8, bottom: 8 })
            .onClick(() => {
              router.back()
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .focusable(true)
      .defaultFocus(true)
      .onClick(() => {
        router.back()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .onClick(() => {
      router.back()
    })
  }
}

