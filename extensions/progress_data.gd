extends "res://singletons/progress_data.gd"

var ncl_available_contents: Array = []

# =========================== Extension =========================== #
func _ready() -> void:
    ncl_check_for_available_mods()

    for ncl_available_content in ncl_available_contents:
        ncl_available_content.add_resources()

    RunData.reset()

    if DebugService.generate_full_unlocked_save_file:
        unlock_all()
        save()
    else:
        load_game_file()
        add_unlocked_by_default()

    set_max_selectable_difficulty()

# =========================== Custom =========================== #
func ncl_check_for_available_mods() -> void:
    var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()
    for mod_data_id in mod_datas:
        var mod_data: ModData = mod_datas[mod_data_id]
        var dependencies: PoolStringArray = mod_data.manifest.dependencies
        if !dependencies.has("Yoko-NewContentLoader"):
            DebugService.log_data("[Skip] Can't find Yoko-NewContentLoader dependence in %s manifest" % [mod_data_id])
            continue

        var content_dir: String = mod_data.dir_path.plus_file("NewContentData.tres")
        var mod_content: Resource = load(content_dir)

        if mod_content == null:
            DebugService.log_data("[Skip] Can't find NewContentData.tres file in %s folder" % [mod_data_id])
            continue

        DebugService.log_data("Found mod's NewContent.tres file, loading resources from: " + mod_data_id)
        ncl_available_contents.append(mod_content)
