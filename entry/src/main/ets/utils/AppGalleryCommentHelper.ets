/**
 * 应用内评论（应用市场评分/评论）辅助 — 仅手机端使用
 * API: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/appgallery-commentmanager
 */

import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { preferences } from '@kit.ArkData'
import { commentManager } from '@kit.AppGalleryKit'

const PREFS_NAME = 'app_settings'
const PREF_QUALIFIED_COMPLETED_COUNT = 'appgallery_comment_qualified_completed_count'
const PREF_LAST_PROMPT_TIME = 'appgallery_comment_last_prompt_time'
const PREF_MANUAL_RATED = 'appgallery_comment_manual_rated'

/** 至少完成几课后才考虑自动弹出 */
const MIN_QUALIFIED_COMPLETIONS = 2
/** 两次弹窗最少间隔天数 */
const PROMPT_COOLDOWN_DAYS = 30

async function getPrefs(context: common.Context): Promise<preferences.Preferences> {
  return preferences.getPreferences(context, PREFS_NAME)
}

/**
 * 记录一次「完成课」（有效完成 +1）
 */
export async function recordLessonCompleted(context: common.Context): Promise<void> {
  try {
    const prefs = await getPrefs(context)
    const raw = await prefs.get(PREF_QUALIFIED_COMPLETED_COUNT, '0')
    const count = Math.max(0, parseInt(raw as string, 10) || 0) + 1
    await prefs.put(PREF_QUALIFIED_COMPLETED_COUNT, String(count))
    await prefs.flush()
    console.info(`[AppGalleryComment] recordLessonCompleted count=${count}`)
  } catch (e) {
    console.warn('[AppGalleryComment] recordLessonCompleted failed:', e)
  }
}

/**
 * 是否满足自动弹出条件：完成课次数达标、冷却期已过、未手动评过分
 */
export async function shouldPromptComment(context: common.Context): Promise<boolean> {
  try {
    const prefs = await getPrefs(context)
    const manual = await prefs.get(PREF_MANUAL_RATED, false) as boolean
    if (manual) {
      return false
    }
    const countStr = await prefs.get(PREF_QUALIFIED_COMPLETED_COUNT, '0')
    const count = parseInt(countStr as string, 10) || 0
    if (count < MIN_QUALIFIED_COMPLETIONS) {
      return false
    }
    const lastStr = await prefs.get(PREF_LAST_PROMPT_TIME, '0')
    const lastTime = parseInt(lastStr as string, 10) || 0
    if (lastTime <= 0) {
      return true
    }
    const cooldownMs = PROMPT_COOLDOWN_DAYS * 24 * 60 * 60 * 1000
    return (Date.now() - lastTime) >= cooldownMs
  } catch (_e) {
    return false
  }
}

async function markPrompted(context: common.Context): Promise<void> {
  const prefs = await getPrefs(context)
  await prefs.put(PREF_LAST_PROMPT_TIME, String(Date.now()))
  await prefs.flush()
}

async function markManualRated(context: common.Context): Promise<void> {
  const prefs = await getPrefs(context)
  await prefs.put(PREF_MANUAL_RATED, true)
  await prefs.put(PREF_LAST_PROMPT_TIME, String(Date.now()))
  await prefs.flush()
}

/**
 * 条件满足则拉起应用内评论弹窗；失败静默
 */
export async function showCommentDialogIfNeeded(context: common.UIAbilityContext): Promise<void> {
  try {
    const ok = await shouldPromptComment(context)
    if (!ok) {
      return
    }
    await commentManager.showCommentDialog(context)
    await markPrompted(context)
  } catch (e) {
    const err = e as BusinessError
    const code = err?.code ?? 0
    console.info(`[AppGalleryComment] showCommentDialogIfNeeded not shown: ${code} ${err?.message ?? ''}`)
    // 部分错误码表示已展示过/不可再弹，写入冷却避免频繁重试
    if (code === 1021500007 || code === 1021500009) {
      try {
        await markPrompted(context)
      } catch (_markErr) {
        // ignore
      }
    }
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
