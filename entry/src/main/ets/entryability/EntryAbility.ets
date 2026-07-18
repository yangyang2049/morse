import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import preferences from '@ohos.data.preferences';
import { LocalizationHelper } from '../utils/LocalizationHelper';
import { SystemBarHelper } from '../utils/SystemBarHelper';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 全应用深色主题；避免跟随系统浅色时导航栏默认变白
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

    // 默认英文；按系统/应用偏好语言映射到 zh-CN / zh-HK / en-US
    LocalizationHelper.initializeAppLanguage();
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let mainPage = 'pages/Index';

    windowStage.getMainWindow().then((windowClass) => {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: '#000000',
        navigationBarContentColor: '#FFFFFF'
      });
    });

    try {
      if (deviceInfo.deviceType === 'wearable') {
        preferences.getPreferences(this.context, 'app_settings').then((prefs) => {
          return prefs.get('privacy_agreed', false);
        }).then((isAgreed) => {
          if (isAgreed) {
            mainPage = 'pages/watch/Index';
          } else {
            mainPage = 'pages/watch/PrivacyPage';
          }
          this.loadContent(windowStage, mainPage);
        }).catch((err: Error) => {
          console.error('[EntryAbility] Failed to get preferences:', err);
          mainPage = 'pages/watch/PrivacyPage';
          this.loadContent(windowStage, mainPage);
        });
      } else {
        this.loadContent(windowStage, mainPage);
      }
    } catch (err) {
      console.error('[EntryAbility] Error in onWindowStageCreate:', err);
      this.loadContent(windowStage, mainPage);
    }
  }

  private loadContent(windowStage: window.WindowStage, page: string): void {
    windowStage.loadContent(page, (err) => {
      if (err.code) {
        console.error('Failed to load the content. Cause: ' + JSON.stringify(err) ?? '');
        return;
      }
      console.info('Succeeded in loading the content.');
      // 页面加载后再设一次，避免启动过渡闪白
      SystemBarHelper.applyDark(this.context);
    });
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
    SystemBarHelper.applyDark(this.context);
  }

  onBackground(): void {
  }
}
