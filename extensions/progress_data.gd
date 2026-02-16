extends "res://singletons/progress_data.gd"

var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()

# =========================== Extension =========================== #
func check_for_available_dlcs() -> void:
    ncl_cheack_for_available_DLC1_gds_install()
    .check_for_available_dlcs()
    ncl_check_for_available_mods()

# =========================== Custom =========================== #
func ncl_cheack_for_available_DLC1_gds_install() -> void:
    if !File.new().file_exists("res://dlcs/dlc_1/dlc_data.tres"): return

    for mod_data_id in mod_datas:
        var mod_data: ModData = mod_datas[mod_data_id]
        var dependencies: PoolStringArray = mod_data.manifest.dependencies
        if !dependencies.has("Yoko-NewContentLoader"):
            ModLoaderLog.info("[NCL] Skip %s: Dependency missing" % [mod_data_id], mod_data_id)
            continue
        
        var dlc_1_gd_path: String = mod_data.dir_path.plus_file("dlc_1_data.gd")

        if !Directory.new().file_exists(dlc_1_gd_path):
             ModLoaderLog.info("[NCL] Skip %s: dlc_1_data.gd not found" % [mod_data_id], mod_data_id)
             continue

        ModLoaderLog.info("[NCL] Successfully found dlc_1_data.gd for: " + mod_data_id, mod_data_id)
        ModLoaderMod.install_script_extension(dlc_1_gd_path)

func ncl_check_for_available_mods() -> void:
    for mod_data_id in mod_datas:
        var mod_data: ModData = mod_datas[mod_data_id]
        var dependencies: PoolStringArray = mod_data.manifest.dependencies
        if !dependencies.has("Yoko-NewContentLoader"):
            ModLoaderLog.info("[NCL] Skip %s: Dependency missing" % [mod_data_id], mod_data_id)
            continue

        var content_path: String = mod_data.dir_path.plus_file("NewContentData.tres")

        if !Directory.new().file_exists(content_path):
             ModLoaderLog.info("[NCL] Skip %s: NewContentData.tres not found" % [mod_data_id], mod_data_id)
             continue

        var mod_content = load(content_path)

        if mod_content != null:
            ModLoaderLog.info("[NCL] Successfully found content for: " + mod_data_id, mod_data_id)
            available_dlcs.append(mod_content)
        else:
            ModLoaderLog.info("[NCL] Error: Failed to load %s" % [content_path], mod_data_id)
