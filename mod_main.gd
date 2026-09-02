extends Node

const MYMODNAME_MOD_DIR := "Yoko-NewContentLoader/"
const MYMODNAME_LOG := "Yoko-NewContentLoader"

var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()
var mod_classes: Array = []

var dir: String = ""
var ext_dir: String = ""

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _init():
    dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
    ext_dir = dir + "extensions/"

    # Add classes
    install_script_classes()

    # Add extensions
    install_script_extensions()

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func install_script_classes() -> void:
    # Get all mods' custom classes
    var valid_mod_classes: Array = []
    for mod_data_id in mod_datas:
        var mod_data: ModData = mod_datas[mod_data_id]
        var dependencies: PoolStringArray = mod_data.manifest.dependencies
        if not dependencies.has("Yoko-NewContentLoader"):
            continue

        var class_service_path: String = mod_data.dir_path.plus_file("extensions/services/class_service.gd")
        if not Directory.new().file_exists(class_service_path):
            ModLoaderLog.info("[NCL] Skip %s: class_service.gd not found" % [mod_data_id], mod_data_id)
            continue

        ModLoaderLog.info("[NCL] Successfully found class_service.gd for: " + mod_data_id, mod_data_id)
        valid_mod_classes.append_array(load(class_service_path).get_classes())

    # Unregister obsolete classes and register new ones
    var valid_classes: Dictionary = {}
    for c in valid_mod_classes:
        var c_name: String = c.class
        if valid_classes.has(c_name):
            continue

        valid_classes[c.class] = c

    var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")

    var keep: Array = []
    var stale: Dictionary = {}
    for old_class in registered_classes:
        var old_name: String = old_class.class
        var class_path: String = old_class.path

        # If old registered class not match any new registered class,
        # or its path is invalid, unregister it.
        if not class_path.begins_with("res://mods-unpacked/"):
            continue

        if not valid_classes.has(old_name) or \
        not Directory.new().file_exists(class_path) or \
        keep.has(old_name) or \
        stale.has(old_name):
            stale[old_name] = true
        else:
            keep.append(old_name)

    var classes_to_unregister: Array = []
    for old_class in registered_classes:
        if not stale.has(old_class.class):
            continue

        classes_to_unregister.append(old_class)

    if not classes_to_unregister.empty():
        unregister_global_classes_by_array(classes_to_unregister)

    # Register new classes if any new classes are found.
    var classes_to_register: Array = []
    for c_name in valid_classes:
        if keep.has(c_name):
            continue

        classes_to_register.append(valid_classes[c_name])

    if not classes_to_register.empty():
        ModLoaderMod.register_global_classes_from_array(classes_to_register)
    else:
        ModLoaderLog.info("[NCL] All classes already registered, nothing to do.", MYMODNAME_LOG)

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

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
static func unregister_global_classes_by_array(classes_to_remove: Array) -> void:
    var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")
    var modified: bool = false

    var class_names_to_remove: Array = []
    for c in classes_to_remove:
        class_names_to_remove.append(c.class)

    for i in range(registered_classes.size() - 1, -1, -1):
        var registered_class: Dictionary = registered_classes[i]
        if class_names_to_remove.has(registered_class.class):
            registered_classes.remove(i)
            modified = true

    if modified:
        ProjectSettings.set_setting("_global_script_classes", registered_classes)
        ProjectSettings.save_custom(_ModLoaderPath.get_override_path())
