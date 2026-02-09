extends Node

const MYMODNAME_MOD_DIR := "Yoko-NewContentLoader"
const MYMODNAME_LOG := "Yoko-NewContentLoader"

var dir: String = ""
var ext_dir: String = ""
var trans_dir: String = ""

# =========================== Extension =========================== #
func _init():
    dir = ModLoaderMod.get_unpacked_dir().plus_file(MYMODNAME_MOD_DIR)
    ext_dir = dir.plus_file("extensions")
    trans_dir = dir.plus_file("translations")

    ModLoaderMod.add_translation(trans_dir.plus_file("NewContentLoader.en.translation"))
    ModLoaderMod.add_translation(trans_dir.plus_file("NewContentLoader.zh.translation"))

    ModLoaderMod.install_script_extension(ext_dir.plus_file("progress_data.gd"))
    ModLoaderMod.install_script_extension(ext_dir.plus_file("run_data.gd"))
    ModLoaderMod.install_script_extension(ext_dir.plus_file("utils.gd"))
