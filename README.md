<div align="center">
  <img src="assets/hero.svg" alt="Yoko-NewContentLoader — shared Brotato content registration infrastructure" width="1200" style="max-width: 100%; height: auto;">

  <h1>Yoko-NewContentLoader</h1>
  <p><strong>Shared content-registration infrastructure for Brotato Mod Loader projects.</strong></p>
  <p>Structured resources · Lifecycle management · Runtime extensions · Mod interoperability</p>

  <p>
    <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/releases"><img src="https://img.shields.io/github/v/release/CYoJkoY/Yoko-NewContentLoader?display_name=tag&sort=semver&style=flat-square&label=release" alt="Latest release"></a>
    <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/CYoJkoY/Yoko-NewContentLoader/release.yml?style=flat-square&label=build" alt="Build status"></a>
    <img src="https://img.shields.io/badge/Brotato-1.15.4-478CBF?style=flat-square" alt="Brotato 1.15.4">
    <img src="https://img.shields.io/badge/Mod%20Loader-6.3.0-5965FF?style=flat-square" alt="Mod Loader 6.3.0">
    <a href="LICENSE"><img src="https://img.shields.io/github/license/CYoJkoY/Yoko-NewContentLoader?style=flat-square" alt="MIT License"></a>
  </p>

  <p><a href="#why-it-exists">Why</a> · <a href="#content-model">Content model</a> · <a href="#integration-boundary">Integration</a> · <a href="#installation">Install</a> · <a href="#development">Develop</a></p>
</div>

> **Core boundary:** dependent mods describe content as Godot resources; NewContentLoader owns registration and lifecycle integration; Brotato remains the runtime that owns gameplay behavior.

## Why it exists

Brotato content mods repeatedly need to register many resources with existing game services while retaining a clean way to refresh or remove them.

**Yoko-NewContentLoader** provides that shared boundary. A dependent mod supplies structured `NewContent` data, and the loader connects it to Brotato's item, weapon, run, effect, entity, zone, challenge, and translation systems.

```text
Dependent mod
      │
      ▼
NewContent resource
      │
      ▼
add_resources() / remove_resources()
      │
      ▼
Brotato services + targeted extensions
```

The objective is not another gameplay framework. It is reusable infrastructure for mods that need consistent content registration.

## Content model

`NewContent` groups the resources a dependent mod wants to register.

| Area | Supported content |
| :--- | :--- |
| Gameplay | Characters, enemies, elites, bosses, items, weapons, effects, consumables, upgrades, sets |
| World | Backgrounds, zones, difficulties, title-screen backgrounds |
| Progression | Challenges, tracked items/effects, stat metadata |
| Localization | Translation resources and localized content |
| Runtime | Scene, player, enemy, and effect behaviors |

Content remains inspectable as data; integration logic stays in the shared loader.

## Integration boundary

### Resource lifecycle

`NewContent` exposes paired `add_resources()` and `remove_resources()` flows. Dependent mods therefore have a consistent registration and teardown path instead of implementing independent cleanup logic.

Relevant service lookups are refreshed after content changes, including unlocked item pools and weapon ID lookups.

### Custom classes

Dependent mods can expose class services through:

```text
extensions/services/class_service.gd
```

`mod_main.gd` can collect the active class set, remove obsolete global registrations, and register valid classes for the current mod stack.

### Script extensions

The loader extends selected Brotato systems, including:

```text
ProgressData
RunData
Utils
Main
WeaponService
FloatingTextManager
ItemService
```

This makes the repository compatibility infrastructure, not just a passive resource container.

## Example

A dependent mod can preload a `NewContent` resource and register its resources:

```gdscript
var content = preload("res://NewContent.tres")
content.add_resources()
```

`NewContent.tres` in this repository is a base template. Exact fields should follow the version of NewContentLoader used by the dependent mod stack.

## Installation

Download the latest `NewContentLoader-*.zip` from [Releases](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases) and place the ZIP in Brotato's Mod Loader `mods` directory.

Install NewContentLoader before enabling mods that declare it as a dependency.

Development layout:

```text
mods-unpacked/
└── Yoko-NewContentLoader/
    ├── extensions/
    ├── NewContent.gd
    ├── NewContent.tres
    ├── manifest.json
    └── mod_main.gd
```

See the [Godot Mod Loader documentation](https://wiki.godotmodding.com/) for current conventions.

## Development

Treat this repository as shared framework code rather than standalone gameplay content.

Keep the architecture centered on one path:

```text
Content resource
      │
      ▼
Registration + lifecycle
      │
      ▼
Brotato service integration
```

Changes to registration order, removal behavior, global class state, or service lookups can affect every dependent mod. Test the complete stack, not only the loader in isolation.

## Release model

`manifest.json` is authoritative. Release tags must match its declared version exactly.

```text
manifest.json: 1.1.0
        │
        ├── v1.1.0     → build allowed
        └── v1.2.0     → build rejected
```

The workflow imports Godot resources, preserves generated `.import` data, packages the Mod Loader ZIP, validates the archive, and checks the packaged manifest.

## Compatibility

| Component | Version |
| :--- | :--- |
| Brotato | **1.15.4** |
| Godot | 3.x / GDScript |
| Mod Loader | **6.3.0** |
| NewContentLoader | **1.1.0** |
| Dependencies | None |
| License | MIT |

Compatibility and dependency metadata live in `manifest.json`.

## Project structure

```text
Yoko-NewContentLoader/
├── .github/workflows/release.yml
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
├── mod_main.gd
├── README.md
└── LICENSE
```

## Related project

[Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) uses NewContentLoader as its content-registration dependency.

## Contributing

Useful changes improve registration correctness, compatibility, lifecycle handling, dependency interoperability, or developer ergonomics.

When changing shared behavior, document the affected Brotato services and test at least one dependent mod that exercises the changed path.

## Support

Development support is available through the deployed payment page:

**https://cyojkoy.github.io/Payment/**

## License

This project is licensed under the [MIT License](LICENSE).

<div align="center">
  <sub>Yoko-NewContentLoader · shared Brotato content infrastructure by CYoJkoY</sub>
</div>
