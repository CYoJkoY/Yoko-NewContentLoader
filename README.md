<div align="center">

# Yoko-NewContentLoader

**Shared content-registration infrastructure for Brotato Mod Loader projects.**

[![Latest Release](https://img.shields.io/github/v/release/CYoJkoY/Yoko-NewContentLoader?display_name=tag&sort=semver&style=flat-square)](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/CYoJkoY/Yoko-NewContentLoader/release.yml?style=flat-square&label=build)](https://github.com/CYoJkoY/Yoko-NewContentLoader/actions/workflows/release.yml)
[![Mod Loader](https://img.shields.io/badge/Mod%20Loader-6.3.0-5965FF?style=flat-square)](#compatibility)
[![Godot](https://img.shields.io/badge/Godot-3.x-478CBF?style=flat-square&logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/github/license/CYoJkoY/Yoko-NewContentLoader?style=flat-square)](LICENSE)

[Overview](#overview) · [Content model](#content-model) · [Integration](#integration) · [Installation](#installation) · [Development](#development)

</div>

---

## Overview

Yoko-NewContentLoader is shared infrastructure for Brotato content mods. It provides a `NewContent` resource and runtime extensions that let dependent mods register structured content through a common pipeline instead of reimplementing registration logic in each project.

It is intended to sit between a content-heavy mod and Brotato's existing services:

```text
Dependent Mod
     │
     ├── Characters / Weapons / Items / Effects / Zones / ...
     │
     ▼
 NewContent resource
     │
     ▼
 NewContent.add_resources()
     │
     ├── Item / Weapon services
     ├── Run / Progress data
     ├── Effects and entities
     ├── Zones / challenges
     └── Translations
```

## Content model

`NewContent` groups the data a dependent mod wants to register. The current resource model covers categories including:

| Content | Examples |
| :--- | :--- |
| Gameplay | Characters, enemies, elites, bosses, items, weapons, effects, consumables, upgrades, sets |
| World | Backgrounds, zones, difficulties, title-screen backgrounds |
| Progression | Challenges, tracked items/effects, stat metadata |
| Localization | Translation resources and localized content |
| Runtime behavior | Scene, player, enemy, and effect behaviors |

The important boundary is that content remains data-driven while the extension layer handles interactions that require existing Brotato systems.

## Integration

### Add / remove lifecycle

`NewContent` exposes paired `add_resources()` and `remove_resources()` flows. Registered resources can therefore be added to the relevant Brotato services and removed again without each dependent mod implementing its own teardown path.

The loader also refreshes relevant service lookups after content changes, including unlocked item pools and weapon ID lookups.

### Custom class discovery

Dependent mods can optionally expose class services under:

```text
extensions/services/class_service.gd
```

`mod_main.gd` can collect the current class set, remove obsolete global registrations, and register valid classes for the active mod stack.

### Script extensions

The project includes extensions for core Brotato systems such as:

- `ProgressData`
- `RunData`
- `Utils`
- `Main`
- `WeaponService`
- `FloatingTextManager`
- `ItemService`

This makes NewContentLoader more than a resource container: it supplies shared compatibility behavior used by dependent content mods.

## Installation

Download the latest `NewContentLoader-*.zip` from [Releases](https://github.com/CYoJkoY/Yoko-NewContentLoader/releases) and place it in Brotato's Mod Loader `mods` directory.

Install Yoko-NewContentLoader **before** enabling mods that declare it as a dependency.

For development:

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

## Example flow

A dependent mod can create a `NewContent` resource and populate its content arrays with Godot resources:

```gdscript
# Conceptual flow
var content = preload("res://NewContent.tres")
content.add_resources()
```

The repository's `NewContent.tres` acts as the base resource template. The exact resource fields should follow the version of NewContentLoader installed by the dependent mod stack.

## Development

Treat this project as framework code rather than standalone gameplay content.

When changing registration logic, preserve the separation between:

```text
Content resource
      │
      ▼
Registration / lifecycle
      │
      ▼
Brotato service integration
```

Changes affecting registration order, removal behavior, global classes, or service lookups can affect every dependent mod and should therefore be tested with the complete stack.

Releases use semantic version tags, and the release workflow now enforces an exact tag/manifest match:

```text
manifest.json: 1.1.0
        │
        ├── tag v1.1.0  → build allowed
        └── tag v1.2.0  → build rejected
```

The workflow also performs Godot resource import, builds the Mod Loader ZIP, preserves generated `.import` data, validates the archive, and verifies the packaged manifest.

## Compatibility

| Component | Declared target |
| :--- | :--- |
| Engine | Godot 3.x / GDScript |
| Mod Loader | **6.3.0** |
| Mod version | **1.1.0** |
| Brotato game version | **1.15.4** |
| License | MIT |

Because this library is used by other mods, dependent projects should use a compatible NewContentLoader release and test the entire mod stack together.

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

[Yoko-YzTato](https://github.com/CYoJkoY/Yoko-YzTato) declares Yoko-NewContentLoader as a required dependency for its content expansion.

## License

This project is licensed under the [MIT License](LICENSE).

## Support the Author

If this framework saves you time while developing or maintaining Brotato content mods, consider supporting its continued development.

<div align="center">
  <a href="https://cyojkoy.github.io/Payment/">
    <img src="https://img.shields.io/badge/Support_the_Author-9E8F7E?style=for-the-badge&logo=buy-me-a-coffee&logoColor=BEB8AE" alt="Support the Author">
  </a>
</div>

---

<div align="center">
  <sub>Yoko-NewContentLoader · Shared Brotato modding infrastructure by CYoJkoY</sub>
</div>
