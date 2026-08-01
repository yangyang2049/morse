import { abilityAccessCtrl, common } from '@kit.AbilityKit'

const DISTRIBUTED_SYNC_PERMISSION = 'ohos.permission.DISTRIBUTED_DATASYNC'

export class DistributedSyncPermissionHelper {
  static async requestOnLearnEntry(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const manager = abilityAccessCtrl.createAtManager()
      const result = await manager.requestPermissionsFromUser(context, [DISTRIBUTED_SYNC_PERMISSION])
      return result.authResults.length > 0 && result.authResults[0] === 0
    } catch (error) {
      console.warn('[DistributedSyncPermission] Permission unavailable or denied:', error)
      return false
    }
  }
}
