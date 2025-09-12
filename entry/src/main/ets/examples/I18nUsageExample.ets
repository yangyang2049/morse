import { i18nService } from '../services/I18nService'
import { SimpleLanguageSwitcher } from '../widgets/LanguageSwitcher'

/**
 * I18n使用示例页面
 * 演示如何在页面中正确使用新的多语言系统
 */
@Entry
@Component
struct I18nUsageExample {
  // 监听语言变化，自动触发UI重新渲染
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  
  // 示例数据
  @State private score: number = 85
  @State private userName: string = 'John'

  build() {
    Column({ space: 20 }) {
      // 页面标题
      Text(i18nService.t('app_name'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      
      // 基础文本使用
      Text(i18nService.t('welcome'))
        .fontSize(18)
        .fontColor($r('app.color.text_primary'))
      
      // 带参数的文本使用（模板替换）
      Text(i18nService.t('your_score_is', { score: this.score.toString() }))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
      
      // 按钮文本
      Button(i18nService.t('start_test'))
        .fontSize(16)
        .backgroundColor($r('app.color.accent'))
        .fontColor(Color.White)
        .borderRadius(8)
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .onClick(() => {
          // 按钮点击处理
          console.log('开始测试')
        })
      
      // 条件显示文本
      Text(this.score >= 80 ? 
        i18nService.t('congratulations_passed') : 
        i18nService.t('keep_trying'))
        .fontSize(16)
        .fontColor(this.score >= 80 ? Color.Green : Color.Orange)
      
      // 列表项示例
      Column({ space: 12 }) {
        this.ListItem(i18nService.t('learn'), 'ic_learn')
        this.ListItem(i18nService.t('practice'), 'ic_practice')
        this.ListItem(i18nService.t('translate'), 'ic_translate')
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(12)
      
      // 语言切换器
      Row() {
        Text(i18nService.t('language'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        
        SimpleLanguageSwitcher()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(8)
      
      // 状态信息
      Column({ space: 8 }) {
        Text(`当前语言: ${this.currentLanguage}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        
        Text(`是否中文: ${i18nService.isChinese()}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        
        Text(`是否英文: ${i18nService.isEnglish()}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.background_tertiary'))
      .borderRadius(8)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor($r('app.color.background_primary'))
  }

  /**
   * 列表项组件
   */
  @Builder
  ListItem(title: string, iconName: string) {
    Row({ space: 12 }) {
      Image($rawfile(`${iconName}.svg`))
        .width(24)
        .height(24)
        .fillColor($r('app.color.text_primary'))
      
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 16, bottom: 16 })
    .backgroundColor(Color.Transparent)
    .borderRadius(8)
    .onClick(() => {
      console.log(`点击了: ${title}`)
    })
  }
}

/**
 * 使用指南和最佳实践
 * 
 * 1. 基础使用：
 *    - 使用 i18nService.t('key') 获取翻译文本
 *    - 使用 @StorageLink('currentLanguage') 监听语言变化
 * 
 * 2. 模板参数：
 *    - 支持参数替换：i18nService.t('hello_user', { name: 'John' })
 *    - 字典中使用 {name} 占位符
 * 
 * 3. 条件显示：
 *    - 可以根据语言状态显示不同内容
 *    - 使用 i18nService.isChinese() / isEnglish() 判断
 * 
 * 4. 组件集成：
 *    - 使用 LanguageSwitcher 或 SimpleLanguageSwitcher 组件
 *    - 自动处理语言切换和UI刷新
 * 
 * 5. 性能优化：
 *    - 语言切换立即生效，无需重启应用
 *    - 使用字典缓存，查找性能高效
 * 
 * 6. 扩展性：
 *    - 可以通过 addTranslation() 动态添加翻译
 *    - 支持远程加载语言包
 */
