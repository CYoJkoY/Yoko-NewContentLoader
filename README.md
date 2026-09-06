# Yoko-NewContentLoader

[![Release](https://img.shields.io/github/v/release/CYoJkoY/Yoko-NewContentLoader?display_name=tag&sort=semver)](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases)
[![License](https://img.shields.io/github/license/CYoJkoY/Yoko-NewContentLoader)](LICENSE)
[![Release Workflow](https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml/badge.svg)](https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml)

> A Brotato content-loading framework for registering custom content and mod-defined extensions at runtime.

Yoko-NewContentLoader provides a `NewContent` resource and a set of script extensions that let dependent mods register custom game content through structured resource data instead of reimplementing the same registration logic in every mod.

It is intended as shared infrastructure for content-heavy Brotato mods, with support for content registration, custom classes, translations, tracked data, stat metadata, effect behaviors, and service extensions.

## What it provides

### Structured content registration

A `NewContent` resource can collect multiple categories of mod content in one place, including:

- Backgrounds
- Characters
- Entities, elites, and bosses
- Stats, items, weapons, effects, consumables, upgrades, and sets
- Difficulties and icons
- Title-screen backgrounds
- Challenges and zones
- Translations
- Scene, enemy, and player effect behaviors

The resource also supports tracked items/effects and stat/effect-key metadata used by dependent content mods.

### Safe add/remove lifecycle

`NewContent` exposes paired `add_resources()` and `remove_resources()` flows. Content is inserted into the corresponding Brotato services, and the same resource can later remove its registered content again.

The loader also refreshes relevant service lookups after modifications, including the unlocked item pool and weapon ID lookup.

### Custom class discovery

For mods depending on Yoko-NewContentLoader, `mod_main.gd` can discover an optional:

```text
extensions/services/class_service.gd
```

It collects the classes exposed by those services, removes obsolete or invalid global class registrations, and registers the current valid class set.

### Script extensions

The loader installs extensions for core Brotato systems such as:

- `ProgressData`
- `RunData`
- `Utils`
- `Main`
- `WeaponService`
- `FloatingTextManager`
- `ItemService`

The project is therefore more than a data container: it also supplies shared compatibility behavior required by content mods built on top of it.

## Installation

Download the latest `NewContentLoader-*.zip` from [Releases](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases) and place it in the game's `mods` directory used by Godot Mod Loader.

Yoko-NewContentLoader is primarily a dependency. Install it before enabling mods that declare it in their `manifest.json` dependencies.

For development, the project uses the standard Mod Loader layout:

```text
mods-unpacked/
└── Yoko-NewContentLoader/
    ├── extensions/
    ├── NewContent.gd
    ├── NewContent.tres
    ├── manifest.json
    └── mod_main.gd
```

See the [Godot Mod Loader documentation](https://github.com/GodotModding/godot-mod-loader/wiki) for current installation and dependency conventions.

## Using NewContent

A dependent mod can create a `NewContent` resource and populate the relevant arrays with its own resources. At runtime, calling `add_resources()` registers those resources into Brotato's services.

Conceptually:

```text
Your Mod
   │
   ├── Characters / Weapons / Items / Effects / Zones / ...
   │
   ▼
NewContent.tres
   │
   ▼
NewContent.add_resources()
   │
   ├── ItemService
   ├── ZoneService
   ├── ChallengeService
   ├── RunData
   ├── EffectBehaviorService
   └── TranslationServer
```

The repository's `NewContent.tres` serves as the base resource template for this pattern.

## Compatibility

| Component | Target |
| :--- | :--- |
| Engine | Godot 3.x / GDScript |
| Mod Loader | 6.2.0 (manifest target) |
| Version | 1.0.0 |

The current manifest does not specify a concrete Brotato game-version range. Treat the Mod Loader target as the primary compatibility baseline and verify dependent mods against the same game build.

## Project structure

```text
Yoko-NewContentLoader/
├── extensions/
│   ├── floating_text_manager.gd
│   ├── item_service.gd
│   ├── main.gd
│   ├── progress_data.gd
│   ├── run_data.gd
│   ├── utils.gd
│   └── weapon_service.gd
├── NewContent.gd
├── NewContent.tres
├── manifest.json
└── mod_main.gd
```

## Related project

[Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) uses Yoko-NewContentLoader as a declared dependency for its content expansion.

## Development

This project is designed as shared modding infrastructure rather than a standalone gameplay mod. Changes to service extensions should be evaluated for compatibility with every dependent content mod, especially changes affecting registration order, removal behavior, global classes, or service lookups.

Release builds are generated automatically from semantic version tags such as:

```text
v1.0.0
v1.1.0
v2.0.0
```

## License

This project is licensed under the [MIT License](LICENSE).

## 💰 Support the Author

If this project saves you time or improves your workflow, consider supporting its development.

<div align="center">
  <a href="https://cyojkoy.github.io/Payment/">
    <img src="https://img.shields.io/badge/Support_the_Author-9E8F7E?style=for-the-badge&logo=buy-me-a-coffee&logoColor=BEB8AE" alt="Support the Author">
  </a>
</div>

---

<div align="center">
  <sub>Yoko-NewContentLoader · Shared Brotato modding infrastructure by CYoJkoY</sub>
</div>
