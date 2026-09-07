# Yoko-NewContentLoader 使用与开发手册

> 面向 Brotato Mod 开发者、Godot 3.x 开发者，以及希望基于 NCL 构建内容型 Mod 的开发者。
>
> **当前基准：NCL 1.1.0 · Brotato 1.15.4 · Brotato Mod Loader 6.3.0 · Godot 3.x / GDScript**
>
> 本文不是单纯的 API 列表。它同时解释 Godot `Resource` / `.tres`、Inspector、脚本继承、Mod Loader Script Extension，以及 NCL 如何把内容接入 Brotato 原生服务。具体 API 行为以当前仓库源码为最终依据。

<div align="center">

### 📖 English version

[Read the English developer guide →](USAGE.en.md)

</div>

## 1. 先理解 NCL：它到底解决什么问题

`Yoko-NewContentLoader` 不是独立玩法 Mod，也不是只负责把几个 `.tres` 文件读取进内存的普通文件加载器。它是一个**共享内容基础设施层**：依赖 NCL 的 Mod 使用 Godot `Resource` 描述内容，NCL 负责发现这些 Mod、读取内容资源、处理 DLC 内容、合并资源、注册到 Brotato 原有服务、提供卸载流程，并提供一组可以被不同 Mod 复用的运行时扩展与工具。

核心路径：

```text
Godot Editor
    │
    │ Resource / .tres
    ▼
Your Mod
    │
    ├── manifest.json
    ├── NewContentData.tres
    ├── NewContentDataDLC1.tres   (可选)
    ├── content/**/*.tres
    ├── translations/*.translation
    └── extensions/*.gd
    │
    ▼
Yoko-NewContentLoader
    │
    ├── 自动发现依赖 Mod
    ├── 基础内容加载
    ├── DLC 内容检测与合并
    ├── Resource 注册 / 卸载
    ├── Global Class 发现与清理
    ├── Brotato Script Extension
    └── Runtime helper API
    │
    ▼
Brotato 原生服务
    │
    ├── ItemService
    ├── ZoneService
    ├── ChallengeService
    ├── RunData
    ├── ProgressData
    ├── WeaponService
    ├── Main
    ├── EffectBehaviorService
    └── TranslationServer / Text
```

### 为什么采用这个边界？

Brotato 本身已经存在角色、武器、物品、效果、区域、挑战、DLC、RunData、ProgressData 等运行时结构。NCL 不再复制一套平行数据库，而是在这些已有边界之上提供统一的 Mod 接入层。

这套设计的三个直接收益是：

1. **Godot Resource 原生工作流。** Resource 可以在 Inspector 中编辑并保存为 `.tres`；Godot 支持 Resource 递归引用、自动序列化和版本控制友好的文本 Resource。citeturn479829search2turn479829search5
2. **沿用游戏自己的数据边界。** 内容最终还是进入 Brotato 的 ItemService、ZoneService、RunData 等系统，不需要另造一份平行数据结构。
3. **基础能力集中复用。** 多个 Mod 可以共享 NCL 的发现、注册、卸载、DLC 分层、tracking、Hook 和工具函数。

> **兼容性边界：** NCL 沿用游戏已有 DLC、ProgressData 和 Service 边界，通常比每个 Mod 自己实现注册体系更容易维护；但这并不意味着跨任意 Brotato 版本或任意 Mod 组合绝对兼容。底层 API 变化、资源 ID 冲突以及多个 Mod 同时修改同一运行时服务仍可能造成冲突。

---

## 2. 五分钟接入一个新 Mod

这是普通内容 Mod 最推荐的接入方式。

### 2.1 声明依赖

在 `manifest.json` 添加：

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

NCL 会遍历 Mod Loader 发现的 Mod，并只对 manifest 明确声明依赖 NCL 的项目做内容发现。当前源码通过 `mod_data.manifest.dependencies` 检查这一点。fileciteturn39file0

### 2.2 准备 Godot Resource

推荐：

```text
MyMod/
├── manifest.json
├── NewContentData.tres
├── content/
│   ├── characters/
│   ├── weapons/
│   ├── items/
│   ├── effects/
│   ├── entities/
│   ├── maps/
│   └── zones/
├── translations/
└── extensions/
```

目录名可以按你的项目习惯调整；真正重要的是 Resource 能被 `NewContentData.tres` 正确引用。

Godot 3.x 中的 `export(Array, Resource)` 会让数组暴露在 Inspector 中，因此你可以把 `.tres` 资源直接拖入数组字段。citeturn479829search6

### 2.3 从 `NewContent.tres` 开始

NCL 仓库提供 `NewContent.tres` 作为模板。当前模板使用 `NewContent.gd`，并已经序列化了各种内容数组字段。fileciteturn46file0

推荐复制为：

```text
NewContentData.tres
```

然后在 Godot Inspector 里编辑。

### 2.4 在 Inspector 里拖入资源

例如：

```text
content/characters/demo_character_data.tres
content/weapons/demo_weapon_data.tres
content/items/demo_item_data.tres
```

Inspector：

```text
NewContentData.tres
  Characters  → demo_character_data.tres
  Weapons     → demo_weapon_data.tres
  Items       → demo_item_data.tres
```

这就是 NCL 最核心的使用方式。

### 2.5 通常不要手动调用 `add_resources()`

普通依赖 Mod 不应该在自己的初始化代码里反复执行：

```gdscript
content.add_resources()
```

NCL 的推荐模式是：

```text
manifest dependency
        ↓
NCL discovery
        ↓
load NewContentData.tres
        ↓
merge if necessary
        ↓
register into Brotato services
```

`ProgressData` 扩展会自动发现依赖 NCL 的 Mod 并读取内容资源。fileciteturn39file0

手动调用 `add_resources()` 更适合你需要完全自定义生命周期的高级场景，而不是标准内容 Mod。

---

## 3. Godot Resource：为什么 NCL 选择 `.tres`

如果第一次使用 NCL，首先要理解 Godot 的 `Resource`。

### 3.1 Node 与 Resource

可以先这样理解：

```text
Node
→ 场景中的实例 / 行为载体

Resource
→ 可保存、可复用的数据对象
```

Godot 官方把 Resource 定义为数据容器；纹理、脚本、动画、翻译、场景等都是 Resource，开发者也可以自己写 `extends Resource` 的脚本并保存为 `.tres`。citeturn479829search2

NCL 因此天然适合这种结构：

```text
CharacterData.tres
WeaponData.tres
ItemData.tres
EffectData.tres
ZoneData.tres
Translation
       ↓
NewContentData.tres
       ↓
NCL
```

### 3.2 为什么不直接使用 JSON

因为 Brotato 内容并不是只有数字和字符串，大量字段会引用其他 Godot Resource：

```text
WeaponData
 ├── icon      → Texture
 ├── effects   → Effect Resource[]
 ├── stats     → WeaponStats Resource
 ├── scene     → PackedScene
 └── ...
```

Godot Resource 可以递归保存子 Resource，Inspector 也可以直接编辑资源引用。citeturn479829search2

JSON 更适合交换数据；`.tres` 更适合描述 Godot 游戏内部资源图。

### 3.3 为什么 `.tres` 很适合 Git

`.tres` 是文本 Resource 序列化格式，适合 Git diff；同时 Godot Editor 可以直接从 FileSystem Dock 打开并通过 Inspector 修改。citeturn479829search2

大型 Mod 推荐：

```text
一个角色 = 一个 CharacterData.tres
一个武器 = 一个 WeaponData.tres
一个道具 = 一个 ItemData.tres
一个效果 = 一个 EffectData.tres
```

再用 `NewContentData.tres` 做聚合，而不是维护一个巨型脚本。

---

# 4. NewContent 全字段

下面按照当前 `NewContent.gd` 的实际字段说明。

## 4.1 `my_id`

```gdscript
export(String) var my_id
```

标识一整个内容集合。NCL 会据此生成 `my_id_hash`。

建议直接使用 Mod namespace：

```text
YzTato
Fantasy
MyExpansion
```

不要让不同逻辑集合长期共用同一 ID。

## 4.2 `groups_in_all_zones`

```gdscript
export(Array, Resource) var groups_in_all_zones = []
```

用于把指定组资源注入所有相关 Zone 数据。

典型用途包括全局敌人组、内容组以及需要在所有区域可用的特殊分组。

## 4.3 `music_tracks`

```gdscript
export(Array, Resource) var music_tracks = []
```

注册音乐相关 Resource。音频文件本身仍由 Godot 导入系统管理，NCL 只负责把对应 Resource 交给游戏内容系统。

推荐：

```text
content/music/
├── battle_01.ogg
└── shop_01.ogg
```

## 4.4 `backgrounds`

```gdscript
export(Array, Resource) var backgrounds = []
```

注册背景，并在添加阶段把背景注入现有 Zone 的 `default_backgrounds`；卸载时反向移除。fileciteturn34file0

因此不需要给每个 Zone 手写一遍背景注入逻辑。

## 4.5 `characters`

```gdscript
export(Array, Resource) var characters = []
```

最终加入：

```gdscript
ItemService.characters
```

正确思路：

```text
CharacterData.tres
        ↓
NewContentData.tres / characters
        ↓
NCL
        ↓
ItemService.characters
```

NCL 不重新定义角色系统；角色 Resource 仍然遵循 Brotato 自己的角色数据结构。

## 4.6 `entities`

```gdscript
export(Array, Resource) var entities = []
```

注册普通 Entity Resource，例如宠物、炮台、特殊实体和地图实体。

## 4.7 `elites` / `bosses`

```gdscript
export(Array, Resource) var elites = []
export(Array, Resource) var bosses = []
```

注册 Elite 与 Boss。

复杂运行时行为应放进相应脚本，而不是把所有逻辑塞进 `NewContent.gd`。

## 4.8 `stats`

```gdscript
export(Array, Resource) var stats = []
```

注册额外 Stat Resource。

注册后 NCL 会重新生成 stat hash，并执行 `Utils.reset_stat_keys()`。fileciteturn34file0

因此不要再为同一个 Stat 系统维护第二套初始化逻辑。

## 4.9 `items`

```gdscript
export(Array, Resource) var items = []
```

注册 Item Resource。

推荐：

```text
content/items/my_item/
├── my_item_data.tres
└── icon.png
```

由 `.tres` 引用图标等 Resource。

## 4.10 `weapons`

```gdscript
export(Array, Resource) var weapons = []
```

注册 Weapon Resource，同时 NCL 建立基于 `my_id_hash` 的 Weapon lookup。fileciteturn38file0

### Starting Weapon

如果 WeaponData 设置了 `add_to_chars_as_starting`，NCL 会自动将该武器添加到对应角色的 `starting_weapons`，并避免重复；卸载时会反向移除。fileciteturn34file0

## 4.11 `effects`

```gdscript
export(Array, Resource) var effects = []
```

注册 Effect Resource。

需要动态行为时配合 Effect Behavior 使用。

## 4.12 `consumables`

```gdscript
export(Array, Resource) var consumables = []
```

注册 Consumable。

此外，NCL 扩展 `ItemService.get_consumable_to_drop()`，允许启用的 DLC 数据通过 `ncl_update_consumable_to_get()` 进一步改变掉落结果。fileciteturn38file0

## 4.13 `upgrades`

注册升级 Resource。建议 Resource 自身描述升级文本 Key、图标、效果与数值，NCL 只负责注册。

## 4.14 `sets`

注册 Set Resource。复杂套装逻辑不要硬编码到 NCL。

## 4.15 `difficulties`

注册 Difficulty Resource，可用于新难度或 Mod 专属难度。

## 4.16 `icons`

注册游戏内部 Icon Resource。注册后的 Icon 也可以被 NCL 自定义伤害飘字系统引用。

## 4.17 `title_screen_backgrounds`

注册标题画面背景 Resource。

## 4.18 `translations`

```gdscript
export(Array, Translation) var translations
```

这里是强类型 `Translation` 数组，而不是通用 `Resource`。

NCL 加载时调用：

```gdscript
TranslationServer.add_translation(translation)
```

卸载时调用对应的 `remove_translation()`。fileciteturn34file0

推荐：

```text
translations/
├── MyMod.en.translation
├── MyMod.zh.translation
└── MyMod.ja.translation
```

然后把它们拖进 `translations`。

## 4.19 `challenges`

注册 Challenge，并刷新 stat challenge 数据：

```gdscript
ChallengeService.challenges
ChallengeService.set_stat_challenges()
```

卸载时 NCL 会反向清理。fileciteturn34file0

## 4.20 `zones`

注册 Zone 到：

```gdscript
ZoneService.zones
```

因此新地图仍然是 Brotato 自己的 Zone 数据，NCL 只是统一处理生命周期。

---

# 5. Tracking：`tracked_items` 与 `tracked_effects`

NCL 不只是注册“静态内容”，还可以把运行过程中的统计项接到 Brotato 的 RunData 生命周期。

## 5.1 `tracked_items`

```gdscript
export(Dictionary) var tracked_items = {}
```

加载时会转换成 hash dictionary 并合并到 `RunData.init_tracked_items`。

推荐理解：

```text
NewContentData
    ↓
tracking schema
    ↓
RunData initialization
    ↓
运行时计数
```

## 5.2 `tracked_effects`

```gdscript
export(Dictionary) var tracked_effects = {}
```

NCL 将其转成 hash 后加入 `RunData.ncl_init_tracked_effects`；RunData 扩展会为四个玩家槽位建立 tracking state。fileciteturn40file0

运行时：

```gdscript
RunData.ncl_add_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_set_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_get_effect_tracking_value(key_hash, player_index)
```

如果对应 value 是 Array，可以使用额外的 `index` 参数操作具体元素。fileciteturn40file0

推荐把跨 Wave、跨菜单以及需要随 Run 状态恢复的统计放这里，而不是另建一个永不保存的全局 Dictionary。

---

# 6. `primary_stats_list`

```gdscript
export(Array, String) var primary_stats_list = []
```

用于向 `RunData.primary_stats_list` 注册额外主要 Stat Key。

例如：

```text
my_custom_stat
my_other_stat
```

NCL 会把这些 String 转换成 hash 后追加到运行时列表。fileciteturn34file0

适合自定义职业、角色或 UI 中需要把某 Stat 作为“主要属性”的项目。

---

# 7. Effect Serialization Keys

```gdscript
export(Array, String) var effect_keys_full_serialization = []
export(Array, String) var effect_keys_with_weapon_stats = []
```

当一个自定义 Effect 的数据需要参与 Brotato 对应的保存/恢复结构时，应把对应 key 统一登记在 NCL 的序列化列表里。

思路是：

```text
自定义 Effect
    ↓
Effect 有需要保存的自定义 key
    ↓
在 NewContentData 中登记
    ↓
RunData 序列化逻辑知道它
```

不要把相同 key 的处理散落在多个 Mod 脚本中。

---

# 8. 文本处理：operator / percent

```gdscript
export(Dictionary) var translation_keys_needing_operator = {}
export(Dictionary) var translation_keys_needing_percent = {}
```

加载时合并到：

```gdscript
Text.keys_needing_operator
Text.keys_needing_percent
```

卸载时反向清理。fileciteturn34file0

如果你的描述文本包含复杂运算符、百分比或动态统计，不要先在每个 Item/Effect 中硬拼字符串；先检查 Brotato 的 Text 体系能否通过这些注册表表达。

---

# 9. Effect Behavior：Data 与 Behavior 分离

三个字段：

```gdscript
export(Array, Resource) var scene_effect_behaviors = []
export(Array, Resource) var enemy_effect_behaviors = []
export(Array, Resource) var player_effect_behaviors = []
```

NCL 的设计是：

```text
Resource = 描述“是什么”
Behavior = 描述“运行时怎么做”
```

加载时加入 `EffectBehaviorService`，卸载时移除。fileciteturn34file0

这意味着一个复杂 Effect 可以拆成：

```text
MyEffectData.tres
MyEffectBehavior.gd
```

而不是让 `NewContent.gd` 变成一个“大总管”。

---

# 10. DLC：NCL 最重要的扩展边界之一

## 10.1 基础内容与 DLC 内容

当前 `ProgressData` 扩展定义了：

```gdscript
var mod_content_configs = [
    ["NewContentData.tres", "", ""],
    ["NewContentDataDLC1.tres", "res://dlcs/dlc_1/dlc_data.tres", "abyssal_terrors"]
]
```

所以一个依赖 NCL 的 Mod 可以同时提供：

```text
NewContentData.tres
NewContentDataDLC1.tres
```

当 `abyssal_terrors` DLC 不可用时，DLC1 内容会被跳过。fileciteturn39file0

## 10.2 为什么使用游戏自己的 DLC 边界

不推荐每个 Mod 自己做：

```text
判断 DLC 是否购买
判断 DLC 是否加载
判断哪些资源可用
自己维护 fallback
```

推荐：

```text
Base NewContent
      +
DLC NewContent
      ↓
NCL
      ↓
Brotato ProgressData / DLC
```

NCL 的目标是让内容继续沿着游戏自己已有的 DLC / ProgressData 路径进入运行时。

## 10.3 两份 Resource 如何合并

如果基础内容和 DLC1 内容都存在，NCL 会复制基础 Resource，并按属性类型自动合并：

```text
Array      → 第二份追加到第一份
Dictionary → 第二份 merge，允许覆盖同 key
其它类型   → 使用 DLC 内容
```

对应源码：`ncl_merge_arrays()`、`ncl_merge_dictionaries()`、`ncl_auto_merge_property()`。fileciteturn39file0

因此应把 DLC1 设计成：

```text
基础内容的增量层
```

而不是完全独立的第二个 Mod。

---

# 11. 一个完整的 DLC Godot 工作流

```text
MyMod/
├── manifest.json
├── NewContentData.tres
├── NewContentDataDLC1.tres
└── content/
    ├── characters/
    │   ├── base_character_data.tres
    │   └── dlc_character_data.tres
    └── weapons/
        ├── base_weapon_data.tres
        └── dlc_weapon_data.tres
```

基础内容：

```text
NewContentData.tres
  Characters → base_character_data.tres
  Weapons    → base_weapon_data.tres
```

DLC 内容：

```text
NewContentDataDLC1.tres
  Characters → dlc_character_data.tres
  Weapons    → dlc_weapon_data.tres
```

运行时：

```text
DLC 可用
   ↓
Base + DLC1
   ↓
merged NewContent
```

DLC 不可用：

```text
Base only
```

用户不需要手动修改你的内容表。

---

# 12. Global Class：`extensions/services/class_service.gd`

NCL 还能帮助依赖项目管理自定义 Global Class。

## 12.1 为什么需要它

Godot 的自定义类型可以让 Resource/Node 真正成为一个明确的类，而不是仅仅“挂了一个脚本”。

典型关系：

```text
RangedWeaponStats
       ↑
       │ extends
       │
DotStructureWeaponStats
```

## 12.2 约定的文件

```text
YourMod/extensions/services/class_service.gd
```

并暴露：

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

真实的 `Yoko-YzTato` 就采用了这一格式。fileciteturn56file0

## 12.3 NCL 的处理流程

```text
遍历 Mod
    ↓
检查 dependencies
    ↓
查找 class_service.gd
    ↓
调用 get_classes()
    ↓
收集所有 Class metadata
    ↓
去重
    ↓
清理已经失效的 _global_script_classes
    ↓
注册新 Class
```

NCL 同时检查类脚本路径是否仍然存在，并清理失效注册。fileciteturn36file0

### 注意

Global Class 名称必须尽可能全局唯一。建议：

```text
YokoFantasyHolyEffect
YzTatoDotStructureWeaponStats
```

而不是：

```text
HolyEffect
WeaponStats
```

---

# 13. End-of-Wave Hook

NCL 扩展 `Main._on_EndWaveTimer_timeout()`，提供四个明确的 Wave 生命周期节点：

```text
before_wave_rewards
after_wave_rewards
before_end_run_scene
before_change_scene
```

源码常量：

```gdscript
NCL_END_WAVE_BEFORE_REWARDS
NCL_END_WAVE_AFTER_REWARDS
NCL_END_WAVE_BEFORE_END_RUN_SCENE
NCL_END_WAVE_BEFORE_CHANGE_SCENE
```

fileciteturn37file0

## 13.1 注册

```gdscript
main.ncl_register_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards",
    100
)
```

参数：

```text
hook_name   Hook 名称
owner       承载 callback 的 Object
method_name 要执行的方法
priority    优先级，数字越小越早
```

NCL 按 priority 排序；相同 priority 再按 method name 排序。不要把“注册先后”当作隐式优先级。fileciteturn37file0

## 13.2 注销

```gdscript
main.ncl_unregister_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards"
)
```

## 13.3 Godot 3.x 协程支持

Hook 可以返回 `GDScriptFunctionState`。NCL 会等待：

```gdscript
yield(result, "completed")
```

Godot 3.x 的 `yield()` 可以等待信号，也可以等待另一个 yield 函数通过 `completed` 信号结束。citeturn479829search3turn479829search4

例如：

```gdscript
func _on_before_wave_rewards():
    yield(get_tree(), "idle_frame")
    do_something()
```

适合：

```text
奖励前处理
奖励后处理
Run 结束前处理
切换 Scene 前处理
```

不适合拿来替代普通游戏事件系统。

---

# 14. Weapon Lookup

NCL 的 `ItemService` 扩展维护：

```gdscript
var ncl_weapon_my_id_lookup: Dictionary = {}
```

提供：

```gdscript
ncl_is_weapon_id(weapon_my_id)
ncl_get_weapon_from_id(weapon_my_id)
ncl_rebuild_weapon_my_id_lookup()
```

fileciteturn38file0

推荐：

```gdscript
var weapon = ItemService.ncl_get_weapon_from_id(weapon_id_hash)
```

不要在高频路径中反复遍历 `ItemService.weapons`。

---

# 15. RunData：Tracking、武器数量与删除

NCL 扩展 `RunData` 的 reset、state save、resume 等路径，用于维护 NCL 自己的 tracking 状态。fileciteturn40file0

### 获取武器数量

```gdscript
RunData.ncl_get_nb_weapon(weapon_my_id_hash, player_index)
```

### 按 ID 删除武器

```gdscript
RunData.ncl_remove_weapon_by_id(weapon, player_index)
```

该路径会进一步调用 `after_weapon_removed()`，因此优先使用它而不是直接操作玩家武器 Array。

---

# 16. Utils Runtime API

当前 `extensions/utils.gd` 提供的主要 `ncl_*` API：

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

源码可直接参考 [`extensions/utils.gd`](../extensions/utils.gd)。fileciteturn43file0

## 16.1 `ncl_quiet_add_stat`

```gdscript
Utils.ncl_quiet_add_stat(stat_hash, value, player_index)
```

直接修改玩家 stat effect，标记 dirty 并重置 stat cache，适合后台累计值。fileciteturn43file0

## 16.2 `ncl_quiet_set_stat`

```gdscript
Utils.ncl_quiet_set_stat(stat_hash, value, player_index)
```

与上者类似，但设置绝对值。

## 16.3 `ncl_curse_effect_value`

```gdscript
Utils.ncl_curse_effect_value(value, modifier, options)
```

支持：

```text
modifier_scale
step
process_negative
is_negative
min_num
max_num
```

内部根据正负与选项决定乘法或除法，然后执行 `stepify` 和上下限限制。fileciteturn43file0

虽然名字来自 Curse 系统，但本质上是一个可复用的 modifier transform helper。

## 16.4 Scaling Stats

```gdscript
Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index)
Utils.ncl_get_dmg_with_scaling_stats(base_damage, scaling_stats, player_index)
Utils.ncl_get_num_with_scaling_stats(base_num, scaling_stats, player_index)
```

用于：

```text
基础值 + Stat × scaling
```

避免每个 Mod 重写相同数学逻辑。

## 16.5 Damage / Number 文本

```gdscript
Utils.ncl_get_dmg_text_with_scaling_stats(...)
Utils.ncl_get_num_text_with_scaling_stats(...)
```

这些函数可以同时表达：

```text
最终值
原始值
数量
Scaling Stat 图标文本
正负变化颜色
```

fileciteturn43file0

## 16.6 Range Scaling

```gdscript
Utils.ncl_get_range_with_detection(...)
Utils.ncl_get_range_text_with_scaling(...)
```

用于基础 Range、Range Stat scaling 和 detection 三者的组合。

## 16.7 Weapon 动态替换

```gdscript
Utils.ncl_change_weapon_within_run(...)
Utils.ncl_change_weapon_within_shop(...)
```

分别处理战斗中的 Weapon 替换和商店中的 Weapon 替换。

内部会同步处理 weapon slot、`tracked_value`、cursed weapon 状态、Shop 刷新等细节，因此优先使用这些 API，而不要自己修改多个内部数组。fileciteturn43file0

---

# 17. 自定义 Damage Number

NCL 扩展 `FloatingTextManager`，识别 `TakeDamageArgs` metadata：

```text
custom_color
custom_icon
```

然后沿用 Brotato 原生 damage display。fileciteturn42file0

创建参数：

```gdscript
var args = Utils.ncl_create_custom_damage_args(
    player_index,
    Color(1, 0.4, 0.2),
    my_icon_hash
)
```

思路：

```text
你的伤害逻辑
      ↓
TakeDamageArgs
      ↓
NCL FloatingTextManager
      ↓
Brotato 原生 Damage Number
```

这样不需要创建第二套 Damage Number Node。

---

# 18. Consumable 运行时生成

```gdscript
Utils.ncl_spawn_consumable(
    consumable_id,
    num,
    pos,
    spread
)
```

该函数优先使用 Brotato 的 consumable pool；只有没有可复用实例时才创建 Scene instance，并设置对应数据、Texture、位置与落点。fileciteturn44file0

这正是 NCL “尽可能复用游戏已有对象池和 Scene 生命周期”的设计。

---

# 19. Gear API：统一处理 Item / Weapon

NCL 定义：

```gdscript
enum GearType {ITEM, WEAPON}
```

并提供：

```gdscript
Utils.ncl_judge_item_type_from_my_id(gear_id)
Utils.ncl_get_nb_gear(gear_id, player_index)
Utils.ncl_add_gear_by_id(gear_id, player_index, num)
Utils.ncl_remove_gear_by_id(gear_id, player_index, num)
Utils.ncl_get_gear_name_from_id(gear_id, num)
```

源码会自动判断 ID 属于 Item 还是 Weapon，然后路由到正确的 `ItemService` / `RunData` API。fileciteturn44file0

特别适合：

```text
Debug Menu
任务奖励
职业系统
事件
成就
转换型技能
```

例如：

```gdscript
Utils.ncl_add_gear_by_id(my_weapon_id, player_index, 1)
```

---

# 20. `ncl_get_true_stat_name`

```gdscript
Utils.ncl_get_true_stat_name(stat)
```

用于把内部 stat key 转换成最终显示名。

源码对 `EMPTY`、`number_of_enemies`、`different_item` 等特殊情况做映射，其余 key 会转为对应的翻译 key。fileciteturn44file0

适合 UI、Debug Tool 和自动生成文本。

---

# 21. Composite Hash

```gdscript
Utils.ncl_generate_composite_hash(values)
```

使用固定 prime `31` 逐项生成组合 hash。fileciteturn43file0

适合内部稳定的组合身份值。

---

# 22. DLC Runtime Script Extension

除了 `NewContentDataDLC1.tres`，依赖 Mod 还可以提供：

```text
extensions/dlc_1_data.gd
```

并继承 Brotato 原生 DLC 数据脚本。

例如 `Yoko-YzTato`：

```gdscript
extends "res://dlcs/dlc_1/dlc_1_data.gd"
```

然后覆盖 `curse_item()`，并先调用父逻辑再叠加自己的效果。fileciteturn48file0

Godot 3.x 支持脚本继承；父类同名方法可以使用：

```gdscript
.some_func()
```

调用。citeturn479829search0

NCL 会检测依赖 Mod 是否存在 `extensions/dlc_1_data.gd`，如果存在则通过 `install_script_extension()` 安装。fileciteturn39file0

---

# 23. NCL 自己是怎么启动的？

`mod_main.gd` 初始化时：

```text
获取所有 ModData
        ↓
确定 NCL unpacked directory
        ↓
install_script_classes()
        ↓
install_script_extensions()
```

当前安装的 NCL Script Extension 包括：

```text
progress_data.gd
run_data.gd
utils.gd
main.gd
weapon_service.gd
floating_text_manager.gd
item_service.gd
```

fileciteturn36file0

这就是为什么你的 Mod 不需要再次安装这些 NCL 扩展。

---

# 24. 多个 Mod 共享 NCL

典型运行环境：

```text
NCL
 ├── Mod A
 ├── Mod B
 └── Mod C
```

每个依赖 Mod 都可以拥有自己的：

```text
NewContentData.tres
```

以及可选：

```text
NewContentDataDLC1.tres
```

NCL 分别加载、合并，再把资源加入 Brotato 服务。

所以 ID 设计必须跨 Mod 可区分。

NCL 会生成 Content Report，并对部分内容数组检查重复 `my_id`，发现重复时写入错误日志。fileciteturn39file0

### 推荐 ID

```text
<namespace>_<content_name>
```

例如：

```text
fantasy_prism_tower
fantasy_soul_link
yztato_chisefengbao
```

不要使用过于通用的：

```text
sword
boss
item01
```

---

# 25. Godot Inspector：推荐的生产工作流

大型 NCL Mod 最推荐的数据驱动流程：

```text
Resource Script
      ↓
export properties
      ↓
Godot Inspector
      ↓
保存 .tres
      ↓
NewContentData.tres 聚合
      ↓
运行 Brotato
```

Godot 的 exported property 会被序列化到 Resource/Scene，并可在 Inspector 编辑。citeturn479829search6

例如：

```gdscript
extends Resource

export(String) var display_name = ""
export(int) var base_value = 0
export(Array, Resource) var effects = []
```

Inspector：

```text
Display Name  [ ... ]
Base Value    [ ... ]
Effects       [Array]
              ├── Effect A
              └── Effect B
```

这比把大量数值硬编码进 GDScript 更适合长期维护。

---

# 26. `.tres` 外部引用注意事项

### 26.1 使用 Godot FileSystem Dock 管理移动

`.tres` 中会保存外部 Resource path。如果直接在操作系统文件管理器移动文件，引用有可能失效。

推荐在 Godot FileSystem Dock 内移动 / 重命名资源。

### 26.2 大型项目尽量拆分 external `.tres`

推荐：

```text
NewContentData.tres
    ↓
CharacterData.tres
WeaponData.tres
ItemData.tres
EffectData.tres
```

而不是把全部子资源都内嵌进一份巨大 Resource。

Godot 支持递归子 Resource，但大型项目应该主动控制资源边界。citeturn479829search2

---

# 27. Godot Script Extension：为什么 NCL 能“扩展游戏自己”

NCL 大量使用：

```gdscript
extends "res://singletons/run_data.gd"
```

或：

```gdscript
extends "res://singletons/item_service.gd"
```

这不是复制系统，而是通过 Godot 脚本继承与 Mod Loader Script Extension 把新行为挂在原有服务上。

Godot 3.x 支持 `extends` 继承脚本，并允许通过 `.method()` 调用父级同名函数。citeturn479829search0

这种模式的意义是：

```text
Brotato 原系统
      ↑
Script Extension
      ↑
NCL
      ↑
你的 Mod
```

而不是：

```text
Brotato 系统
      ×
完全重写一套 NCL 系统
```

对兼容性尤其重要：扩展时应尽可能调用父实现，仅增加你的差异逻辑。

---

# 28. 添加 / 卸载生命周期为什么成对出现

NCL 的核心生命周期是：

```gdscript
add_resources()
remove_resources()
```

添加阶段包含：

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

卸载阶段逐项反向移除，然后重新初始化 unlocked pool 与 weapon lookup。fileciteturn34file0

因此不要直接：

```gdscript
ItemService.items.append(my_item)
```

再把清理工作遗忘。

优先使用：

```text
NewContentData.tres → items
```

让 NCL 成为统一生命周期管理器。

---

# 29. 推荐的大型 Mod 目录结构

```text
MyMod/
├── manifest.json
├── README.md
├── LICENSE
│
├── NewContentData.tres
├── NewContentDataDLC1.tres
│
├── content/
│   ├── characters/
│   ├── weapons/
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
│
├── translations/
│   ├── MyMod.en.translation
│   ├── MyMod.zh.translation
│   └── MyMod.ja.translation
│
└── extensions/
    ├── services/
    │   └── class_service.gd
    ├── dlc_1_data.gd
    ├── effects/
    └── systems/
```

可以把它理解成：

```text
content/       → 资源数据
extensions/    → 运行时行为 / 游戏集成
translations/  → 文本
NewContentData → 内容入口聚合
manifest       → Mod Loader / 生态元数据
```

---

# 30. 常见错误

## 30.1 没声明依赖

症状：`NewContentData.tres` 存在，但 NCL 完全不处理它。

检查：

```json
"dependencies": ["Yoko-NewContentLoader"]
```

## 30.2 内容文件名错误

默认发现路径是：

```text
NewContentData.tres
NewContentDataDLC1.tres
```

不要随意改成：

```text
content.tres
NewData.tres
```

除非你同时改变 NCL 的发现逻辑。

## 30.3 Duplicate ID

关注：

```text
[NCL] Duplicate ids ...
```

检查你的 Mod 以及与它一起启用的其它 NCL Mod。

## 30.4 把所有逻辑塞进 Resource

Resource 用于描述数据；复杂动态行为应进入：

```text
extensions/
Effect Behavior
Scene Script
```

## 30.5 直接操作全局数组

不要把：

```gdscript
ItemService.items.append(...)
```

当成默认方式。

让 NCL 负责注册和卸载。

## 30.6 覆盖父脚本但不调用父实现

如果必须保留 Brotato 原逻辑：

```gdscript
func some_func():
    var result = .some_func()
    # add your behavior
    return result
```

这也是 NCL 自己大量使用的扩展模式。citeturn479829search0

---

# 31. 日志：如何知道 NCL 是否成功工作

重点搜索 Mod Loader 日志中的：

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

检查 manifest 是否声明 NCL。

### `NewContentData.tres not found`

检查文件名和 Mod 根目录位置。

### `DLC ... not available`

DLC 不可用，DLC 内容被主动跳过。这是正常的兼容路径。

### `Duplicate ids`

检查 `my_id`。

这些日志来自 `progress_data.gd` 的内容发现、合并和报告逻辑。fileciteturn39file0

---

# 32. 内容不显示时的正确排查顺序

```text
① Mod Loader 是否发现你的 Mod？
        ↓
② manifest.dependencies 是否包含 NCL？
        ↓
③ NewContentData.tres 是否存在？
        ↓
④ Godot Inspector 是否可以正常打开 Resource？
        ↓
⑤ 子 Resource 是否全部能打开？
        ↓
⑥ NCL Content Report 是否出现？
        ↓
⑦ 是否有 Duplicate ID？
        ↓
⑧ Brotato 对应 Service 是否已经接收到资源？
        ↓
⑨ 是否需要额外 Runtime Script Extension？
```

这样可以把：

```text
Godot 资源问题
NCL 注册问题
Brotato Runtime 问题
```

逐层分离。

---

# 33. 版本与兼容性

当前 manifest：

```text
NCL version       1.1.0
Brotato           1.15.4
Mod Loader        6.3.0
Dependencies      none
```

fileciteturn47file0

NCL 是基础层，因此升级后的测试强度应高于普通内容 Mod。

建议回归矩阵：

```text
NCL 自身
  ↓
至少一个内容型 Mod
  ↓
至少一个 DLC 型 Mod
  ↓
至少一个大量使用 extensions 的 Mod
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

因为这些都是当前 NCL 的核心 Script Extension。fileciteturn36file0

---

# 34. 什么时候应该使用 NCL？

非常适合：

```text
✔ 大量角色 / 武器 / 道具的内容 Mod
✔ 自定义 Effect 较多的 Mod
✔ 需要 DLC 分层内容的 Mod
✔ 需要 RunData tracking
✔ 需要 Global Class
✔ 需要 Wave 生命周期 Hook
✔ 需要跨多个系统复用工具
✔ 需要复用 Brotato 原生 Service
✔ 需要长期维护的中大型 Mod
```

不一定需要：

```text
△ 极小的单文件 UI Patch
△ 只改一个数值
△ 完全不添加 Resource 内容的小型补丁
```

NCL 的价值随着内容量、运行时扩展数量和多人协作规模增加而增长。

---

# 35. 正确的 NCL 开发思维

遇到一个新需求时，先问：

```text
我要添加的是“数据”还是“行为”？
          ↓
数据 → Godot Resource
          ↓
放入 NewContentData
          ↓
行为 → 找 Brotato 的所属系统
          ↓
优先 Script Extension / extends
          ↓
生命周期需求 → Hook
          ↓
跨 Run 状态 → RunData tracking
          ↓
通用算法 → Utils
```

不要反过来：

```text
先写一个巨大的 Manager
       ↓
再强行把 Brotato 塞进去
```

NCL 的目的正是把这些边界提前固定下来。

---

# 36. 完整小型示例

目标：

```text
新角色
新武器
新道具
一个 tracking value
```

目录：

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

manifest：

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

整个注册框架无需由你的 Mod 再写一遍。

---

# 37. 大型 Mod 建议

当项目达到几十个角色、几百件物品、大量 Effect 后，建议进一步按职责拆分：

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

然后让：

```text
NewContentData.tres
```

担任“内容入口聚合器”。

这样可以：

- 保持 Inspector 可管理。
- 保持 Git diff 粒度小。
- 允许多个开发者并行制作内容。
- 避免 `NewContentData.tres` 变成不可维护的巨型资源。
- 让 Data 与 Runtime Behavior 独立演进。

---

# 38. 发布前检查表

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
[ ] 复杂 Runtime Behavior 不塞进 NewContent.gd
[ ] 跨 Run 状态使用 RunData tracking
[ ] 生命周期需求使用 Hook
[ ] 不维护第二套 ItemService / RunData 数据库
[ ] 完整启动一次游戏
[ ] 检查 [NCL] Content report
[ ] 检查 Duplicate ids
[ ] 检查 Brotato / Mod Loader 版本
```

---

# 39. 参考资料

Godot：

- [Godot 3.5 Resources](https://docs.godotengine.org/en/3.5/tutorials/scripting/resources.html)
- [Godot 3.5 GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html)
- [Godot 3.5 GDScript Exports](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_exports.html)
- [Godot 3.5 yield / GDScriptFunctionState](https://docs.godotengine.org/en/3.5/classes/class_%40gdscript.html)

Mod Loader：

- [Godot Mod Loader documentation](https://wiki.godotmodding.com/)

NCL 关键源码：

- [`NewContent.gd`](../NewContent.gd) — 内容字段与添加/卸载生命周期
- [`NewContent.tres`](../NewContent.tres) — Resource 模板
- [`mod_main.gd`](../mod_main.gd) — NCL 启动与 Script Extension 安装
- [`extensions/progress_data.gd`](../extensions/progress_data.gd) — Mod/DLC 发现与合并
- [`extensions/run_data.gd`](../extensions/run_data.gd) — tracking 与武器辅助
- [`extensions/utils.gd`](../extensions/utils.gd) — Runtime helper API
- [`extensions/main.gd`](../extensions/main.gd) — End-of-Wave Hook
- [`extensions/item_service.gd`](../extensions/item_service.gd) — Weapon lookup / Consumable Hook
- [`extensions/weapon_service.gd`](../extensions/weapon_service.gd) — Weapon Service 扩展
- [`extensions/floating_text_manager.gd`](../extensions/floating_text_manager.gd) — 自定义 Damage Number

---

<div align="center">

**Yoko-NewContentLoader · 用 Godot Resource 描述内容，通过 Brotato 原生运行时边界扩展游戏。**

</div>
