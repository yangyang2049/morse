/**
 * 豆花全家桶 — 应用推荐页
 * 列出豆花科技旗下应用，点击卡片跳转应用市场详情页
 */
import { common, Want } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';

interface FamilyApp {
  name: string;
  desc: string;
  icon: Resource;
  bundleId: string;
  badgeText?: string;
}

@Entry
@Component
export struct AppFamilyPage {
  private readonly APPGALLERY_PREFIX: string = 'https://appgallery.huawei.com/app/detail?id=';

  private apps: FamilyApp[] = [
    {
      name: '全能计分器',
      desc: '多项目一键计分，比分实时同步',
      icon: $r('app.media.ic_family_jifenqi'),
      bundleId: 'com.douhua.jifen',
      badgeText: '体育分类第 17 名'
    },
    {
      name: '计数器App',
      desc: '点按即记，自动保存',
      icon: $r('app.media.ic_family_counter'),
      bundleId: 'com.douhua.counter'
    },
    {
      name: '棋钟App',
      desc: '多棋类对局计时，落子按钟',
      icon: $r('app.media.ic_family_gotimer'),
      bundleId: 'com.douhua.gotimer'
    },
    {
      name: '英语语法手册',
      desc: '语法速查与练习',
      icon: $r('app.media.ic_family_yingyuyufa'),
      bundleId: 'com.douhua.yingyuyufa'
    },
    {
      name: '国旗小百科',
      desc: '国旗百科与趣味问答',
      icon: $r('app.media.ic_flag_wiki'),
      bundleId: 'com.douhua.flag',
      badgeText: '2万+下载'
    },
    {
      name: '掌上元素周期表',
      desc: '元素信息速查',
      icon: $r('app.media.ic_periodic_table'),
      bundleId: 'com.douhua.yuansu',
      badgeText: '1万+下载'
    }
  ];

  private resolveAbilityContext(): common.UIAbilityContext | null {
    const host = this.getUIContext()?.getHostContext();
    if (host) {
      return host as common.UIAbilityContext;
    }
    try {
      return getContext(this) as common.UIAbilityContext;
    } catch (_e) {
      return null;
    }
  }

  private openAppStore(bundleId: string): void {
    const url = this.APPGALLERY_PREFIX + bundleId;
    const context = this.resolveAbilityContext();
    if (!context) {
      this.getUIContext().getPromptAction().showToast({ message: '无法打开应用市场' });
      return;
    }
    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      };
      void context.startAbility(want).catch((err: Error) => {
        console.warn('[AppFamilyPage] AppGallery open failed, try openLink:', err.message);
        void context.openLink(url).catch((err2: Error) => {
          console.error('[AppFamilyPage] openLink failed:', err2.message);
          this.getUIContext().getPromptAction().showToast({ message: '无法打开应用市场' });
        });
      });
    } catch (e) {
      console.error('[AppFamilyPage] openAppStore failed:', e);
      this.getUIContext().getPromptAction().showToast({ message: '无法打开应用市场' });
    }
  }

  @Builder
  HeaderBuilder() {
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
        .borderRadius(24)
        .onClick(() => {
          router.back();
        })

      Text('豆花全家桶')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 48 })
    }
    .width('100%')
      .height(56)
      .backgroundColor('#000000')
      .padding({ left: 4, right: 16 })
  }

  @Builder
  AppListItem(app: FamilyApp) {
    Row({ space: 12 }) {
      Image(app.icon)
        .width(52)
        .height(52)
        .borderRadius(12)
        .objectFit(ImageFit.Contain)

      Column({ space: 8 }) {
        Row({ space: 6 }) {
          Text(app.name)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (app.badgeText) {
            Text(app.badgeText)
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFD700')
          }
        }
        .width('100%')
          .alignItems(VerticalAlign.Center)

        Text(app.desc)
          .fontSize(12)
          .fontColor('#B0B0B0')
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
      .padding(12)
      .backgroundColor('#1A1A1A')
      .borderRadius(12)
      .border({ width: 1, color: '#333333' })
      .onClick(() => {
        this.openAppStore(app.bundleId);
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder
  AppContent() {
    Column({ space: 12 }) {
      ForEach(this.apps, (app: FamilyApp) => {
        this.AppListItem(app)
      }, (app: FamilyApp) => app.bundleId)
    }
    .width('100%')
  }

  build() {
    Column() {
      this.HeaderBuilder()

      Scroll() {
        Column({ space: 16 }) {
          Text('豆花科技出品的更多应用')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')

          this.AppContent()
        }
        .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 24 })
          .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .backgroundColor('#000000')
    }
    .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
