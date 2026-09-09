extends Node

const MYMODNAME_MOD_DIR := "Yoko-NewContentLoader/"

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
    var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()
    var valid_mod_classes: Array = []
    var managed_mod_path_prefixes: Array = []
    for mod_data_id in mod_datas:
        var mod_data: ModData = mod_datas[mod_data_id]
        if mod_data.manifest == null:
            continue
        if not mod_data.manifest.dependencies.has("Yoko-NewContentLoader"):
            continue
        managed_mod_path_prefixes.append("res://mods-unpacked/" + mod_data.dir_name + "/")
        if not mod_data.is_active or not mod_data.is_loadable:
            continue
        var class_service_path: String = mod_data.dir_path.plus_file("extensions/services/class_service.gd")
        if not Directory.new().file_exists(class_service_path):
            continue
        valid_mod_classes.append_array(load(class_service_path).get_classes())

    var valid_classes: Dictionary = {}
    for c in valid_mod_classes:
        if not valid_classes.has(c.class):
            valid_classes[c.class] = c

    var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")
    var keep: Array = []
    var classes_to_unregister: Array = []
    for old_class in registered_classes:
        var class_path: String = old_class.path
        var is_managed_class: bool = false
        for managed_mod_path_prefix in managed_mod_path_prefixes:
            if class_path.begins_with(managed_mod_path_prefix):
                is_managed_class = true
                break
        if not is_managed_class:
            continue
        var old_name: String = old_class.class
        if not valid_classes.has(old_name) or valid_classes[old_name].path != class_path or keep.has(old_name):
            classes_to_unregister.append(old_class)
        else:
            keep.append(old_name)

    if not classes_to_unregister.empty():
        unregister_global_classes_by_array(classes_to_unregister)

    var classes_to_register: Array = []
    var registered_names: Array = []
    for registered_class in ProjectSettings.get_setting("_global_script_classes"):
        registered_names.append(registered_class.class)
    for c_name in valid_classes:
        if not registered_names.has(c_name):
            classes_to_register.append(valid_classes[c_name])
    if not classes_to_register.empty():
        ModLoaderMod.register_global_classes_from_array(classes_to_register)

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

static func unregister_global_classes_by_array(classes_to_remove: Array) -> void:
    var registered_classes: Array = ProjectSettings.get_setting("_global_script_classes")
    var registered_class_icons: Dictionary = ProjectSettings.get_setting("_global_script_class_icons")
    var modified: bool = false
    var removed_class_names: Array = []
    for c in classes_to_remove:
        for i in range(registered_classes.size() - 1, -1, -1):
            if registered_classes[i].class == c.class and registered_classes[i].path == c.path:
                registered_classes.remove(i)
                removed_class_names.append(c.class)
                modified = true
                break
    for remaining_class in registered_classes:
        while removed_class_names.has(remaining_class.class):
            removed_class_names.erase(remaining_class.class)
    for removed_class_name in removed_class_names:
        if registered_class_icons.has(removed_class_name):
            registered_class_icons.erase(removed_class_name)
            modified = true
    if not modified:
        return
    ProjectSettings.set_setting("_global_script_classes", registered_classes)
    ProjectSettings.set_setting("_global_script_class_icons", registered_class_icons)
    ProjectSettings.save_custom(_ModLoaderPath.get_override_path())
