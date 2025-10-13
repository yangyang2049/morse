import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';

/**
 * 手电筒服务
 * 用于控制设备的闪光灯/手电筒功能
 */
export class FlashlightService {
    private static instance: FlashlightService | null = null
    private cameraManager: camera.CameraManager | null = null
    private isInitialized: boolean = false
    private isFlashlightOn: boolean = false
    private context: common.BaseContext | null = null
    private isPlaying: boolean = false

    private constructor() { }

    static getInstance(): FlashlightService {
        if (!FlashlightService.instance) {
            FlashlightService.instance = new FlashlightService()
        }
        return FlashlightService.instance
    }

    /**
     * 初始化手电筒服务
     * @param context 应用上下文
     */
    async init(context: common.BaseContext): Promise<void> {
        console.info('[FlashlightService] Initializing...')

        try {
            this.context = context
            this.cameraManager = camera.getCameraManager(context)
            this.isInitialized = true
            console.info('[FlashlightService] Initialization completed successfully')
        } catch (error) {
            const err = error as BusinessError
            console.error(`[FlashlightService] Initialization failed, error code: ${err.code}, message: ${err.message}`)
            throw new Error('Failed to initialize FlashlightService')
        }
    }

    /**
     * 打开手电筒
     */
    async turnOn(): Promise<void> {
        if (!this.isInitialized || !this.cameraManager) {
            throw new Error('FlashlightService not initialized')
        }

        try {
            console.info('[FlashlightService] Turning on flashlight...')
            this.cameraManager.setTorchMode(camera.TorchMode.ON)
            this.isFlashlightOn = true
            console.info('[FlashlightService] Flashlight turned on successfully')
        } catch (error) {
            const err = error as BusinessError
            console.error(`[FlashlightService] Failed to turn on flashlight, error code: ${err.code}, message: ${err.message}`)
            throw new Error('Failed to turn on flashlight')
        }
    }

    /**
     * 关闭手电筒
     */
    async turnOff(): Promise<void> {
        if (!this.isInitialized || !this.cameraManager) {
            throw new Error('FlashlightService not initialized')
        }

        try {
            console.info('[FlashlightService] Turning off flashlight...')
            this.cameraManager.setTorchMode(camera.TorchMode.OFF)
            this.isFlashlightOn = false
            console.info('[FlashlightService] Flashlight turned off successfully')
        } catch (error) {
            const err = error as BusinessError
            console.error(`[FlashlightService] Failed to turn off flashlight, error code: ${err.code}, message: ${err.message}`)
            throw new Error('Failed to turn off flashlight')
        }
    }

    /**
     * 切换手电筒状态
     */
    async toggle(): Promise<boolean> {
        if (this.isFlashlightOn) {
            await this.turnOff()
        } else {
            await this.turnOn()
        }
        return this.isFlashlightOn
    }

    /**
     * 获取手电筒当前状态
     */
    isOn(): boolean {
        return this.isFlashlightOn
    }

    /**
     * 检查服务是否已初始化
     */
    isServiceInitialized(): boolean {
        return this.isInitialized
    }

    /**
     * 检查是否正在播放摩尔斯码
     */
    isPlayingMorse(): boolean {
        return this.isPlaying
    }

    /**
     * 停止播放摩尔斯码
     */
    stopPlaying(): void {
        this.isPlaying = false
    }

    /**
     * 闪烁一次（点 - 短闪）
     * @param duration 闪烁持续时间（毫秒）
     */
    private async flashDit(duration: number = 150): Promise<void> {
        if (!this.isPlaying) return

        await this.turnOn()
        await this.sleep(duration)
        await this.turnOff()
    }

    /**
     * 闪烁一次（划 - 长闪）
     * @param duration 闪烁持续时间（毫秒）
     */
    private async flashDah(duration: number = 450): Promise<void> {
        if (!this.isPlaying) return

        await this.turnOn()
        await this.sleep(duration)
        await this.turnOff()
    }

    /**
     * 延迟
     */
    private sleep(ms: number): Promise<void> {
        return new Promise<void>((resolve) => {
            setTimeout(() => resolve(), ms)
        })
    }

    /**
     * 播放摩尔斯码序列
     * @param morseCode 摩尔斯码字符串，如 "... --- ..."
     */
    async playMorseCode(morseCode: string): Promise<void> {
        if (!this.isInitialized || !this.cameraManager) {
            throw new Error('FlashlightService not initialized')
        }

        if (this.isPlaying) {
            console.warn('[FlashlightService] Already playing morse code')
            return
        }

        console.info(`[FlashlightService] Playing morse code: ${morseCode}`)
        this.isPlaying = true

        try {
            for (let i = 0; i < morseCode.length && this.isPlaying; i++) {
                const char = morseCode[i]

                if (char === '.') {
                    // 点 - 短闪
                    await this.flashDit(150)
                    await this.sleep(150) // 点后间隔
                } else if (char === '-') {
                    // 划 - 长闪
                    await this.flashDah(450)
                    await this.sleep(150) // 划后间隔
                } else if (char === ' ') {
                    // 字母间间隔
                    await this.sleep(300)
                } else if (char === '/') {
                    // 单词间间隔
                    await this.sleep(700)
                }
            }

            console.info('[FlashlightService] Morse code playback completed')
        } catch (error) {
            console.error('[FlashlightService] Error playing morse code:', error)
        } finally {
            this.isPlaying = false
            // 确保手电筒关闭
            if (this.isFlashlightOn) {
                await this.turnOff()
            }
        }
    }

    /**
     * 播放SOS信号
     * SOS摩尔斯码: ... --- ... (三短三长三短)
     */
    async playSOS(): Promise<void> {
        console.info('[FlashlightService] Playing SOS signal')
        await this.playMorseCode('... --- ...')
    }

    /**
     * 释放资源
     */
    async release(): Promise<void> {
        console.info('[FlashlightService] Releasing resources...')

        try {
            // 如果手电筒开着，先关闭
            if (this.isFlashlightOn && this.cameraManager) {
                await this.turnOff()
            }

            this.cameraManager = null
            this.context = null
            this.isInitialized = false
            console.info('[FlashlightService] Resources released successfully')
        } catch (error) {
            console.error('[FlashlightService] Error during release:', error)
        }
    }

    /**
     * 销毁服务
     */
    destroy(): void {
        this.release()
        FlashlightService.instance = null
    }
}

// 导出单例实例
export const flashlightService = FlashlightService.getInstance()

