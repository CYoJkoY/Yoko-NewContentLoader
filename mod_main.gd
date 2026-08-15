extends Node

const MYMODNAME_MOD_DIR := "Yoko-NewContentLoader/"
const MYMODNAME_LOG := "Yoko-NewContentLoader"

var dir: String = ""
var ext_dir: String = ""

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _init():
    dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
    ext_dir = dir + "extensions/"

    # Add extensions
    install_script_extensions()

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func install_script_extensions() -> void:
    var extensions: Array = [

        "progress_data.gd",
        "run_data.gd",
        "utils.gd",
        "main.gd",
        "weapon_service.gd", # Temporary workaround, will remove once the official fix is in place.
        "floating_text_manager.gd",
        "item_service.gd",

    ]

    for path in extensions:
        var extension_path = ext_dir.plus_file(path)
        ModLoaderMod.install_script_extension(extension_path)
