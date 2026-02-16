extends "res://singletons/progress_data.gd"

var ncl_available_contents: Array = []

# =========================== Extension =========================== #
func _init() -> void:
    ncl_check_for_available_mods()
    
    for mod_content in ncl_available_contents:
        available_dlcs.append(mod_content)

# =========================== Custom =========================== #
func ncl_check_for_available_mods() -> void:
    var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()
    for mod_data_id in mod_datas:
        var mod_data: ModData = mod_datas[mod_data_id]
        var dependencies: PoolStringArray = mod_data.manifest.dependencies
        if !dependencies.has("Yoko-NewContentLoader"):
            ModLoaderLog.info("[NCL] Skip %s: Dependency missing" % [mod_data_id], mod_data_id)
            continue

        var content_path: String = mod_data.dir_path.plus_file("NewContentData.tres")
        var dir = Directory.new()

        if not dir.file_exists(content_path):
             ModLoaderLog.info("[NCL] Skip %s: NewContentData.tres not found" % [mod_data_id], mod_data_id)
             continue

        var mod_content = load(content_path)

        if mod_content != null:
            ModLoaderLog.info("[NCL] Successfully found content for: " + mod_data_id, mod_data_id)
            ncl_available_contents.append(mod_content)
        else:
            ModLoaderLog.info("[NCL] Error: Failed to load %s" % [content_path], mod_data_id)
