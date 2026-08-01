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
   * 应用内评分仅在手机、平板和 2in1 设备上启用。
   */
  static supportsAppGalleryComment(): boolean {
    try {
      const deviceType = deviceInfo.deviceType
      return deviceType === 'phone' || deviceType === 'tablet' || deviceType === '2in1'
    } catch (error) {
      console.error('[DeviceHelper] Error checking AppGallery comment support:', error)
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
