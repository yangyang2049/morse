import { distributedKVStore, preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { CourseCatalogV2 } from '../data/CourseCatalogV2'

export interface LearningCounter {
  itemId: string
  totalAttempts: number
  correctAttempts: number
  incorrectAttempts: number
  lastPracticed: number
}

export interface LearningSnapshot {
  completedCourseIds: string[]
  counters: LearningCounter[]
  favoriteItemIds: string[]
  mistakeItemIds: string[]
  lastPracticed: number
  lastPracticedCourseId: string
  lastPracticedItemId: string
}

interface ReplicaCounterRecord {
  courseId: string
  itemId: string
  replicaId: string
  totalAttempts: number
  correctAttempts: number
  incorrectAttempts: number
  lastPracticed: number
  consecutiveCorrect: number
}

interface ToggleRecord {
  enabled: boolean
  updatedAt: number
  replicaId: string
}

type SnapshotListener = (snapshot: LearningSnapshot) => void

const BUNDLE_NAME = 'com.douhua.morsecode'
const STORE_ID = 'morse_learning_v2'
const LOCAL_META_STORE = 'morse_learning_v2_local_meta'
const REPLICA_ID_KEY = 'replica_id'
const KEY_COMPLETED_PREFIX = 'v2/completed/'
const KEY_COUNTER_PREFIX = 'v2/counter/'
const KEY_FAVORITE_PREFIX = 'v2/favorite/'
const KEY_MISTAKE_PREFIX = 'v2/mistake/'

export class LearningRepositoryV2 {
  private static instance: LearningRepositoryV2 | null = null
  private manager: distributedKVStore.KVManager | null = null
  private store: distributedKVStore.SingleKVStore | null = null
  private context: common.UIAbilityContext | null = null
  private replicaId: string = ''
  private initialized: boolean = false
  private syncEnabled: boolean = false
  private listeners: SnapshotListener[] = []
  private counterWriteQueue: Promise<void> = Promise.resolve()

  private constructor() {}

  static getInstance(): LearningRepositoryV2 {
    if (!LearningRepositoryV2.instance) {
      LearningRepositoryV2.instance = new LearningRepositoryV2()
    }
    return LearningRepositoryV2.instance
  }

  async init(context: common.UIAbilityContext, enableDistributedSync: boolean): Promise<void> {
    if (!this.initialized) {
      this.context = context
      this.replicaId = await this.loadOrCreateReplicaId(context)
      const config: distributedKVStore.KVManagerConfig = { bundleName: BUNDLE_NAME, context: context }
      this.manager = distributedKVStore.createKVManager(config)
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: enableDistributedSync,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      }
      this.store = await this.manager.getKVStore(STORE_ID, options) as distributedKVStore.SingleKVStore
      this.store.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL,
        (_change: distributedKVStore.ChangeNotification) => {
          void this.notifyListeners()
        })
      this.initialized = true
    }
    await this.setSyncEnabled(enableDistributedSync)
    await this.notifyListeners()
  }

  async setSyncEnabled(enabled: boolean): Promise<void> {
    this.syncEnabled = enabled
    if (this.store) {
      try {
        await this.store.enableSync(enabled)
      } catch (error) {
        console.warn('[LearningRepositoryV2] Failed to update sync state:', error)
      }
    }
  }

  isDistributedSyncEnabled(): boolean {
    return this.syncEnabled
  }

  subscribe(listener: SnapshotListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners = [...this.listeners, listener]
    }
  }

  unsubscribe(listener: SnapshotListener): void {
    this.listeners = this.listeners.filter((item: SnapshotListener) => item !== listener)
  }

  async recordAttempt(courseId: string, itemId: string, correct: boolean): Promise<void> {
    if (!CourseCatalogV2.isCourseId(courseId)) {
      return
    }
    await this.enqueuePracticeAttempt(courseId, itemId, correct)
  }

  async recordPracticeAttempt(itemId: string, correct: boolean): Promise<void> {
    await this.enqueuePracticeAttempt('', itemId, correct)
  }

  private async enqueuePracticeAttempt(courseId: string, itemId: string, correct: boolean): Promise<void> {
    const operation = this.counterWriteQueue.then(() => {
      return this.writePracticeAttempt(courseId, itemId, correct)
    }, () => {
      return this.writePracticeAttempt(courseId, itemId, correct)
    })
    this.counterWriteQueue = operation
    await operation
  }

  private async writePracticeAttempt(courseId: string, itemId: string, correct: boolean): Promise<void> {
    if (!this.store || this.replicaId.length === 0) {
      return
    }
    const key = this.counterKey(itemId, this.replicaId)
    const current = await this.readReplicaCounter(key, itemId)
    const consecutiveCorrect = correct ? current.consecutiveCorrect + 1 : 0
    const updated: ReplicaCounterRecord = {
      courseId: courseId,
      itemId: itemId,
      replicaId: this.replicaId,
      totalAttempts: current.totalAttempts + 1,
      correctAttempts: current.correctAttempts + (correct ? 1 : 0),
      incorrectAttempts: current.incorrectAttempts + (correct ? 0 : 1),
      lastPracticed: Date.now(),
      consecutiveCorrect: consecutiveCorrect
    }
    await this.store.put(key, JSON.stringify(updated))
    if (correct && consecutiveCorrect >= 3) {
      await this.setMistake(itemId, false)
    } else if (!correct) {
      await this.setMistake(itemId, true)
    }
    await this.notifyListeners()
  }

  async completeCourse(courseId: string): Promise<void> {
    if (!CourseCatalogV2.isCourseId(courseId) || !this.store) {
      return
    }
    await this.store.put(`${KEY_COMPLETED_PREFIX}${courseId}`, true)
    await this.notifyListeners()
  }

  async isCourseCompleted(courseId: string): Promise<boolean> {
    if (!this.store || !CourseCatalogV2.isCourseId(courseId)) {
      return false
    }
    try {
      return await this.store.get(`${KEY_COMPLETED_PREFIX}${courseId}`) as boolean
    } catch (_error) {
      return false
    }
  }

  async setFavorite(itemId: string, enabled: boolean): Promise<void> {
    await this.putToggle(KEY_FAVORITE_PREFIX, itemId, enabled)
  }

  async setMistake(itemId: string, enabled: boolean): Promise<void> {
    await this.putToggle(KEY_MISTAKE_PREFIX, itemId, enabled)
  }

  async getSnapshot(): Promise<LearningSnapshot> {
    const empty: LearningSnapshot = {
      completedCourseIds: [], counters: [], favoriteItemIds: [], mistakeItemIds: [], lastPracticed: 0,
      lastPracticedCourseId: '', lastPracticedItemId: ''
    }
    if (!this.store) {
      return empty
    }
    const entries = await this.store.getEntries('v2/')
    const completed: string[] = []
    const counterMap: Map<string, LearningCounter> = new Map()
    const favoriteMap: Map<string, ToggleRecord> = new Map()
    const mistakeMap: Map<string, ToggleRecord> = new Map()
    let lastPracticed = 0
    let lastPracticedCourseId = ''
    let lastPracticedItemId = ''

    for (const entry of entries) {
      const key = entry.key
      const rawValue = entry.value.value
      if (key.startsWith(KEY_COMPLETED_PREFIX) && rawValue === true) {
        completed.push(key.substring(KEY_COMPLETED_PREFIX.length))
      } else if (key.startsWith(KEY_COUNTER_PREFIX) && typeof rawValue === 'string') {
        const record = this.parseReplicaCounter(rawValue)
        if (record) {
          const current = counterMap.get(record.itemId) || {
            itemId: record.itemId, totalAttempts: 0, correctAttempts: 0, incorrectAttempts: 0, lastPracticed: 0
          }
          counterMap.set(record.itemId, {
            itemId: record.itemId,
            totalAttempts: current.totalAttempts + record.totalAttempts,
            correctAttempts: current.correctAttempts + record.correctAttempts,
            incorrectAttempts: current.incorrectAttempts + record.incorrectAttempts,
            lastPracticed: Math.max(current.lastPracticed, record.lastPracticed)
          })
          if (record.lastPracticed > lastPracticed) {
            lastPracticed = record.lastPracticed
            lastPracticedCourseId = record.courseId || ''
            lastPracticedItemId = record.itemId
          }
        }
      } else if (key.startsWith(KEY_FAVORITE_PREFIX) && typeof rawValue === 'string') {
        this.mergeToggle(favoriteMap, key.substring(KEY_FAVORITE_PREFIX.length), rawValue)
      } else if (key.startsWith(KEY_MISTAKE_PREFIX) && typeof rawValue === 'string') {
        this.mergeToggle(mistakeMap, key.substring(KEY_MISTAKE_PREFIX.length), rawValue)
      }
    }
    return {
      completedCourseIds: completed,
      counters: Array.from(counterMap.values()),
      favoriteItemIds: this.enabledToggleIds(favoriteMap),
      mistakeItemIds: this.enabledToggleIds(mistakeMap),
      lastPracticed: lastPracticed,
      lastPracticedCourseId: lastPracticedCourseId,
      lastPracticedItemId: lastPracticedItemId
    }
  }

  private async loadOrCreateReplicaId(context: common.Context): Promise<string> {
    const store = await preferences.getPreferences(context, LOCAL_META_STORE)
    const existing = await store.get(REPLICA_ID_KEY, '') as string
    if (existing.length > 0) {
      return existing
    }
    const created = `${Date.now().toString(36)}-${Math.floor(Math.random() * 0x7fffffff).toString(36)}`
    await store.put(REPLICA_ID_KEY, created)
    await store.flush()
    return created
  }

  private counterKey(itemId: string, replicaId: string): string {
    return `${KEY_COUNTER_PREFIX}${encodeURIComponent(itemId)}/${replicaId}`
  }

  private async readReplicaCounter(key: string, itemId: string): Promise<ReplicaCounterRecord> {
    if (this.store) {
      try {
        const value = await this.store.get(key)
        if (typeof value === 'string') {
          const record = this.parseReplicaCounter(value)
          if (record) {
            return record
          }
        }
      } catch (_error) {
      }
    }
    return {
      courseId: '', itemId: itemId, replicaId: this.replicaId, totalAttempts: 0, correctAttempts: 0,
      incorrectAttempts: 0, lastPracticed: 0, consecutiveCorrect: 0
    }
  }

  private parseReplicaCounter(value: string): ReplicaCounterRecord | null {
    try {
      return JSON.parse(value) as ReplicaCounterRecord
    } catch (_error) {
      return null
    }
  }

  private async putToggle(prefix: string, itemId: string, enabled: boolean): Promise<void> {
    if (!this.store || this.replicaId.length === 0) {
      return
    }
    const record: ToggleRecord = { enabled: enabled, updatedAt: Date.now(), replicaId: this.replicaId }
    await this.store.put(`${prefix}${encodeURIComponent(itemId)}/${this.replicaId}`, JSON.stringify(record))
    await this.notifyListeners()
  }

  private mergeToggle(target: Map<string, ToggleRecord>, encodedKey: string, value: string): void {
    try {
      const separator = encodedKey.lastIndexOf('/')
      const itemId = decodeURIComponent(separator >= 0 ? encodedKey.substring(0, separator) : encodedKey)
      const incoming = JSON.parse(value) as ToggleRecord
      const current = target.get(itemId)
      if (!current || incoming.updatedAt > current.updatedAt ||
        (incoming.updatedAt === current.updatedAt && incoming.replicaId > current.replicaId)) {
        target.set(itemId, incoming)
      }
    } catch (_error) {
    }
  }

  private enabledToggleIds(map: Map<string, ToggleRecord>): string[] {
    const result: string[] = []
    for (const entry of map.entries()) {
      if (entry[1].enabled) {
        result.push(entry[0])
      }
    }
    return result
  }

  private async notifyListeners(): Promise<void> {
    if (this.listeners.length === 0) {
      return
    }
    const snapshot = await this.getSnapshot()
    for (const listener of this.listeners) {
      listener(snapshot)
    }
  }
}

export const learningRepositoryV2 = LearningRepositoryV2.getInstance()
