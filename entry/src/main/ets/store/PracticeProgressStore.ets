import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

interface CharacterProgress {
    character: string
    totalAttempts: number // 总练习次数
    correctAttempts: number // 正确次数
    incorrectAttempts: number // 错误次数
    lastPracticed: number // 最后练习时间戳
}

const PREFS_NAME = 'practice_progress'
const KEY_PROGRESS = 'character_progress'

export class PracticeProgressStore {
    private static instance: PracticeProgressStore
    private progressMap: Map<string, CharacterProgress> = new Map()
    private preferencesStore: preferences.Preferences | null = null

    private constructor() {
    }

    static getInstance(): PracticeProgressStore {
        if (!PracticeProgressStore.instance) {
            PracticeProgressStore.instance = new PracticeProgressStore()
        }
        return PracticeProgressStore.instance
    }

    async init(context: Context): Promise<void> {
        try {
            this.preferencesStore = await preferences.getPreferences(context, PREFS_NAME)
            await this.load()
        } catch (error) {
            console.error('[PracticeProgressStore] Failed to initialize:', error)
        }
    }

    private async load(): Promise<void> {
        if (!this.preferencesStore) return

        try {
            const progressJson = await this.preferencesStore.get(KEY_PROGRESS, '{}') as string
            const progressObj = JSON.parse(progressJson) as Record<string, CharacterProgress>

            this.progressMap.clear()
            const keys = Object.keys(progressObj)
            for (let i = 0; i < keys.length; i++) {
                const char = keys[i]
                this.progressMap.set(char, progressObj[char])
            }

            console.log(`[PracticeProgressStore] Loaded progress for ${this.progressMap.size} characters`)
        } catch (error) {
            console.error('[PracticeProgressStore] Failed to load progress:', error)
        }
    }

    private async save(): Promise<void> {
        if (!this.preferencesStore) return

        try {
            const progressObj: Record<string, CharacterProgress> = {}
            const entries = Array.from(this.progressMap.entries())
            for (let i = 0; i < entries.length; i++) {
                const entry = entries[i]
                progressObj[entry[0]] = entry[1]
            }

            const progressJson = JSON.stringify(progressObj)
            await this.preferencesStore.put(KEY_PROGRESS, progressJson)
            await this.preferencesStore.flush()
        } catch (error) {
            console.error('[PracticeProgressStore] Failed to save progress:', error)
        }
    }

    // 记录正确答案
    async recordCorrect(character: string): Promise<void> {
        const progress = this.progressMap.get(character) || {
            character: character,
            totalAttempts: 0,
            correctAttempts: 0,
            incorrectAttempts: 0,
            lastPracticed: 0
        }

        progress.totalAttempts++
        progress.correctAttempts++
        progress.lastPracticed = Date.now()

        this.progressMap.set(character, progress)
        await this.save()
    }

    // 记录错误答案
    async recordIncorrect(character: string): Promise<void> {
        const progress = this.progressMap.get(character) || {
            character: character,
            totalAttempts: 0,
            correctAttempts: 0,
            incorrectAttempts: 0,
            lastPracticed: 0
        }

        progress.totalAttempts++
        progress.incorrectAttempts++
        progress.lastPracticed = Date.now()

        this.progressMap.set(character, progress)
        await this.save()
    }

    // 获取字符进度
    getProgress(character: string): CharacterProgress | null {
        return this.progressMap.get(character) || null
    }

    // 计算字符的权重（权重越高，越应该被练习）
    getCharacterWeight(character: string): number {
        const progress = this.progressMap.get(character)

        if (!progress || progress.totalAttempts === 0) {
            // 未练习过的字符权重最高
            return 10.0
        }

        const accuracy = progress.correctAttempts / progress.totalAttempts

        // 根据正确率和练习次数计算权重
        // 正确率越低，权重越高
        // 练习次数越少，权重越高
        let weight = 1.0

        // 正确率影响 (0-100%正确率)
        if (accuracy < 0.3) {
            weight *= 5.0 // 正确率低于30%，权重x5
        } else if (accuracy < 0.5) {
            weight *= 3.0 // 正确率30-50%，权重x3
        } else if (accuracy < 0.7) {
            weight *= 2.0 // 正确率50-70%，权重x2
        } else if (accuracy < 0.9) {
            weight *= 1.5 // 正确率70-90%，权重x1.5
        } else {
            weight *= 0.5 // 正确率90%以上，权重x0.5
        }

        // 练习次数影响
        if (progress.totalAttempts < 5) {
            weight *= 2.0 // 练习少于5次，权重x2
        } else if (progress.totalAttempts < 10) {
            weight *= 1.5 // 练习5-10次，权重x1.5
        } else if (progress.totalAttempts > 30) {
            weight *= 0.7 // 练习超过30次，权重x0.7
        }

        return weight
    }

    // 获取所有字符进度统计
    getAllProgress(): Map<string, CharacterProgress> {
        return new Map(this.progressMap)
    }

    // 清除所有进度（用于重置）
    async clearAllProgress(): Promise<void> {
        this.progressMap.clear()
        await this.save()
    }
}

