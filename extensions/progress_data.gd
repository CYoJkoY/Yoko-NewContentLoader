extends "res://singletons/progress_data.gd"

const PROPERTIES_TO_IGNORE: Array = [
    "Reference",
    "Resource",
    "resource_local_to_scene",
    "resource_path",
    "resource_name",
    "script",
    "Script Variables",
    "my_id",
    "my_id_hash"
]
const NEW_CONTENT_RESOURCE_PATH: String = "res://mods-unpacked/Yoko-NewContentLoader/NewContent.tres"
const CONTENT_ARRAY_PROPERTIES: Array = [
    "groups_in_all_zones",
    "music_tracks",
    "backgrounds",
    "characters",
    "entities",
    "elites",
    "bosses",
    "stats",
    "items",
    "weapons",
    "effects",
    "consumables",
    "upgrades",
    "sets",
    "difficulties",
    "icons",
    "title_screen_backgrounds",
    "challenges",
    "zones",
    "scene_effect_behaviors",
    "enemy_effect_behaviors",
    "player_effect_behaviors"
]

const CONTENT_CONFIGS: Array = [
    ["NewContentData.tres", ""],
    ["NewContentDataDLC1.tres", "abyssal_terrors"],
    ["NewContentDataDLC2.tres", "primal_dread"],
]

var _ncl_installed_dlc_ids: Array = []
var ncl_content_registration_ready: bool = false
var ncl_contents: Dictionary = {}
var ncl_registered_contents: Array = []
var ncl_content_dlc_ids: Dictionary = {}

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func _ready() -> void:
    ncl_content_registration_ready = true

func check_for_available_dlcs() -> void:
    .check_for_available_dlcs()
    ZoneService.ncl_filter_owned_zones()
    ncl_install_owned_dlc_extensions()
    ncl_check_for_available_mods()

func check_dlc_valid_for_saved_run_state() -> bool:
    if !.check_dlc_valid_for_saved_run_state():
        return false
    return ncl_check_content_valid_for_run_state(saved_run_state)

func ncl_check_content_valid_for_run_state(state: Dictionary) -> bool:
    if !state.get("has_run_state", false):
        return true
    var registered_ids: Array = []
    for content in ncl_registered_contents:
        registered_ids.append(content.my_id)
    var requirements: Dictionary = state.get("ncl_content_dlc_ids", {})
    for mod_id in requirements:
        if !registered_ids.has(mod_id):
            return false
        for dlc_id in requirements[mod_id]:
            if !is_dlc_available(dlc_id):
                return false
    return true

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func ncl_get_content(mod_id: String) -> Resource:
    return ncl_contents.get(mod_id)

func ncl_check_for_available_mods() -> void:
    for mod_data in ModLoaderStore.mod_load_order:
        if !mod_data.is_active or !mod_data.is_loadable:
            continue
        if !mod_data.manifest.dependencies.has("Yoko-NewContentLoader"):
            continue
        var mod_id: String = mod_data.manifest.get_mod_id()
        if ncl_contents.has(mod_id):
            continue

        var merged_content: Resource = null
        var required_dlcs: Array = []
        for config in CONTENT_CONFIGS:
            var dlc_id: String = config[1]
            if dlc_id != "" and !is_dlc_available(dlc_id):
                continue
            var content_path: String = mod_data.dir_path.plus_file(config[0])
            if !ResourceLoader.exists(content_path):
                continue
            var content: Resource = load(content_path)
            if content == null:
                ModLoaderLog.error("Cannot load required content resource: " + content_path, mod_id)
                merged_content = null
                break
            merged_content = ncl_merge_contents(merged_content, content, mod_id)
            if dlc_id != "":
                required_dlcs.append(dlc_id)

        if merged_content == null:
            continue
        ncl_contents[mod_id] = merged_content
        ncl_content_dlc_ids[mod_id] = required_dlcs
        merged_content.add_resources()
        ncl_log_content_report(merged_content, mod_id)

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func ncl_merge_contents(content_1: Resource, content_2: Resource, new_id: String) -> Resource:
    if content_1 == null or content_2 == null:
        var source: Resource = content_1 if content_1 != null else content_2
        if source == null:
            source = load(NEW_CONTENT_RESOURCE_PATH)
        var copy: Resource = source.duplicate()
        copy.my_id = new_id
        copy._generate_hashes()
        return copy

    var merged_content: Resource = content_1.duplicate()
    merged_content.my_id = new_id
    var property_list: Array = content_1.get_property_list()
    for property_dict in property_list:
        var prop_name: String = property_dict["name"]
        if prop_name in PROPERTIES_TO_IGNORE:
            continue
        if (property_dict["usage"] & PROPERTY_USAGE_STORAGE) == 0:
            continue

        var value1 = content_1.get(prop_name)
        var value2 = content_2.get(prop_name)

        var merged_value = ncl_auto_merge_property(value1, value2, prop_name, new_id)
        if merged_value != null:
            merged_content.set(prop_name, merged_value)

    merged_content._generate_hashes()
    return merged_content

func ncl_auto_merge_property(value1, value2, property_name: String, new_id: String):
    if (
        property_name in ["content_name", "content_icon", "content_logo"]
        and (value2 == null or str(value2) == "")
    ):
        return value1
    if value2 == null:
        return value1

    if typeof(value1) == TYPE_ARRAY and typeof(value2) == TYPE_ARRAY:
        return ncl_merge_arrays(value1, value2)

    if typeof(value1) == TYPE_DICTIONARY and typeof(value2) == TYPE_DICTIONARY:
        return ncl_merge_dictionaries(value1, value2)

    ModLoaderLog.info("[NCL] Property '%s' is of a non-mergeable type or type mismatch. Using the value from content_2 to override." % [property_name], new_id)
    return value2

func ncl_merge_arrays(array1: Array, array2: Array) -> Array:
    var result = array1.duplicate()
    if !array2.empty():
        result.append_array(array2)
    return result

func ncl_merge_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
    var result = dict1.duplicate()
    if !dict2.empty():
        result.merge(dict2, true)
    return result

func ncl_log_content_report(content: Resource, mod_data_id: String) -> void:
    var summary: Array = []
    for property_name in CONTENT_ARRAY_PROPERTIES:
        var value = content.get(property_name)
        if !(value is Array):
            continue
        var count: int = value.size()
        if count <= 0:
            continue

        summary.append("%s=%d" % [property_name, count])
        ncl_log_duplicate_resource_ids(property_name, value, mod_data_id)

    if !summary.empty():
        ModLoaderLog.info(
            "[NCL] Content report: %s" % [PoolStringArray(summary).join(", ")],
            mod_data_id
        )

func ncl_log_duplicate_resource_ids(
    property_name: String,
    resources: Array,
    mod_data_id: String
) -> void:
    var seen: Dictionary = {}
    var duplicates: Array = []
    for resource in resources:
        if resource == null:
            continue

        var raw_resource_id = resource.get("my_id")
        if raw_resource_id == null:
            continue

        var resource_id: String = str(raw_resource_id)
        if resource_id == "":
            continue
        if seen.has(resource_id):
            duplicates.append(resource_id)
        else:
            seen[resource_id] = true

    if !duplicates.empty():
        ModLoaderLog.error(
            "[NCL] Duplicate ids in %s: %s" % [
                property_name,
                PoolStringArray(duplicates).join(", "),
            ],
            mod_data_id
        )

func ncl_install_owned_dlc_extensions() -> void:
    for dlc in [["abyssal_terrors", "dlc_1_data.gd", "res://dlcs/dlc_1/dlc_1_data.gd"], ["primal_dread", "dlc_2_data.gd", "res://dlcs/dlc_2/dlc_2_data.gd"]]:
        var dlc_id: String = dlc[0]
        if !is_dlc_available(dlc_id) or _ncl_installed_dlc_ids.has(dlc_id):
            continue
        _ncl_installed_dlc_ids.append(dlc_id)
        var installed: bool = false
        for mod_data in ModLoaderStore.mod_load_order:
            if !mod_data.is_active or !mod_data.is_loadable:
                continue
            if !mod_data.manifest.dependencies.has("Yoko-NewContentLoader"):
                continue
            var path: String = mod_data.dir_path.plus_file("extensions/" + dlc[1])
            if !ResourceLoader.exists(path):
                continue
            ModLoaderMod.install_script_extension(path)
            installed = true
        if !installed:
            continue
        for i in ItemService.update_data_list.size():
            var update: UpdateData = ItemService.update_data_list[i]
            if update.id != dlc_id or update.update_type != UpdateData.UpdateType.DLC:
                continue
            var original: DLCData = update.dlc_data
            var extended_script: Script = load(dlc[2])
            var extended: DLCData = extended_script.new()
            for property in original.get_property_list():
                if (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
                    continue
                if (property.usage & PROPERTY_USAGE_STORAGE) == 0:
                    continue
                extended.set(property.name, original.get(property.name))
            var owned_update: UpdateData = update.duplicate()
            owned_update.dlc_data = extended
            ItemService.update_data_list[i] = owned_update

func ncl_get_available_zones() -> Array:
    var result: Array = []
    for zone in ZoneService.zones:
        if zone.dlc_id == "" or is_dlc_available(zone.dlc_id):
            result.append(zone)
    return result

func get_character_difficulty_info(
    character_id: int,
    zone_id: int,
    is_random_zone: bool = false
) -> ZoneDifficultyInfo:
    if !is_random_zone:
        return.get_character_difficulty_info(character_id, zone_id, false)
    var lowest: ZoneDifficultyInfo = null
    for zone in ncl_get_available_zones():
        var info: ZoneDifficultyInfo =.get_character_difficulty_info(
            character_id,
            zone.my_id,
            false
        )
        if (
            lowest == null
            or (
                info.max_difficulty_beaten.difficulty_value
                < lowest.max_difficulty_beaten.difficulty_value
            )
        ):
            lowest = info
    return lowest

func ncl_get_registered_contents() -> Array:
    return ncl_registered_contents
