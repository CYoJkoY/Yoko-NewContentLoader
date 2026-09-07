<div align="center">

# Yoko-NewContentLoader

**Shared content-registration infrastructure for Brotato Mod Loader projects.**

<p>
  <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/releases"><img src="https://img.shields.io/github/v/release/CYoJkoY/Yoko-NewContentLoader?display_name=tag&sort=semver&style=flat-square&label=release" alt="Latest release"></a>
  <a href="https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/CYoJkoY/Yoko-NewContentLoader/release.yml?style=flat-square&label=build" alt="Build status"></a>
  <img src="https://img.shields.io/badge/Brotato-1.15.4-478CBF?style=flat-square" alt="Brotato 1.15.4">
  <img src="https://img.shields.io/badge/Mod%20Loader-6.3.0-5965FF?style=flat-square" alt="Mod Loader 6.3.0">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/CYoJkoY/Yoko-NewContentLoader?style=flat-square" alt="MIT License"></a>
</p>

<p><a href="#why-it-exists">Why it exists</a> · <a href="#content-model">Content model</a> · <a href="#integration">Integration</a> · <a href="#installation">Installation</a> · <a href="#development">Development</a></p>

</div>

## Why it exists

Brotato content mods repeatedly need to solve the same problem: register a large collection of resources with existing game services while still being able to remove or refresh those resources cleanly.

**Yoko-NewContentLoader** provides that shared boundary. A dependent mod supplies structured content through `NewContent`, and the loader connects that data to Brotato's item, weapon, run, effect, entity, zone, challenge, and translation systems.

The architecture is intentionally data-driven:

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
Brotato services + runtime extensions
```

## Content model

`NewContent` groups the data a dependent mod wants to register.

| Area | Supported content |
| :--- | :--- |
| Gameplay | Characters, enemies, elites, bosses, items, weapons, effects, consumables, upgrades, sets |
| World | Backgrounds, zones, difficulties, title-screen backgrounds |
| Progression | Challenges, tracked items/effects, stat metadata |
| Localization | Translation resources and localized content |
| Runtime behavior | Scene, player, enemy, and effect behaviors |

The important boundary is that content remains inspectable as data while integration logic stays in the shared loader.

## Integration

### Resource lifecycle

`NewContent` exposes paired `add_resources()` and `remove_resources()` flows. This gives dependent mods a consistent registration and teardown path instead of requiring each project to implement its own cleanup.

The loader also refreshes relevant service lookups after content changes, including unlocked item pools and weapon ID lookups.

### Custom classes

A dependent mod can expose class services under:

```text
extensions/services/class_service.gd
```

`mod_main.gd` can collect the active class set, remove obsolete global registrations, and register valid classes for the current mod stack.

### Script extensions

The loader extends core Brotato systems including:

```text
ProgressData
RunData
Utils
Main
WeaponService
FloatingTextManager
ItemService
```

That makes the project shared compatibility infrastructure rather than only a passive resource container.

## Example flow

A dependent mod can create a `NewContent` resource and populate its content arrays with Godot resources.

```gdscript
var content = preload("res://NewContent.tres")
content.add_resources()
```

`NewContent.tres` in this repository acts as the base resource template. Exact fields should follow the version of NewContentLoader installed by the dependent mod stack.

## Installation

Download the latest `NewContentLoader-*.zip` from [Releases](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases) and place the ZIP in Brotato's Mod Loader `mods` directory.

Install Yoko-NewContentLoader **before** enabling mods that declare it as a dependency.

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

See the [Godot Mod Loader documentation](https://wiki.godotmodding.com/) for current installation and dependency conventions.

## Development

Treat this repository as framework code rather than standalone gameplay content.

When changing registration logic, preserve the boundary:

```text
Content resource
      │
      ▼
Registration / lifecycle
      │
      ▼
Brotato service integration
```

Changes to registration order, removal behavior, global class state, or service lookups can affect every dependent mod. Test the complete stack rather than only the loader in isolation.

### Release validation

Releases use semantic version tags and enforce an exact tag/manifest match:

```text
manifest.json: 1.1.0
        │
        ├── tag v1.1.0  → build allowed
        └── tag v1.2.0  → build rejected
```

The workflow imports Godot resources, preserves generated `.import` data, builds the Mod Loader ZIP, validates the archive, and verifies the packaged manifest.

## Compatibility

| Component | Declared target |
| :--- | :--- |
| Game | **Brotato 1.15.4** |
| Engine | Godot 3.x / GDScript |
| Mod Loader | **6.3.0** |
| Mod version | **1.1.0** |
| Dependencies | None |
| License | MIT |

`manifest.json` is the source of truth for version and compatibility.

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

[Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) uses Yoko-NewContentLoader as a required dependency for its content expansion.

## Contributing

Useful contributions improve registration correctness, compatibility, lifecycle handling, dependency interoperability, or developer ergonomics.

When changing shared behavior, document the affected Brotato services and test at least one dependent mod that exercises the changed path.

## Support

If this framework saves you time while developing Brotato content mods, support is available through the deployed payment page:

**https://cyojkoy.github.io/Payment/**

## License

This project is licensed under the [MIT License](LICENSE).

<div align="center">
  <sub>Yoko-NewContentLoader · shared Brotato content infrastructure by CYoJkoY</sub>
</div>
