import deviceInfo from '@ohos.deviceInfo'

/**
 * 设备类型检测工具
 */
export class DeviceHelper {
  /**
   * 检查是否为手表设备
   */
  static isWearable(): boolean {
    try {
      const deviceType = deviceInfo.deviceType
      return deviceType === 'wearable'
    } catch (error) {
      console.error('[DeviceHelper] Error getting device type:', error)
      return false
    }
  }

  /**
   * 检查是否为平板设备
   */
  static isTablet(): boolean {
    try {
      const deviceType = deviceInfo.deviceType
      return deviceType === 'tablet'
    } catch (error) {
      console.error('[DeviceHelper] Error getting device type:', error)
      return false
    }
  }

  /**
   * 检查是否为手机设备
   */
  static isPhone(): boolean {
    try {
      const deviceType = deviceInfo.deviceType
      return deviceType === 'phone'
    } catch (error) {
      console.error('[DeviceHelper] Error getting device type:', error)
      return false
    }
  }

  /**
   * 获取设备类型
   */
  static getDeviceType(): string {
    try {
      return deviceInfo.deviceType
    } catch (error) {
      console.error('[DeviceHelper] Error getting device type:', error)
      return 'phone'
    }
  }
}



