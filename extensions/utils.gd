extends "res://singletons/utils.gd"

const scales: Array = [
    {"value": 1000000000000000.0, "suffix": "P"},
    {"value": 1000000000000.0, "suffix": "T"},
    {"value": 1000000000.0, "suffix": "B"},
    {"value": 1000000.0, "suffix": "M"},
    {"value": 1000.0, "suffix": "K"}
]

# =========================== Extension =========================== #

# =========================== Custom =========================== #

# =========================== Method =========================== #
func ncl_delete_projectile(proj: Node2D) -> void:
    proj.hide()
    proj.velocity = Vector2.ZERO
    proj._hitbox.collision_layer = proj._original_collision_layer
    proj._enable_stop_delay = false
    proj._elapsed_delay = 0
    proj._sprite.material = null
    proj._animation_player.stop()
    proj.set_physics_process(false)

    disconnect_all_signal_connections(proj, "hit_something")
    disconnect_all_signal_connections(proj._hitbox, "killed_something")

    if is_instance_valid(proj._hitbox.from) and \
    proj._hitbox.from.has_signal("died") and \
    proj._hitbox.from.is_connected("died", proj, "on_entity_died"):
        proj._hitbox.from.disconnect("died", proj, "on_entity_died")
    
    proj.queue_free()

func ncl_quiet_add_stat(stat_hash: int, value: int, player_index: int) -> void:
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[stat_hash] += value
    RunData._are_player_stats_dirty[player_index] = true
    Utils.reset_stat_cache(player_index)

func ncl_format_number(number: float) -> String:
    var is_negative: bool = number < 0
    var abs_number: float = abs(number)
    
    var result: String = str(abs_number)
    if abs_number >= 1000.0:
        for scale in scales:
            if abs_number >= scale.value:
                result = str(stepify(abs_number / scale.value, 0.01)) + scale.suffix
                break
    
    if is_negative and abs_number != 0.0:
        result = "-" + result
    
    return result

func ncl_curse_effect_value(value: float, modifier: float, options: Dictionary = {}) -> float:
    var step: float = options.get("step", 0.01)
    var process_negative: bool = options.get("process_negative", true)
    var is_negative: bool = options.get("is_negative", false)
    var min_num: float = options.get("min_num", NAN)
    var max_num: float = options.get("max_num", NAN)

    match is_negative or (process_negative and value < 0.0):
        true:
            value = stepify(value / (1.0 + modifier), step)
        false:
            value = stepify(value * (1.0 + modifier), step)

    if !is_nan(min_num): value = max(value, min_num)
    if !is_nan(max_num): value = min(value, max_num)

    return value

func ncl_curse_item(item_data: ItemParentData, player_index: int) -> ItemParentData:
    var dlc: DLCData = ProgressData.get_dlc_data("abyssal_terrors")
    return dlc.curse_item(item_data, player_index)

func ncl_create_tracking(key: String, value: float) -> String:
    var color: String = Utils.SECONDARY_FONT_COLOR_HTML
    var key_text: String = tr(key)
    return "[color=%s]%s[/color]" % [color, key_text.format([value])]

func ncl_curse_enemy(enemy: Enemy) -> void:
    var curse: float = Utils.sum_all_player_stats(Keys.stat_curse_hash)
    var main: Node = get_scene_node()
    var effect_behaviors: Array = main._effect_behaviors.get_children()
    for effect_behavior in effect_behaviors:
        if !(effect_behavior is CurseSceneEffectBehavior): continue

        effect_behavior._curse_enemy(enemy, curse)
        break
