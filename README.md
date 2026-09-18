# QingXing / 轻醒

QingXing 是一个 macOS 菜单栏应用，用于帮助你在长时间久坐后及时提醒起身休息，减少久坐带来的疲劳和健康风险。

它会在指定的工作时间段内按固定间隔发出提醒，同时支持：

- 自定义提醒开始 / 结束时间
- 固定间隔提醒
- 自定义额外提醒时间点
- 午休免打扰
- 稍后提醒（snooze）
- 登录时自动启动
- macOS Menu Bar + 设置窗口交互

## 功能概览

- 以 MenuBarExtra 形式运行，界面轻量，不占用主窗口空间
- 使用 Notification Center 发送提醒，并支持「稍后提醒」和「知道了」操作
- 允许在一天中定义“提醒活动区间”，避免上班时间外误提醒
- 支持午休时段过滤，不在午休时间打扰用户
- 设置持久化保存到本地，可在应用重启后保留配置

## 运行方式

### 1. 安装依赖

本项目使用 Swift Package Manager，依赖项在 `Package.swift` 中声明。

### 2. 本地构建

```bash
swift build
```

### 3. 运行应用

在 macOS 上可以直接通过 Xcode 或 SwiftPM 运行该可执行目标：

```bash
swift run QingXing
```

如果你使用 Xcode，也可以打开该项目并选择 `QingXing` 目标执行。

## 测试

```bash
swift test
```

项目中的测试入口位于：

- `Tests/QingXingTests/ReminderPlannerTests.swift`

## 打包与产物

项目提供了脚本用于编译和打包为 `.app` / `.dmg`：

```bash
./scripts/build.sh
./scripts/package.sh
```

- `scripts/build.sh`：执行 `swift build`
- `scripts/package.sh`：执行 Release 编译、生成应用包、进行 ad-hoc 签名，并生成 DMG
- 打包产物默认输出到 `outputs/` 目录

## 项目结构

```text
QingXing/
├── Package.swift
├── Package.resolved
├── README.md
├── Resources/
├── Scripts/
│   ├── build.sh
│   ├── package.sh
│   ├── test.sh
│   └── make_icon.swift
├── Sources/
│   ├── QingXing/
│   │   ├── AppModel.swift
│   │   ├── CountdownRing.swift
│   │   ├── MenuBarView.swift
│   │   ├── NotificationManager.swift
│   │   ├── QingXingApp.swift
│   │   ├── SettingsView.swift
│   │   └── Theme.swift
│   └── QingXingCore/
│       ├── AppSettings.swift
│       ├── ReminderPlanner.swift
│       └── SettingsStore.swift
├── Tests/
│   └── QingXingTests/
│       └── ReminderPlannerTests.swift
├── outputs/
└── work/
```

## 关键模块说明

- `QingXingApp.swift`：应用入口，注册 MenuBarExtra 与设置窗口
- `AppModel.swift`：管理应用配置、启动逻辑、通知调度和系统事件监听
- `NotificationManager.swift`：负责本地通知注册、调度、稍后提醒和动作处理
- `ReminderPlanner.swift`：计算当天提醒时间，并过滤午休与非活跃时段
- `AppSettings.swift`：应用配置模型，支持持久化存储
- `SettingsView.swift`：设置页界面

## 注意事项

- 该应用依赖 macOS 的 `UserNotifications` 和 `AppKit` 能力，适用于 macOS 14+
- 首次运行时，系统可能要求允许通知权限；若未授权，提醒功能可能无法正常触发
- `scripts/package.sh` 中使用了 ad-hoc 签名，适合本地调试和打包测试，不替代正式开发者签名

## 许可

当前仓库未声明特定许可证文件，若需要正式发布或分发，请先确认许可协议和签名要求。
