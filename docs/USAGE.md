# Yoko-NewContentLoader 使用与开发手册

> 面向 Brotato Mod 开发者、Godot 3.x 开发者，以及希望基于 NCL 构建内容型 Mod 的开发者。
>
> **当前基准：NCL 1.1.0 · Brotato 1.1.15.4 · Brotato Mod Loader 6.3.0 · Godot 3.x / GDScript**

> 本文使用的源码链接均为普通 GitHub Markdown 链接，不依赖 ChatGPT/内部引用语法；你可以直接在 GitHub 上点击查看对应源码。

<div align="center">

### English version

[Read the English developer guide →](USAGE.en.md)

</div>

## 1. NCL 到底解决什么问题

`Yoko-NewContentLoader` 不是玩法 Mod，也不是简单的文件读取器，而是一层共享的 Brotato 内容基础设施。

依赖 NCL 的 Mod 使用 Godot `Resource` / `.tres` 描述内容，NCL 负责发现依赖 Mod、加载内容、处理 DLC、合并资源、注册到 Brotato 原有服务、提供成对的卸载流程，并提供可以被多个 Mod 复用的运行时扩展与工具函数。

核心链路：

```text
Godot Editor
    ↓
Resource / .tres
    ↓
Your Mod
    ├── manifest.json
    ├── NewContentData.tres
    ├── NewContentDataDLC1.tres   (可选)
    ├── content/**/*.tres
    ├── translations/*
    └── extensions/*.gd
    ↓
Yoko-NewContentLoader
    ├── Mod discovery
    ├── Resource loading / merge
    ├── DLC gating
    ├── add / remove lifecycle
    ├── Global Class registration
    ├── Script Extension
    └── Runtime helpers
    ↓
Brotato 原生服务
```

NCL 的原则是：**不重新发明 Brotato 的数据模型，而是让多个 Mod 以统一方式进入游戏已有的运行时边界。**

建议同时阅读源码入口：[NewContent.gd](../NewContent.gd)、[mod_main.gd](../mod_main.gd) 与 [extensions/progress_data.gd](../extensions/progress_data.gd)。

## 2. 五分钟接入一个 Mod

### 2.1 声明依赖

`manifest.json` 至少要声明：

```json
{
  "name": "MyMod",
  "namespace": "MyNamespace",
  "version_number": "1.0.0",
  "description": "My Brotato content mod",
  "dependencies": [
    "Yoko-NewContentLoader"
  ]
}
```

NCL 只处理显式依赖它的 Mod。

### 2.2 推荐目录结构

```text
MyMod/
├── manifest.json
├── NewContentData.tres
├── NewContentDataDLC1.tres       # 可选
├── content/
│   ├── characters/
│   ├── weapons/
│   ├── items/
│   ├── effects/
│   ├── entities/
│   ├── challenges/
│   ├── zones/
│   └── icons/
├── translations/
└── extensions/
    ├── services/
    │   └── class_service.gd
    └── dlc_1_data.gd
```

目录名是推荐约定，不是 NCL 的发现契约。真正的契约是：`NewContentData.tres` 位于 Mod 根目录，并且它可以正确引用你的 Resource。

### 2.3 使用 `NewContent.tres` 模板

仓库中的 [`NewContent.tres`](../NewContent.tres) 是一个 Resource 模板，对应 [`NewContent.gd`](../NewContent.gd)。复制后命名为：

```text
NewContentData.tres
```

然后在 Godot Inspector 中编辑。

### 2.4 Inspector 工作流

NCL 的核心就是把内容作为 Resource 引用填进聚合 Resource：

```text
NewContentData.tres
  Characters  → character_data.tres
  Weapons     → weapon_data.tres
  Items       → item_data.tres
  Effects     → effect_data.tres
```

Godot 3.x 的 `export(Array, Resource)` 会把这些数组暴露到 Inspector。

官方参考：[Godot 3.6 Resources](https://docs.godotengine.org/en/3.6/tutorials/scripting/resources.html) · [Godot 3.6 GDScript exports](https://docs.godotengine.org/en/3.6/tutorials/scripting/gdscript/gdscript_exports.html)

### 2.5 普通 Mod 不需要手动注册

通常不要在 Mod 启动阶段重复调用：

```gdscript
content.add_resources()
```

推荐生命周期是：

```text
manifest dependency
    ↓
NCL discovery
    ↓
NewContentData.tres
    ↓
optional DLC merge
    ↓
Brotato registration
```

具体发现、读取与合并逻辑见 [`extensions/progress_data.gd`](../extensions/progress_data.gd)。

## 3. Godot Resource：NCL 为什么使用 `.tres`

### 3.1 Node 与 Resource

可以用下面的模型理解：

```text
Node
→ 场景实例、生命周期、运行时行为

Resource
→ 可保存、可引用、可复用的数据
```

NCL 更偏向第二种，因为角色、武器、物品、Effect、Zone 等本质上都需要一个稳定的数据描述层。

例如一个 Weapon Resource 可以继续引用：

```text
WeaponData.tres
├── icon       → Texture
├── effects    → Effect Resource[]
├── stats      → Stats Resource
└── scene      → PackedScene
```

这样可以让 Godot 自己处理 Resource 引用、序列化与 Inspector 编辑。进一步了解 Resource 的生命周期与外部/内置资源区别，可参考 [Godot 3.6 Resources](https://docs.godotengine.org/en/3.6/tutorials/scripting/resources.html)。

### 3.2 为什么不是 JSON

JSON 更适合交换数据，而 NCL 处理的是 Godot 内部 Resource 图：一个 Resource 经常继续引用 Texture、PackedScene、其它 Resource 或 Translation。

因此：

```text
JSON → 交换格式
.tres → Godot authored content
```

### 3.3 为什么推荐拆成多个 `.tres`

大型 Mod 不应该把所有内容都塞进一个巨大 Resource。推荐：

```text
one character → one .tres
one weapon    → one .tres
one item      → one .tres
one effect    → one .tres
```

再由 `NewContentData.tres` 进行聚合。

这对 Git diff、多人协作、Inspector 编辑和问题定位都更友好。

## 4. `NewContent` 全字段

当前实际字段定义位于 [`NewContent.gd`](../NewContent.gd)。主要字段如下：

| 字段 | 类型 | 用途 |
| :--- | :--- | :--- |
| `my_id` | `String` | 内容集合身份 |
| `groups_in_all_zones` | `Array, Resource` | 全 Zone 分组资源 |
| `music_tracks` | `Array, Resource` | 音乐资源 |
| `backgrounds` | `Array, Resource` | 背景资源 |
| `characters` | `Array, Resource` | 角色 |
| `entities` | `Array, Resource` | Entity |
| `elites` | `Array, Resource` | Elite |
| `bosses` | `Array, Resource` | Boss |
| `stats` | `Array, Resource` | 自定义 Stat |
| `items` | `Array, Resource` | 道具 |
| `weapons` | `Array, Resource` | 武器 |
| `effects` | `Array, Resource` | Effect |
| `consumables` | `Array, Resource` | Consumable |
| `upgrades` | `Array, Resource` | Upgrade |
| `sets` | `Array, Resource` | Set |
| `difficulties` | `Array, Resource` | Difficulty |
| `icons` | `Array, Resource` | Icon Resource |
| `title_screen_backgrounds` | `Array, Resource` | 标题背景 |
| `translations` | `Array, Translation` | 翻译 |
| `challenges` | `Array, Resource` | Challenge |
| `zones` | `Array, Resource` | Zone |
| `tracked_items` | `Dictionary` | RunData Item tracking |
| `tracked_effects` | `Dictionary` | NCL Effect tracking |
| `primary_stats_list` | `Array, String` | 主要 Stat Key |
| `effect_keys_full_serialization` | `Array, String` | 完整序列化 Effect Key |
| `effect_keys_with_weapon_stats` | `Array, String` | Weapon Stat 相关 Effect Key |
| `translation_keys_needing_operator` | `Dictionary` | operator 元数据 |
| `translation_keys_needing_percent` | `Dictionary` | percent 元数据 |
| `scene_effect_behaviors` | `Array, Resource` | Scene Effect Behavior |
| `enemy_effect_behaviors` | `Array, Resource` | Enemy Effect Behavior |
| `player_effect_behaviors` | `Array, Resource` | Player Effect Behavior |

### `my_id`

推荐使用稳定且具有命名空间意义的值：

```text
MyMod
YzTato
YokoFantasy
```

不要让多个独立内容包长期共享一个 ID。

### `backgrounds`

NCL 不只是保存背景，还会在注册阶段把背景加入现有 Zone 的 `default_backgrounds`，卸载时反向移除。

源码：[NewContent.gd](../NewContent.gd)

### `characters`

最终会进入 Brotato 的 `ItemService.characters`。你的角色 Resource 仍然应该遵循 Brotato 原有数据模型。

### `stats`

注册 Stat 后，NCL 会重新建立 Stat Key / hash 状态。不要在 Mod 内再维护第二套 Stat 注册系统。

### `weapons`

注册后 NCL 会维护基于 `my_id_hash` 的 Weapon lookup。如果 WeaponData 设置了 `add_to_chars_as_starting`，NCL 会把它加入对应角色的 `starting_weapons`，并在卸载时反向处理。

相关实现：[extensions/item_service.gd](../extensions/item_service.gd) 与 [NewContent.gd](../NewContent.gd)

### `translations`

该字段是 `Array, Translation`，不是普通 `Resource`。NCL 会把 Translation 加入 `TranslationServer`，卸载时移除。

推荐：

```text
translations/
├── MyMod.en.translation
├── MyMod.zh.translation
└── MyMod.ja.translation
```

### `challenges` / `zones`

分别进入 Brotato 的 Challenge / Zone 服务，并由 NCL 统一维护生命周期。

## 5. Tracking：让自定义状态进入 RunData

### `tracked_items`

```gdscript
export(Dictionary) var tracked_items = {}
```

用于声明与 RunData 相关的 Item tracking。

### `tracked_effects`

```gdscript
export(Dictionary) var tracked_effects = {}
```

用于 NCL 自己的 Effect tracking。

运行时 API 位于 [`extensions/run_data.gd`](../extensions/run_data.gd)：

```gdscript
RunData.ncl_add_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_set_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_get_effect_tracking_value(key_hash, player_index)
```

如果你的数据需要跨 Wave、跨界面或跟随 Run 保存/恢复，不应该简单地放进一个永不持久化的全局 Dictionary。

## 6. Primary Stats 与 Effect Serialization

### `primary_stats_list`

```gdscript
export(Array, String) var primary_stats_list = []
```

NCL 会把这些 Stat Key 接入 `RunData.primary_stats_list`。

### Effect serialization metadata

```gdscript
export(Array, String) var effect_keys_full_serialization = []
export(Array, String) var effect_keys_with_weapon_stats = []
```

当你的自定义 Effect 有需要参与保存/恢复的数据时，在这里集中声明相关 Key。

## 7. Text：operator / percent

```gdscript
export(Dictionary) var translation_keys_needing_operator = {}
export(Dictionary) var translation_keys_needing_percent = {}
```

这些设置会并入 Brotato 的 Text 注册表。这样做的目的不是重新实现文本系统，而是让自定义文本继续使用游戏已有的格式处理逻辑。

## 8. Effect Behavior：数据与行为分离

三个 Behavior 集合：

```gdscript
scene_effect_behaviors
enemy_effect_behaviors
player_effect_behaviors
```

推荐：

```text
Resource
→ 描述“是什么”

Behavior
→ 描述“运行时怎么做”
```

一个复杂 Effect 可以拆成：

```text
MyEffectData.tres
MyEffectBehavior.gd
```

而不是把游戏逻辑写进 `NewContent.gd`。

## 9. DLC 支持

当前 NCL 的 DLC1 内容入口是：

```text
NewContentData.tres
NewContentDataDLC1.tres
```

DLC1 是否加载由 [`extensions/progress_data.gd`](../extensions/progress_data.gd) 根据游戏 DLC 状态判断。

### 合并规则

当前实现的核心语义是：

```text
Array
→ DLC 内容追加

Dictionary
→ DLC 内容 merge，并允许同 key 覆盖

其它属性
→ DLC 值覆盖基础值
```

因此应把 DLC1 当作“基础内容的增量层”，而不是第二个完全独立的 Mod。

### 推荐工作流

```text
NewContentData.tres
    ↓
Base content

NewContentDataDLC1.tres
    ↓
Optional DLC layer
    ↓
NCL merge
```

另外，DLC 还可以通过：

```text
extensions/dlc_1_data.gd
```

进行运行时 Script Extension。示例可参考 [Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) 中对应实现。

## 10. Global Class：`class_service.gd`

如果你的 Mod 提供自定义 Global Class，可使用：

```text
extensions/services/class_service.gd
```

例如：

```gdscript
extends Reference

static func get_classes() -> Array:
    return [
        {
            "base": "RangedWeaponStats",
            "class": "DotStructureWeaponStats",
            "language": "GDScript",
            "path": "res://mods-unpacked/YourMod/content/structures/dot_structure_stats.gd"
        }
    ]
```

### Godot 继承与父类调用

自定义 Class 经常会继承 Brotato 的基类 Resource / Script：

```gdscript
extends RangedWeaponStats
```

在 Godot 3.6 中，GDScript 的脚本继承仍然使用 `extends`；覆盖父类方法时，可以用 `.method()` 调用父实现。参考 [Godot 3.6 GDScript Basics](https://docs.godotengine.org/en/3.6/getting_started/scripting/gdscript/gdscript_basics.html)。

## 11. End-of-Wave Hook

NCL 的 `Main` 扩展提供：

```text
before_wave_rewards
after_wave_rewards
before_end_run_scene
before_change_scene
```

源码：[extensions/main.gd](../extensions/main.gd)

注册：

```gdscript
main.ncl_register_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards",
    100
)
```

`priority` 越小越早执行；相同优先级使用方法名排序。不要依赖注册顺序。

注销：

```gdscript
main.ncl_unregister_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards"
)
```

### Godot 3.x 协程

Hook 可以返回 `GDScriptFunctionState`。NCL 会等待：

```gdscript
yield(result, "completed")
```

例如：

```gdscript
func _on_before_wave_rewards():
    yield(get_tree(), "idle_frame")
    do_something()
```

参考 [Godot 3.x @GDScript / yield](https://docs.godotengine.org/zh-cn/3.x/classes/class_%40gdscript.html)。Godot 3.x 的 `yield()` 可以等待对象发出的信号，也可以等待另一个 yield 函数通过 `completed` 信号结束。

## 12. Weapon Lookup

NCL 的 ItemService 扩展提供：

```gdscript
ncl_is_weapon_id(weapon_my_id)
ncl_get_weapon_from_id(weapon_my_id)
ncl_rebuild_weapon_my_id_lookup()
```

源码：[extensions/item_service.gd](../extensions/item_service.gd)

## 13. RunData 辅助 API

[`extensions/run_data.gd`](../extensions/run_data.gd) 还提供：

```gdscript
RunData.ncl_get_nb_weapon(weapon_my_id_hash, player_index)
RunData.ncl_remove_weapon_by_id(weapon, player_index)
```

优先通过 NCL 的移除路径操作武器，避免直接修改内部 Array 而跳过既有生命周期。

## 14. Utils Runtime API

当前主要 `ncl_*` 工具函数包括：

```text
ncl_quiet_add_stat
ncl_quiet_set_stat
ncl_curse_effect_value
ncl_curse_item
ncl_curse_enemy
ncl_create_tracking
ncl_get_scaling_stats_dmg
ncl_get_dmg_with_scaling_stats
ncl_get_num_with_scaling_stats
ncl_get_dmg_text_with_scaling_stats
ncl_get_num_text_with_scaling_stats
ncl_get_range_with_detection
ncl_get_range_text_with_scaling
ncl_get_signed_col
ncl_queue_free_weapon
ncl_change_weapon_within_run
ncl_change_weapon_within_shop
ncl_create_custom_damage_args
ncl_get_validate_node_name
ncl_spawn_consumable
ncl_judge_item_type_from_my_id
ncl_get_nb_gear
ncl_add_gear_by_id
ncl_remove_gear_by_id
ncl_get_gear_name_from_id
ncl_get_true_stat_name
ncl_generate_composite_hash
```

源码：[extensions/utils.gd](../extensions/utils.gd)

## 15. 自定义 Damage Number

NCL 扩展 `FloatingTextManager`，识别 `TakeDamageArgs` metadata：

```text
custom_color
custom_icon
```

并继续走 Brotato 原有 damage display 路径。

## 16. Consumable 运行时生成

```gdscript
Utils.ncl_spawn_consumable(
    consumable_id,
    num,
    pos,
    spread
)
```

NCL 优先复用 Brotato 的 Consumable pool；无可复用实例时才创建 Scene instance。

## 17. Gear API

NCL 统一处理 Item / Weapon：

```gdscript
enum GearType {ITEM, WEAPON}
```

```gdscript
Utils.ncl_judge_item_type_from_my_id(gear_id)
Utils.ncl_get_nb_gear(gear_id, player_index)
Utils.ncl_add_gear_by_id(gear_id, player_index, num)
Utils.ncl_remove_gear_by_id(gear_id, player_index, num)
Utils.ncl_get_gear_name_from_id(gear_id, num)
```

## 18. DLC Runtime Script Extension

DLC 行为扩展可以放在：

```text
extensions/dlc_1_data.gd
```

并继承 Brotato 原生 DLC 数据脚本。

例如：

```gdscript
extends "res://dlcs/dlc_1/dlc_1_data.gd"
```

然后通过覆盖方法叠加自己的逻辑，同时尽量保留父实现。

## 19. NCL 自身的启动过程

```text
Mod Loader ModData
      ↓
NCL startup
      ↓
install_script_classes()
      ↓
install_script_extensions()
      ↓
ProgressData discovers dependent content
```

当前核心扩展包括：

```text
progress_data.gd
run_data.gd
utils.gd
main.gd
weapon_service.gd
floating_text_manager.gd
item_service.gd
```

## 20. 多个 Mod 共享 NCL

```text
NCL
 ├── Mod A
 ├── Mod B
 └── Mod C
```

每个 Mod 可以有自己的：

```text
NewContentData.tres
NewContentDataDLC1.tres
```

ID 应保持跨 Mod 可区分，例如：

```text
fantasy_prism_tower
fantasy_soul_link
yztato_chisefengbao
```

## 21. Godot Resource 管理规则

### 21.1 优先使用 Godot FileSystem Dock

`.tres` 会记录外部 Resource path。建议在 Godot FileSystem Dock 中移动和重命名资源，降低引用断裂风险。

### 21.2 控制 Resource 边界

推荐：

```text
NewContentData.tres
    ├── CharacterData.tres
    ├── WeaponData.tres
    ├── ItemData.tres
    └── EffectData.tres
```

不要把整个 Mod 做成一个无法维护的单体 Resource。

### 21.3 `.tres`、`.tscn`、`.gd` 的职责

```text
.tres → 数据与资源引用
.tscn → Node / 场景组合
.gd   → Runtime behavior
```

这正好对应 NCL 的 Data / Behavior 分层。

## 22. Godot Script Extension

NCL 会把自己的脚本扩展挂到 Brotato 原有脚本上，例如：

```gdscript
extends "res://singletons/run_data.gd"
```

和：

```gdscript
extends "res://singletons/item_service.gd"
```

核心原则是：

```text
Brotato 原系统
      ↑
Script Extension
      ↑
NCL
      ↑
你的 Mod
```

扩展父脚本时，应尽可能先调用父逻辑，再加入自己的差异行为。

参考：[Godot 3.6 GDScript Basics](https://docs.godotengine.org/en/3.6/getting_started/scripting/gdscript/gdscript_basics.html)

## 23. 添加 / 卸载生命周期

NCL 的核心生命周期：

```gdscript
add_resources()
remove_resources()
```

添加阶段统一处理：

```text
Translations
Zones
Backgrounds
Characters
Entities
Elites
Bosses
Stats
Items
Consumables
Upgrades
Sets
Difficulties
Icons
Title Screen Backgrounds
Weapons
Effects
Challenges
Effect Behaviors
Tracking
Text registrations
```

卸载阶段反向清理，并刷新 unlocked pool 与 weapon lookup。

## 24. 推荐的大型 Mod 目录结构

```text
MyMod/
├── manifest.json
├── README.md
├── LICENSE
├── NewContentData.tres
├── NewContentDataDLC1.tres
├── content/
│   ├── characters/
│   ├── weapons/
│   │   ├── melee/
│   │   ├── ranged/
│   │   └── special/
│   ├── items/
│   ├── effects/
│   ├── entities/
│   ├── elites/
│   ├── bosses/
│   ├── challenges/
│   ├── maps/
│   ├── zones/
│   ├── structures/
│   └── icons/
├── translations/
└── extensions/
    ├── services/
    │   └── class_service.gd
    ├── dlc_1_data.gd
    ├── effects/
    └── systems/
```

## 25. 常见错误

### 25.1 没声明依赖

检查：

```json
"dependencies": ["Yoko-NewContentLoader"]
```

### 25.2 `NewContentData.tres` 不在根目录

默认发现文件名是：

```text
NewContentData.tres
NewContentDataDLC1.tres
```

### 25.3 Duplicate ID

检查所有参与发现的 NCL Mod，不要让多个内容使用冲突的 `my_id`。

### 25.4 把 Runtime Behavior 写进 Resource 聚合器

Resource 描述数据；动态行为应放到脚本、Scene Script 或 Effect Behavior。

### 25.5 覆盖父方法但不调用父实现

需要保留原逻辑时：

```gdscript
func some_func():
    var result = .some_func()
    # add your behavior
    return result
```

## 26. `[NCL]` 日志排查

重点搜索：

```text
[NCL]
```

常见情况：

```text
Successfully load NewContentData.tres
Successfully load NewContentDataDLC1.tres
Successfully load <mod_id>
Content report: characters=..., weapons=..., items=...
```

### `Dependency missing`

检查 `manifest.json`。

### `NewContentData.tres not found`

检查文件名和 Mod 根目录。

### `DLC ... not available`

DLC 不可用，因此 DLC 层被正确跳过。

### `Duplicate ids`

检查 Resource ID 命名。

## 27. 内容不显示时的正确排查顺序

```text
① Mod Loader 是否发现你的 Mod？
        ↓
② manifest.dependencies 是否包含 NCL？
        ↓
③ NewContentData.tres 是否存在？
        ↓
④ Godot Inspector 是否可以打开 Resource？
        ↓
⑤ 子 Resource 是否全部有效？
        ↓
⑥ 是否出现 NCL Content Report？
        ↓
⑦ 是否存在 Duplicate ID？
        ↓
⑧ Brotato 对应 Service 是否收到资源？
        ↓
⑨ 是否缺少 Runtime Script Extension？
```

这样可以把问题拆分为：

```text
Godot Resource 问题
NCL 注册问题
Brotato Runtime 问题
```

## 28. 版本与兼容性

当前 manifest：

```text
NCL version       1.1.0
Brotato           1.1.15.4
Mod Loader        6.3.0
Dependencies      none
```

NCL 是基础层，因此升级后的回归测试应覆盖：

```text
NCL 自身
  ↓
内容型 Mod
  ↓
DLC 型 Mod
  ↓
Runtime Extension 较多的 Mod
```

重点检查：

```text
ProgressData
RunData
Main
WeaponService
ItemService
Utils
```

## 29. 什么时候应该使用 NCL

适合：

```text
✔ 大量角色 / 武器 / 道具
✔ 大量自定义 Effect
✔ DLC 分层内容
✔ RunData tracking
✔ Global Class
✔ Wave lifecycle Hook
✔ 跨系统 Runtime utility
✔ 深度复用 Brotato Service
✔ 中大型、长期维护的 Mod
```

对于只修改一个数值或只有一个很小的 UI Patch，不一定需要引入 NCL。

## 30. 正确的 NCL 开发思维

遇到新需求时：

```text
新需求
  ↓
先判断是 Data 还是 Behavior
  ↓
Data → Godot Resource
  ↓
注册到 NewContentData
  ↓
Behavior → 找 Brotato 所属系统
  ↓
优先 Script Extension / extends
  ↓
生命周期需求 → Hook
  ↓
跨 Run 状态 → RunData tracking
  ↓
通用算法 → Utils
```

不要先创建一个巨大的 Manager，再把 Brotato 强行塞进去。

## 31. 完整小型示例

目标：

```text
新角色
新武器
新道具
一个 tracking value
```

项目：

```text
MyDemoMod/
├── manifest.json
├── NewContentData.tres
└── content/
    ├── characters/
    │   └── demo_character_data.tres
    ├── weapons/
    │   └── demo_weapon_data.tres
    └── items/
        └── demo_item_data.tres
```

Inspector：

```text
My Id: DemoMod

Characters:
  - demo_character_data.tres

Weapons:
  - demo_weapon_data.tres

Items:
  - demo_item_data.tres

Tracked Effects:
  demo_kills: 0
```

启动后：

```text
发现 DemoMod
      ↓
读取 NewContentData.tres
      ↓
注册 Character / Weapon / Item
      ↓
初始化 tracking
      ↓
刷新 unlocked pool
      ↓
重建 weapon lookup
```

## 32. 大型 Mod 建议

当项目达到几十个角色、几百件物品、大量 Effect 后，建议按职责继续拆分：

```text
content/
├── characters/
├── weapons/
│   ├── melee/
│   ├── ranged/
│   └── special/
├── items/
│   ├── offensive/
│   ├── defensive/
│   └── utility/
├── effects/
├── entities/
├── zones/
└── challenges/
```

然后让 `NewContentData.tres` 担任内容入口聚合器。

## 33. 发布前检查表

```text
[ ] manifest.json 声明 Yoko-NewContentLoader
[ ] NewContentData.tres 位于 Mod 根目录
[ ] 所有 .tres 可在 Godot Inspector 打开
[ ] 所有 external Resource path 有效
[ ] 所有 my_id 唯一
[ ] Translation Resource 已注册
[ ] DLC 内容进入 NewContentDataDLC1.tres
[ ] DLC 行为进入 extensions/dlc_1_data.gd
[ ] 需要 Global Class 时提供 class_service.gd
[ ] Runtime Behavior 不塞进 NewContent.gd
[ ] 跨 Run 状态使用 RunData tracking
[ ] 生命周期需求使用 Hook
[ ] 不维护第二套 ItemService / RunData 数据库
[ ] 完整启动一次游戏
[ ] 检查 [NCL] Content report
[ ] 检查 Duplicate ids
[ ] 检查 Brotato / Mod Loader 版本
```

## 34. 参考资料

Godot 3.6：

- [Godot 3.6 Resources](https://docs.godotengine.org/en/3.6/tutorials/scripting/resources.html)
- [Godot 3.6 GDScript Basics](https://docs.godotengine.org/en/3.6/getting_started/scripting/gdscript/gdscript_basics.html)
- [Godot 3.6 GDScript Exports](https://docs.godotengine.org/en/3.6/tutorials/scripting/gdscript/gdscript_exports.html)
- [Godot 3.6 @GDScript](https://docs.godotengine.org/en/3.6/classes/class_%40gdscript.html)

Mod Loader：

- [Godot Mod Loader documentation](https://wiki.godotmodding.com/)

NCL 关键源码：

- [`NewContent.gd`](../NewContent.gd)
- [`NewContent.tres`](../NewContent.tres)
- [`mod_main.gd`](../mod_main.gd)
- [`extensions/progress_data.gd`](../extensions/progress_data.gd)
- [`extensions/run_data.gd`](../extensions/run_data.gd)
- [`extensions/utils.gd`](../extensions/utils.gd)
- [`extensions/main.gd`](../extensions/main.gd)
- [`extensions/item_service.gd`](../extensions/item_service.gd)
- [`extensions/weapon_service.gd`](../extensions/weapon_service.gd)
- [`extensions/floating_text_manager.gd`](../extensions/floating_text_manager.gd)

---

<div align="center">

**Yoko-NewContentLoader · 用 Godot Resource 描述内容，通过 Brotato 原生运行时边界扩展游戏。**

</div>
