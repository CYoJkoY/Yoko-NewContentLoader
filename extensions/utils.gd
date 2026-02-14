extends "res://singletons/utils.gd"

const scales: Array = [
    {"value": 1000000000000000.0, "suffix": "P"},
    {"value": 1000000000000.0, "suffix": "T"},
    {"value": 1000000000.0, "suffix": "B"},
    {"value": 1000000.0, "suffix": "M"},
    {"value": 1000.0, "suffix": "K"}
]

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

func ncl_curse_enemy(enemy: Enemy) -> void:
    var curse: float = Utils.sum_all_player_stats(Keys.stat_curse_hash)
    var main: Node = get_scene_node()
    var effect_behaviors: Array = main._effect_behaviors.get_children()
    for effect_behavior in effect_behaviors:
        if !(effect_behavior is CurseSceneEffectBehavior): continue

        effect_behavior._curse_enemy(enemy, curse)
        break

func ncl_create_tracking(key: String, value: float) -> String:
    var color: String = Utils.SECONDARY_FONT_COLOR_HTML
    var key_text: String = tr(key)
    var str_value: String = str(value) if value < 999 else tr("INFINITE")
    return "[color=%s]%s[/color]" % [color, key_text.format([str_value])]

func ncl_get_scaling_stats_dmg(scaling_stats: Array, player_index: int) -> float:
    var dmg: float = 0.0
    for stat in scaling_stats:
        dmg += stat[1] * Utils.get_stat(stat[0], player_index)
    return dmg

func ncl_get_dmg_text_with_scaling_stats(damage: int, p_scaling_stats: Array, base_damage: int, options: Dictionary = {}) -> String:
    var nb: int = options.get("nb", 1)
    var effects: Array = options.get("effects", [])
    var player_index: int = options.get("player_index", -1)
    var show_initial: bool = options.get("show_initial", true)

    for effect in effects:
        if effect is PlayerHealthStatEffect and effect.key == "stat_damage":
            damage += effect.get_bonus_damage(player_index)
    
    var color: String = ncl_get_signed_col(damage, base_damage)
    var dmg_text: String = "[color=%s]%s[/color]" % [color, ncl_format_number(damage)]

    var text = dmg_text if nb == 1 else "%sx%s" % [dmg_text, str(nb)]

    if damage != base_damage and show_initial:
        var initial_dmg_text = ncl_format_number(base_damage) if nb == 1 else ncl_format_number(base_damage) + "x" + str(nb)
        text += " [color=%s]|%s[/color]" % [Utils.GRAY_COLOR_STR, initial_dmg_text]

    text += " (" + WeaponService.get_scaling_stats_icon_text(p_scaling_stats) + ")"

    return text

func ncl_get_signed_col(value: float, base_value: float) -> String:
    var col_pos_a: String = "#" + ProgressData.settings.color_positive
    var col_neutral_a: String = "white"
    var col_neg_a: String = "#" + ProgressData.settings.color_negative
    if value > base_value: return col_pos_a
    elif value == base_value: return col_neutral_a
    else: return col_neg_a
