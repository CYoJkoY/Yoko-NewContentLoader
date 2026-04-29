extends "res://singletons/run_data.gd"

var ncl_init_tracked_effects: Dictionary = {}

var ncl_tracked_effects: Array = [ {}, {}, {}, {}]

# =========================== Extension =========================== #
func reset(restart: bool = false) -> void:
    .reset(restart)
    _ncl_tracked_effects_reset()
    
func get_state() -> Dictionary:
    var state: Dictionary =.get_state()
    state.ncl_tracked_effects = ncl_tracked_effects.duplicate(true)

    return state

func resume_from_state(state: Dictionary) -> void:
    .resume_from_state(state)
    ncl_tracked_effects = Utils.convert_to_hash_array(state.ncl_tracked_effects.duplicate())

# =========================== Custom =========================== #
func _ncl_tracked_effects_reset() -> void:
    for player_index in range(ncl_tracked_effects.size()): ncl_tracked_effects[player_index] = ncl_init_tracking_effects()

# =========================== Methods =========================== #
func ncl_init_tracking_effects() -> Dictionary:
    return ncl_init_tracked_effects.duplicate(true)

func ncl_add_effect_tracking_value(ncl_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        ModLoaderLog.info("[add] ncl tracking key %s does not exist" % ncl_tracking_key_hash, "Yoko-NewContentLoader")
        return

    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash][index] += int(value)
    else:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash] += int(value)

func ncl_set_effect_tracking_value(ncl_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        ModLoaderLog.info("[set] ncl tracking key %s does not exist" % ncl_tracking_key_hash, "Yoko-NewContentLoader")
        return

    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash][index] = int(value)
    else:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash] = int(value)

func ncl_get_effect_tracking_value(ncl_tracking_key_hash: int, player_index: int, index: int = 0) -> float:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        ModLoaderLog.info("[get] ncl tracking key %s does not exist" % ncl_tracking_key_hash, "Yoko-NewContentLoader")
        return 0.0
    
    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        return ncl_tracked_effects[player_index][ncl_tracking_key_hash][index]
    else:
        return ncl_tracked_effects[player_index][ncl_tracking_key_hash]
