# 无厘头德州扑克 (PokerGame)

iOS SwiftUI 实现的搞笑风德州扑克 MVP，玩家对战 3 个性格各异的 AI，可在对战中使用 6 种搞笑技能。

## 项目结构

```
PokerGame/
├── project.yml                    # XcodeGen 配置
└── PokerGame/
    ├── PokerGameApp.swift         # 入口
    ├── Info.plist
    ├── Models/
    │   ├── Card.swift             # 花色 / 点数 / 单张牌
    │   ├── Deck.swift             # 52 张牌堆
    │   ├── HandEvaluator.swift    # 7 选 5 牌型评估
    │   ├── Player.swift           # 玩家 / AI 性格
    │   └── Skill.swift            # 6 种技能 + 冷却
    ├── ViewModels/
    │   └── GameViewModel.swift    # 状态机 / 下注循环 / AI 决策 / 技能
    ├── Views/
    │   ├── GameView.swift
    │   ├── PlayerView.swift
    │   ├── CardView.swift
    │   ├── ActionBarView.swift
    │   ├── SkillBarView.swift
    │   └── SettlementView.swift
    └── Assets.xcassets/           # AI 生成的 PNG（背景、头像、卡背、AppIcon）
```

## 编译运行

需要 macOS + Xcode 15+，iOS 16+。

### 方式 A：XcodeGen（推荐）

```bash
brew install xcodegen
cd PokerGame
xcodegen generate
open PokerGame.xcodeproj
```

### 方式 B：Xcode 手动建工程

1. Xcode → New → App → iOS App → SwiftUI，命名 `PokerGame`
2. 删除自动生成的 `ContentView.swift` 和 `Assets.xcassets`
3. 把仓库内 `PokerGame/PokerGame/` 下所有文件 / 目录拖入工程，**勾选 "Copy items if needed" 与 "Create groups"**，target 选中 PokerGame
4. 在 target General → 设置 Display Name = 无厘头德州扑克，Deployment iOS = 16.0
5. ⌘R 即可在模拟器或真机运行

## 已实现功能

- 完整德州扑克流程：发底牌 → preflop → flop → turn → river → showdown
- 大小盲、跟注、加注、过牌、弃牌、All-in 推进
- 7 张牌取 5 张最佳的牌型评估（含 A-2-3-4-5 顺子）
- 4 种性格 AI：激进鬼 / 保守怪 / 玄学家（默认 random）/ 搞怪精
- 6 种搞笑技能：换牌术、偷看、倒霉蛋、混乱、护盾、吃瓜
- 技能目标选择：偷看 / 倒霉蛋 通过点击 AI 头像选定
- 冷却 + 护盾抵消 + 倒霉蛋强制跟注
- 结算面板：展示获胜者牌型、筹码变化、操作日志
- iOS 安全区适配（默认 SwiftUI 行为）、纵向锁定

## 已生成的美术资源

由 Nano Banana Pro（Gemini 3 Pro Image）生成，存于 `PokerGame/Assets.xcassets/`：

| 资产 | 状态 |
|---|---|
| Background（牌桌背景） | ✅ 已生成 |
| PlayerAvatar（玩家头像-酷猫） | ✅ 已生成 |
| AI1（激进鬼-老虎） | ✅ 已生成 |
| AI2（保守怪-乌龟） | ✅ 已生成 |
| AI3（搞怪精-猴子） | ⚠️ 生成时服务 500，请运行 `bash .comate/regenerate-missing.sh` 重试 |
| CardBack（卡背） | ✅ 已生成 |
| AppIcon（应用图标 1024×1024） | ⚠️ 同上 |

AI3 和 AppIcon 缺失时，UI 会自动 fallback 到首字母+渐变占位，不影响编译运行。

## 已知限制 / 后续可扩展

- 边池（side pot）按简化逻辑处理，仅在多人 All-in 时按主底池均分；正式发布需补全
- 无音效 / 背景音乐（`需求文档.md` 第 7 节明确不实现）
- 无粒子特效，使用 SF Symbols + 颜色变化反馈
- AppIcon 只生成 1024×1024 主图，发布前需用 [appicon.co](https://www.appicon.co/) 生成全尺寸
- 无启动屏图，使用空 `UILaunchScreen` 字典占位
- 上架前需补：隐私清单 (`PrivacyInfo.xcprivacy`)、App Store 截图、签名证书、合规说明

## 入审风险提示

- 德州扑克类应用 Apple 审核较严，建议：
  - 不开放真实货币购买筹码
  - 主页明确说明"无任何赌博性质，纯娱乐"
  - 设置 17+ 年龄分级
  - 提供"重置筹码"入口（已通过结算面板实现）
