extends "res://singletons/run_data.gd"

var ncl_init_tracked_effects: Dictionary = {}

var ncl_tracked_effects: Array = [ {}, {}, {}, {}]

# =========================== Extension =========================== #
func reset(restart: bool = false) -> void:
    .reset(restart)
    for player_index in ncl_tracked_effects.size():
        ncl_tracked_effects[player_index] = ncl_init_tracking_effects()

func get_state() -> Dictionary:
    var state: Dictionary =.get_state()
    state.ncl_tracked_effects = ncl_tracked_effects.duplicate(true)

    return state

func resume_from_state(state: Dictionary) -> void:
    .resume_from_state(state)
    ncl_tracked_effects = Utils.convert_to_hash_array(state.ncl_tracked_effects.duplicate())

# =========================== Methods =========================== #
func ncl_init_tracking_effects() -> Dictionary:
    return ncl_init_tracked_effects.duplicate(true)

func ncl_add_effect_tracking_value(ncl_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        print("[add] ncl tracking key %s does not exist" % ncl_tracking_key_hash)
        return

    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash][index] += value as int
    else:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash] += value as int

func ncl_set_effect_tracking_value(ncl_tracking_key_hash: int, value: float, player_index: int, index: int = 0) -> void:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        print("[set] ncl tracking key %s does not exist" % ncl_tracking_key_hash)
        return

    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash][index] = value as int
    else:
        ncl_tracked_effects[player_index][ncl_tracking_key_hash] = value as int

func ncl_get_effect_tracking_value(ncl_tracking_key_hash: int, player_index: int, index: int = 0) -> float:
    if !ncl_tracked_effects[player_index].has(ncl_tracking_key_hash):
        print("[get] ncl tracking key %s does not exist" % ncl_tracking_key_hash)
        return 0.0
    
    if ncl_tracked_effects[player_index][ncl_tracking_key_hash] is Array:
        return ncl_tracked_effects[player_index][ncl_tracking_key_hash][index]
    else:
        return ncl_tracked_effects[player_index][ncl_tracking_key_hash]
