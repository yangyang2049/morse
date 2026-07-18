import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import preferences from '@ohos.data.preferences';
import { LocalizationHelper } from '../utils/LocalizationHelper';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    // 默认英文；按系统/应用偏好语言映射到 zh-CN / zh-HK / en-US
    LocalizationHelper.initializeAppLanguage();
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let mainPage = 'pages/Index';
    
    // Set status bar and navigation bar style
    windowStage.getMainWindow().then((windowClass) => {
      // Set status bar and navigation bar properties
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: '#000000',
        navigationBarContentColor: '#FFFFFF'
      });
    });

    try {
      if (deviceInfo.deviceType === 'wearable') {
        // Check privacy agreement for wearable
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
          // Fallback to Privacy Page if check fails for safety
          mainPage = 'pages/watch/PrivacyPage';
          this.loadContent(windowStage, mainPage);
        });
      } else {
        // Phone/Tablet logic (default)
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
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
  }

  onForeground(): void {
    // Ability has brought to foreground
  }

  onBackground(): void {
    // Ability has back to background
  }
}
