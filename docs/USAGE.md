# Yoko-NewContentLoader 使用与开发文档

> 面向 Brotato Mod 开发者的完整操作手册。
>
> 本文以仓库当前 `1.1.0` 实现为准，兼容目标为 Brotato `1.15.4`、Brotato Mod Loader `6.3.0`。如果你的代码与本文示例存在差异，请优先以当前仓库源码与 `manifest.json` 为准。

## 先看这里：5 分钟接入一个 Mod

Yoko-NewContentLoader（以下简称 **NCL**）不是一个独立玩法 Mod，而是一层共享基础设施：其他 Mod 通过 `NewContent` 资源声明内容，NCL 负责发现、合并、注册、卸载，并把这些资源接入 Brotato 原有服务。

最小接入路径只有 4 步：

```text
1. manifest.json 声明依赖 Yoko-NewContentLoader
                 ↓
2. 创建 NewContentData.tres
                 ↓
3. 把角色 / 武器 / 道具 / 敌人 / 翻译等资源填入对应字段
                 ↓
4. 启动游戏，由 NCL 自动发现并加载
```

### 最小 manifest

```json
{
  "name": "MyMod",
  "namespace": "MyNamespace",
  "version_number": "1.0.0",
  "dependencies": [
    "Yoko-NewContentLoader"
  ]
}
```

### 最小 NewContentData.tres

```text
[gd_resource type="Resource" load_steps=2 format=2]

[ext_resource path="res://mods-unpacked/Yoko-NewContentLoader/NewContent.gd" type="Script" id=1]

[resource]
script = ExtResource( 1 )
my_id = "MyMod"
characters = [ ... ]
weapons = [ ... ]
items = [ ... ]
translations = [ ... ]
```

正常情况下，**不需要在你的 Mod 里手动调用 `add_resources()`**。NCL 会扫描所有声明依赖自己的 Mod，读取 `NewContentData.tres`，再自动把内容接入游戏。

---

## 1. NCL 到底在做什么

Brotato 原本已经拥有自己的内容系统：角色、武器、物品、效果、敌人、挑战、区域、翻译等最终都由游戏内部服务管理。NCL 的目标不是再造一个平行的内容框架，而是在这些现有服务上增加一个稳定的 Mod 内容入口。

核心模型是：

```text
                    Brotato 原生系统
             ┌─────────┬─────────┬─────────┐
             │ItemService│ZoneService│RunData│ ...
             └─────────┴─────────┴─────────┘
                       ▲
                       │
                NCL 注册 / 卸载层
                       ▲
                       │
                 NewContent 数据
                       ▲
             ┌─────────┴─────────┐
             │                   │
        NewContentData.tres  NewContentDataDLC1.tres
             │                   │
             └─────────┬─────────┘
                       │
                 你的 Mod 资源
```

这也是 NCL 的主要价值：Mod 开发者主要描述“**我增加了什么**”，而不是反复实现“**怎样把它塞进每一个 Brotato 服务里**”。

---

## 2. 为什么使用 Brotato 自己的 DLC / Progress 系统

NCL 当前的内容发现入口位于 Brotato 的 `ProgressData` 扩展中。它遍历 Mod Loader 已加载的 Mod，只处理 manifest 中声明依赖 `Yoko-NewContentLoader` 的 Mod，然后把每个 Mod 的内容资源组织成一份 DLC 数据并加入游戏现有的可用 DLC 容器。

当前实现同时支持两层内容：

```text
NewContentData.tres
        │
        ├── 基础内容
        │
        └──────────────┐
                       ▼
NewContentDataDLC1.tres
        │
        ├── DLC1 内容
        │
        └──────────────┐
                       ▼
               自动合并为一份内容
                       │
                       ▼
                available_dlcs
```

DLC1 的识别使用游戏现有的 DLC ID：

```text
abyssal_terrors
```

只有在游戏当前确实提供对应 DLC 数据时，NCL 才会继续读取依赖 Mod 的 `NewContentDataDLC1.tres`。

### 为什么这种方式有利于兼容性

这里需要区分“架构优势”和“绝对兼容保证”。使用原生 DLC / ProgressData 边界意味着：

1. 内容最终仍然进入 Brotato 已经理解的服务和数据结构，而不是另建一个平行的 Mod 数据库。
2. Mod 的内容可以复用游戏自己的物品池、武器查找、区域、挑战、RunData、翻译和其他生命周期。
3. NCL 只扩展少数明确的服务边界，因此不同内容 Mod 更容易共享同一套注册逻辑。
4. DLC 内容只有在游戏对应 DLC 可用时才进入加载路径，天然具备一个明确的兼容性边界。
5. 基础内容与 DLC1 内容可以分别维护，再由 NCL 自动合并。

这并不意味着“使用 NCL 就一定不会发生 Mod 冲突”。如果两个 Mod 使用相同 `my_id`、相互修改相同底层服务、或假设完全不同的游戏版本，仍然可能产生兼容性问题。

---

## 3. 安装 NCL

### 玩家安装

1. 安装 Brotato `1.15.4`。
2. 安装 Brotato Mod Loader `6.3.0`。
3. 从 NCL Releases 下载对应的 `NewContentLoader-*.zip`。
4. 把 ZIP 放入 Mod Loader 的 `mods` 目录。
5. 再安装声明依赖 NCL 的内容 Mod。

正常安装结构为：

```text
mods/
├── NewContentLoader-*.zip
├── MyMod-*.zip
└── OtherMod-*.zip
```

### 开发环境

开发时推荐使用 `mods-unpacked`：

```text
mods-unpacked/
├── Yoko-NewContentLoader/
└── MyMod/
```

NCL 的源码目录结构通常为：

```text
Yoko-NewContentLoader/
├── NewContent.gd
├── NewContent.tres
├── extensions/
├── manifest.json
└── mod_main.gd
```

### 依赖声明是关键

NCL 通过：

```gdscript
mod_data.manifest.dependencies.has("Yoko-NewContentLoader")
```

来判断一个 Mod 是否应该进入内容加载流程。

因此你的 Mod 即使拥有正确的 `NewContentData.tres`，**只要没有在 manifest 中声明 NCL 依赖，NCL 就不会主动加载它。**

---

# 4. NewContent：所有内容的统一入口

`NewContent.gd` 继承自 Godot `Resource`。你的 Mod 应该通过继承这一资源模板的 `.tres` 文件来描述需要注册的内容。

完整字段可以按用途分为 7 组。

## 4.1 基础字段

### `my_id`

每一份 `NewContent` 都应该有唯一标识。

```gdscript
my_id = "MyMod"
```

NCL 会根据 `my_id` 生成内部哈希，并把它作为这份内容的稳定标识。

建议：

```text
项目名 / Mod 内部唯一 ID
```

避免：

```text
test
new
mod
content
```

因为内容合并、日志和扩展之间都依赖明确的身份边界。

---

# 5. 游戏内容资源字段

## 5.1 `backgrounds`

向 Brotato 的背景资源集合添加内容。

```gdscript
backgrounds = [
    preload("res://mods-unpacked/MyMod/content/maps/my_background.tres")
]
```

NCL 会：

1. 调用 `ItemService.add_backgrounds()`。
2. 把这些背景加入当前 Zone 的 `default_backgrounds`。
3. 在卸载时反向移除。

因此，如果你的 Mod 新增一个地图背景，并希望相关 Zone 自动可以使用它，这个字段是标准入口。

## 5.2 `characters`

添加新的角色资源：

```gdscript
characters = [
    preload("res://mods-unpacked/MyMod/content/characters/example.tres")
]
```

内容加载后，角色进入 `ItemService.characters`，因此普通的 Brotato 角色查询与后续流程都可以继续使用这些对象。

## 5.3 `entities`

注册普通实体。

常用于：

- 特殊敌人
- 特殊中立单位
- Mod 自定义实体
- 其他由 Brotato Entity 数据模型表达的内容

## 5.4 `elites`

添加 Elite 实体。

## 5.5 `bosses`

添加 Boss 实体。

## 5.6 `stats`

注册新的 Stat 定义。

注意：NCL 会在内容全部加入后重新生成统计数据哈希，并调用 `Utils.reset_stat_keys()`，所以 Mod 不应该自己重复维护这些底层注册动作。

## 5.7 `items`

添加普通 Item：

```gdscript
items = [
    preload("res://mods-unpacked/MyMod/content/items/example/example_data.tres")
]
```

加载后会进入 `ItemService.items`。

适用范围包括：

- 被动道具
- 商店道具
- 修改玩家属性的道具
- 触发 Effect 的道具
- 与其他 Mod 系统组合的道具

## 5.8 `weapons`

添加武器资源：

```gdscript
weapons = [
    preload("res://mods-unpacked/MyMod/content/weapons/example.tres")
]
```

NCL 除了把武器加入 `ItemService.weapons` 外，还会额外建立 `my_id_hash → WeaponData` 的快速索引。

之后可以直接使用：

```gdscript
ItemService.ncl_get_weapon_from_id(weapon_my_id_hash)
```

获得武器。

## 5.9 `effects`

添加 Effect 定义。

这是扩展复杂玩法时最常使用的字段之一。Effect 仍然由 Brotato 原有的 Effect / Item / Weapon 体系消费，NCL 负责的是注册和生命周期，而不是替你发明新的 Effect 数据模型。

## 5.10 `consumables`

添加 Consumable。

NCL 同时扩展了 `ItemService.get_consumable_to_drop()`，因此依赖 NCL 的 DLC / Mod 可以通过 `ncl_update_consumable_to_get()` 改写最终掉落的 Consumable。

## 5.11 `upgrades`

添加升级项。

## 5.12 `sets`

添加物品 / 武器 Set。

## 5.13 `difficulties`

添加新的 Difficulty。

## 5.14 `icons`

注册游戏 UI 使用的图标资源。

这对自定义 Effect、伤害数字、状态描述以及其他 UI 数据尤其有用。

## 5.15 `title_screen_backgrounds`

向标题界面背景集合加入资源。

## 5.16 `groups_in_all_zones`

添加会出现在所有 Zone 的内容组。

用于希望跨地图始终存在的内容分组。

## 5.17 `music_tracks`

注册新的音乐资源。

---

# 6. Zone 与 Challenge

## 6.1 `zones`

注册新的 Zone：

```gdscript
zones = [
    preload("res://mods-unpacked/MyMod/content/zones/example.tres")
]
```

NCL 会将它加入：

```gdscript
ZoneService.zones
```

如果同时存在 `backgrounds`，NCL 还会把新增背景写入各 Zone 的默认背景集合。

## 6.2 `challenges`

注册挑战：

```gdscript
challenges = [
    preload("res://mods-unpacked/MyMod/content/challenges/example.tres")
]
```

注册后 NCL 会刷新 ChallengeService 的统计挑战映射。

卸载时会同时移除：

```text
ChallengeService.challenges
ChallengeService.stat_challenges
```

因此挑战数据不会因为 Mod 被移除而永久残留在当前运行时注册表中。

---

# 7. Localization：翻译与特殊文本格式

## 7.1 `translations`

可以直接注册 Godot `Translation` 资源：

```gdscript
translations = [
    preload("res://mods-unpacked/MyMod/translations/MyMod.zh.translation"),
    preload("res://mods-unpacked/MyMod/translations/MyMod.en.translation")
]
```

NCL 会调用：

```gdscript
TranslationServer.add_translation()
```

卸载时再调用：

```gdscript
TranslationServer.remove_translation()
```

因此推荐把完整语言资源直接放入 `translations`，而不是通过自定义初始化函数手动注册。

## 7.2 `translation_keys_needing_operator`

用于告诉游戏某些翻译键需要运算符格式化。

例如某文本需要显示：

```text
+10
-20%
```

可以把相应键映射交给 NCL：

```gdscript
translation_keys_needing_operator = {
    "MY_STAT_DESCRIPTION": true
}
```

NCL 会合并到：

```gdscript
Text.keys_needing_operator
```

## 7.3 `translation_keys_needing_percent`

用于需要百分号格式化的翻译键。

```gdscript
translation_keys_needing_percent = {
    "MY_PERCENT_STAT": true
}
```

NCL 会把它们合并到：

```gdscript
Text.keys_needing_percent
```

卸载时会撤销对应注册。

---

# 8. RunData 数据追踪功能

NCL 对 `RunData` 做了较深的扩展。这些字段适合“玩法统计”和“运行过程中持续积累的数据”。

## 8.1 `tracked_items`

声明需要被持续追踪的 Item 数据。

```gdscript
tracked_items = {
    "my_item_key": 0
}
```

NCL 会把 Dictionary 转换成游戏内部哈希格式，并合并进：

```gdscript
RunData.init_tracked_items
```

适合：

- 某类道具收集次数
- 某个内容系统累计次数
- 与已有 RunData 统计机制整合的数据

## 8.2 `tracked_effects`

与 `tracked_items` 类似，但用于 Effect：

```gdscript
tracked_effects = {
    "my_effect_key": 0
}
```

它会进入 NCL 扩展的：

```gdscript
RunData.ncl_init_tracked_effects
```

运行时提供：

```gdscript
RunData.ncl_add_effect_tracking_value()
RunData.ncl_set_effect_tracking_value()
RunData.ncl_get_effect_tracking_value()
```

### 增加值

```gdscript
RunData.ncl_add_effect_tracking_value(
    Keys.my_effect_key_hash,
    1,
    player_index
)
```

### 设置值

```gdscript
RunData.ncl_set_effect_tracking_value(
    Keys.my_effect_key_hash,
    10,
    player_index
)
```

### 读取值

```gdscript
var value = RunData.ncl_get_effect_tracking_value(
    Keys.my_effect_key_hash,
    player_index
)
```

如果某个追踪键不存在，NCL 会写日志并返回 `0`，而不会静默创建一个拼写错误的键。

## 8.3 数组型追踪值

`ncl_*_effect_tracking_value()` 也支持追踪值本身为 Array 的情况：

```text
tracking_key → [value_0, value_1, value_2]
```

这时通过：

```gdscript
index = 0
```

选择要读写的槽位。

---

# 9. 自定义 Primary Stats

`primary_stats_list` 用于扩展游戏对 Primary Stat 的认知：

```gdscript
primary_stats_list = [
    "MY_CUSTOM_STAT"
]
```

NCL 会转换成哈希后追加到：

```gdscript
RunData.primary_stats_list
```

这适合：

- 自定义角色属性
- 新增真正意义上的主要属性
- 需要被 UI / 统计逻辑作为 Primary Stat 处理的自定义键

与其直接修改 Brotato 原始 `RunData`，推荐让 NCL 统一注册。

---

# 10. Weapon / Effect Serialization 扩展

NCL 暴露两组额外的序列化键列表：

```gdscript
effect_keys_full_serialization = [
    "MY_EFFECT_KEY"
]
```

以及：

```gdscript
effect_keys_with_weapon_stats = [
    "MY_WEAPON_EFFECT_KEY"
]
```

它们分别进入：

```gdscript
RunData.effect_keys_full_serialization
RunData.effect_keys_with_weapon_stats
```

### 什么时候使用

当你的自定义 Effect 包含额外运行状态，而标准 Effect 序列化逻辑无法自动覆盖时，就应该考虑将对应键加入这些列表。

例如：

```text
Effect
 ├── base values
 ├── custom runtime state
 └── weapon-related values
```

此时把键登记到对应序列化集合，可以使存档 / RunData 的处理知道这些 Effect 需要额外保留。

---

# 11. Effect Behavior 三种注册入口

`NewContent` 支持三种行为资源：

```gdscript
scene_effect_behaviors = []
enemy_effect_behaviors = []
player_effect_behaviors = []
```

## 11.1 `scene_effect_behaviors`

适合场景级 Effect 行为。

## 11.2 `enemy_effect_behaviors`

适合敌人身上的 Effect 行为。

## 11.3 `player_effect_behaviors`

适合玩家身上的 Effect 行为。

三者最终都会注册到：

```gdscript
EffectBehaviorService
```

卸载时 NCL 会把对应资源移除。

### 典型使用方式

```text
Item / Weapon / Effect Data
            │
            ▼
     EffectBehavior
            │
    ┌───────┼────────┐
    ▼       ▼        ▼
  Scene   Enemy    Player
```

这允许 Mod 将“数据定义”和“需要主动运行的行为”分开。

---

# 12. Starting Weapon 自动注册

这是 `NewContent` 中一个很实用、也容易被忽略的功能。

如果 WeaponData 中定义：

```gdscript
add_to_chars_as_starting = [
    "my_character_id"
]
```

那么 NCL 在 `add_resources()` 时会自动：

1. 根据角色 ID 查找角色。
2. 检查该角色是否已经拥有这把武器。
3. 没有则加入 `starting_weapons`。

卸载时则会反向移除。

因此你不需要为“角色初始武器”再单独写一套注册脚本。

### 推荐写法

```text
CharacterData
   ↑
WeaponData.add_to_chars_as_starting
```

而不是：

```text
mod_main.gd
   └── 手动查角色
       └── 手动 append weapon
```

---

# 13. Content 自动合并机制

NCL 当前支持一个 Mod 同时提供：

```text
NewContentData.tres
NewContentDataDLC1.tres
```

其中：

- `NewContentData.tres` = 常规内容
- `NewContentDataDLC1.tres` = DLC1 专属内容

NCL 会自动执行属性级合并。

## 13.1 Array 合并

如果两个内容资源都有：

```text
items = [A, B]
items = [C, D]
```

最终：

```text
items = [A, B, C, D]
```

NCL 使用追加方式合并数组。

## 13.2 Dictionary 合并

例如：

```text
tracked_items = { A: 1 }
tracked_items = { B: 2 }
```

最终：

```text
{ A: 1, B: 2 }
```

如果键冲突，第二份内容覆盖第一份内容。

## 13.3 非 Array / Dictionary

对于不可自动合并或发生类型不一致的属性，NCL 使用 `content_2` 的值覆盖 `content_1`，并输出日志。

因此不要假设所有属性都会“智能叠加”。

### 推荐设计

```text
Array       → 追加式设计
Dictionary  → 键级合并
Scalar      → 明确知道谁覆盖谁
```

---

# 14. 内容加载与卸载生命周期

NCL 为内容提供完整的成对生命周期：

```text
add_resources()
      │
      ├── TranslationServer
      ├── ZoneService
      ├── ItemService
      ├── Starting Weapons
      ├── ChallengeService
      ├── EffectBehaviorService
      ├── Text
      ├── RunData
      └── Custom Resources

remove_resources()
      │
      └── 反向清理上述注册
```

这意味着如果你编写的是长期运行的 Mod / Mod Loader 生态，**不要只实现添加，不实现删除**。

### 自定义扩展点

`NewContent.gd` 提供：

```gdscript
func add_custom_resources() -> void:
    pass

func remove_custom_resources() -> void:
    pass
```

依赖项目可以通过继承 / 自定义实现，在公共注册流程之外挂接自己的注册资源。

---

# 15. Custom Class 自动发现

这是 NCL 对 Mod Loader 全局脚本类的另一层基础设施支持。

NCL 启动时会扫描所有 Mod：

```text
mod manifest
   │
   └── 是否依赖 NCL？
           │
           ├── 否 → 跳过
           └── 是
                │
                ▼
extensions/services/class_service.gd
                │
                ▼
            get_classes()
                │
                ▼
         注册 Global Classes
```

## 15.1 你的 Mod 需要什么

在你的 Mod 中创建：

```text
extensions/services/class_service.gd
```

并提供：

```gdscript
static func get_classes() -> Array:
    return [
        {
            "class": "MyCustomClass",
            "path": "res://mods-unpacked/MyMod/extensions/my_custom_class.gd"
        }
    ]
```

具体类数据结构应与你当前 Mod Loader / 项目实现一致。

## 15.2 NCL 做什么

NCL 会：

- 收集所有依赖 NCL 的 Mod 的类。
- 删除已经不存在的旧类。
- 删除非法路径的类。
- 避免同名类重复注册。
- 通过 Mod Loader 注册新的全局类。

这使多个 Mod 可以共享自定义类，而无需每个 Mod 手动修改 `_global_script_classes`。

### 特别重要

如果你的 Mod 声明依赖 NCL，但没有：

```text
extensions/services/class_service.gd
```

NCL 会直接记录 Skip 日志，不会因此让整个加载流程失败。

---

# 16. End-of-Wave Hooks

NCL 扩展了 Brotato 主循环的波次结束流程，提供四个稳定的时机：

```gdscript
Main.NCL_END_WAVE_BEFORE_REWARDS
Main.NCL_END_WAVE_AFTER_REWARDS
Main.NCL_END_WAVE_BEFORE_END_RUN_SCENE
Main.NCL_END_WAVE_BEFORE_CHANGE_SCENE
```

它们的时间线为：

```text
波次结束
  │
  ▼
before_wave_rewards
  │
  ▼
原版奖励处理
  │
  ▼
after_wave_rewards
  │
  ▼
挑战 UI
  │
  ▼
before_change_scene
  │
  ▼
切换场景
```

如果本局结束：

```text
波次结束
  │
  ▼
before_end_run_scene
  │
  ▼
End Run Scene
```

## 16.1 注册 Hook

```gdscript
Main.ncl_register_end_wave_hook(
    "before_wave_rewards",
    self,
    "my_before_rewards",
    100
)
```

函数签名：

```gdscript
func my_before_rewards():
    # 你的逻辑
```

如果是 `before_change_scene`，可以接收场景参数：

```gdscript
func my_before_change_scene(scene: String):
    # 根据 scene 决定行为
```

## 16.2 Priority

priority 越小越先执行。

例如：

```text
priority 10  → 先执行
priority 50
priority 100 → 后执行
```

当 priority 相同时，NCL 会按方法名排序，保持稳定顺序。

## 16.3 异步 Hook

Hook 可以返回 `GDScriptFunctionState`。

NCL 会检测并 `yield` 等待，因此可以写：

```gdscript
func my_hook():
    yield(get_tree().create_timer(0.2), "timeout")
    # 继续执行
```

这样适合需要等待 UI / Tween / 动画完成的波次结束逻辑。

## 16.4 注销 Hook

```gdscript
Main.ncl_unregister_end_wave_hook(
    "before_wave_rewards",
    self,
    "my_before_rewards"
)
```

推荐在自定义对象销毁或 Mod 生命周期结束时注销，避免持有过期 owner。

---

# 17. Consumable 掉落 Hook

NCL 修改了：

```gdscript
ItemService.get_consumable_to_drop()
```

流程变为：

```text
原版随机 Consumable
        │
        ▼
遍历 enabled_dlcs
        │
        ▼
寻找 ncl_update_consumable_to_get()
        │
        ▼
让对应 DLC 修改结果
        │
        ▼
最终 Consumable
```

## 17.1 基础实现

如果你的 Mod 没有特殊需求，什么都不需要做。

## 17.2 自定义掉落逻辑

如果你的 DLC 内容需要修改最终掉落，可以在对应 DLC Data 脚本中实现：

```gdscript
func ncl_update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
    # 例如根据自己的规则替换掉落
    return base_consumable_data
```

多个 DLC 可以依次参与处理，因此推荐保持函数：

```text
输入 → 判断是否需要修改 → 修改或原样返回
```

而不是无条件覆盖其他 Mod 的结果。

---

# 18. Weapon Lookup 与运行时换武器

NCL 在 `ItemService` 中维护：

```gdscript
ncl_weapon_my_id_lookup
```

并提供：

```gdscript
ItemService.ncl_is_weapon_id(weapon_my_id)
ItemService.ncl_get_weapon_from_id(weapon_my_id)
ItemService.ncl_rebuild_weapon_my_id_lookup()
```

## 18.1 判断是不是 Weapon

```gdscript
if ItemService.ncl_is_weapon_id(weapon_id):
    # weapon_id 是武器
```

## 18.2 通过 ID 取武器

```gdscript
var weapon = ItemService.ncl_get_weapon_from_id(weapon_id)
```

## 18.3 什么时候需要重建

通常 NCL 自己会在内容加载 / 卸载后调用：

```gdscript
ItemService.ncl_rebuild_weapon_my_id_lookup()
```

只有在你绕过 NCL 生命周期、直接修改 `ItemService.weapons` 时，才需要特别考虑手动重建。

**更推荐不要直接绕过 NCL 的注册流程。**

---

# 19. RunData：运行时武器管理

NCL 的 `RunData` 扩展还提供：

```gdscript
RunData.ncl_get_nb_weapon()
RunData.ncl_remove_weapon_by_id()
```

## 查询玩家持有数量

```gdscript
var count = RunData.ncl_get_nb_weapon(
    weapon_my_id_hash,
    player_index
)
```

## 按 ID 删除武器

```gdscript
var removed_tracked_value = RunData.ncl_remove_weapon_by_id(
    weapon_data,
    player_index
)
```

返回值是被删除武器的 `tracked_value`，适合在“替换武器”或“保留历史统计”的机制中继续传递。

---

# 20. Utils：通用开发辅助 API

NCL 对 Brotato `Utils` 增加了大量可复用函数。这里按实际用途分类。

## 20.1 静默修改玩家属性

### `ncl_quiet_add_stat`

```gdscript
Utils.ncl_quiet_add_stat(
    Keys.stat_damage_hash,
    10,
    player_index
)
```

作用：增加属性，同时标记 Stat dirty 并重置缓存。

### `ncl_quiet_set_stat`

```gdscript
Utils.ncl_quiet_set_stat(
    Keys.stat_damage_hash,
    100,
    player_index
)
```

适合需要修改当前运行状态，但不希望触发额外 UI / 普通流程的场景。

---

## 20.2 Curse 数值处理

### `ncl_curse_effect_value`

这是一个通用的数值变换工具。

```gdscript
var result = Utils.ncl_curse_effect_value(
    value,
    modifier
)
```

支持：

```gdscript
{
    "modifier_scale": 1.0,
    "step": 0.01,
    "process_negative": true,
    "is_negative": false,
    "min_num": NAN,
    "max_num": NAN
}
```

主要逻辑：

- 正向数值：乘以 `1 + modifier`。
- 负向数值：默认使用除法模型。
- 可以显式指定 `is_negative`。
- 可以控制是否处理负值。
- 可以设置量化步长。
- 可以设置最大值 / 最小值。

例如：

```gdscript
var cursed = Utils.ncl_curse_effect_value(
    10.0,
    0.2,
    {
        "step": 1.0,
        "min_num": 1
    }
)
```

---

## 20.3 Curse Item / Enemy

### `ncl_curse_item`

```gdscript
var cursed_item = Utils.ncl_curse_item(
    item_data,
    player_index
)
```

它会将逻辑交给游戏 DLC1 数据的 `curse_item()` 实现。

### `ncl_curse_enemy`

```gdscript
Utils.ncl_curse_enemy(enemy)
```

它会读取玩家当前 Curse，并找到支持 `_curse_enemy` 的 EffectBehavior 执行对应处理。

---

# 21. Damage / Number Scaling 工具

## 21.1 计算带属性缩放的 Damage

```gdscript
var damage = Utils.ncl_get_dmg_with_scaling_stats(
    base_damage,
    scaling_stats,
    player_index
)
```

其中 `scaling_stats` 采用：

```text
[stat_hash, coefficient]
```

最终伤害还会考虑玩家的 Percent Damage。

## 21.2 计算普通数量

```gdscript
var number = Utils.ncl_get_num_with_scaling_stats(
    base_num,
    scaling_stats,
    player_index
)
```

不会额外经过 Percent Damage。

## 21.3 自动生成 Damage 文本

```gdscript
var text = Utils.ncl_get_dmg_text_with_scaling_stats(
    base_damage,
    scaling_stats,
    {
        "nb": 1,
        "effects": [],
        "player_index": player_index,
        "show_initial": true
    }
)
```

结果会包含：

- 最终数值
- 与初始值的差异
- 缩放属性图标文字
- 颜色提示

## 21.4 自动生成 Number 文本

```gdscript
var text = Utils.ncl_get_num_text_with_scaling_stats(
    base_num,
    scaling_stats
)
```

---

# 22. Range Scaling

## `ncl_get_range_with_detection`

```gdscript
var range = Utils.ncl_get_range_with_detection(
    base_range,
    range_rate,
    player_index,
    200
)
```

其中默认 detection 是 `200`。

## `ncl_get_range_text_with_scaling`

```gdscript
var text = Utils.ncl_get_range_text_with_scaling(
    base_range,
    range_rate,
    player_index
)
```

适合直接生成带缩放说明的 UI 文本。

---

# 23. 数值颜色辅助

## `ncl_get_signed_col`

```gdscript
var color = Utils.ncl_get_signed_col(
    current,
    base
)
```

默认：

```text
增加 → positive color
降低 → negative color
不变 → white
```

如果需要反向语义：

```gdscript
Utils.ncl_get_signed_col(current, base, true)
```

适合“数值越低越好”这类特殊 UI。

---

# 24. Weapon 动态替换

NCL 提供两套工具，用于在游戏进行过程中把已有武器替换成另一把武器。

## 24.1 战斗中替换

```gdscript
Utils.ncl_change_weapon_within_run(
    weapon_position,
    new_weapon_id,
    player_index
)
```

它会处理：

1. 从当前武器列表移除旧武器。
2. 调整后续武器位置。
3. 获取新武器。
4. 保留 tracked value。
5. 如旧武器被 Curse，继续传递最低 Curse 强度。
6. 重新加入 RunData。
7. 延迟添加到玩家当前武器节点。

因此比手动 `erase + add_weapon` 更安全。

## 24.2 商店中替换

```gdscript
Utils.ncl_change_weapon_within_shop(
    weapon,
    new_weapon_id,
    player_index,
    shop
)
```

除了替换 RunData 外，还会更新：

- Shop weapon container
- Shop statistics
- Shop items
- Focus
- Combine sound

如果你的机制是“锻造 / 合成 / 武器变形”，优先使用这两个函数。

---

# 25. 自定义伤害参数与自定义飘字

NCL 扩展了 `FloatingTextManager`。

如果 `TakeDamageArgs` 中包含：

```text
custom_color
custom_icon
```

NCL 会拦截伤害显示，并使用指定颜色 / 图标绘制伤害数字。

## 创建参数

```gdscript
var args = Utils.ncl_create_custom_damage_args(
    player_index,
    Color("#FF00AA"),
    Keys.my_icon_hash
)
```

然后将 `args` 传入伤害处理函数。

### 只使用自定义颜色

```gdscript
var args = Utils.ncl_create_custom_damage_args(
    player_index,
    Color("#FF00AA")
)
```

### 注意

只有在游戏设置允许显示伤害数字时，自定义飘字才会真正显示。

---

# 26. Consumable 生成

## `ncl_spawn_consumable`

```gdscript
Utils.ncl_spawn_consumable(
    consumable_id,
    number,
    position,
    spread
)
```

它会：

1. 从 `ItemService.consumables` 中找到 ConsumableData。
2. 尝试从游戏对象池复用实例。
3. 没有实例时创建新节点。
4. 设置图标与数据。
5. 在指定位置生成。
6. 给一个可控的随机散布距离。

适用于：

- 击杀掉落
- 技能生成
- 宝箱奖励
- 自定义事件

---

# 27. Item / Weapon 通用 Gear API

NCL 提供一套可以同时处理 Item 和 Weapon 的统一 API。

## 27.1 判断类型

```gdscript
var gear_type = Utils.ncl_judge_item_type_from_my_id(id)
```

结果：

```gdscript
Utils.GearType.ITEM
Utils.GearType.WEAPON
-1
```

## 27.2 查询持有数量

```gdscript
var count = Utils.ncl_get_nb_gear(
    gear_id,
    player_index
)
```

NCL 会自动判断：

```text
Item   → RunData.get_nb_item()
Weapon → RunData.ncl_get_nb_weapon()
```

## 27.3 添加 Gear

```gdscript
Utils.ncl_add_gear_by_id(
    gear_id,
    player_index,
    1
)
```

无论 Item / Weapon 都能使用。

## 27.4 删除 Gear

```gdscript
Utils.ncl_remove_gear_by_id(
    gear_id,
    player_index,
    1
)
```

## 27.5 根据 ID 生成带颜色名称

```gdscript
var text = Utils.ncl_get_gear_name_from_id(
    gear_id,
    1
)
```

返回的是已经带 Tier 颜色与数量信息的 BBCode 文本，可直接用于 Brotato 的文本 UI。

---

# 28. Stat 名称转换

## `ncl_get_true_stat_name`

```gdscript
var text = Utils.ncl_get_true_stat_name(
    "stat_damage"
)
```

内部会处理：

- 空字符串
- `number_of_enemies`
- `different_item`
- 普通 Stat key

并自动走 `TranslationServer` / `tr()`。

因此比直接：

```gdscript
tr(stat)
```

更适合 Mod 自定义 Stat 文本。

---

# 29. Composite Hash

## `ncl_generate_composite_hash`

```gdscript
var hash = Utils.ncl_generate_composite_hash([
    hash_a,
    hash_b,
    hash_c
])
```

内部使用：

```text
result = result * 31 + value
```

适合将多个 ID / 状态组合成稳定的组合键。

---

# 30. 节点名称与对象池辅助

## `ncl_get_validate_node_name`

用于处理 Godot 运行时节点名中的 `@` 后缀：

```gdscript
var clean_name = Utils.ncl_get_validate_node_name(node.name)
```

适合比较实例化 / 动态创建后的节点名称。

## `ncl_queue_free_weapon`

不要直接粗暴 `queue_free()` 运行中的 Weapon 节点。NCL 提供：

```gdscript
Utils.ncl_queue_free_weapon(weapon)
```

它会：

- 将 cooldown 设为极大值
- 禁用 hitbox
- 禁用 target tracking
- 隐藏节点
- 最后禁用节点处理

这样适合在武器热替换时安全退出旧武器。

---

# 31. `mod_main.gd`：NCL 自身如何启动

理解 NCL 的启动流程，对开发依赖 Mod 很重要。

当前 `mod_main.gd` 的职责主要有两个：

```text
① 注册共享自定义类
② 安装 NCL 对 Brotato 原始脚本的扩展
```

启动时会安装：

```text
progress_data.gd
run_data.gd
utils.gd
main.gd
weapon_service.gd
floating_text_manager.gd
item_service.gd
```

因此这些扩展都是在 Brotato 原有类上做增量式增强，而不是复制整套系统。

---

# 32. 推荐的 Mod 项目结构

一个完整的 NCL 依赖 Mod 可以采用：

```text
MyMod/
├── content/
│   ├── characters/
│   ├── weapons/
│   ├── items/
│   ├── entities/
│   ├── effects/
│   ├── challenges/
│   ├── maps/
│   └── zones/
├── extensions/
│   ├── services/
│   │   └── class_service.gd
│   ├── effects/
│   ├── dlc_1_data.gd
│   └── ...
├── translations/
│   ├── MyMod.zh.translation
│   ├── MyMod.en.translation
│   └── ...
├── NewContentData.tres
├── NewContentDataDLC1.tres
├── manifest.json
├── mod_main.gd
└── README.md
```

推荐职责边界：

```text
content/        → 数据
translations/   → 本地化
extensions/     → 需要主动执行的运行时逻辑
NewContent*.tres → 注册清单
mod_main.gd     → 项目入口与少量运行时安装
```

---

# 33. 一个完整的最小例子

假设你要制作一个新增角色 + 武器 + 道具 + 翻译的 Mod。

## 33.1 manifest.json

```json
{
  "name": "ExampleMod",
  "namespace": "Example",
  "version_number": "1.0.0",
  "description": "Example content mod powered by Yoko-NewContentLoader.",
  "dependencies": [
    "Yoko-NewContentLoader"
  ]
}
```

## 33.2 NewContentData.tres

```text
[gd_resource type="Resource" load_steps=5 format=2]

[ext_resource path="res://mods-unpacked/Yoko-NewContentLoader/NewContent.gd" type="Script" id=1]
[ext_resource path="res://mods-unpacked/ExampleMod/content/characters/example.tres" type="Resource" id=2]
[ext_resource path="res://mods-unpacked/ExampleMod/content/weapons/example.tres" type="Resource" id=3]
[ext_resource path="res://mods-unpacked/ExampleMod/content/items/example.tres" type="Resource" id=4]

[resource]
script = ExtResource( 1 )
my_id = "ExampleMod"
characters = [ ExtResource( 2 ) ]
weapons = [ ExtResource( 3 ) ]
items = [ ExtResource( 4 ) ]
```

## 33.3 启动后的实际流程

```text
Brotato 启动
     │
     ▼
Mod Loader 发现 ExampleMod
     │
     ▼
检查 manifest.dependencies
     │
     ├── 没有 NCL → 不处理
     │
     └── 有 NCL
           │
           ▼
     读取 NewContentData.tres
           │
           ▼
     合并为 ExampleMod 内容
           │
           ▼
     加入 ItemService.characters
     加入 ItemService.weapons
     加入 ItemService.items
           │
           ▼
     刷新索引 / Pool / Hash
           │
           ▼
        游戏可用
```

---

# 34. DLC1 Mod 的正确写法

如果你的内容只应该在游戏拥有 DLC1 时可用，可以使用：

```text
NewContentDataDLC1.tres
```

同时可以提供：

```text
extensions/dlc_1_data.gd
```

NCL 会检查当前游戏是否存在：

```text
res://dlcs/dlc_1/dlc_data.tres
```

并且只对声明依赖 NCL 的 Mod 安装对应的 `dlc_1_data.gd`。

### DLC1 路径模型

```text
MyMod/
├── NewContentData.tres
├── NewContentDataDLC1.tres
└── extensions/
    └── dlc_1_data.gd
```

### 适合什么情况

适合：

- 只有 DLC 用户才应该看到的内容
- 依赖 DLC1 数据结构的玩法
- Curse 等 DLC 原生机制的扩展
- 需要在 DLCData 上增加方法的项目

### 不推荐什么

不要简单地在普通 `NewContentData.tres` 中塞入 DLC1 专属资源，再期待运行时自己处理不存在的依赖。

让 NCL 的 DLC 边界承担这项职责更清晰。

---

# 35. 多 Mod 协作

NCL 最适合的场景不是“只有一个 Mod 使用它”，而是：

```text
                  NCL
          ┌────────┼────────┐
          │        │        │
        Mod A    Mod B    Mod C
          │        │        │
          ▼        ▼        ▼
       Content  Content  Content
```

所有 Mod 共享：

- 内容注册
- 生命周期
- DLC 边界
- 自定义类发现
- 运行追踪
- End Wave hooks
- Weapon lookup
- Utils helper

因此 Mod A 不应该直接假设“只有我会修改 `ItemService.items`”。开发时要始终考虑：

```text
NCL 是共享层
        ↓
你的 Mod 只是其中一个消费者
```

---

# 36. 如何设计一个“真正兼容 NCL”的 Mod

## 原则一：数据优先

优先：

```text
NewContentData.tres
```

而不是：

```text
mod_main.gd
└── 一大堆 append()
```

## 原则二：只扩展需要扩展的系统

例如你只是新增 10 把武器，不应该去覆盖：

```text
RunData
ItemService
Main
ProgressData
```

只需要把武器放进：

```gdscript
NewContent.weapons
```

## 原则三：不要重复注册

不要自己再调用：

```gdscript
ItemService.weapons.append(...)
```

同时又让 NCL 加一次。

否则容易造成：

- 重复武器
- duplicate ID
- Pool 异常
- 商店出现重复内容

## 原则四：自定义 ID 必须稳定

建议：

```text
namespace_feature_name
```

例如：

```text
mythic_sword
void_core
stitch_clock
```

避免简单：

```text
sword
item1
boss
```

## 原则五：不要依赖加载顺序的偶然性

如果你确实需要“某个 Mod 先初始化”，应该通过 manifest dependency / load order 等正式机制解决，而不是假设 Mod Loader 当前恰好先执行了谁。

---

# 37. Duplicate ID 与诊断

NCL 会在加载内容后生成 Content Report，并检查各数组中的 `my_id` 重复情况。

典型日志：

```text
[NCL] Content report: characters=4, weapons=12, items=20
```

如果发现重复：

```text
[NCL] Duplicate ids in weapons: some_weapon_id
```

### 排查顺序

1. 搜索两个 Mod 是否使用相同 `my_id`。
2. 检查基础内容与 DLC1 内容是否重复引用了同一个资源。
3. 检查是否在 NCL 注册后又手动 append。
4. 检查资源 duplicate 后是否保持了错误的 ID。

Duplicate ID 是最应该优先修复的问题之一。

---

# 38. 常见问题

## Q1：我创建了 NewContentData.tres，为什么游戏里没有内容？

最先检查：

```text
manifest.dependencies
```

必须包含：

```json
"Yoko-NewContentLoader"
```

然后检查文件名必须是：

```text
NewContentData.tres
```

并且位于 Mod 根目录。

## Q2：为什么 DLC1 内容没有加载？

检查：

```text
1. 游戏是否拥有 DLC1
2. NewContentDataDLC1.tres 是否存在
3. manifest 是否依赖 NCL
4. 内容是否确实能被 Godot load()
```

如果游戏没有 `abyssal_terrors`，NCL 会主动跳过 DLC1 内容。

## Q3：为什么 class_service.gd 没生效？

检查：

```text
extensions/services/class_service.gd
```

是否存在，并且 `get_classes()` 返回的数据是否有效。

## Q4：我能直接修改 ItemService 吗？

技术上可以，但不推荐。

优先使用：

```gdscript
NewContent.items
NewContent.weapons
NewContent.characters
```

让 NCL 管理生命周期和索引。

## Q5：多个 Mod 能不能同时使用 NCL？

可以，这正是 NCL 的主要设计目的之一。

每个 Mod 会被单独发现，然后各自的 NewContent 数据都会进入游戏的共享服务。

## Q6：NCL 会自动处理我的自定义玩法吗？

不会。

NCL 负责的是基础注册和公共桥接。复杂机制仍然由你的：

```text
extensions/
```

负责。

## Q7：我什么时候应该写自己的 `mod_main.gd`？

当你的 Mod 需要：

- 安装脚本扩展
- 注册自定义运行时服务
- 建立自定义单例 / 节点
- 安装自己的 DLC 行为
- 设置特殊初始化逻辑

如果只是增加静态内容，通常不需要大量自定义代码。

---

# 39. 推荐的开发工作流

```text
需求
 │
 ▼
判断是不是“内容”
 │
 ├── 是 → NewContentData.tres
 │
 └── 否 → 是否需要修改 Brotato 运行时？
                    │
                    ├── 否 → 结束
                    │
                    └── 是 → extensions/
                                 │
                                 ▼
                           找到真正的宿主服务
                                 │
                                 ▼
                           最小化脚本扩展
                                 │
                                 ▼
                           使用 NCL 公共 API
                                 │
                                 ▼
                              测试
                                 │
                                 ▼
                         检查 Content Report
                                 │
                                 ▼
                             打包发布
```

### 每次增加新内容之前先问 3 个问题

```text
1. 这是 Resource 还是 Runtime Behavior？
2. 如果是 Resource，NewContent 有对应字段吗？
3. 如果没有字段，能否通过现有 Hook / Utils 完成？
```

只有前面都不能解决时，才应该新增基础设施。

---

# 40. Release / Compatibility

当前 NCL manifest 声明：

```text
NCL version        1.1.0
Brotato            1.15.4
Mod Loader         6.3.0
Dependencies       none
```

`manifest.json` 是版本与兼容性声明的权威来源。

NCL 是“基础层 Mod”，因此版本升级时不能只检查自己是否能启动，还应检查：

```text
NCL
├── Yoko-YzTato
├── Yoko-Fantasy
├── Yoko-MoreStatsContainer
├── 其他内容 Mod
└── 依赖 NCL 的第三方 Mod
```

尤其需要回归：

- Content 加载 / 卸载
- DLC1 内容发现
- duplicate ID 检测
- 自定义 Global Class
- End Wave Hook
- RunData serialization
- Weapon lookup
- Consumable drop hook
- Utils helper

因为基础层的一个改动可能影响所有依赖项目。

---

# 41. 调试与日志

NCL 使用 Mod Loader 日志记录加载状态，例如：

```text
[NCL] Successfully load NewContentData.tres
[NCL] Successfully load NewContentDataDLC1.tres
[NCL] Content report: weapons=12, items=30
[NCL] Duplicate ids in weapons: ...
[NCL] Skip: Dependency missing
[NCL] Skip: DLC abyssal_terrors not available
```

排错时优先关注：

```text
[NCL] Skip
[NCL] Error
[NCL] Duplicate ids
```

而不是先怀疑你的具体 Item / Weapon 数据。

推荐调试顺序：

```text
① Manifest dependency
② Mod 是否被 Mod Loader 发现
③ NewContentData 是否存在
④ Content Report
⑤ Duplicate ID
⑥ 运行时扩展
```

---

# 42. 设计建议：什么时候应该使用 NCL

非常适合：

- 大量角色 / 武器 / 道具的内容型 Mod
- 多 DLC / 多模块内容 Mod
- 多个 Mod 共享运行时扩展
- 需要统一的内容卸载能力
- 需要统一的 RunData Tracking
- 需要自定义 Global Classes
- 需要在波次生命周期插入玩法
- 需要扩展 Weapon / Consumable / Floating Text

尤其适合这种生态：

```text
基础设施 Mod
       │
       ├── 内容 Mod A
       ├── 内容 Mod B
       ├── 内容 Mod C
       └── 内容 Mod D
```

而不适合把 NCL 当作“我的整个游戏逻辑都应该写在这里”的万能框架。

---

# 43. 一句话理解 NCL

可以把 NCL 理解成：

> **“让 Brotato 内容 Mod 按 DLC / ProgressData 的方式进入原生服务，同时给多个 Mod 提供一套可共享的注册、卸载、追踪、Hook 和运行时工具层。”**

你的 Mod 负责：

```text
我有什么内容？
我需要什么特殊行为？
```

NCL 负责：

```text
我怎么把这些内容正确接入游戏？
怎么让多个 Mod 共存？
怎么在需要时卸载？
怎么让运行时扩展有公共入口？
```

这就是它作为“基础类 Mod”最重要的价值。
