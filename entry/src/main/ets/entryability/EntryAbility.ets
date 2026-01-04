import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import preferences from '@ohos.data.preferences';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    // Initialize language detection and set to AppStorage
    this.initializeLanguage();
  }

  // Initialize language based on system locale
  private initializeLanguage(): void {
    try {
      // Try multiple methods to get the correct system language
      const systemLocale = i18n.System.getSystemLocale();
      const appPreferredLanguage = i18n.System.getAppPreferredLanguage();

      console.log(`[EntryAbility] System locale: ${systemLocale}`);
      console.log(`[EntryAbility] App preferred language: ${appPreferredLanguage}`);

      let languageCode = 'zh-CN'; // Default to Chinese

      // Use app preferred language if available, otherwise fall back to system locale
      const languageToCheck = appPreferredLanguage || systemLocale;
      console.log(`[EntryAbility] Language to check: ${languageToCheck}`);

      if (languageToCheck.startsWith('zh')) {
        languageCode = 'zh-CN';
        console.log(`[EntryAbility] Detected Chinese language: ${languageToCheck}`);
      } else if (languageToCheck.startsWith('en')) {
        languageCode = 'en-US';
        console.log(`[EntryAbility] Detected English language: ${languageToCheck}`);
      } else {
        console.log(`[EntryAbility] Unknown language: ${languageToCheck}, defaulting to Chinese`);
      }

      console.log(`[EntryAbility] Setting initial language to: ${languageCode}`);
      AppStorage.setOrCreate('currentLanguage', languageCode);

      // Verify the language was set
      const verifyLang = AppStorage.get<string>('currentLanguage');
      console.log(`[EntryAbility] Verified language in AppStorage: ${verifyLang}`);
      
      /* FORCE ENGLISH FOR SCREENSHOTS - Uncomment below to force English language
      // Force English language for screenshots
      const languageCode = 'en-US';
      console.log(`[EntryAbility] FORCED language to: ${languageCode} (for screenshots)`);
      AppStorage.setOrCreate('currentLanguage', languageCode);
      
      // Set system preferred language to English
      i18n.System.setAppPreferredLanguage('en-Latn-US');
      
      // Verify the language was set
      const verifyLang = AppStorage.get<string>('currentLanguage');
      console.log(`[EntryAbility] Verified language in AppStorage: ${verifyLang}`);
      */
    } catch (error) {
      console.error('[EntryAbility] Failed to initialize language:', error);
      AppStorage.setOrCreate('currentLanguage', 'zh-CN'); // Fallback to Chinese
    }
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
