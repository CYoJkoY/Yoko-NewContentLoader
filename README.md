<div align="center">
  <h1>Yoko-NewContentLoader</h1>
  <p><strong>Shared content infrastructure for Brotato Mod Loader projects.</strong></p>
  <p>Godot Resources · DLC-aware loading · Lifecycle management · Runtime extensions</p>
  <p>
    <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/releases"><img src="https://img.shields.io/github/v/release/CYoJkoY/Yoko-NewContentLoader?display_name=tag&sort=semver&style=flat-square&label=release" alt="Latest release"></a>
    <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/CYoJkoY/Yoko-NewContentLoader/release.yml?style=flat-square&label=build" alt="Build status"></a>
    <img src="https://img.shields.io/badge/Brotato-1.1.15.4-478CBF?style=flat-square" alt="Brotato 1.1.15.4">
    <img src="https://img.shields.io/badge/Mod%20Loader-6.3.0-5965FF?style=flat-square" alt="Mod Loader 6.3.0">
    <a href="LICENSE"><img src="https://img.shields.io/github/license/CYoJkoY/Yoko-NewContentLoader?style=flat-square" alt="MIT License"></a>
  </p>
</div>

> **NCL is a foundation mod, not a gameplay mod.** Dependent projects describe content with Godot `Resource` files, while NCL discovers, merges, registers, removes, and extends that content through Brotato's existing runtime boundaries.

<div align="center">

## <img src="assets/readme/icons/documentation.svg" width="20" height="20" alt=""> Developer Documentation

**Start here before building a mod on top of NCL.**

[中文使用与开发手册](docs/USAGE.md) · [English Usage & Developer Guide](docs/USAGE.en.md)

**Covers:** Godot `Resource` / `.tres`, Inspector workflow, every `NewContent` field, DLC loading, Global Classes, Wave Hooks, RunData tracking, Utility APIs, extension patterns, debugging, and publishing.

</div>

## <img src="assets/readme/icons/overview.svg" width="20" height="20" alt=""> Quick start

A dependent content mod normally needs only:

```text
manifest.json
      ↓
depend on Yoko-NewContentLoader
      ↓
NewContentData.tres
      ↓
fill Resource arrays in the Godot Inspector
      ↓
launch Brotato
      ↓
NCL discovers and registers the content
```

Minimal dependency:

```json
{
  "dependencies": [
    "Yoko-NewContentLoader"
  ]
}
```

Minimal project layout:

```text
MyMod/
├── manifest.json
├── NewContentData.tres
├── content/
└── extensions/
```

For normal content mods, you do **not** need to manually call `add_resources()` during startup. NCL's `ProgressData` integration discovers mods that declare the dependency and loads their `NewContentData.tres` automatically.

## <img src="assets/readme/icons/features.svg" width="20" height="20" alt=""> Why NCL exists

Brotato already owns the runtime systems that understand characters, weapons, items, effects, zones, challenges, RunData, DLCs, and translations. NCL provides a common bridge so many mods can feed those systems without maintaining separate registration frameworks.

```text
Godot Resource graph
        ↓
NewContentData
        ↓
NCL discovery / merge / lifecycle
        ↓
Brotato services
```

The result is intentionally modular:

```text
content data     → what exists
runtime extension→ how special behavior works
NewContentData   → what should be registered
NCL              → how it enters the game
Brotato          → authoritative runtime
```

## <img src="assets/readme/icons/architecture.svg" width="20" height="20" alt=""> Core capabilities

| Area | What NCL provides |
| :--- | :--- |
| Content registration | Characters, entities, elites, bosses, stats, items, weapons, effects, consumables, upgrades, sets, difficulties, icons, backgrounds, zones, challenges, music and more |
| Godot workflow | `Resource` + `.tres` based authoring and Inspector-driven content aggregation |
| DLC | Base content + optional DLC1 content with availability checks and property-level merge behavior |
| Lifecycle | Paired `add_resources()` / `remove_resources()` registration and teardown |
| Global classes | Discover, deduplicate, unregister stale, and register dependent-mod Global Classes |
| Run state | Item/effect tracking, primary-stat registration, weapon helpers |
| Wave lifecycle | Prioritized hooks before/after rewards and before scene transitions |
| Runtime helpers | Weapon lookup/replacement, gear helpers, consumable spawning, damage/range/stat scaling and more |
| UI integration | Custom damage-number colors and icons through the game's existing display path |

## <img src="assets/readme/icons/installation.svg" width="20" height="20" alt=""> Installation

Requirements:

- Brotato **1.1.15.4**
- Brotato Mod Loader **6.3.0**

Download the latest `NewContentLoader-*.zip` from [Releases](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases) and place it in the Mod Loader `mods` directory.

Development layout:

```text
mods-unpacked/
├── Yoko-NewContentLoader/
└── YourMod/
```

## <img src="assets/readme/icons/development.svg" width="20" height="20" alt=""> Related projects

- [Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) — large content expansion using NCL.
- [Yoko-Fantasy](https://github.com/CYoJkoY/Yoko-Fantasy) — systems-heavy expansion using NCL.
- [Yoko-MoreStatsContainer](https://github.com/CYoJkoY/Yoko-MoreStatsContainer) — focused stats UI extension.

## <img src="assets/readme/icons/verification.svg" width="20" height="20" alt=""> Troubleshooting

Check these first:

```text
manifest dependency → NewContentData.tres → Godot Inspector
→ [NCL] Content report → Duplicate IDs → DLC availability
→ required runtime extension → Brotato version
```

The detailed manuals include a layer-by-layer diagnostic procedure and examples for common `[NCL]` log messages.

## <img src="assets/readme/icons/documentation.svg" width="20" height="20" alt=""> Documentation

| Guide | Purpose |
| :--- | :--- |
| [中文：使用与开发手册](docs/USAGE.md) | 从 Godot Resource 创建，到 DLC、Hook、RunData、Utils 和完整排错 |
| [English: Usage & Developer Guide](docs/USAGE.en.md) | Full English guide for authors and maintainers |
| [Godot 3.6 Resources](https://docs.godotengine.org/en/3.6/tutorials/scripting/resources.html) | Resource / `.tres` fundamentals |
| [Godot 3.6 GDScript](https://docs.godotengine.org/en/3.6/getting_started/scripting/gdscript/gdscript_basics.html) | `extends`, inheritance and GDScript patterns |
| [Godot Mod Loader](https://wiki.godotmodding.com/) | Mod Loader installation and extension conventions |

## <img src="assets/readme/icons/heart.svg" width="20" height="20" alt=""> Support

<a href="https://cyojkoy.github.io/Payment/"><img src="assets/readme/support-cta.svg" alt="Support Yoko-NewContentLoader" width="900" style="max-width:100%;height:auto;"></a>

Development support: **https://cyojkoy.github.io/Payment/**

## License

This project is licensed under the [MIT License](LICENSE).

<div align="center">
  <sub>Yoko-NewContentLoader · shared Brotato content infrastructure by CYoJkoY</sub>
</div>
