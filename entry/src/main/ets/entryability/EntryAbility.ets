import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';

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
    } catch (error) {
      console.error('[EntryAbility] Failed to initialize language:', error);
      AppStorage.setOrCreate('currentLanguage', 'zh-CN'); // Fallback to Chinese
    }
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return;
      }
    });

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
