# 手电筒功能说明 / Flashlight Feature Documentation

## 概述 / Overview

已成功为应用添加手电筒服务和测试功能。

Successfully added flashlight service and test functionality to the app.

## 实现的功能 / Implemented Features

### 1. FlashlightService（手电筒服务）

**文件位置 / File Location:**
- `entry/src/main/ets/services/FlashlightService.ets`

**功能 / Features:**
- ✅ 初始化手电筒服务
- ✅ 打开手电筒 (`turnOn()`)
- ✅ 关闭手电筒 (`turnOff()`)
- ✅ 切换手电筒状态 (`toggle()`)
- ✅ 获取当前状态 (`isOn()`)
- ✅ 播放摩尔斯码序列 (`playMorseCode()`)
- ✅ 播放SOS信号 (`playSOS()`)
- ✅ 停止播放 (`stopPlaying()`)
- ✅ 资源释放 (`release()`)

**技术实现 / Technical Implementation:**
- 使用 HarmonyOS Camera Kit 的 `CameraManager.setTorchMode()` API
- 单例模式设计，确保全局唯一实例
- **运行时权限请求**：自动检查并请求相机权限
- 完整的错误处理和日志记录
- 权限被拒绝时显示友好提示

### 2. 设置页面测试按钮

**文件位置 / File Location:**
- `entry/src/main/ets/pages/me/MePage.ets`

**功能 / Features:**
- ✅ 在设置页面添加"手电筒测试"选项
- ✅ 实时显示手电筒状态（开启/关闭）
- ✅ 状态指示器（开启时显示金色圆点，关闭时显示灰色圆点）
- ✅ 在设置页面添加"SOS测试"选项
- ✅ 点击播放SOS摩尔斯码信号（三短三长三短：`... --- ...`）
- ✅ 播放中显示动态状态（"播放中..."）
- ✅ 播放中可点击停止
- ✅ 多语言支持（简体中文、繁体中文、英文）
- ✅ 页面离开时自动关闭手电筒并停止播放

**UI 设计 / UI Design:**
- 与现有设置项保持一致的设计风格
- 清晰的状态指示
- 点击即可切换

### 3. 权限配置

**修改的文件 / Modified Files:**
- `entry/src/main/module.json5` - 添加相机权限请求
- `entry/src/main/resources/base/element/string.json` - 简体中文权限说明
- `entry/src/main/resources/en_US/element/string.json` - 英文权限说明
- `entry/src/main/resources/zh_HK/element/string.json` - 繁体中文权限说明

**权限说明 / Permission Reason:**
- 简体中文：需要相机权限以使用手电筒功能
- English: Camera permission is required to use the flashlight function
- 繁體中文：需要相機權限以使用手電筒功能

## 使用方法 / Usage

### 在设置页面测试 / Test in Settings Page

1. 打开应用，进入"我"（设置）页面
2. 找到"手电筒测试"选项
3. 点击该选项即可切换手电筒开关
4. 状态文字和指示器会实时更新

### 在代码中使用 / Use in Code

```typescript
import { flashlightService } from '../services/FlashlightService'

// 初始化服务
await flashlightService.init(context)

// 打开手电筒
await flashlightService.turnOn()

// 关闭手电筒
await flashlightService.turnOff()

// 切换状态
const newState = await flashlightService.toggle()

// 获取当前状态
const isOn = flashlightService.isOn()
```

## 下一步计划 / Next Steps

根据用户需求，如果手电筒功能测试成功，将会：
- 将手电筒功能集成到翻译页面
- 使用手电筒闪烁来显示摩尔斯码（点：短闪，划：长闪）

If the flashlight feature works well, the next steps will be:
- Integrate flashlight into the translation page
- Use flashlight flashing to display Morse code (dot: short flash, dash: long flash)

## 参考资料 / References

- HarmonyOS Camera Kit 文档
- 参考实现：https://bbs.itying.com/topic/67de132a687c4e0048a82af1

## 注意事项 / Notes

1. **首次使用时，系统会自动弹出相机权限请求对话框**
2. 如果用户拒绝权限，会显示友好提示信息
3. 手电筒功能仅在支持闪光灯的设备上可用
4. 页面离开时会自动关闭手电筒，避免电量浪费
5. 所有操作都有完整的错误处理和用户提示

## 权限机制 / Permission Mechanism

### 权限声明 / Permission Declaration
在 `module.json5` 中声明了相机权限：
```json
"requestPermissions": [
  {
    "name": "ohos.permission.CAMERA",
    "reason": "$string:camera_permission_reason",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

### 运行时权限请求 / Runtime Permission Request
**延迟初始化策略：**
- 手电筒服务采用**延迟初始化**设计
- **不在页面加载时初始化**，避免不必要的权限请求
- **只在用户首次点击手电筒按钮时才初始化**

`FlashlightService` 在首次使用时会：
1. 检查相机权限状态
2. 如果未授权，自动弹出系统权限对话框
3. 等待用户授权
4. 根据授权结果初始化或抛出错误

**用户体验优化：**
- ✅ 用户打开应用或切换到翻译页面时**不会**弹出权限请求
- ✅ 只有在用户**主动点击手电筒按钮**时才请求权限
- ✅ 一旦授权成功，后续使用无需再次请求

