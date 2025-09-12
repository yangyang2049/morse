import { DialogManager } from './CustomDialog'

interface LanguageOption {
  name: string
  code: string
}

interface DialogListItem {
  text: string
  selected?: boolean
  onClick?: () => void
}

/**
 * 选择对话框组件
 * 使用自定义对话框实现选择功能
 */
export class SelectionDialog {
  /**
   * 显示语言选择对话框
   * @param languages 语言选项数组
   * @param onLanguageSelect 语言选择回调
   */
  static showLanguageSelection(
    languages: Array<LanguageOption>,
    currentLanguage: string,
    onLanguageSelect: (languageCode: string) => void
  ): void {
    if (languages.length === 0) {
      console.error('SelectionDialog: 语言选项不能为空')
      return
    }

    // 使用自定义对话框显示语言选择（列表样式 + 边框 + 右侧黄色圆圈高亮）
    DialogManager.show({
      title: '选择语言',
      showCancel: false,
      showClose: true,
      listItems: languages.map((lang): DialogListItem => ({
        text: lang.name,
        selected: lang.code === currentLanguage,
        onClick: () => onLanguageSelect(lang.code)
      }))
    })
  }
}
