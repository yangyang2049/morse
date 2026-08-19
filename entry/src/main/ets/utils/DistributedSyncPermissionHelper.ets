import { abilityAccessCtrl, common } from '@kit.AbilityKit'

const DISTRIBUTED_SYNC_PERMISSION = 'ohos.permission.DISTRIBUTED_DATASYNC'

export class DistributedSyncPermissionHelper {
  static async requestOnLearnEntry(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const manager = abilityAccessCtrl.createAtManager()
      const result = await manager.requestPermissionsFromUser(context, [DISTRIBUTED_SYNC_PERMISSION])
      const granted = result.authResults.length > 0 && result.authResults[0] === 0
      const dialogShownResults: boolean[] = result.dialogShownResults || []
      console.info(`[LearningSyncV2] permission result, granted=${granted}, ` +
        `authResults=[${result.authResults.join(',')}], dialogShown=[${dialogShownResults.join(',')}]`)
      return granted
    } catch (error) {
      console.error('[LearningSyncV2] permission request failed', error)
      return false
    }
  }
}
