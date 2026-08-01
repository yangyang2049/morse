/**
 * 应用内评论（应用市场评分/评论）辅助。
 * 自动请求仅用于手机、平板和 2in1；手表端不参与启动计数，也不弹窗。
 * API: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/appgallery-commentmanager
 */

import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { preferences } from '@kit.ArkData'
import { commentManager } from '@kit.AppGalleryKit'
import { DeviceHelper } from './DeviceHelper'

const PREFS_NAME = 'app_settings'
const PREF_LAUNCH_COUNT = 'appgallery_comment_launch_count_v1'
const PREF_AUTO_PROMPTED = 'appgallery_comment_auto_prompted_v1'
const PREF_MANUAL_RATED = 'appgallery_comment_manual_rated'

/** 第 3 次冷启动进入首页时请求一次评分 */
const MIN_APP_LAUNCHES = 3

async function getPrefs(context: common.Context): Promise<preferences.Preferences> {
  return preferences.getPreferences(context, PREFS_NAME)
}

async function markAutoPrompted(context: common.Context): Promise<void> {
  const prefs = await getPrefs(context)
  await prefs.put(PREF_AUTO_PROMPTED, true)
  await prefs.flush()
}

async function markManualRated(context: common.Context): Promise<void> {
  const prefs = await getPrefs(context)
  await prefs.put(PREF_MANUAL_RATED, true)
  await prefs.flush()
}

/**
 * 记录一次应用冷启动，并在第 3 次进入首页时拉起一次应用内评论弹窗。
 * 接口临时不可用时静默返回，下次冷启动可再次尝试；已展示过或已手动评分后不再自动请求。
 */
export async function showCommentDialogOnLaunchIfNeeded(context: common.UIAbilityContext): Promise<void> {
  if (!DeviceHelper.supportsAppGalleryComment()) {
    return
  }

  try {
    const prefs = await getPrefs(context)
    const launchCountValue = await prefs.get(PREF_LAUNCH_COUNT, 0)
    const launchCount = Math.max(0, Number(launchCountValue)) + 1
    await prefs.put(PREF_LAUNCH_COUNT, launchCount)
    await prefs.flush()
    console.info(`[AppGalleryComment] app launch count=${launchCount}`)

    const manuallyRated = await prefs.get(PREF_MANUAL_RATED, false)
    const autoPrompted = await prefs.get(PREF_AUTO_PROMPTED, false)
    if (launchCount < MIN_APP_LAUNCHES || manuallyRated === true || autoPrompted === true) {
      return
    }

    await commentManager.showCommentDialog(context)
    await markAutoPrompted(context)
  } catch (e) {
    const err = e as BusinessError
    const code = err?.code ?? 0
    console.info(`[AppGalleryComment] showCommentDialogOnLaunchIfNeeded not shown: ${code} ${err?.message ?? ''}`)
    // 只有调用成功才写入已请求状态；失败时保留到下一次冷启动重试。
  }
}

/**
 * 设置页手动拉起；成功返回 true
 */
export async function showCommentDialogManual(context: common.UIAbilityContext): Promise<boolean> {
  try {
    await commentManager.showCommentDialog(context)
    await markManualRated(context)
    return true
  } catch (e) {
    const err = e as BusinessError
    console.info(`[AppGalleryComment] showCommentDialogManual failed: ${err?.code} ${err?.message}`)
    return false
  }
}
