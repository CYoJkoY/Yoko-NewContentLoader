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
const DLC1_DATA_RESOURCE_PATH: String = "res://dlcs/dlc_1/dlc_data.tres"
const DLC1_DATA_SCRIPT_PATH: String = "res://dlcs/dlc_1/dlc_1_data.gd"
const NCL_DLC1_DATA_EXTENSION_PATH: String = "res://mods-unpacked/Yoko-NewContentLoader/extensions/dlcs/dlc_1/dlc_1_data.gd"
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

var mod_datas: Dictionary = ModLoaderMod.get_mod_data_all()
var mod_content_configs: Array = [

	["NewContentData.tres", "", ""],
	["NewContentDataDLC1.tres", "res://dlcs/dlc_1/dlc_data.tres", "abyssal_terrors"]

]

# =========================== Extension =========================== #
func check_for_available_dlcs() -> void:
	ncl_check_for_available_dlc1_extensions()
	.check_for_available_dlcs()
	ncl_check_for_available_mods()

# =========================== Custom =========================== #
func ncl_check_for_available_dlc1_extensions() -> void:
	if !ncl_is_dlc1_runtime_available():
		ModLoaderLog.info("[NCL] Skip: DLC1 runtime data not found", "Yoko-NewContentLoader")
		return
	if Directory.new().file_exists(NCL_DLC1_DATA_EXTENSION_PATH):
		ModLoaderMod.install_script_extension(NCL_DLC1_DATA_EXTENSION_PATH)
		ModLoaderLog.info("[NCL] Installed managed dlc_1_data.gd extension", "Yoko-NewContentLoader")

	for mod_data_id in mod_datas:
		var mod_data: ModData = mod_datas[mod_data_id]
		var dependencies: PoolStringArray = mod_data.manifest.dependencies
		if !dependencies.has("Yoko-NewContentLoader"):
			ModLoaderLog.info("[NCL] Skip: Dependency missing", mod_data_id)
			continue

		ncl_register_dlc1_curse_item_pass(mod_data, mod_data_id)

func ncl_is_dlc1_runtime_available() -> bool:
	return ResourceLoader.exists(DLC1_DATA_RESOURCE_PATH) or Directory.new().file_exists(DLC1_DATA_SCRIPT_PATH)

func ncl_register_dlc1_curse_item_pass(mod_data: ModData, mod_data_id: String) -> void:
	if !Utils.has_method("ncl_register_dlc1_curse_item_pass"):
		return

	var pass_path: String = mod_data.dir_path.plus_file("extensions/services/dlc1_curse_pass.gd")
	if !Directory.new().file_exists(pass_path):
		ModLoaderLog.info("[NCL] Skip: dlc1_curse_pass.gd not found", mod_data_id)
		return

	var pass_script = load(pass_path)
	if pass_script == null:
		ModLoaderLog.info("[NCL] Error: Failed to load dlc1_curse_pass.gd", mod_data_id)
		return

	Utils.ncl_register_dlc1_curse_item_pass(mod_data_id, pass_script.new(), "apply", 100)
	ModLoaderLog.info("[NCL] Registered DLC1 curse item pass", mod_data_id)

func ncl_check_for_available_mods() -> void:
	for mod_data_id in mod_datas:
		var mod_data: ModData = mod_datas[mod_data_id]
		var dependencies: PoolStringArray = mod_data.manifest.dependencies
		if !dependencies.has("Yoko-NewContentLoader"):
			ModLoaderLog.info("[NCL] Skip: Dependency missing", mod_data_id)
			continue

		var common_mod_content: Resource = ncl_load_content(mod_data, mod_data_id, 0)
		var dlc1_mod_content: Resource = ncl_load_content(mod_data, mod_data_id, 1)

		var mod_content: Resource = ncl_merge_contents(common_mod_content, dlc1_mod_content, mod_data_id)
		ncl_log_content_report(mod_content, mod_data_id)
		ModLoaderLog.info("[NCL] Successfully load %s" % [mod_content.my_id], mod_data_id)

		available_dlcs.append(mod_content)

# =========================== Method =========================== #
func ncl_load_content(mod_data: ModData, mod_data_id: String, config_index: int) -> Resource:
	var content_file_name: String = mod_content_configs[config_index][0]
	var content_path: String = mod_data.dir_path.plus_file(content_file_name)
	var dlc_path: String = mod_content_configs[config_index][1]
	var dlc_id: String = mod_content_configs[config_index][2]

	if dlc_path != "" and !is_dlc_available(dlc_id):
		ModLoaderLog.info("[NCL] Skip: DLC %s not available" % [dlc_id], mod_data_id)
		return null

	if !Directory.new().file_exists(content_path):
		ModLoaderLog.info("[NCL] Skip: %s not found" % [content_file_name], mod_data_id)
		return null

	var mod_content: Resource = load(content_path)
	if mod_content != null:
		ModLoaderLog.info("[NCL] Successfully load %s" % [content_file_name], mod_data_id)
		return mod_content
	else:
		ModLoaderLog.info("[NCL] Error: Failed to load %s" % [content_file_name], mod_data_id)
		return null

func ncl_merge_contents(content_1: Resource, content_2: Resource, new_id: String) -> Resource:
	match [content_1 == null, content_2 == null]:
		[true, true]:
			var merged_content: Resource = load(NEW_CONTENT_RESOURCE_PATH).duplicate()
			merged_content.my_id = new_id
			return merged_content
		[false, true]:
			content_1.my_id = new_id
			return content_1
		[true, false]:
			content_2.my_id = new_id
			return content_2

	var merged_content: Resource = content_1.duplicate()
	merged_content.my_id = new_id
	var property_list: Array = content_1.get_property_list()
	for property_dict in property_list:
		var prop_name: String = property_dict["name"]
		if prop_name in PROPERTIES_TO_IGNORE: continue

		var value1 = content_1.get(prop_name)
		var value2 = content_2.get(prop_name)

		var merged_value = ncl_auto_merge_property(value1, value2, prop_name, new_id)
		if merged_value != null: merged_content.set(prop_name, merged_value)

	merged_content._generate_hashes()
	return merged_content

func ncl_auto_merge_property(value1, value2, property_name: String, new_id: String):
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
	if !array2.empty(): result.append_array(array2)
	return result

func ncl_merge_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	var result = dict1.duplicate()
	if !dict2.empty(): result.merge(dict2, true)
	return result

func ncl_log_content_report(content: Resource, mod_data_id: String) -> void:
	var summary: Array = []
	for property_name in CONTENT_ARRAY_PROPERTIES:
		var value = content.get(property_name)
		if !(value is Array): continue
		var count: int = value.size()
		if count <= 0: continue

		summary.append("%s=%d" % [property_name, count])
		ncl_log_duplicate_resource_ids(property_name, value, mod_data_id)

	if !summary.empty():
		ModLoaderLog.info("[NCL] Content report: %s" % [PoolStringArray(summary).join(", ")], mod_data_id)

func ncl_log_duplicate_resource_ids(property_name: String, resources: Array, mod_data_id: String) -> void:
	var seen: Dictionary = {}
	var duplicates: Array = []
	for resource in resources:
		if resource == null: continue

		var raw_resource_id = resource.get("my_id")
		if raw_resource_id == null: continue

		var resource_id: String = str(raw_resource_id)
		if resource_id == "": continue
		if seen.has(resource_id):
			duplicates.append(resource_id)
		else:
			seen[resource_id] = true

	if !duplicates.empty():
		ModLoaderLog.error("[NCL] Duplicate ids in %s: %s" % [property_name, PoolStringArray(duplicates).join(", ")], mod_data_id)
