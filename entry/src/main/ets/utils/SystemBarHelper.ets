import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'

/**
 * 深色系统栏（状态栏 + 底部导航栏）。
 * 路由跳转到新的 @Entry 页时系统会重置栏颜色，导致底部先闪白，
 * 因此需在 EntryAbility 与每个 @Entry 页 aboutToAppear / onPageShow 中重新应用。
 */
export class SystemBarHelper {
  static applyDark(context: common.Context | undefined | null): void {
    if (!context) {
      return
    }
    try {
      window.getLastWindow(context).then((win: window.Window) => {
        win.setWindowSystemBarProperties({
          statusBarColor: '#000000',
          statusBarContentColor: '#FFFFFF',
          navigationBarColor: '#000000',
          navigationBarContentColor: '#FFFFFF'
        })
      }).catch((error: Error) => {
        console.error('[SystemBarHelper] Failed to get window:', error)
      })
    } catch (error) {
      console.error('[SystemBarHelper] Failed to apply dark system bars:', error)
    }
  }

  /** 从组件 UIContext 取 HostContext 后应用 */
  static applyDarkFromUIContext(uiContext: UIContext | undefined | null): void {
    if (!uiContext) {
      return
    }
    try {
      const host = uiContext.getHostContext()
      if (host) {
        SystemBarHelper.applyDark(host as common.Context)
      }
    } catch (error) {
      console.error('[SystemBarHelper] Failed to apply from UIContext:', error)
    }
  }
}
