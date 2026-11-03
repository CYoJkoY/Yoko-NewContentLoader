extends "res://singletons/run_data.gd"

var ncl_init_tracked_effects: Dictionary = {}

var ncl_tracked_effects: Array = [ {}, {}, {}, {}]

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func reset(restart: bool = false) -> void:
    .reset(restart)
    _ncl_tracked_effects_reset()
    
func get_state() -> Dictionary:
    var state: Dictionary =.get_state()
    state.ncl_content_dlc_ids = {}
    for content in ProgressData.ncl_get_registered_contents():
        state.ncl_content_dlc_ids[content.my_id] = ProgressData.ncl_content_dlc_ids.get(content.my_id, []).duplicate()
    state.ncl_tracked_effects = ncl_tracked_effects.duplicate(true)

    return state

func resume_from_state(state: Dictionary) -> void:
    .resume_from_state(state)
    _ncl_tracked_effects_reset()
    ncl_tracked_effects = Utils.convert_to_hash_array(state.ncl_tracked_effects.duplicate(true))

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func _ncl_tracked_effects_reset() -> void:
    for player_index in range(ncl_tracked_effects.size()): ncl_tracked_effects[player_index] = ncl_init_tracking_effects()

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func ncl_init_tracking_effects() -> Dictionary:
    return ncl_init_tracked_effects.duplicate(true)

func ncl_add_effect_tracking_value(ncl_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        ModLoaderLog.info("[add] ncl tracking key %s does not exist" % ncl_tracking_key_hash, "Yoko-NewContentLoader")
        return

    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash][index] += int(value)
    else: ncl_tracked_effects[player_index][ncl_tracking_key_hash] += int(value)

func ncl_set_effect_tracking_value(ncl_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        ModLoaderLog.info("[set] ncl tracking key %s does not exist" % ncl_tracking_key_hash, "Yoko-NewContentLoader")
        return

    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash][index] = int(value)
    else: ncl_tracked_effects[player_index][ncl_tracking_key_hash] = int(value)

func ncl_get_effect_tracking_value(ncl_tracking_key_hash: int, player_index: int, index: int = 0) -> float:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        ModLoaderLog.info("[get] ncl tracking key %s does not exist" % ncl_tracking_key_hash, "Yoko-NewContentLoader")
        return 0.0
    
    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        return ncl_tracked_effects[player_index][ncl_tracking_key_hash][index]
    else: return ncl_tracked_effects[player_index][ncl_tracking_key_hash]

func ncl_get_nb_weapon(weapon_my_id_hash: int, player_index: int) -> int:
    var player_weapons: Array = RunData.get_player_weapons_ref(player_index)
    var count: int = 0
    for weapon in player_weapons:
        if weapon.my_id_hash != weapon_my_id_hash: continue
    
        count += 1
    return count

func ncl_remove_weapon_by_id(weapon: WeaponData, player_index: int) -> int:
    var weapons: Array = get_player_weapons_ref(player_index)
    var weapon_my_id: int = weapon.get_my_id_hash()
    for index in weapons.size():
        if weapons[index].get_my_id_hash() == weapon_my_id:
            return remove_weapon_by_index(index, player_index)

    return 0
