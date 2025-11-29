import { BusinessError } from "@kit.BasicServicesKit";
import { media } from "@kit.MediaKit";
import { audio } from "@kit.AudioKit";
import { Context } from '@kit.AbilityKit';
import { vibratorService } from './VibratorService';

export class AudioService {
  private static instance: AudioService | null = null
  private soundPool: media.SoundPool | null = null
  private isInitialized: boolean = false
  private context: Context | null = null
  private loadedSounds: Map<string, number> = new Map() // soundName -> soundId
  private isPlaying: boolean = false

  private constructor() {}

  static getInstance(): AudioService {
    if (!AudioService.instance) {
      AudioService.instance = new AudioService()
    }
    return AudioService.instance
  }

  // 初始化音频服务
  async init(context?: Context): Promise<void> {
    console.info("[AudioService] ===== INIT CALLED =====");

    this.context = context || this.context;

    try {
      // 如果已经初始化且存在可用的 SoundPool，避免重复创建
      if (this.isInitialized && this.soundPool) {
        console.info('[AudioService] Already initialized, skip creating SoundPool');
        return;
      }

      await this.createSoundPool();
      this.isInitialized = true;
      
      // 预加载音频文件
      await this.preloadSounds();
      
      console.info("[AudioService] Initialization completed successfully");
    } catch (error) {
      console.error("[AudioService] Initialization failed:", error);
      throw new Error("Initialization failed");
    }
  }

  // 预加载音频文件
  private async preloadSounds(): Promise<void> {
    try {
      console.info("[AudioService] Preloading sounds...");
      await this.loadSound('dit');
      await this.loadSound('dah');
      console.info("[AudioService] Sounds preloaded successfully");
    } catch (error) {
      console.error("[AudioService] Failed to preload sounds:", error);
      // 不抛出错误，允许继续运行
    }
  }

  // 创建SoundPool
  private async createSoundPool(): Promise<void> {
    console.info("[AudioService] Creating SoundPool...");

    const audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
      rendererFlags: 1,
    };

    try {
      // 若已有旧的 SoundPool 引用，先释放引用，避免 soundId 与实例不匹配
      if (this.soundPool) {
        console.info('[AudioService] Discarding previous SoundPool reference before creating new one');
        this.soundPool = null;
      }

      this.soundPool = await media.createSoundPool(10, audioRendererInfo);
      console.info(`[AudioService] Succeeded in createSoundPool`);
    } catch (error) {
      console.error(`[AudioService] Failed to createSoundPool: ${error}`);
      throw new Error("Failed to create SoundPool");
    }
  }

  // 加载音频文件
  private async loadSound(soundName: string): Promise<number> {
    if (!this.soundPool) {
      throw new Error("SoundPool not initialized");
    }

    // 如果已经加载过，直接返回
    const existingSoundId = this.loadedSounds.get(soundName);
    if (existingSoundId && existingSoundId > 0) {
      console.info(`[AudioService] Sound ${soundName} already loaded, soundId: ${existingSoundId}`);
      return existingSoundId;
    }

    const filePath = this.getSoundFilePath(soundName);
    console.info(`[AudioService] Loading sound ${soundName}: ${filePath}`);

    try {
      // 获取文件描述符
      if (!this.context?.resourceManager) {
        throw new Error("Resource manager not available");
      }

      const fileDescriptor = this.context.resourceManager.getRawFdSync(
        filePath.replace("rawfile/", "")
      );
      if (!fileDescriptor) {
        throw new Error(`Failed to get file descriptor for ${filePath}`);
      }

      if (!this.soundPool) {
        throw new Error("SoundPool not available");
      }

      const soundId = await this.soundPool.load(
        fileDescriptor.fd,
        fileDescriptor.offset,
        fileDescriptor.length
      );
      console.info(`[AudioService] Load initiated for ${soundName}, soundId: ${soundId}`);

      // SoundPool.load() 返回的 soundId > 0 表示加载成功，可以直接使用
      // 不需要额外等待，load() 方法本身已经是异步的，会等待加载完成
      if (soundId > 0) {
        this.loadedSounds.set(soundName, soundId);
        console.info(`[AudioService] Sound ${soundName} ready for playback, soundId: ${soundId}`);
        return soundId;
      } else {
        throw new Error(`Failed to load sound ${soundName}, invalid soundId: ${soundId}`);
      }
    } catch (error) {
      console.error(`[AudioService] Failed to load ${soundName}: ${error}`);
      throw new Error(`Failed to load sound: ${error}`);
    }
  }

  // 获取音频文件路径
  private getSoundFilePath(soundName: string): string {
    return `rawfile/${soundName}.wav`;
  }

  // 播放点音（短音）
  async playDit(): Promise<void> {
    console.log('播放点音 (dit)')
    // 同步振动
    void vibratorService.vibrateDit()
    return this.playSound('dit', 100) // 100ms 短音
  }

  // 播放划音（长音）
  async playDah(): Promise<void> {
    console.log('播放划音 (dah)')
    // 同步振动
    void vibratorService.vibrateDah()
    return this.playSound('dah', 300) // 300ms 长音
  }

  // 播放空格（静音）
  async playSpace(): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve()
      }, 100) // 100ms 静音
    })
  }

  // 播放字母间间隔（静音）
  async playLetterSpace(): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve()
      }, 300) // 300ms 静音
    })
  }

  // 播放单词间间隔（静音）
  async playWordSpace(): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve()
      }, 700) // 700ms 静音
    })
  }

  // 内部播放音频方法
  private async playSound(soundName: string, duration: number): Promise<void> {
    // 检查SoundPool状态，如果需要则重新初始化
    if (!this.soundPool || !this.isInitialized) {
      console.warn(`[AudioService] SoundPool not available, attempting to reinitialize...`);
      try {
        await this.init(this.context || undefined);
      } catch (error) {
        console.error(`[AudioService] Failed to reinitialize: ${error}`);
        // 回退到静音播放
        await new Promise<void>((resolve) => {
          setTimeout(() => resolve(), duration);
        });
        return;
      }
    }

    try {
      // 确保音频已加载
      const soundId = await this.loadSound(soundName);

      const playParameters: media.PlayParameters = {
        loop: 0, // 不循环
        rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
        leftVolume: 1.0, // 恢复正常音量
        rightVolume: 1.0, // 恢复正常音量
        priority: 0, // 降低优先级
      };

      if (!this.soundPool) {
        console.error("[AudioService] SoundPool not available for playback");
        // 回退到静音播放
        await new Promise<void>((resolve) => {
          setTimeout(() => resolve(), duration);
        });
        return;
      }

      // 验证 soundId 是否有效
      if (soundId <= 0) {
        console.error(`[AudioService] Invalid soundId for ${soundName}: ${soundId}`);
        // 回退到静音播放
        await new Promise<void>((resolve) => {
          setTimeout(() => resolve(), duration);
        });
        return;
      }

      try {
        console.info(`[AudioService] Attempting to play ${soundName} with soundId: ${soundId}`);
        const streamId = await this.soundPool.play(soundId, playParameters);
        console.info(`[AudioService] Successfully played ${soundName}, streamId: ${streamId}`);
        
        // 等待播放完成
        await new Promise<void>((resolve) => {
          setTimeout(() => {
            resolve();
          }, duration);
        });
      } catch (error) {
        console.error(`[AudioService] Failed to play ${soundName}: ${error}`);
        // 回退到静音播放
        await new Promise<void>((resolve) => {
          setTimeout(() => resolve(), duration);
        });
      }
    } catch (error) {
      console.error(`[AudioService] Error playing ${soundName}:`, error);
      // 回退到静音播放
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), duration);
      });
    }
  }

  // 播放摩尔斯码序列
  async playMorseSequence(morseCode: string): Promise<void> {
    if (!morseCode || morseCode.trim().length === 0) {
      return
    }

    console.log('播放摩尔斯码序列:', morseCode)
    this.isPlaying = true

    try {
      for (let i = 0; i < morseCode.length; i++) {
        const char = morseCode[i]
        
        if (char === '.') {
          await this.playDit()
          // 点后间隔
          await new Promise<void>((resolve) => {
            setTimeout(() => resolve(), 100)
          })
        } else if (char === '-') {
          await this.playDah()
          // 划后间隔
          await new Promise<void>((resolve) => {
            setTimeout(() => resolve(), 100)
          })
        } else if (char === ' ') {
          // 字母间间隔
          await this.playLetterSpace()
        } else if (char === '/') {
          // 单词间间隔
          await this.playWordSpace()
        }
      }
    } finally {
      this.isPlaying = false
    }
  }

  // 停止音频播放
  stopAudio(): void {
    console.log('停止音频播放')
    this.isPlaying = false
  }

  // 检查是否正在播放
  isAudioPlaying(): boolean {
    return this.isPlaying
  }

  // 释放资源
  async release(force: boolean = false): Promise<void> {
    console.info(`[AudioService] Release called, force: ${force}`);
    
    try {
      if (this.soundPool) {
        // 清理已加载的音频
        this.loadedSounds.clear();
        
        // 释放SoundPool
        this.soundPool = null;
        console.info('[AudioService] SoundPool released');
      }
      
      this.isInitialized = false;
    } catch (error) {
      console.error('[AudioService] Error during release:', error);
    }
  }

  // 销毁服务
  destroy(): void {
    this.stopAudio()
    this.release()
    AudioService.instance = null
  }
}

// 导出单例实例
export const audioService = AudioService.getInstance()