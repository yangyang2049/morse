/**
 * 首页「推荐应用」入口隐藏辅助
 * 用户点过一次「推荐应用」后永久隐藏，跨版本、跨重启持久化，避免临时促销打扰。
 */
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const RECOMMEND_PREFS_STORE_NAME: string = 'morsecode_recommend_prefs';
const KEY_RECOMMEND_APPS_DISMISSED: string = 'recommend_apps_dismissed';

export class RecommendAppsDismissHelper {
  private static store: preferences.Preferences | null = null;
  private static initPromise: Promise<void> | null = null;

  private static async ensureStore(context: common.Context): Promise<preferences.Preferences> {
    if (RecommendAppsDismissHelper.store) {
      return RecommendAppsDismissHelper.store;
    }
    if (!RecommendAppsDismissHelper.initPromise) {
      RecommendAppsDismissHelper.initPromise = (async () => {
        RecommendAppsDismissHelper.store = await preferences.getPreferences(context, RECOMMEND_PREFS_STORE_NAME);
      })();
    }
    await RecommendAppsDismissHelper.initPromise;
    return RecommendAppsDismissHelper.store!;
  }

  static async isDismissed(context: common.Context): Promise<boolean> {
    try {
      const store = await RecommendAppsDismissHelper.ensureStore(context);
      return await store.get(KEY_RECOMMEND_APPS_DISMISSED, false) as boolean;
    } catch (e) {
      console.warn('[RecommendAppsDismiss] isDismissed failed:', JSON.stringify(e));
      return false;
    }
  }

  static async markDismissed(context: common.Context): Promise<void> {
    try {
      const store = await RecommendAppsDismissHelper.ensureStore(context);
      await store.put(KEY_RECOMMEND_APPS_DISMISSED, true);
      await store.flush();
    } catch (e) {
      console.warn('[RecommendAppsDismiss] markDismissed failed:', JSON.stringify(e));
    }
  }
}
