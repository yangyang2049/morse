import { promptAction } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'

@Component
export struct MePage {
  @State appVersion: string = '1.0.0'
  @State appName: string = '摩斯密码'

  aboutToAppear() {
    this.loadAppInfo()
  }

  private loadAppInfo() {
    this.appVersion = '1.0.0'
    this.appName = '摩斯密码'
  }

  // 使用说明
  private showInstructions() {
    promptAction.showDialog({
      title: '使用说明',
      message: '1. 学习：从基础课程开始，逐步掌握摩尔斯电码\n2. 练习：通过不同难度的练习巩固学习成果\n3. 翻译：将文字转换为摩尔斯电码或反向转换\n4. 码表：查看完整的摩尔斯电码对照表\n\n点击播放按钮可以听到摩尔斯电码的声音',
      buttons: [
        {
          text: '知道了',
          color: '#FFD700'
        }
      ],
      alignment: DialogAlignment.Center
    }).then((result) => {
      console.log('用户确认了使用说明')
    })
  }

  // 评分和反馈
  private showRating() {
    this.openAppGallery()
  }

  // 分享应用
  private shareApp(): void {
    try {
      const shareText = '推荐一款学习摩尔斯密码的应用：\n《摩斯密码》📡\n\n• 从零学习摩尔斯电码\n• 跟读练习与听力训练\n• 文本与摩斯互相翻译\n\n立即下载：\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'

      const sysPB = pasteboard.getSystemPasteboard()
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
      sysPB.setPasteData(pasteData)

      promptAction.showToast({
        message: '分享内容已复制到剪贴板',
        duration: 2000
      })
    } catch (error) {
      console.error('复制到剪贴板失败:', error)
      promptAction.showToast({
        message: '复制失败，请稍后重试',
        duration: 2000
      })
    }
  }

  // 打开应用市场进行评分和反馈
  private openAppGallery(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.morsecode'
        }
      }

      context.startAbility(want).then(() => {
        promptAction.showToast({
          message: '正在打开应用市场…',
          duration: 1500
        })
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openAppGalleryByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openAppGalleryByBrowser()
    }
  }

  // 通过浏览器打开应用市场页面作为备选方案
  private openAppGalleryByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'
      }

      context.startAbility(want).then(() => {
        promptAction.showToast({
          message: '已通过浏览器打开应用市场',
          duration: 2000
        })
      }).catch((error: Error) => {
        console.error('浏览器打开应用市场失败:', error)
        promptAction.showToast({
          message: '无法打开应用市场，请稍后重试',
          duration: 3000
        })
      })
    } catch (error) {
      console.error('备选方案异常:', error)
      promptAction.showToast({
        message: '无法打开应用市场，请稍后重试',
        duration: 3000
      })
    }
  }



  @Builder SettingsItem(title: string, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .onClick(onClick)
  }

  build() {
    Column() {
      // 头部 - 应用信息（黑色背景，图标置顶）
      Column() {
        Image($r('app.media.startIcon'))
          .width(80)
          .height(80)
          .borderRadius(20)
          .margin({ bottom: 16 })
          .shadow({
            radius: 8,
            color: 'rgba(255, 255, 255, 0.3)',
            offsetX: 0,
            offsetY: 2
          })

        Text(this.appName)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 4 })

        Text(`版本 ${this.appVersion}`)
          .fontSize(14)
          .fontColor('#B0B0B0')
        }
        .width('100%')
        .padding({ top: 60, bottom: 40 })
        .alignItems(HorizontalAlign.Center)

        // 设置项（黑色背景卡片 + 分割线，无图标）
        Column() {
        // 盒子容器
        Column() {
          this.SettingsItem('使用说明', () => {
            this.showInstructions()
          })
          Divider().strokeWidth(1).color('#222222')

          this.SettingsItem('评分和反馈', () => {
            this.openAppGallery()
          })
          Divider().strokeWidth(1).color('#222222')

          this.SettingsItem('分享应用', () => {
            this.shareApp()
          })
        }
        .width('100%')
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .padding({ top: 4, bottom: 4 })
        .constraintSize({ maxWidth: 400 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      // 底部
      Column() {
        Text('让学习摩斯密码简单又有趣')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCCCCC')
          .margin({ bottom: 16 })

        Text('© 2025 重庆豆花科技有限公司')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ bottom: 20 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
