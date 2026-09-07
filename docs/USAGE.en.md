# Yoko-NewContentLoader — Usage & Developer Guide

> A developer-focused guide for Brotato mod authors using Godot 3.x and Brotato Mod Loader.
>
> **Baseline: NCL 1.1.0 · Brotato 1.15.4 · Brotato Mod Loader 6.3.0 · Godot 3.x / GDScript**

> All source references in this document use ordinary GitHub Markdown links. There are no ChatGPT/internal citation markers in the document.

<div align="center">

### 中文文档

[阅读中文版使用与开发手册 →](USAGE.md)

</div>

## 1. What NCL is

`Yoko-NewContentLoader` is not a gameplay mod and not merely a file loader. It is shared content infrastructure for content-heavy Brotato mods.

A dependent mod describes content with Godot `Resource` / `.tres` files. NCL discovers dependent mods, loads their content, handles optional DLC layers, merges Resources, registers them into Brotato's existing services, provides paired teardown, and exposes reusable runtime extensions and utility APIs.

Architecture:

```text
Godot Editor
    ↓
Resource / .tres
    ↓
Your Mod
    ├── manifest.json
    ├── NewContentData.tres
    ├── NewContentDataDLC1.tres   (optional)
    ├── content/**/*.tres
    ├── translations/*
    └── extensions/*.gd
    ↓
Yoko-NewContentLoader
    ├── discover dependent mods
    ├── load / merge Resources
    ├── gate DLC content
    ├── add / remove lifecycle
    ├── Global Class registration
    ├── Script Extensions
    └── runtime helpers
    ↓
Brotato runtime services
```

The core rule is: **NCL does not replace Brotato's data model. It gives multiple mods a common way to feed data into the game's existing runtime boundaries.**

Start with the source files [`NewContent.gd`](../NewContent.gd), [`mod_main.gd`](../mod_main.gd), and [`extensions/progress_data.gd`](../extensions/progress_data.gd).

## 2. Quick start: add an NCL-powered mod

### 2.1 Declare the dependency

Add NCL to `manifest.json`:

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

NCL only processes mods that explicitly declare this dependency.

### 2.2 Recommended project layout

```text
MyMod/
├── manifest.json
├── NewContentData.tres
├── NewContentDataDLC1.tres       # optional
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

These directory names are conventions. The important loader contract is that `NewContentData.tres` exists at the mod root and correctly references your Resources.

### 2.3 Start from the NCL Resource template

The repository provides [`NewContent.tres`](../NewContent.tres), backed by [`NewContent.gd`](../NewContent.gd). Copy it into the dependent mod and name it:

```text
NewContentData.tres
```

Open it in the Godot Inspector.

### 2.4 Compose content through the Inspector

Typical setup:

```text
NewContentData.tres
  Characters  → character_data.tres
  Weapons     → weapon_data.tres
  Items       → item_data.tres
  Effects     → effect_data.tres
```

Godot 3.x export syntax such as `export(Array, Resource)` makes those arrays directly editable in the Inspector.

Official references: [Godot Resources](https://docs.godotengine.org/en/3.5/tutorials/scripting/resources.html) and [GDScript exports](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_exports.html).

### 2.5 Do not manually register normal content

A normal dependent mod should usually not run:

```gdscript
content.add_resources()
```

The intended lifecycle is:

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

The discovery and loading path lives in [`extensions/progress_data.gd`](../extensions/progress_data.gd).

## 3. The Godot model behind NCL

### 3.1 Resource vs Node

Use this mental model:

```text
Node
→ scene instance / lifecycle / runtime behavior

Resource
→ reusable, serializable data
```

NCL is primarily a Resource-driven layer because characters, weapons, items, effects, zones, translations, and similar content need persistent data descriptions.

A weapon can naturally become a Resource graph:

```text
WeaponData.tres
├── icon    → Texture
├── effects → Effect Resource[]
├── stats   → Stats Resource
└── scene   → PackedScene
```

Godot then handles Resource references, serialization, and Inspector editing.

### 3.2 Why `.tres` instead of JSON

JSON is a useful interchange format, but NCL is working with a Godot Resource graph. `.tres` keeps Godot-native references and authoring semantics intact.

Use:

```text
JSON → external data exchange
.tres → authored Godot content
```

### 3.3 Why split Resources

For large projects, prefer:

```text
one character → one .tres
one weapon    → one .tres
one item      → one .tres
one effect    → one .tres
```

and let `NewContentData.tres` aggregate them. This keeps Git diffs smaller, Inspector editing manageable, and ownership boundaries clear.

## 4. `NewContent` field reference

The complete field definition is in [`NewContent.gd`](../NewContent.gd).

| Field | Type | Purpose |
| :--- | :--- | :--- |
| `my_id` | `String` | Identity of the content collection |
| `groups_in_all_zones` | `Array, Resource` | Zone-wide groups |
| `music_tracks` | `Array, Resource` | Music Resources |
| `backgrounds` | `Array, Resource` | Background Resources |
| `characters` | `Array, Resource` | Character content |
| `entities` | `Array, Resource` | Entity content |
| `elites` | `Array, Resource` | Elite content |
| `bosses` | `Array, Resource` | Boss content |
| `stats` | `Array, Resource` | Custom stat Resources |
| `items` | `Array, Resource` | Item content |
| `weapons` | `Array, Resource` | Weapon content |
| `effects` | `Array, Resource` | Effect content |
| `consumables` | `Array, Resource` | Consumables |
| `upgrades` | `Array, Resource` | Upgrades |
| `sets` | `Array, Resource` | Sets |
| `difficulties` | `Array, Resource` | Difficulties |
| `icons` | `Array, Resource` | In-game icons |
| `title_screen_backgrounds` | `Array, Resource` | Title backgrounds |
| `translations` | `Array, Translation` | Translation Resources |
| `challenges` | `Array, Resource` | Challenges |
| `zones` | `Array, Resource` | Zones |
| `tracked_items` | `Dictionary` | RunData item tracking |
| `tracked_effects` | `Dictionary` | NCL effect tracking |
| `primary_stats_list` | `Array, String` | Additional primary stat keys |
| `effect_keys_full_serialization` | `Array, String` | Effect keys for full serialization |
| `effect_keys_with_weapon_stats` | `Array, String` | Effect keys associated with weapon stats |
| `translation_keys_needing_operator` | `Dictionary` | Special operator metadata |
| `translation_keys_needing_percent` | `Dictionary` | Special percent metadata |
| `scene_effect_behaviors` | `Array, Resource` | Scene Effect Behaviors |
| `enemy_effect_behaviors` | `Array, Resource` | Enemy Effect Behaviors |
| `player_effect_behaviors` | `Array, Resource` | Player Effect Behaviors |

### `my_id`

Use a stable namespace-level identifier:

```text
MyMod
YokoFantasy
YzTato
```

Keep independent content collections distinct.

### `backgrounds`

NCL registers the background and adds it to existing zones' `default_backgrounds`; teardown reverses that operation.

Source: [`NewContent.gd`](../NewContent.gd).

### `characters`

Characters are registered into Brotato's `ItemService.characters`. The Character Resource should still follow the game's own content model.

### `stats`

Custom stat Resources are registered and NCL rebuilds the relevant stat-key/hash state. A dependent mod should not create a second stat registration mechanism.

### `weapons`

Weapons are registered and NCL maintains a lookup based on `my_id_hash`. When weapon data declares `add_to_chars_as_starting`, NCL adds it to the referenced characters' `starting_weapons` and handles teardown.

Sources: [`extensions/item_service.gd`](../extensions/item_service.gd) and [`NewContent.gd`](../NewContent.gd).

### `translations`

This is an `Array, Translation`, not a generic Resource array. NCL adds the Translation to `TranslationServer` and removes it during teardown.

Recommended:

```text
translations/
├── MyMod.en.translation
├── MyMod.zh.translation
└── MyMod.ja.translation
```

### `challenges` and `zones`

They enter Brotato's Challenge and Zone services under the same NCL-managed lifecycle.

## 5. RunData tracking

### `tracked_items`

```gdscript
export(Dictionary) var tracked_items = {}
```

Use this to declare Item-related tracking state that belongs with RunData.

### `tracked_effects`

```gdscript
export(Dictionary) var tracked_effects = {}
```

Use this for NCL-specific Effect tracking.

Runtime helpers live in [`extensions/run_data.gd`](../extensions/run_data.gd):

```gdscript
RunData.ncl_add_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_set_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_get_effect_tracking_value(key_hash, player_index)
```

Prefer RunData tracking for state that must follow the run instead of keeping an unrelated global Dictionary.

## 6. Primary stats and serialization metadata

### Primary stats

```gdscript
export(Array, String) var primary_stats_list = []
```

Use this when a custom stat should participate in Brotato's primary-stat classification.

### Effect serialization

```gdscript
export(Array, String) var effect_keys_full_serialization = []
export(Array, String) var effect_keys_with_weapon_stats = []
```

Register custom Effect keys here when they must be known by the game's save/restore-related Effect serialization paths.

## 7. Text metadata

```gdscript
export(Dictionary) var translation_keys_needing_operator = {}
export(Dictionary) var translation_keys_needing_percent = {}
```

These registries extend Brotato's existing Text formatting behavior rather than introducing a parallel formatter.

## 8. Effect Behavior: separate data and runtime behavior

NCL exposes:

```gdscript
scene_effect_behaviors
enemy_effect_behaviors
player_effect_behaviors
```

Use:

```text
Resource
→ what the content is

Behavior
→ how it behaves at runtime
```

For a complex Effect, prefer:

```text
MyEffectData.tres
MyEffectBehavior.gd
```

instead of placing gameplay logic in `NewContent.gd`.

## 9. DLC-aware loading

NCL supports a base Resource and an optional DLC1 Resource:

```text
NewContentData.tres
NewContentDataDLC1.tres
```

The DLC availability check and merge logic are implemented in [`extensions/progress_data.gd`](../extensions/progress_data.gd).

### Merge semantics

```text
Array
→ append DLC entries

Dictionary
→ merge DLC keys; later values can override

Other properties
→ DLC value wins
```

Treat DLC1 as an incremental layer over base content.

### DLC runtime behavior

A dependent mod may additionally provide:

```text
extensions/dlc_1_data.gd
```

and extend the game's DLC data script. See [Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) for a real dependent-mod example.

## 10. Global Classes with `class_service.gd`

A dependent mod can expose custom Global Class metadata at:

```text
extensions/services/class_service.gd
```

Example:

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

NCL processes this as:

```text
find dependent mod
    ↓
find class_service.gd
    ↓
call get_classes()
    ↓
deduplicate metadata
    ↓
remove stale registrations
    ↓
register valid classes
```

Keep custom class names globally distinctive.

### Why Godot inheritance matters

A custom class may extend a Brotato type:

```gdscript
extends RangedWeaponStats
```

When overriding a method, preserve the parent implementation where appropriate:

```gdscript
func calculate_value():
    var base = .calculate_value()
    return base + my_bonus
```

Official reference: [GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html).

## 11. End-of-Wave Hooks

NCL's `Main` extension exposes:

```text
before_wave_rewards
after_wave_rewards
before_end_run_scene
before_change_scene
```

Source: [`extensions/main.gd`](../extensions/main.gd).

Register:

```gdscript
main.ncl_register_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards",
    100
)
```

Smaller `priority` values run first. For equal priority, NCL uses method-name ordering. Do not rely on incidental registration order.

Unregister with:

```gdscript
main.ncl_unregister_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards"
)
```

### Godot 3.x coroutines

A Hook may return a `GDScriptFunctionState`. NCL waits for:

```gdscript
yield(result, "completed")
```

Example:

```gdscript
func _on_before_wave_rewards():
    yield(get_tree(), "idle_frame")
    do_something()
```

Official reference: [GDScript / yield](https://docs.godotengine.org/en/3.5/classes/class_%40gdscript.html).

Use Hooks for lifecycle-level operations, not as a universal event bus.

## 12. Weapon lookup

NCL's ItemService extension exposes:

```gdscript
ncl_is_weapon_id(weapon_my_id)
ncl_get_weapon_from_id(weapon_my_id)
ncl_rebuild_weapon_my_id_lookup()
```

Source: [`extensions/item_service.gd`](../extensions/item_service.gd).

Use the lookup instead of repeatedly scanning `ItemService.weapons` in hot paths.

## 13. RunData weapon helpers

[`extensions/run_data.gd`](../extensions/run_data.gd) also provides:

```gdscript
RunData.ncl_get_nb_weapon(weapon_my_id_hash, player_index)
RunData.ncl_remove_weapon_by_id(weapon, player_index)
```

Use the NCL removal path rather than directly deleting from internal arrays so existing removal behavior remains intact.

## 14. `Utils.ncl_*` runtime API

The main utility extension is [`extensions/utils.gd`](../extensions/utils.gd). Current public helpers include:

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

### Stat mutation

```gdscript
Utils.ncl_quiet_add_stat(stat_hash, value, player_index)
Utils.ncl_quiet_set_stat(stat_hash, value, player_index)
```

### Modifier transformation

```gdscript
Utils.ncl_curse_effect_value(value, modifier, options)
```

Supported options include `modifier_scale`, `step`, `process_negative`, `is_negative`, `min_num`, and `max_num`.

### Scaling formulas

```gdscript
Utils.ncl_get_scaling_stats_dmg(...)
Utils.ncl_get_dmg_with_scaling_stats(...)
Utils.ncl_get_num_with_scaling_stats(...)
```

These centralize common `base + stat * scaling` calculations.

### Weapon replacement

```gdscript
Utils.ncl_change_weapon_within_run(...)
Utils.ncl_change_weapon_within_shop(...)
```

Prefer these helpers instead of mutating multiple internal arrays yourself; they preserve the related weapon, tracking, cursed-state, and shop behavior handled by the implementation.

## 15. Custom damage numbers

NCL extends [`extensions/floating_text_manager.gd`](../extensions/floating_text_manager.gd) and recognizes these `TakeDamageArgs` metadata keys:

```text
custom_color
custom_icon
```

A mod can create compatible arguments through `ncl_create_custom_damage_args()` and still use Brotato's existing damage-number display path.

## 16. Consumable spawning

```gdscript
Utils.ncl_spawn_consumable(
    consumable_id,
    num,
    pos,
    spread
)
```

The helper prefers Brotato's existing consumable pool and only creates a new Scene instance when necessary.

## 17. Gear API

NCL exposes unified Item / Weapon operations:

```gdscript
enum GearType {ITEM, WEAPON}

Utils.ncl_judge_item_type_from_my_id(gear_id)
Utils.ncl_get_nb_gear(gear_id, player_index)
Utils.ncl_add_gear_by_id(gear_id, player_index, num)
Utils.ncl_remove_gear_by_id(gear_id, player_index, num)
Utils.ncl_get_gear_name_from_id(gear_id, num)
```

Useful for debug tools, events, rewards, achievements, and conversion effects.

## 18. Godot Script Extension

NCL's game integration relies heavily on Mod Loader Script Extension and Godot inheritance rather than replacing Brotato systems.

Examples:

```gdscript
extends "res://singletons/run_data.gd"
```

or:

```gdscript
extends "res://singletons/item_service.gd"
```

When overriding parent behavior, preserve the original implementation whenever appropriate:

```gdscript
func some_func():
    var result = .some_func()
    # add your behavior
    return result
```

Official reference: [GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html).

## 19. Resource lifecycle: add and remove are a pair

NCL's core lifecycle is:

```gdscript
add_resources()
remove_resources()
```

Registration covers the content groups represented by `NewContent`, while teardown reverses those changes and rebuilds relevant runtime pools/lookups.

Therefore, avoid using direct global-array mutation as your primary registration mechanism:

```gdscript
ItemService.items.append(my_item)
```

Instead, put the Resource into `NewContentData.tres` and let NCL own the lifecycle.

## 20. Multiple mods using one NCL instance

A normal stack may look like:

```text
NCL
 ├── Mod A
 ├── Mod B
 └── Mod C
```

Each dependent mod can provide its own:

```text
NewContentData.tres
NewContentDataDLC1.tres
```

NCL combines these into shared Brotato services, so IDs must be distinguishable across the entire mod stack.

Recommended naming:

```text
<namespace>_<content_name>
```

For example:

```text
fantasy_prism_tower
fantasy_soul_link
yztato_chisefengbao
```

Avoid overly generic IDs such as `sword`, `boss`, or `item01`.

## 21. Godot resource-management rules

### Use the Godot FileSystem dock

`.tres` files store external Resource paths. Prefer moving and renaming resources through the Godot FileSystem dock rather than arbitrary OS-level file moves.

### Keep resource boundaries explicit

```text
NewContentData.tres
├── CharacterData.tres
├── WeaponData.tres
├── ItemData.tres
└── EffectData.tres
```

### Keep file responsibilities clear

```text
.tres → data
.gd   → runtime behavior
.tscn → scene composition
```

## 22. Troubleshooting order

When content is missing, isolate the failure layer:

```text
1. Is Mod Loader finding the mod?
2. Does manifest.json depend on NCL?
3. Does NewContentData.tres exist at the mod root?
4. Can Godot open it in the Inspector?
5. Can every referenced Resource open?
6. Does [NCL] Content report appear?
7. Are there duplicate IDs?
8. Did the owning Brotato service receive the Resource?
9. Does the feature require another Script Extension?
```

Search the Mod Loader log for:

```text
[NCL]
Successfully load NewContentData.tres
Successfully load NewContentDataDLC1.tres
Content report: ...
Duplicate ids ...
```

The discovery/report implementation is in [`extensions/progress_data.gd`](../extensions/progress_data.gd).

## 23. Compatibility and regression testing

Current baseline:

```text
NCL         1.1.0
Brotato     1.15.4
Mod Loader 6.3.0
```

Because NCL is a shared foundation, changes should be tested against more than the framework itself:

```text
NCL
 ↓
content-heavy dependent mod
 ↓
DLC-dependent mod
 ↓
runtime-extension-heavy mod
```

Pay particular attention to:

```text
ProgressData
RunData
Main
WeaponService
ItemService
Utils
```

## 24. Recommended decision process

For a new feature:

```text
New feature
    ↓
data or behavior?
    ↓
data → Godot Resource
    ↓
register through NewContentData
    ↓
behavior → identify the owning Brotato system
    ↓
prefer Script Extension / inheritance
    ↓
lifecycle-sensitive → Hook
    ↓
Run-persistent state → RunData tracking
    ↓
shared algorithm → Utils
```

Avoid starting with a giant custom Manager and then forcing Brotato into it. NCL exists to keep ownership boundaries visible.

## 25. Complete miniature example

```text
MyDemoMod/
├── manifest.json
├── NewContentData.tres
└── content/
    ├── characters/demo_character_data.tres
    ├── weapons/demo_weapon_data.tres
    └── items/demo_item_data.tres
```

`manifest.json`:

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

Inspector:

```text
My Id: DemoMod
Characters:
  - demo_character_data.tres
Weapons:
  - demo_weapon_data.tres
Items:
  - demo_item_data.tres
```

Runtime flow:

```text
NCL discovery
    ↓
load NewContentData.tres
    ↓
register Character / Weapon / Item
    ↓
initialize tracking / pools / lookup
```

## 26. Release checklist

```text
[ ] manifest.json declares Yoko-NewContentLoader
[ ] NewContentData.tres is at the mod root
[ ] major .tres files open in the Godot Inspector
[ ] external Resource paths are valid
[ ] all IDs are unique
[ ] translations are registered
[ ] DLC resources are isolated in NewContentDataDLC1.tres
[ ] DLC runtime behavior is in extensions/dlc_1_data.gd
[ ] class_service.gd exists when custom Global Classes are needed
[ ] runtime behavior is not placed in NewContent.gd
[ ] persistent Run state uses RunData tracking
[ ] lifecycle work uses End-of-Wave Hooks
[ ] no parallel ItemService / RunData database is maintained
[ ] the target dependency stack boots successfully
[ ] [NCL] Content Report was checked
[ ] duplicate-ID errors were checked
[ ] Brotato / Mod Loader versions were verified
```

## 27. Reference material

### Godot 3.x

- [Resources](https://docs.godotengine.org/en/3.5/tutorials/scripting/resources.html)
- [GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html)
- [GDScript Exports](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_exports.html)
- [GDScript / yield](https://docs.godotengine.org/en/3.5/classes/class_%40gdscript.html)

### Brotato Mod Loader

- [Godot Mod Loader documentation](https://wiki.godotmodding.com/)

### NCL source

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

**Yoko-NewContentLoader · Author content as Godot Resources, integrate through Brotato's existing runtime boundaries.**

</div>
