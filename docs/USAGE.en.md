# Yoko-NewContentLoader — Usage & Developer Guide

> A detailed manual for Brotato mod developers using Godot 3.x and Brotato Mod Loader.
>
> **Baseline:** NCL 1.1.0 · Brotato 1.15.4 · Brotato Mod Loader 6.3.0 · Godot 3.x / GDScript
>
> This guide explains the actual architecture and workflow of the current repository: Godot `Resource` and `.tres` authoring, Inspector-driven content composition, Mod Loader script extensions, DLC-aware loading, resource lifecycle, global classes, wave hooks, tracking, and the shared runtime helper API.

<div align="center">

### 📖 中文文档

[阅读中文版使用与开发手册 →](USAGE.md)

</div>

## 1. What NCL is

`Yoko-NewContentLoader` is not a gameplay mod and not merely a file loader. It is shared infrastructure for content-heavy Brotato mods.

A dependent mod describes content with Godot Resources. NCL discovers that mod, loads and merges its content, respects the game's DLC boundary, registers the resources into Brotato's existing services, provides paired teardown, and exposes reusable runtime extensions.

The architecture is:

```text
Godot Editor
    │
    │ Resource / .tres
    ▼
Dependent Mod
    │
    ├── manifest.json
    ├── NewContentData.tres
    ├── NewContentDataDLC1.tres   (optional)
    ├── content/**/*.tres
    ├── translations/*.translation
    └── extensions/*.gd
    │
    ▼
Yoko-NewContentLoader
    │
    ├── discover dependent mods
    ├── load base content
    ├── detect / merge DLC content
    ├── register / remove resources
    ├── discover global classes
    ├── install Brotato script extensions
    └── expose runtime helpers
    │
    ▼
Brotato runtime services
```

The important design rule is: **NCL does not replace Brotato's data model. It gives mods a common way to feed data into it.**

The repository currently extends selected Brotato systems including `ProgressData`, `RunData`, `Utils`, `Main`, `WeaponService`, `FloatingTextManager`, and `ItemService`. fileciteturn36file0

### Why this is a good foundation

Godot Resources are data containers with native serialization, Inspector editing, recursive Resource references, and `.tres` text storage that is friendly to version control. citeturn479829search2turn479829search5

That makes a content mod naturally look like:

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
      ↓
Brotato services
```

This also avoids building a second Item/Weapon database that can drift away from the game.

> **Compatibility boundary:** using the game's existing DLC, `ProgressData`, and service boundaries generally reduces duplication and makes large mod stacks easier to maintain. It does **not** guarantee compatibility across every Brotato version or every combination of script extensions. Engine/API changes, duplicate IDs, and multiple mods modifying the same service can still conflict.

---

# 2. Quick start: add a new NCL-powered mod in five minutes

## 2.1 Declare the dependency

Add NCL to your `manifest.json`:

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

NCL scans the Mod Loader's known mods and only processes projects whose manifest explicitly depends on `Yoko-NewContentLoader`. fileciteturn39file0

## 2.2 Create your Godot content resources

A recommended layout is:

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

The directory names are conventions, not the loader contract. What matters is that the Resources you create can be referenced by `NewContentData.tres`.

Godot 3.x's `export(Array, Resource)` syntax exposes Resource arrays in the Inspector, making drag-and-drop `.tres` composition practical. citeturn479829search6

## 2.3 Start from `NewContent.tres`

NCL ships a `NewContent.tres` template using `NewContent.gd`. The template already serializes the major content arrays. fileciteturn46file0

Copy it into your mod as:

```text
NewContentData.tres
```

Then edit it in the Godot Inspector.

## 2.4 Populate the Inspector

For example:

```text
content/characters/demo_character_data.tres
content/weapons/demo_weapon_data.tres
content/items/demo_item_data.tres
```

Then:

```text
NewContentData.tres
  Characters  → demo_character_data.tres
  Weapons     → demo_weapon_data.tres
  Items       → demo_item_data.tres
```

## 2.5 Usually do not call `add_resources()` yourself

The normal dependent-mod workflow is **not**:

```gdscript
content.add_resources()
```

Instead:

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

NCL's `ProgressData` extension discovers the content Resource automatically. fileciteturn39file0

Direct `add_resources()` / `remove_resources()` calls are advanced lifecycle controls and should be used deliberately.

---

# 3. The Godot model behind NCL

## 3.1 Resource vs Node

For NCL development, use this mental model:

```text
Node
→ scene instance / runtime behavior

Resource
→ serialized, reusable data
```

Godot's official documentation describes Resource as a data container. Resources can be scripted, serialized as `.tres` / `.res`, referenced from other Resources, and edited directly in the Inspector. citeturn479829search2

That maps directly to NCL:

```text
Resource files describe content.
Script extensions describe runtime behavior.
NewContentData describes what should be registered.
```

## 3.2 Why `.tres` is preferred

For a large mod, `.tres` provides three useful properties:

- Godot can edit it directly in the Inspector.
- Resource references remain first-class instead of being manually reconstructed from IDs.
- Text serialization produces useful Git diffs. citeturn479829search2

Prefer:

```text
one character → one .tres
one weapon    → one .tres
one item      → one .tres
one effect    → one .tres
```

and let `NewContentData.tres` aggregate them.

## 3.3 Why not JSON?

Brotato content is a graph of Resources, not only primitive values. A weapon can reference icons, effects, stat Resources, scenes, and other assets.

Godot can recursively serialize Resource properties, which is exactly what this model needs. citeturn479829search2

JSON is useful for interchange data; Godot Resources are better suited to authored game content.

## 3.4 Exported properties are the editor contract

NCL's `NewContent` script uses Godot 3.x export syntax such as:

```gdscript
export(Array, Resource) var weapons = []
export(Array, Resource) var items = []
export(Array, Translation) var translations
```

Exported properties are serialized into the attached Resource/Scene and exposed in the Inspector. citeturn479829search6

This is why NCL can provide a common authoring surface without a custom editor plugin.

---

# 4. The `NewContent` Resource: complete field reference

The current `NewContent.gd` defines the following major groups. fileciteturn34file0

| Field | Type | Purpose |
| :--- | :--- | :--- |
| `my_id` | `String` | Identity of the content collection |
| `groups_in_all_zones` | `Array, Resource` | Zone-wide group resources |
| `music_tracks` | `Array, Resource` | Music Resources |
| `backgrounds` | `Array, Resource` | Background resources |
| `characters` | `Array, Resource` | Character content |
| `entities` | `Array, Resource` | General entities |
| `elites` | `Array, Resource` | Elite definitions |
| `bosses` | `Array, Resource` | Boss definitions |
| `stats` | `Array, Resource` | Custom stat Resources |
| `items` | `Array, Resource` | Item definitions |
| `weapons` | `Array, Resource` | Weapon definitions |
| `effects` | `Array, Resource` | Effect definitions |
| `consumables` | `Array, Resource` | Consumable definitions |
| `upgrades` | `Array, Resource` | Upgrade definitions |
| `sets` | `Array, Resource` | Set definitions |
| `difficulties` | `Array, Resource` | Difficulty definitions |
| `icons` | `Array, Resource` | In-game icon Resources |
| `title_screen_backgrounds` | `Array, Resource` | Title-screen backgrounds |
| `translations` | `Array, Translation` | Translation Resources |
| `challenges` | `Array, Resource` | Challenge definitions |
| `zones` | `Array, Resource` | Zone definitions |
| `tracked_items` | `Dictionary` | RunData item tracking schema |
| `tracked_effects` | `Dictionary` | NCL effect-tracking schema |
| `primary_stats_list` | `Array, String` | Additional primary stat keys |
| `effect_keys_full_serialization` | `Array, String` | Effect keys included in full serialization |
| `effect_keys_with_weapon_stats` | `Array, String` | Effect keys associated with weapon-stat serialization |
| `translation_keys_needing_operator` | `Dictionary` | Special Text operator handling |
| `translation_keys_needing_percent` | `Dictionary` | Special Text percent handling |
| `scene_effect_behaviors` | `Array, Resource` | Scene-level effect behavior definitions |
| `enemy_effect_behaviors` | `Array, Resource` | Enemy effect behavior definitions |
| `player_effect_behaviors` | `Array, Resource` | Player effect behavior definitions |

The intended usage is consistent: **describe the content in a Resource, then let NCL connect it to the owning Brotato service.**

## 4.1 `my_id`

```gdscript
export(String) var my_id
```

This is the identity of the entire content collection. NCL generates a hash from it.

Use a stable namespace-level identifier such as:

```text
MyMod
YokoFantasy
YzTato
```

Do not reuse the same collection identity for unrelated modules.

## 4.2 `groups_in_all_zones`

Registers group resources intended to be available across zones. Think of it as a zone-group injection mechanism rather than a second Zone database.

## 4.3 `music_tracks`

Registers music-related Resources. Keep actual audio files under your project's normal Godot asset structure and let the relevant Resource reference them.

Example:

```text
content/music/
├── battle_01.ogg
└── shop_01.ogg
```

## 4.4 `backgrounds`

Registers backgrounds and also adds them to existing zones' `default_backgrounds`; teardown reverses that operation. fileciteturn34file0

This is useful when one background should become a valid default for multiple zone entries.

## 4.5 `characters`

Registers Character Resources into `ItemService.characters`.

```text
CharacterData.tres
        ↓
NewContentData.tres / characters
        ↓
NCL
        ↓
ItemService.characters
```

The Character Resource itself should follow Brotato's own data model.

## 4.6 `entities`

Registers Entity Resources for general special units, pets, turrets, map entities, and other spawnable content.

## 4.7 `elites` and `bosses`

Registers Elite and Boss definitions. Keep complex runtime behavior in dedicated scripts or behavior Resources instead of placing it in `NewContent.gd`.

## 4.8 `stats`

Registers Stat Resources. After registration NCL regenerates stat hashes and resets the stat-key state. fileciteturn34file0

That means a dependent mod should not create its own parallel stat-key initialization mechanism.

## 4.9 `items`

Registers Item Resources. A common pattern is:

```text
content/items/my_item/
├── my_item_data.tres
└── icon.png
```

The `.tres` should reference the imported Godot assets.

## 4.10 `weapons`

Registers Weapon Resources and rebuilds an NCL weapon lookup keyed by `my_id_hash`. fileciteturn38file0

### Starting weapons

Weapon data can declare `add_to_chars_as_starting`. NCL will add the weapon to the referenced characters' `starting_weapons` collections and avoid duplicate insertion; teardown reverses it. fileciteturn34file0

This removes the need for a separate startup pass in your mod.

## 4.11 `effects`

Registers Effect Resources. Use the Effect Behavior arrays when the Effect also needs custom runtime behavior.

## 4.12 `consumables`

Registers Consumables. NCL also extends `ItemService.get_consumable_to_drop()` so active DLC data can post-process a selected consumable through `ncl_update_consumable_to_get()`. fileciteturn38file0

## 4.13 `upgrades`

Registers upgrade Resources. Keep text keys, icons, effects, and values in the upgrade data itself; the loader should remain the registration boundary.

## 4.14 `sets`

Registers Set Resources. Set-specific gameplay logic belongs in the set/effect implementation, not in the loader.

## 4.15 `difficulties`

Registers Difficulty Resources for new or mod-specific difficulty definitions.

## 4.16 `icons`

Registers in-game Icon Resources. These can also be referenced by NCL's custom damage-number display.

## 4.17 `title_screen_backgrounds`

Registers title-screen background Resources.

## 4.18 `translations`

This field is explicitly typed as `Array, Translation`:

```gdscript
export(Array, Translation) var translations
```

When resources are added, NCL calls `TranslationServer.add_translation()`. Teardown removes the same Translation Resource. fileciteturn34file0

A recommended layout is:

```text
translations/
├── MyMod.en.translation
├── MyMod.zh.translation
└── MyMod.ja.translation
```

## 4.19 `challenges`

Registers Challenge Resources and refreshes Brotato's stat-challenge data. Teardown removes the registered challenge entries. fileciteturn34file0

## 4.20 `zones`

Registers Zone Resources into `ZoneService.zones`. NCL is responsible for the lifecycle; the Zone itself remains a Brotato-style Zone Resource.

---

# 5. RunData tracking

## 5.1 `tracked_items`

```gdscript
export(Dictionary) var tracked_items = {}
```

This defines tracking keys that are converted and merged into `RunData.init_tracked_items`.

Think of it as a small schema declaration:

```text
NewContentData
      ↓
tracking schema
      ↓
RunData initialization
      ↓
runtime values
```

## 5.2 `tracked_effects`

```gdscript
export(Dictionary) var tracked_effects = {}
```

NCL hashes and merges this schema into `RunData.ncl_init_tracked_effects`. The RunData extension then initializes tracking state for four player slots. fileciteturn40file0

Runtime methods:

```gdscript
RunData.ncl_add_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_set_effect_tracking_value(key_hash, value, player_index)
RunData.ncl_get_effect_tracking_value(key_hash, player_index)
```

When the tracking value is an Array, the optional `index` parameter targets an element. fileciteturn40file0

Use this for information that should follow RunData rather than live in an unrelated global dictionary.

## 5.3 Primary stats

```gdscript
export(Array, String) var primary_stats_list = []
```

NCL converts these stat names to hashes and appends them to `RunData.primary_stats_list`. fileciteturn34file0

This is useful when a mod introduces a stat that should participate in Brotato's primary-stat classification.

---

# 6. Effect serialization metadata

NCL exposes:

```gdscript
export(Array, String) var effect_keys_full_serialization = []
export(Array, String) var effect_keys_with_weapon_stats = []
```

Use these when a custom Effect has state that needs to be known by Brotato's related serialization paths.

The design goal is central registration:

```text
custom Effect key
      ↓
NewContentData metadata
      ↓
RunData serialization logic
```

Do not duplicate the same registration in multiple mod scripts.

---

# 7. Text metadata: operators and percentages

```gdscript
export(Dictionary) var translation_keys_needing_operator = {}
export(Dictionary) var translation_keys_needing_percent = {}
```

At registration time these merge into Brotato's Text lookup dictionaries; teardown removes them. fileciteturn34file0

Use these registries when your translation keys need the existing Text system's special operator/percent handling.

---

# 8. Effect Behavior: keep data and behavior separate

NCL exposes three behavior collections:

```gdscript
scene_effect_behaviors
enemy_effect_behaviors
player_effect_behaviors
```

Use the following split:

```text
Resource
→ what the content is

Behavior
→ what it does at runtime
```

The corresponding Resources are added to `EffectBehaviorService` and removed during teardown. fileciteturn34file0

For a complex effect, prefer:

```text
MyEffectData.tres
MyEffectBehavior.gd
```

rather than extending `NewContent.gd` with gameplay-specific logic.

---

# 9. DLC-aware loading

DLC support is one of NCL's most important architectural boundaries.

## 9.1 Base content + DLC content

The current `ProgressData` extension defines:

```gdscript
var mod_content_configs = [
    ["NewContentData.tres", "", ""],
    ["NewContentDataDLC1.tres", "res://dlcs/dlc_1/dlc_data.tres", "abyssal_terrors"]
]
```

Therefore a dependent mod may provide:

```text
NewContentData.tres
NewContentDataDLC1.tres
```

If the `abyssal_terrors` DLC is not available, the DLC1 file is skipped. fileciteturn39file0

## 9.2 Why use the game's DLC boundary?

Without NCL, each mod could independently decide how to detect the DLC, how to conditionally load resources, and how to create fallback data.

With NCL:

```text
Base Content
     +
DLC Content
     ↓
NCL
     ↓
Brotato ProgressData / DLC
```

This keeps the compatibility decision at the shared infrastructure level.

## 9.3 Merge semantics

When both content Resources exist, NCL duplicates the base Resource and merges properties:

```text
Array      → append DLC entries
Dictionary → merge DLC keys, allowing override
Other      → DLC value wins
```

The implementation is in `ncl_auto_merge_property()`, `ncl_merge_arrays()`, and `ncl_merge_dictionaries()`. fileciteturn39file0

### Recommended mental model

Treat `NewContentDataDLC1.tres` as an **incremental DLC layer** over the base content, not as an unrelated second mod.

---

# 10. Full DLC authoring workflow in Godot

Example layout:

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

In the base Resource:

```text
Characters → base_character_data.tres
Weapons    → base_weapon_data.tres
```

In the DLC Resource:

```text
Characters → dlc_character_data.tres
Weapons    → dlc_weapon_data.tres
```

At runtime:

```text
DLC available
    ↓
base + DLC1
    ↓
merged NewContent
```

Otherwise:

```text
base only
```

This is especially useful for large content packs because optional DLC assets remain isolated at authoring time.

---

# 11. Custom Global Classes with `class_service.gd`

NCL can discover custom Global Class registrations from dependent mods.

## 11.1 File contract

Create:

```text
extensions/services/class_service.gd
```

with:

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

This format is used by the real `Yoko-YzTato` dependent project. fileciteturn56file0

## 11.2 Discovery process

At startup NCL:

```text
iterates mods
    ↓
checks NCL dependency
    ↓
looks for class_service.gd
    ↓
loads get_classes()
    ↓
collects class definitions
    ↓
deduplicates them
    ↓
removes stale _global_script_classes entries
    ↓
registers valid classes
```

NCL also checks whether the referenced class path exists. fileciteturn36file0

## 11.3 Godot inheritance matters

A custom class often extends a Brotato base Resource or script:

```gdscript
extends RangedWeaponStats
```

Godot 3.x supports script inheritance through `extends`. When overriding a method, the parent implementation can be invoked with the `.` prefix:

```gdscript
func calculate_value():
    var base = .calculate_value()
    return base + my_bonus
```

citeturn479829search0

This is a central compatibility technique in NCL's architecture: **extend the existing game behavior and preserve its parent implementation whenever possible.**

---

# 12. End-of-Wave Hooks

NCL extends Brotato's `Main` end-of-wave path and exposes four lifecycle points:

```text
before_wave_rewards
after_wave_rewards
before_end_run_scene
before_change_scene
```

Corresponding constants exist in `extensions/main.gd`. fileciteturn37file0

## 12.1 Register a hook

```gdscript
main.ncl_register_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards",
    100
)
```

Parameters:

```text
hook_name
→ lifecycle stage

owner
→ Object that owns the callback

method_name
→ method to call

priority
→ smaller value executes earlier
```

Hooks are sorted by priority and then method name. Do not rely on incidental registration order. fileciteturn37file0

## 12.2 Unregister

```gdscript
main.ncl_unregister_end_wave_hook(
    "before_wave_rewards",
    self,
    "_on_before_wave_rewards"
)
```

## 12.3 Godot 3.x coroutines

A callback may yield and return a `GDScriptFunctionState`. NCL detects that state and waits for its `completed` signal.

For example:

```gdscript
func _on_before_wave_rewards():
    yield(get_tree(), "idle_frame")
    do_something()
```

Godot 3.x's `yield()` can pause execution until a signal is emitted, and yielded functions expose a `completed` signal when they finish. citeturn479829search3turn479829search4

Use Wave Hooks for lifecycle-level work such as reward preprocessing or scene-transition preparation. Do not use them as a universal event bus for every gameplay effect.

---

# 13. Weapon lookup

NCL maintains an internal lookup:

```gdscript
ncl_weapon_my_id_lookup
```

with:

```gdscript
ncl_is_weapon_id(weapon_my_id)
ncl_get_weapon_from_id(weapon_my_id)
ncl_rebuild_weapon_my_id_lookup()
```

fileciteturn38file0

Prefer:

```gdscript
var weapon = ItemService.ncl_get_weapon_from_id(weapon_id_hash)
```

over repeatedly scanning the complete weapon array.

---

# 14. RunData: tracking and weapon helpers

NCL extends `RunData` and includes its custom effect tracking in save/resume state handling. fileciteturn40file0

Useful helpers:

```gdscript
RunData.ncl_get_nb_weapon(weapon_my_id_hash, player_index)
RunData.ncl_remove_weapon_by_id(weapon, player_index)
```

The removal path also runs the existing post-removal behavior, so direct array mutation should not be your default approach.

---

# 15. `Utils.ncl_*` runtime API

The current utility extension contains these main methods:

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

fileciteturn43file0

## 15.1 Quiet stat mutation

```gdscript
Utils.ncl_quiet_add_stat(stat_hash, value, player_index)
Utils.ncl_quiet_set_stat(stat_hash, value, player_index)
```

These update player effects, mark stats dirty, and reset the stat cache. fileciteturn43file0

Use them for internal counters or state changes where you do not need the ordinary visual stat-update path.

## 15.2 Modifier transform

```gdscript
Utils.ncl_curse_effect_value(value, modifier, options)
```

Supported options include:

```text
modifier_scale
step
process_negative
is_negative
min_num
max_num
```

The helper applies the sign-aware transform and then snaps/clamps the result. fileciteturn43file0

The name comes from the existing curse implementation, but the helper is reusable for any consistent modifier transformation.

## 15.3 Scaling damage and counts

```gdscript
Utils.ncl_get_scaling_stats_dmg(scaling_stats, player_index)
Utils.ncl_get_dmg_with_scaling_stats(base_damage, scaling_stats, player_index)
Utils.ncl_get_num_with_scaling_stats(base_num, scaling_stats, player_index)
```

These are useful for formulas such as:

```text
base value + Stat × coefficient
```

## 15.4 User-facing scaling text

```gdscript
Utils.ncl_get_dmg_text_with_scaling_stats(...)
Utils.ncl_get_num_text_with_scaling_stats(...)
```

They can present the final value, original value, count, scaling-stat text, and positive/negative color conventions used by the game. fileciteturn43file0

## 15.5 Range scaling

```gdscript
Utils.ncl_get_range_with_detection(...)
Utils.ncl_get_range_text_with_scaling(...)
```

Use these when a range formula needs to combine base range, Range stat scaling, and the game's detection baseline.

## 15.6 Weapon replacement

```gdscript
Utils.ncl_change_weapon_within_run(...)
Utils.ncl_change_weapon_within_shop(...)
```

These handle replacement during a run or while the shop is active. The implementation takes care of details such as weapon position, tracked value, cursed state, and shop/UI refresh behavior. fileciteturn43file0

---

# 16. Custom damage numbers

NCL extends `FloatingTextManager` and recognizes metadata on `TakeDamageArgs`:

```text
custom_color
custom_icon
```

fileciteturn42file0

Create the arguments with:

```gdscript
var args = Utils.ncl_create_custom_damage_args(
    player_index,
    Color(1, 0.4, 0.2),
    my_icon_hash
)
```

The intended pipeline is:

```text
custom damage logic
       ↓
TakeDamageArgs
       ↓
NCL FloatingTextManager
       ↓
Brotato damage-number UI
```

This lets a mod reuse the game's existing display path.

---

# 17. Spawning consumables

```gdscript
Utils.ncl_spawn_consumable(
    consumable_id,
    num,
    pos,
    spread
)
```

The implementation reuses Brotato's consumable pool when possible, creating a Scene instance only when no reusable object is available. It then applies the consumable data, texture, spawn position, and destination. fileciteturn44file0

This is another example of NCL preferring existing Godot scene/object-pool mechanisms over a parallel object manager.

---

# 18. Gear API: treat Items and Weapons uniformly

NCL defines:

```gdscript
enum GearType {ITEM, WEAPON}
```

and exposes:

```gdscript
Utils.ncl_judge_item_type_from_my_id(gear_id)
Utils.ncl_get_nb_gear(gear_id, player_index)
Utils.ncl_add_gear_by_id(gear_id, player_index, num)
Utils.ncl_remove_gear_by_id(gear_id, player_index, num)
Utils.ncl_get_gear_name_from_id(gear_id, num)
```

The utility determines whether the ID belongs to an Item or Weapon, then routes to the correct service and RunData method. fileciteturn44file0

Useful for:

```text
Debug tools
Quest rewards
Jobs / classes
Events
Achievements
Conversion effects
```

Example:

```gdscript
Utils.ncl_add_gear_by_id(my_weapon_id, player_index, 1)
```

---

# 19. Stat names and composite hashes

## `ncl_get_true_stat_name`

```gdscript
Utils.ncl_get_true_stat_name(stat)
```

Converts internal stat keys into display-oriented translation keys, with special handling for values such as `number_of_enemies`, `different_item`, and the empty key. fileciteturn44file0

## `ncl_generate_composite_hash`

```gdscript
Utils.ncl_generate_composite_hash(values)
```

Combines a list of values with the implementation's fixed prime (`31`) to produce a stable composite hash. fileciteturn43file0

---

# 20. DLC runtime script extension

A DLC-aware mod may also provide:

```text
extensions/dlc_1_data.gd
```

and extend the game's DLC data script directly:

```gdscript
extends "res://dlcs/dlc_1/dlc_1_data.gd"
```

The real `Yoko-YzTato` project uses this pattern to override `curse_item()` and then combine its own behavior with the base DLC implementation. fileciteturn48file0

NCL's `ProgressData` extension looks for this file in dependent mods and installs it as a script extension when present. fileciteturn39file0

This is a direct application of Godot 3.x script inheritance and Mod Loader extension behavior.

---

# 21. How NCL itself boots

`mod_main.gd` initializes NCL by gathering Mod Loader data and installing two kinds of extensions:

```text
NCL startup
   ↓
get all ModData
   ↓
install global-class metadata
   ↓
install script extensions
```

The current extension set is:

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

This is why dependent mods should not reinstall NCL's own extensions.

---

# 22. Multiple mods using NCL

A normal stack may look like:

```text
NCL
 ├── Mod A
 ├── Mod B
 └── Mod C
```

Each mod can expose its own:

```text
NewContentData.tres
NewContentDataDLC1.tres
```

NCL loads them independently and registers their resources into shared Brotato services.

Therefore IDs must be globally distinguishable across the mod stack.

NCL's content report checks content arrays for duplicate `my_id` values and logs duplicates as errors. fileciteturn39file0

### Recommended naming

```text
<namespace>_<content_name>
```

Example:

```text
fantasy_prism_tower
fantasy_soul_link
yztato_chisefengbao
```

Avoid generic IDs such as:

```text
sword
boss
item01
```

---

# 23. Godot resource-management rules for large mods

## 23.1 Prefer external `.tres` boundaries

Keep major resources separate:

```text
NewContentData.tres
    ├── CharacterData.tres
    ├── WeaponData.tres
    ├── ItemData.tres
    └── EffectData.tres
```

Godot supports recursive Resources, but overly large monolithic Resources are harder to review and merge. citeturn479829search2

## 23.2 Move and rename from the Godot editor

Resource files store references to external assets. Prefer the Godot FileSystem dock for moves and renames so the editor can keep references coherent.

## 23.3 Keep runtime behavior in scripts

Use:

```text
.tres → data
.gd   → runtime behavior
.tscn → scene composition
```

This follows Godot's natural Node/Resource separation and keeps the NCL registration layer small.

---

# 24. A complete recommended project layout

For a medium/large mod:

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

Use this mental boundary:

```text
content/        → what the mod contains
extensions/     → how it behaves at runtime
translations/   → how it is presented
NewContentData  → what should be registered
manifest.json   → how it participates in the mod ecosystem
```

---

# 25. A complete miniature example

Goal:

```text
one character
one weapon
one item
one tracking value
```

Project:

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

Manifest:

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

Tracked Effects:
  demo_kills: 0
```

Runtime:

```text
NCL finds DemoMod
      ↓
loads NewContentData.tres
      ↓
registers character / weapon / item
      ↓
initializes tracking
      ↓
rebuilds unlocked pools / weapon lookup
```

The dependent mod does not need to duplicate this infrastructure.

---

# 26. Debugging: read the `[NCL]` log first

Search Mod Loader logs for:

```text
[NCL]
```

Useful messages include:

```text
Successfully load NewContentData.tres
Successfully load NewContentDataDLC1.tres
Successfully load <mod_id>
Content report: characters=..., weapons=..., items=...
```

### `Dependency missing`

The mod does not declare:

```json
"Yoko-NewContentLoader"
```

### `NewContentData.tres not found`

The file is missing, misnamed, or not located at the mod root.

### `DLC ... not available`

The optional DLC is unavailable, so NCL correctly skipped the DLC layer.

### `Duplicate ids`

One or more Resource IDs collide within the discovered content.

The discovery and report logic comes from `extensions/progress_data.gd`. fileciteturn39file0

---

# 27. Troubleshooting order

When content is missing, isolate the layer first:

```text
1. Is Mod Loader finding the mod?
        ↓
2. Does manifest.json depend on NCL?
        ↓
3. Does NewContentData.tres exist?
        ↓
4. Can Godot open the Resource in the Inspector?
        ↓
5. Can every referenced child Resource open?
        ↓
6. Does the NCL Content Report appear?
        ↓
7. Are there duplicate IDs?
        ↓
8. Did the owning Brotato service receive the Resource?
        ↓
9. Does the feature require a runtime extension?
```

This separates:

```text
Godot asset problems
NCL registration problems
Brotato runtime problems
```

instead of treating all three as one failure.

---

# 28. NCL development and compatibility strategy

The current manifest declares:

```text
NCL             1.1.0
Brotato         1.15.4
Mod Loader      6.3.0
Dependencies    none
```

fileciteturn47file0

Because NCL is a shared base layer, a change here should be tested more broadly than a normal content-only change.

Recommended regression stack:

```text
NCL itself
   ↓
at least one content-heavy dependent mod
   ↓
at least one DLC-dependent mod
   ↓
at least one mod using runtime extensions
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

These are among the current extension boundaries installed by `mod_main.gd`. fileciteturn36file0

---

# 29. When NCL is the right abstraction

NCL is a strong fit when a mod has:

```text
✔ many characters / weapons / items
✔ custom effects
✔ optional DLC content
✔ cross-wave or RunData state
✔ custom Global Classes
✔ lifecycle hooks
✔ shared runtime utilities
✔ deep reuse of Brotato services
✔ long-term maintenance requirements
```

It is not necessarily needed for:

```text
△ a tiny one-file UI patch
△ one numeric tweak
△ a patch that adds no Resource content
```

The value of NCL grows with the amount of content and runtime integration your mod needs.

---

# 30. The recommended decision process

For a new feature, decide in this order:

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
prefer script extension / inheritance
    ↓
lifecycle-sensitive → use a Hook
    ↓
Run-persistent state → use RunData tracking
    ↓
shared algorithm → use Utils
```

Avoid starting with a giant custom Manager and then forcing Brotato into it. NCL is designed to keep the game's existing ownership boundaries visible.

---

# 31. Release checklist

Before publishing a mod that depends on NCL:

```text
[ ] manifest.json declares Yoko-NewContentLoader
[ ] NewContentData.tres is at the mod root
[ ] all major .tres resources open in the Godot Inspector
[ ] external Resource paths are valid
[ ] all my_id values are unique
[ ] translations are registered
[ ] DLC resources are isolated in NewContentDataDLC1.tres
[ ] DLC runtime behavior is in extensions/dlc_1_data.gd
[ ] class_service.gd exists when custom Global Classes are needed
[ ] runtime behavior is not placed into NewContent.gd
[ ] persistent Run state uses RunData tracking
[ ] lifecycle work uses End-of-Wave Hooks
[ ] no second parallel ItemService / RunData database exists
[ ] the game boots with the target dependency stack
[ ] [NCL] Content Report was checked
[ ] Duplicate ID errors were checked
[ ] Brotato and Mod Loader versions were verified
```

---

# 32. Reference material

Godot:

- [Godot 3.5 Resources](https://docs.godotengine.org/en/3.5/tutorials/scripting/resources.html)
- [Godot 3.5 GDScript Basics](https://docs.godotengine.org/en/3.5/getting_started/scripting/gdscript/gdscript_basics.html)
- [Godot 3.5 GDScript Exports](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_exports.html)
- [Godot 3.5 GDScript / yield](https://docs.godotengine.org/en/3.5/classes/class_%40gdscript.html)

Brotato Mod Loader:

- [Godot Mod Loader documentation](https://wiki.godotmodding.com/)

Project source:

- [`NewContent.gd`](../NewContent.gd) — Resource fields and registration lifecycle
- [`NewContent.tres`](../NewContent.tres) — Godot Resource template
- [`mod_main.gd`](../mod_main.gd) — NCL startup and script extensions
- [`extensions/progress_data.gd`](../extensions/progress_data.gd) — discovery and DLC merge
- [`extensions/run_data.gd`](../extensions/run_data.gd) — tracking and weapon helpers
- [`extensions/utils.gd`](../extensions/utils.gd) — runtime helper API
- [`extensions/main.gd`](../extensions/main.gd) — End-of-Wave Hooks
- [`extensions/item_service.gd`](../extensions/item_service.gd) — weapon lookup and Consumable hook
- [`extensions/weapon_service.gd`](../extensions/weapon_service.gd) — Weapon Service extension
- [`extensions/floating_text_manager.gd`](../extensions/floating_text_manager.gd) — custom damage numbers

---

<div align="center">

**Yoko-NewContentLoader · Author content as Godot Resources, integrate through Brotato's existing runtime boundaries.**

</div>
