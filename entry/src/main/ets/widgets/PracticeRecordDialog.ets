import { PracticeViewModel } from '../viewmodel/PracticeViewModel'
import { MorseCode } from '../models/MorseCode'
import { i18nService } from '../services/I18nService'

@CustomDialog
export struct PracticeRecordDialog {
  @Link vm: PracticeViewModel
  controller: CustomDialogController

  // 获取已练习数量
  private getPracticedCount(): number {
    const completionCount = this.vm.getCompletionCount()
    return Array.from(completionCount.values()).filter(count => count > 0).length
  }

  // 获取总数量
  private getTotalCount(): number {
    return this.vm.getCurrentCodes().length
  }

  // 获取芯片背景颜色
  private getChipBackgroundColor(index: number): string {
    const completionCount = this.vm.getCompletionCount()
    const hasBeenPracticed = completionCount.has(index) && (completionCount.get(index) || 0) > 0
    return hasBeenPracticed ? 'rgba(76, 175, 80, 0.3)' : 'rgba(153, 153, 153, 0.2)'
  }

  // 获取芯片边框
  private getChipBorder(index: number): BorderOptions {
    const hadIncorrect = this.vm.getHadIncorrectOnCompletion()
    const showIncorrectBadge = hadIncorrect.get(index) === true
    return showIncorrectBadge 
      ? { width: 1.2, color: 'rgba(255, 215, 0, 0.8)' }
      : { width: 0, color: Color.Transparent }
  }

  // 获取芯片文字颜色
  private getChipTextColor(index: number): string {
    const completionCount = this.vm.getCompletionCount()
    const hasBeenPracticed = completionCount.has(index) && (completionCount.get(index) || 0) > 0
    return hasBeenPracticed ? '#4CAF50' : '#999999'
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(i18nService.t('practice_records'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        
        Blank().layoutWeight(1)
        
        // 关闭按钮
        Button() {
          Image($rawfile('ic_close.svg'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .onClick(() => {
          this.controller.close()
        })
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 20 })

      Blank().height(16)

      // 可滚动的字母网格区域
      Scroll() {
        Grid() {
          ForEach(this.vm.getCurrentCodes(), (code: MorseCode, index: number) => {
            GridItem() {
              Stack({ alignContent: Alignment.Center }) {
                // 背景圆圈
                Column()
                  .width(48)
                  .height(48)
                  .backgroundColor(this.getChipBackgroundColor(index))
                  .borderRadius(24)
                  .border(this.getChipBorder(index))
                
                // 字符文本
                Text(code.character)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getChipTextColor(index))
                  .textAlign(TextAlign.Center)
              }
              .width(48)
              .height(48)
            }
          }, (code: MorseCode, index: number) => `${code.character}_${index}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsGap(12)
        .columnsGap(12)
        .width('100%')
        .padding({ right: 8 })
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ left: 20, right: 20 })

      Blank().height(16)

      // 统计信息
      Row() {
        // 已练习数量
        Column() {
          Text(`${this.getPracticedCount()}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          
          Text(i18nService.t('practiced'))
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        
        // 垂直分隔线
        Column()
          .width(1)
          .height(40)
          .backgroundColor('rgba(255, 255, 255, 0.2)')
          .margin({ left: 8, right: 8 })
        
        // 总数量
        Column() {
          Text(`${this.getTotalCount()}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')
          
          Text(i18nService.t('total'))
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(12)
      .backgroundColor('#1A1A1A')
      .borderRadius(12)
      .margin({ left: 20, right: 20 })
    }
    .width('100%')
    .constraintSize({ maxHeight: '90%' })
    .backgroundColor('#2A2A2A')
    .borderRadius(20)
    .padding(20)
  }
}
