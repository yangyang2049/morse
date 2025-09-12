// 事件数据类型定义
export interface LessonCompletedEventData {
  lessonNumber: number
  completedLessons: number[]
  unitUnlocked: Map<string, boolean>
}

// 事件中心 - 用于解耦的事件通知
export class EventHub {
  private static instance: EventHub
  private listeners: Map<string, Array<(data?: Object) => void>> = new Map()

  private constructor() {}

  static getInstance(): EventHub {
    if (!EventHub.instance) {
      EventHub.instance = new EventHub()
    }
    return EventHub.instance
  }

  // 订阅事件
  on(eventName: string, callback: (data?: Object) => void): void {
    if (!this.listeners.has(eventName)) {
      this.listeners.set(eventName, [])
    }
    this.listeners.get(eventName)?.push(callback)
    console.error(`[EventHub] on: subscribed to ${eventName}, total listeners: ${this.listeners.get(eventName)?.length}`)
  }

  // 取消订阅
  off(eventName: string, callback: (data?: Object) => void): void {
    const callbacks = this.listeners.get(eventName)
    if (callbacks) {
      const index = callbacks.indexOf(callback)
      if (index > -1) {
        callbacks.splice(index, 1)
        console.error(`[EventHub] off: unsubscribed from ${eventName}, remaining listeners: ${callbacks.length}`)
      }
    }
  }

  // 发布事件
  emit(eventName: string, data?: Object): void {
    const callbacks = this.listeners.get(eventName)
    if (callbacks) {
      console.error(`[EventHub] emit: ${eventName} with data:`, data, `to ${callbacks.length} listeners`)
      callbacks.forEach(callback => {
        try {
          callback(data)
        } catch (error) {
          console.error(`[EventHub] emit: error in callback for ${eventName}:`, error)
        }
      })
    } else {
      console.error(`[EventHub] emit: no listeners for ${eventName}`)
    }
  }

  // 清除所有监听器
  clear(): void {
    this.listeners.clear()
    console.error(`[EventHub] clear: all listeners cleared`)
  }
}

// 导出单例实例
export const eventHub = EventHub.getInstance()

// 事件名称常量
export class Events {
  static readonly LESSON_COMPLETED = 'lesson_completed'
  static readonly LANGUAGE_CHANGED = 'language_changed'
}
