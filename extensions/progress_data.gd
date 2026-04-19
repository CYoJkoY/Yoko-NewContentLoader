extends "res://singletons/progress_data.gd"

var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()
var mod_content_configs: Array = [

    ["NewContentData.tres", ""],
    ["NewContentDataDLC1.tres", "res://dlcs/dlc_1/dlc_data.tres"]

]

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

        var common_mod_content: Resource = ncl_load_content(mod_data, mod_data_id, 0)
        var dlc1_mod_content: Resource = ncl_load_content(mod_data, mod_data_id, 1)

        var mod_content: Resource = ncl_merge_contents(common_mod_content, dlc1_mod_content, mod_data_id)

        available_dlcs.append(mod_content)

# =========================== Method =========================== #
func ncl_load_content(mod_data: ModData, mod_data_id: String, config_index: int):
    var content_file_name: String = mod_content_configs[config_index][0]
    var content_path: String = mod_data.dir_path.plus_file(content_file_name)
    var dlc_path: String = mod_content_configs[config_index][1]

    if dlc_path != "" and !File.new().file_exists(dlc_path): return null

    if !Directory.new().file_exists(content_path):
        ModLoaderLog.info("[NCL] Skip %s: %s not found" % [mod_data_id, content_file_name], mod_data_id)
        return null

    var mod_content: Resource = load(content_path)
    if mod_content != null:
        ModLoaderLog.info("[NCL] Successfully load %s" % [content_file_name], mod_data_id)
        return mod_content
    else: ModLoaderLog.info("[NCL] Error: Failed to load %s" % [content_file_name], mod_data_id)

func ncl_merge_contents(content_1: Resource, content_2: Resource, new_id: String) -> Resource:
    var merged_content: Resource = load("res://mods-unpacked/Yoko-NewContentLoader/NewContent.tres")
    merged_content.my_id = new_id
    match [content_1 != null, content_2 != null]:
        [false, false]: return merged_content
        [true, false]: return content_1
        [false, true]: return content_2

    merged_content.groups_in_all_zones = ncl_merge_arrays(content_1.groups_in_all_zones, content_2.groups_in_all_zones)
    merged_content.music_tracks = ncl_merge_arrays(content_1.music_tracks, content_2.music_tracks)
    merged_content.backgrounds = ncl_merge_arrays(content_1.backgrounds, content_2.backgrounds)
    merged_content.characters = ncl_merge_arrays(content_1.characters, content_2.characters)
    merged_content.entities = ncl_merge_arrays(content_1.entities, content_2.entities)
    merged_content.elites = ncl_merge_arrays(content_1.elites, content_2.elites)
    merged_content.bosses = ncl_merge_arrays(content_1.bosses, content_2.bosses)
    merged_content.stats = ncl_merge_arrays(content_1.stats, content_2.stats)
    merged_content.items = ncl_merge_arrays(content_1.items, content_2.items)
    merged_content.weapons = ncl_merge_arrays(content_1.weapons, content_2.weapons)
    merged_content.effects = ncl_merge_arrays(content_1.effects, content_2.effects)
    merged_content.consumables = ncl_merge_arrays(content_1.consumables, content_2.consumables)
    merged_content.upgrades = ncl_merge_arrays(content_1.upgrades, content_2.upgrades)
    merged_content.sets = ncl_merge_arrays(content_1.sets, content_2.sets)
    merged_content.difficulties = ncl_merge_arrays(content_1.difficulties, content_2.difficulties)
    merged_content.icons = ncl_merge_arrays(content_1.icons, content_2.icons)
    merged_content.title_screen_backgrounds = ncl_merge_arrays(content_1.title_screen_backgrounds, content_2.title_screen_backgrounds)
    merged_content.challenges = ncl_merge_arrays(content_1.challenges, content_2.challenges)
    merged_content.zones = ncl_merge_arrays(content_1.zones, content_2.zones)
    merged_content.scene_effect_behaviors = ncl_merge_arrays(content_1.scene_effect_behaviors, content_2.scene_effect_behaviors)
    merged_content.enemy_effect_behaviors = ncl_merge_arrays(content_1.enemy_effect_behaviors, content_2.enemy_effect_behaviors)
    merged_content.player_effect_behaviors = ncl_merge_arrays(content_1.player_effect_behaviors, content_2.player_effect_behaviors)
    
    merged_content.tracked_items = ncl_merge_dictionaries(content_1.tracked_items, content_2.tracked_items)
    merged_content.tracked_effects = ncl_merge_dictionaries(content_1.tracked_effects, content_2.tracked_effects)
    merged_content.translation_keys_needing_operator = ncl_merge_dictionaries(content_1.translation_keys_needing_operator, content_2.translation_keys_needing_operator)
    merged_content.translation_keys_needing_percent = ncl_merge_dictionaries(content_1.translation_keys_needing_percent, content_2.translation_keys_needing_percent)
    
    merged_content._generate_hashes()
    
    if !merged_content.tracked_items.empty():
        merged_content.tracked_items_hash = Utils.convert_dictionary_to_hash(merged_content.tracked_items)
    
    if !merged_content.tracked_effects.empty():
        merged_content.tracked_effects_hash = Utils.convert_dictionary_to_hash(merged_content.tracked_effects)
    
    return merged_content

func ncl_merge_arrays(array1: Array, array2: Array) -> Array:
    var result = array1.duplicate()
    if !array2.empty(): result.append_array(array2)
    return result

func ncl_merge_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
    var result = dict1.duplicate()
    if !dict2.empty(): result.merge(dict2, true)
    return result
