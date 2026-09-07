# Yoko-NewContentLoader 使用与开发手册

> 面向 Brotato Mod 开发者、Godot 3.x 开发者，以及希望基于 NCL 构建内容型 Mod 的开发者。
>
> **当前基准：NCL 1.1.0 · Brotato 1.15.4 · Brotato Mod Loader 6.3.0 · Godot 3.x / GDScript**

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

官方参考：[Resources](https://docs.godotengine.org/en/3.5/tutorials/scripting/resources.html) · [GDScript exports](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_exports.html)

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

这样可以让 Godot 自己处理 Resource 引用、序列化与 Inspector 编辑。

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

NCL 启动时会：

```text
遍历依赖 Mod
    ↓
查找 class_service.gd
    ↓
调用 get_classes()
    ↓
去重
    ↓
清理失效注册
    ↓
注册有效 Global Class
```

Global Class 名称应该尽量全局唯一。

## 11. End-of-Wave Hook

NCL 的 `Main` 扩展提供：

```text
before_wave_rewards
after_wave_rewards
before_end_run_scene
before_change_scene
```

源码：[extensions/main.gd](../extensions/main.gd)

### 注册

```gdscript
main.ncl_register_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards",
    100
)
```

`priority` 越小越早执行；相同 priority 时再按 method name 排序。不要依赖偶然的注册先后顺序。

### 注销

```gdscript
main.ncl_unregister_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards"
)
```

### Godot 3.x 协程

Hook 可以返回 `GDScriptFunctionState`，NCL 会等待：

```gdscript
yield(result, "completed")
```

官方参考：[GDScript `yield`](https://docs.godotengine.org/en/3.5/classes/class_%40gdscript.html)

例如：

```gdscript
func _on_before_wave_rewards():
    yield(get_tree(), "idle_frame")
    do_something()
```

这非常适合 Wave 生命周期操作，但不应把 Hook 当作所有游戏事件的万能总线。

## 12. Weapon Lookup

NCL 的 ItemService 扩展提供：

```gdscript
ncl_is_weapon_id(weapon_my_id)
ncl_get_weapon_from_id(weapon_my_id)
ncl_rebuild_weapon_my_id_lookup()
```

源码：[extensions/item_service.gd](../extensions/item_service.gd)

高频查询场景下，应优先使用 lookup，而不是反复遍历 `ItemService.weapons`。

## 13. RunData 武器辅助

[`extensions/run_data.gd`](../extensions/run_data.gd) 提供：

```gdscript
RunData.ncl_get_nb_weapon(weapon_my_id_hash, player_index)
RunData.ncl_remove_weapon_by_id(weapon, player_index)
```

按 ID 删除武器时，优先使用 NCL API，以保证后续的 Brotato 原生移除逻辑仍然执行。

## 14. Utils Runtime API

主要 API 位于 [`extensions/utils.gd`](../extensions/utils.gd)：

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

### 14.1 Stat 修改

```gdscript
Utils.ncl_quiet_add_stat(stat_hash, value, player_index)
Utils.ncl_quiet_set_stat(stat_hash, value, player_index)
```

适合内部累计或设置状态值。

### 14.2 Modifier transform

```gdscript
Utils.ncl_curse_effect_value(value, modifier, options)
```

支持 `modifier_scale`、`step`、`process_negative`、`is_negative`、`min_num`、`max_num` 等选项。

### 14.3 Scaling

```gdscript
Utils.ncl_get_scaling_stats_dmg(...)
Utils.ncl_get_dmg_with_scaling_stats(...)
Utils.ncl_get_num_with_scaling_stats(...)
```

用于 `base + stat * scaling` 一类的公式。

### 14.4 武器替换

```gdscript
Utils.ncl_change_weapon_within_run(...)
Utils.ncl_change_weapon_within_shop(...)
```

这些 API 负责同步处理武器槽、tracking、cursed 状态以及商店相关状态，因此不要手工修改多个内部数组。

## 15. 自定义 Damage Number

NCL 扩展 [`extensions/floating_text_manager.gd`](../extensions/floating_text_manager.gd)，识别 `TakeDamageArgs` 中的：

```text
custom_color
custom_icon
```

通过 NCL 创建参数：

```gdscript
Utils.ncl_create_custom_damage_args(
    player_index,
    Color(1, 0.4, 0.2),
    my_icon_hash
)
```

这样可以继续复用 Brotato 原生 Damage Number 显示路径，而不是创建第二套浮字系统。

## 16. Consumable 运行时生成

```gdscript
Utils.ncl_spawn_consumable(
    consumable_id,
    num,
    pos,
    spread
)
```

实现位于 [`extensions/utils.gd`](../extensions/utils.gd)。它优先复用 Brotato 的 consumable pool，只有必要时才创建新的 Scene instance。

## 17. Gear API

NCL 定义统一的 Item / Weapon 操作：

```gdscript
enum GearType {ITEM, WEAPON}

Utils.ncl_judge_item_type_from_my_id(gear_id)
Utils.ncl_get_nb_gear(gear_id, player_index)
Utils.ncl_add_gear_by_id(gear_id, player_index, num)
Utils.ncl_remove_gear_by_id(gear_id, player_index, num)
Utils.ncl_get_gear_name_from_id(gear_id, num)
```

适用于 Debug Tool、事件、任务奖励、成就和转换效果等场景。

## 18. Godot Script Extension

NCL 的核心集成方式不是重写 Brotato，而是通过 Mod Loader 的 Script Extension 在原系统上增加行为。

例如：

```gdscript
extends "res://singletons/run_data.gd"
```

或：

```gdscript
extends "res://singletons/item_service.gd"
```

Godot 3.x 的脚本继承使用 `extends`；覆盖父类方法时，可以用：

```gdscript
var result = .some_func()
```

先保留原逻辑，再叠加你的差异行为。

官方参考：[GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html)

## 19. Add / Remove 生命周期

NCL 的 Resource 生命周期是成对的：

```gdscript
add_resources()
remove_resources()
```

添加阶段会处理：

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
Tracking
Text metadata
Effect Behaviors
```

因此不要简单地：

```gdscript
ItemService.items.append(my_item)
```

然后忘记清理。让 `NewContentData.tres` 成为内容入口，由 NCL 管理注册和卸载。

## 20. 多个 Mod 同时使用 NCL

正常环境：

```text
NCL
 ├── Mod A
 ├── Mod B
 └── Mod C
```

每个 Mod 都可以有自己的 `NewContentData.tres` 和可选的 `NewContentDataDLC1.tres`。

因此 `my_id` 与各类内容 ID 都应该有明确命名空间：

```text
<namespace>_<content_name>
```

例如：

```text
fantasy_prism_tower
fantasy_soul_link
yztato_chisefengbao
```

避免：

```text
sword
boss
item01
```

## 21. Godot Resource 管理规则

### 使用 FileSystem Dock 移动 / 重命名

`.tres` 会保存外部 Resource path。大型项目应优先通过 Godot FileSystem Dock 操作资源。

### 控制 Resource 边界

推荐：

```text
NewContentData.tres
├── CharacterData.tres
├── WeaponData.tres
├── ItemData.tres
└── EffectData.tres
```

而不是生成无法维护的单体 Resource。

### 三类文件的职责

```text
.tres → 数据
.gd   → 行为
.tscn → Scene 组成
```

## 22. 排错顺序

出现“内容不显示”时，不要立即怀疑 NCL。逐层检查：

```text
1. Mod Loader 是否发现 Mod？
2. manifest.json 是否依赖 NCL？
3. NewContentData.tres 是否位于 Mod 根目录？
4. Godot Inspector 能否正常打开？
5. 所有子 Resource 是否有效？
6. 日志是否出现 [NCL] Content report？
7. 是否存在 Duplicate ID？
8. 对应 Brotato Service 是否收到资源？
9. 是否需要额外 Script Extension？
```

重点搜索日志：

```text
[NCL]
Successfully load NewContentData.tres
Successfully load NewContentDataDLC1.tres
Content report: ...
Duplicate ids ...
```

发现与报告逻辑见 [`extensions/progress_data.gd`](../extensions/progress_data.gd)。

## 23. 版本与回归测试

当前基准：

```text
NCL         1.1.0
Brotato     1.15.4
Mod Loader 6.3.0
```

NCL 是基础层，所以每次核心修改都应至少验证：

```text
NCL 自身
↓
一个普通内容 Mod
↓
一个 DLC Mod
↓
一个使用 Runtime Extension 的 Mod
```

重点回归：

```text
ProgressData
RunData
Main
WeaponService
ItemService
Utils
```

## 24. 推荐开发思维

面对一个新功能，先判断：

```text
这是数据还是行为？
        ↓
数据 → Resource
        ↓
NewContentData

行为 → Brotato 所属系统
        ↓
Script Extension / inheritance

生命周期 → Hook
跨 Run 状态 → RunData tracking
通用算法 → Utils
```

NCL 最重要的价值不是“帮你自动注册几个数组”，而是给大型 Mod 一个稳定的内容入口、生命周期边界与共享运行时层。

## 25. 最小完整示例

```text
MyDemoMod/
├── manifest.json
├── NewContentData.tres
└── content/
    ├── characters/demo_character_data.tres
    ├── weapons/demo_weapon_data.tres
    └── items/demo_item_data.tres
```

`manifest.json`：

```json
{
  "name": "DemoMod",
  "namespace": "Demo",
  "version_number": "1.0.0",
  "dependencies": [
    "Yoko-NewContentLoader"
  ]
}
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
```

启动后：

```text
NCL discovery
    ↓
load NewContentData.tres
    ↓
register Character / Weapon / Item
    ↓
initialize tracking / pools / lookup
```

## 26. 参考资料

### Godot 3.x

- [Resources](https://docs.godotengine.org/en/3.5/tutorials/scripting/resources.html)
- [GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html)
- [GDScript Exports](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_exports.html)
- [GDScript / yield](https://docs.godotengine.org/en/3.5/classes/class_%40gdscript.html)

### Mod Loader

- [Godot Mod Loader documentation](https://wiki.godotmodding.com/)

### NCL 源码

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
