<div align="center">
  <h1>Yoko-NewContentLoader</h1>
  <p><strong>Shared content-registration infrastructure for Brotato Mod Loader projects.</strong></p>
  <p>Structured resources · DLC-aware loading · Lifecycle management · Runtime extensions</p>
  <p>
    <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/releases"><img src="https://img.shields.io/github/v/release/CYoJkoY/Yoko-NewContentLoader?display_name=tag&sort=semver&style=flat-square&label=release" alt="Latest release"></a>
    <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/CYoJkoY/Yoko-NewContentLoader/release.yml?style=flat-square&label=build" alt="Build status"></a>
    <img src="https://img.shields.io/badge/Brotato-1.15.4-478CBF?style=flat-square" alt="Brotato 1.15.4">
    <img src="https://img.shields.io/badge/Mod%20Loader-6.3.0-5965FF?style=flat-square" alt="Mod Loader 6.3.0">
    <a href="LICENSE"><img src="https://img.shields.io/github/license/CYoJkoY/Yoko-NewContentLoader?style=flat-square" alt="MIT License"></a>
  </p>
</div>

> **Core boundary:** dependent mods describe content as Godot resources; NewContentLoader owns discovery, DLC-aware loading, registration, lifecycle cleanup, and shared runtime integration; Brotato remains the gameplay runtime.

<div align="center">

## <img src="assets/readme/icons/documentation.svg" width="20" height="20" alt=""> [完整使用与开发文档](docs/USAGE.md)

**从零接入 NCL、配置 `NewContentData.tres`、使用 DLC 内容、注册自定义类、编写 Wave Hook、使用 RunData / Utils API，以及排查加载问题。**

<a href="docs/USAGE.md"><strong>→ 先阅读：5 分钟接入教程 + 完整 API / 功能说明</strong></a>

</div>

## <img src="assets/readme/icons/overview.svg" width="20" height="20" alt=""> Quick start

最小接入路径：

```text
1. manifest.json 声明依赖 Yoko-NewContentLoader
                    ↓
2. 创建 NewContentData.tres
                    ↓
3. 填入角色 / 武器 / 道具 / 敌人 / 翻译等资源
                    ↓
4. 启动 Brotato，由 NCL 自动发现并加载
```

最小依赖声明：

```json
{
  "dependencies": [
    "Yoko-NewContentLoader"
  ]
}
```

最小内容结构：

```text
MyMod/
├── NewContentData.tres
├── manifest.json
└── content/
    ├── characters/
    ├── weapons/
    └── items/
```

**通常不需要在你的 Mod 里手动调用 `add_resources()`。** NCL 会扫描声明了依赖的 Mod，读取内容资源，并将其接入游戏服务。

## <img src="assets/readme/icons/features.svg" width="20" height="20" alt=""> Why it exists

Brotato 已经拥有角色、武器、物品、效果、敌人、挑战、区域、翻译和 RunData 等原生服务。NCL 不建立平行数据库，而是在这些原生边界之上提供统一的 Mod 内容入口。

```text
Your Mod
   │
   ▼
NewContentData(.tres)
   │
   ▼
NCL discovery + DLC merge
   │
   ├── ItemService
   ├── ZoneService
   ├── ChallengeService
   ├── EffectBehaviorService
   ├── TranslationServer / Text
   ├── RunData
   └── selected Brotato runtime extensions
```

这使大量内容 Mod 可以共享同一套注册、卸载、追踪、Hook 和运行时辅助，而不需要重复修改 Brotato 的每一个服务。

## <img src="assets/readme/icons/architecture.svg" width="20" height="20" alt=""> DLC-aware content loading

NCL 扩展 `ProgressData`，只处理 manifest 中声明依赖 NCL 的 Mod，并分别尝试读取：

```text
NewContentData.tres
NewContentDataDLC1.tres  ← 对应 DLC 可用时才读取
```

基础内容与 DLC1 内容会自动合并为该 Mod 的一份 `NewContent`，再进入游戏现有的可用 DLC / content 路径。

当前 DLC1 边界使用：

```text
abyssal_terrors
```

如果游戏没有对应 DLC 数据，NCL 会主动跳过 DLC1 内容。

这种设计让内容继续沿着 Brotato 自己已有的 DLC / ProgressData 边界进入运行时，通常比每个 Mod 自己实现一套注册体系更容易维护和协作。但它不是任意游戏版本、任意 Mod 组合的绝对兼容保证；底层 API 变化、重复 ID 和多个 Mod 同时改写相同运行时服务仍然可能产生冲突。

## <img src="assets/readme/icons/features.svg" width="20" height="20" alt=""> Content model

`NewContent` 是一个 Godot `Resource`，主要入口包括：

| Category | Resource fields |
| :--- | :--- |
| World | `groups_in_all_zones`, `backgrounds`, `zones`, `difficulties`, `title_screen_backgrounds`, `music_tracks` |
| Gameplay | `characters`, `entities`, `elites`, `bosses`, `stats`, `items`, `weapons`, `effects`, `consumables`, `upgrades`, `sets` |
| UI | `icons` |
| Progression | `challenges`, `tracked_items`, `tracked_effects`, `primary_stats_list` |
| Serialization | `effect_keys_full_serialization`, `effect_keys_with_weapon_stats` |
| Localization | `translations`, `translation_keys_needing_operator`, `translation_keys_needing_percent` |
| Runtime behavior | `scene_effect_behaviors`, `enemy_effect_behaviors`, `player_effect_behaviors` |

每个字段的创建方式、适用场景、完整示例和注意事项见 [完整使用与开发文档](docs/USAGE.md)。

## <img src="assets/readme/icons/architecture.svg" width="20" height="20" alt=""> Integration

NCL 当前扩展的核心 Brotato 系统包括：

```text
ProgressData
RunData
Utils
Main
WeaponService
FloatingTextManager
ItemService
```

主要能力：

- 自动发现依赖 NCL 的内容 Mod。
- 基础内容 / DLC1 内容属性级合并。
- 成对的内容添加与卸载。
- 自定义 Global Class 自动发现、去重和清理。
- End-of-Wave Hook。
- Item / Effect tracking。
- Primary Stat 注册。
- Effect serialization 键注册。
- Weapon `my_id_hash` 快速索引。
- Consumable 掉落二次处理 Hook。
- 自定义伤害颜色 / 图标飘字。
- 运行中 / 商店中的 Weapon 动态替换。
- Item / Weapon 通用 Gear API。
- Damage / Range / Stat scaling 工具。
- Consumable 运行时生成辅助。

## <img src="assets/readme/icons/installation.svg" width="20" height="20" alt=""> Installation

要求：**Brotato 1.15.4**、**Brotato Mod Loader 6.3.0**。

下载最新 `NewContentLoader-*.zip` 到 Mod Loader 的 `mods` 目录，并在使用 NCL 的其他 Mod 之前安装它。

开发环境：

```text
mods-unpacked/
├── Yoko-NewContentLoader/
└── YourMod/
```

## <img src="assets/readme/icons/development.svg" width="20" height="20" alt=""> Development

NCL 是共享基础设施。修改以下任何一项，都可能影响所有依赖项目：

```text
registration / teardown
DLC discovery
_global_script_classes
RunData tracking / serialization
Weapon lookup
End Wave hooks
Brotato service extensions
```

因此推荐至少使用一个真实依赖 Mod 做完整回归测试。

当前 manifest：

```text
Version       1.1.0
Brotato       1.15.4
Mod Loader    6.3.0
Dependencies  none
```

## <img src="assets/readme/icons/verification.svg" width="20" height="20" alt=""> Troubleshooting

优先检查：

```text
① manifest.dependencies 是否包含 Yoko-NewContentLoader
② NewContentData.tres 是否位于 Mod 根目录
③ Content Report 是否出现
④ 是否存在 Duplicate ids
⑤ DLC1 是否真的可用
⑥ class_service.gd 是否存在并返回有效类
⑦ runtime extension 是否匹配当前 Brotato 版本
```

详细日志案例与逐项排查流程见 [USAGE.md → 调试与日志](docs/USAGE.md)。

## <img src="assets/readme/icons/development.svg" width="20" height="20" alt=""> Related projects

- [Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) — content-heavy Brotato expansion using NCL.
- [Yoko-Fantasy](https://github.com/CYoJkoY/Yoko-Fantasy) — systems-heavy Brotato expansion using NCL.
- [Yoko-MoreStatsContainer](https://github.com/CYoJkoY/Yoko-MoreStatsContainer) — focused Brotato UI extension.
- [Brotato Mod Loader](https://wiki.godotmodding.com/) — Mod Loader documentation.

## <img src="assets/readme/icons/documentation.svg" width="20" height="20" alt=""> Documentation

README 用于快速定位、快速接入和能力概览；完整的字段级文档、API、DLC 接入、Hook、RunData、Utils、故障排查和最佳实践统一维护在：

**[📖 Yoko-NewContentLoader 完整使用与开发文档](docs/USAGE.md)**

## <img src="assets/readme/icons/heart.svg" width="20" height="20" alt=""> Support

<a href="https://cyojkoy.github.io/Payment/"><img src="assets/readme/support-cta.svg" alt="Support Yoko-NewContentLoader" width="900" style="max-width:100%;height:auto;"></a>

Development support: **https://cyojkoy.github.io/Payment/**

## License

This project is licensed under the [MIT License](LICENSE).
