extends "res://singletons/run_data.gd"

const NCL_HASH_UINT32_RANGE: int = 4294967296
const NCL_HASH_INT32_MAX: int = 2147483647

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

func get_player_effect(key: int, player_index: int):
    assert(player_index >= 0, key)
    var effects: Dictionary = get_player_effects(player_index)
    if effects.has(key):
        return effects[key]

    var signed_key: int = _ncl_hash_to_signed(key)
    if signed_key != key and effects.has(signed_key):
        var signed_value = effects[signed_key]
        effects[key] = signed_value
        return signed_value

    var unsigned_key: int = _ncl_hash_to_unsigned(key)
    if unsigned_key != key and effects.has(unsigned_key):
        var unsigned_value = effects[unsigned_key]
        effects[key] = unsigned_value
        return unsigned_value

    var defaults: Dictionary = PlayerRunData.init_effects()
    if defaults.has(key):
        var value = _ncl_duplicate_default_effect(defaults[key])
        effects[key] = value
        return value
    if signed_key != key and defaults.has(signed_key):
        var signed_default = _ncl_duplicate_default_effect(defaults[signed_key])
        effects[signed_key] = signed_default
        effects[key] = signed_default
        return signed_default
    if unsigned_key != key and defaults.has(unsigned_key):
        var unsigned_default = _ncl_duplicate_default_effect(defaults[unsigned_key])
        effects[unsigned_key] = unsigned_default
        effects[key] = unsigned_default
        return unsigned_default

    effects[key] = 0
    return effects[key]

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

func _ncl_hash_to_signed(hash_value: int) -> int:
	if hash_value > NCL_HASH_INT32_MAX:
		return hash_value - NCL_HASH_UINT32_RANGE
	return hash_value


func _ncl_hash_to_unsigned(hash_value: int) -> int:
	if hash_value < 0:
		return hash_value + NCL_HASH_UINT32_RANGE
	return hash_value


func _ncl_duplicate_default_effect(value):
	if value is Dictionary:
		return value.duplicate(true)
	if value is Array:
		return value.duplicate(true)
	if value is Resource:
		return value.duplicate(true)
	return value
