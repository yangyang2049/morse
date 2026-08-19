import { distributedKVStore, preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
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

interface DeviceStateEvent {
  action: distributedDeviceManager.DeviceStateChange
  device: distributedDeviceManager.DeviceBasicInfo
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
  private deviceManager: distributedDeviceManager.DeviceManager | null = null
  private context: common.UIAbilityContext | null = null
  private replicaId: string = ''
  private initialized: boolean = false
  private syncEnabled: boolean = false
  private syncInFlight: boolean = false
  private pendingSyncReason: string = ''
  private syncWatchdogId: number = -1
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
    console.info(`[LearningSyncV2] init requested, initialized=${this.initialized}, permissionGranted=${enableDistributedSync}`)
    if (!this.initialized) {
      this.context = context
      this.replicaId = await this.loadOrCreateReplicaId(context)
      const config: distributedKVStore.KVManagerConfig = { bundleName: BUNDLE_NAME, context: context }
      this.manager = distributedKVStore.createKVManager(config)
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        // Use one explicit PUSH_PULL coordinator. Mixing autoSync with manual sync can cause
        // concurrent synchronization requests as soon as a trusted device becomes available.
        autoSync: false,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      }
      this.store = await this.manager.getKVStore(STORE_ID, options) as distributedKVStore.SingleKVStore
      console.info(`[LearningSyncV2] store opened, storeId=${STORE_ID}, bundleName=${BUNDLE_NAME}, ` +
        `replicaId=${this.replicaId}, autoSync=false`)
      this.store.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL,
        (change: distributedKVStore.ChangeNotification) => {
          console.info(`[LearningSyncV2] dataChange, sourceDevice=${this.shortDeviceId(change.deviceId)}, ` +
            `insert=${change.insertEntries.length}, update=${change.updateEntries.length}, ` +
            `delete=${change.deleteEntries.length}`)
          void this.notifyListeners()
        })
      this.store.on('syncComplete', (results: Array<[string, number]>) => {
        this.clearSyncWatchdog()
        this.syncInFlight = false
        const summary = results.map((result: [string, number]) =>
          `${this.shortDeviceId(result[0])}:${result[1]}`).join(',')
        console.info(`[LearningSyncV2] syncComplete, results=[${summary}]`)
        void this.notifyListeners()
        this.runPendingSync()
      })
      this.initialized = true
    }
    await this.setSyncEnabled(enableDistributedSync)
    if (this.syncEnabled) {
      await this.syncNow('init')
    }
    await this.notifyListeners()
  }

  async setSyncEnabled(enabled: boolean): Promise<void> {
    if (!this.store) {
      this.syncEnabled = false
      console.warn('[LearningSyncV2] setSyncEnabled skipped because store is unavailable')
      return
    }
    try {
      await this.store.enableSync(enabled)
      this.syncEnabled = enabled
      console.info(`[LearningSyncV2] enableSync succeeded, enabled=${enabled}`)
      if (enabled) {
        this.ensureDeviceManager()
      }
    } catch (error) {
      this.syncEnabled = false
      console.error(`[LearningSyncV2] enableSync failed, requested=${enabled}`, error)
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
      console.warn(`[LearningSyncV2] completeCourse skipped, courseId=${courseId}, storeReady=${this.store !== null}`)
      return
    }
    await this.store.put(`${KEY_COMPLETED_PREFIX}${courseId}`, true)
    console.info(`[LearningSyncV2] course completion stored locally, courseId=${courseId}, replicaId=${this.replicaId}`)
    await this.notifyListeners()
    await this.syncNow(`completeCourse:${courseId}`)
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

  private ensureDeviceManager(): void {
    if (this.deviceManager) {
      return
    }
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager(BUNDLE_NAME)
      console.info('[LearningSyncV2] DeviceManager created')
      this.deviceManager.on('deviceStateChange', (event: DeviceStateEvent) => {
        console.info(`[LearningSyncV2] deviceStateChange, action=${event.action}, ` +
          `deviceId=${this.shortDeviceId(event.device.deviceId)}, type=${event.device.deviceType}, ` +
          `name=${event.device.deviceName}`)
        if (event.action === distributedDeviceManager.DeviceStateChange.AVAILABLE) {
          void this.syncNow('deviceAvailable')
        }
      })
    } catch (error) {
      this.deviceManager = null
      console.error('[LearningSyncV2] Failed to create DeviceManager', error)
    }
  }

  private async syncNow(reason: string): Promise<void> {
    if (!this.syncEnabled || !this.store) {
      console.warn(`[LearningSyncV2] sync skipped, reason=${reason}, enabled=${this.syncEnabled}, ` +
        `storeReady=${this.store !== null}`)
      return
    }
    this.ensureDeviceManager()
    if (!this.deviceManager) {
      console.warn(`[LearningSyncV2] sync skipped, reason=${reason}, DeviceManager unavailable`)
      return
    }
    if (this.syncInFlight) {
      this.pendingSyncReason = reason
      console.info(`[LearningSyncV2] sync queued because another request is active, reason=${reason}`)
      return
    }
    this.syncInFlight = true
    try {
      const devices = await this.deviceManager.getAvailableDeviceList()
      const deviceIds = devices.map((device: distributedDeviceManager.DeviceBasicInfo) => {
        const networkId = device.networkId || ''
        return networkId.length > 0 ? networkId : device.deviceId
      })
      const deviceSummary = devices.map((device: distributedDeviceManager.DeviceBasicInfo) =>
        `${device.deviceName}/${device.deviceType}/network=${this.shortDeviceId(device.networkId || '')}/` +
          `device=${this.shortDeviceId(device.deviceId)}`).join(',')
      console.info(`[LearningSyncV2] available devices, reason=${reason}, count=${devices.length}, ` +
        `devices=[${deviceSummary}]`)
      if (deviceIds.length === 0) {
        this.syncInFlight = false
        console.warn(`[LearningSyncV2] sync not started because no authorized and connectable remote device was found, ` +
          `reason=${reason}`)
        return
      }
      this.store.sync(deviceIds, distributedKVStore.SyncMode.PUSH_PULL, 0)
      this.startSyncWatchdog(reason)
      console.info(`[LearningSyncV2] PUSH_PULL submitted, reason=${reason}, targets=${deviceIds.length}`)
    } catch (error) {
      this.syncInFlight = false
      console.error(`[LearningSyncV2] PUSH_PULL failed to submit, reason=${reason}, ` +
        `error=${JSON.stringify(error)}, text=${error}`)
      this.runPendingSync()
    }
  }

  private startSyncWatchdog(reason: string): void {
    this.clearSyncWatchdog()
    this.syncWatchdogId = setTimeout(() => {
      if (!this.syncInFlight) {
        return
      }
      this.syncInFlight = false
      console.warn(`[LearningSyncV2] syncComplete timeout, reason=${reason}`)
      this.runPendingSync()
    }, 15000)
  }

  private clearSyncWatchdog(): void {
    if (this.syncWatchdogId >= 0) {
      clearTimeout(this.syncWatchdogId)
      this.syncWatchdogId = -1
    }
  }

  private runPendingSync(): void {
    if (this.pendingSyncReason.length === 0) {
      return
    }
    const reason = this.pendingSyncReason
    this.pendingSyncReason = ''
    void this.syncNow(`pending:${reason}`)
  }

  private shortDeviceId(deviceId: string): string {
    if (deviceId.length <= 12) {
      return deviceId
    }
    return `${deviceId.substring(0, 6)}...${deviceId.substring(deviceId.length - 6)}`
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
    console.info(`[LearningSyncV2] notifying snapshot, completed=[${snapshot.completedCourseIds.join(',')}], ` +
      `counters=${snapshot.counters.length}, favorites=${snapshot.favoriteItemIds.length}, ` +
      `mistakes=${snapshot.mistakeItemIds.length}`)
    for (const listener of this.listeners) {
      listener(snapshot)
    }
  }
}

export const learningRepositoryV2 = LearningRepositoryV2.getInstance()
