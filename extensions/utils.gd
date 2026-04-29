extends "res://singletons/utils.gd"

# =========================== Method =========================== #
func ncl_quiet_add_stat(stat_hash: int, value: int, player_index: int) -> void:
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[stat_hash] += value
    RunData._are_player_stats_dirty[player_index] = true
    Utils.reset_stat_cache(player_index)

func ncl_quiet_set_stat(stat_hash: int, value: int, player_index: int) -> void:
    var effects: Dictionary = RunData.get_player_effects(player_index)
    effects[stat_hash] = value
    RunData._are_player_stats_dirty[player_index] = true
    Utils.reset_stat_cache(player_index)

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

func ncl_curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
    var dlc_1: DLCData = ProgressData.get_dlc_data("abyssal_terrors")
    return dlc_1.curse_item(item_data, player_index, turn_randomization_off, min_modifier)

func ncl_curse_enemy(enemy: Enemy) -> void:
    var curse: float = Utils.sum_all_player_stats(Keys.stat_curse_hash)
    var main: Node = get_scene_node()
    var effect_behaviors: Array = main._effect_behaviors.get_children()
    for effect_behavior in effect_behaviors:
        if !(effect_behavior.has_method("_curse_enemy")): continue

        effect_behavior._curse_enemy(enemy, curse)
        break

func ncl_create_tracking(key: String, value: float, show_inf: bool = true) -> String:
    var color: String = Utils.SECONDARY_FONT_COLOR_HTML
    var key_text: String = tr(key)
    var str_value: String = str(value) if !show_inf else "∞" if value >= 999 else str(value)
    return "[color=%s]%s[/color]" % [color, key_text.format([str_value])]

func ncl_get_scaling_stats_dmg(scaling_stats: Array, player_index: int) -> float:
    var dmg: float = 0.0
    for stat in scaling_stats:
        dmg += stat[1] * Utils.get_stat(stat[0], player_index)

    return dmg

func ncl_get_dmg_with_scaling_stats(base_damage: int, p_scaling_stats: Array, player_index: int) -> float:
    var scaling_stats_dmg: float = ncl_get_scaling_stats_dmg(p_scaling_stats, player_index)
    var dmg: float = base_damage + scaling_stats_dmg
    var final_dmg: float = dmg * (1.0 + Utils.get_stat(Keys.stat_percent_damage_hash, player_index) / 100.0)

    return final_dmg

func ncl_get_dmg_text_with_scaling_stats(damage: int, p_scaling_stats: Array, base_damage: int, options: Dictionary = {}) -> String:
    var nb: int = options.get("nb", 1)
    var effects: Array = options.get("effects", [])
    var player_index: int = options.get("player_index", -1)
    var show_initial: bool = options.get("show_initial", true)

    for effect in effects:
        if effect is PlayerHealthStatEffect and effect.key == "stat_damage":
            damage += effect.get_bonus_damage(player_index)

    var color: String = ncl_get_signed_col(damage, base_damage)
    var dmg_text: String = "[color=%s]%s[/color]" % [color, str(damage)]

    var text = dmg_text if nb == 1 else "%sx%s" % [dmg_text, str(nb)]

    if damage != base_damage and show_initial:
        var initial_dmg_text = str(base_damage) if nb == 1 else str(base_damage) + "x" + str(nb)
        text += " [color=%s]|%s[/color]" % [Utils.GRAY_COLOR_STR, initial_dmg_text]

    text += " (" + WeaponService.get_scaling_stats_icon_text(p_scaling_stats) + ")"

    return text

func ncl_get_range_with_detection(base_range: int, range_rate: float, player_index: int = -1, detection: int = 200) -> float:
    return detection + base_range + Utils.get_stat(Keys.stat_range_hash, player_index) * range_rate

func ncl_get_signed_col(value: float, base_value: float, reverse: bool = false) -> String:
    var colors = {
        "pos": "#" + ProgressData.settings.color_positive,
        "neg": "#" + ProgressData.settings.color_negative,
        "neutral": "white"
    }

    var comparison = sign(value - base_value)
    if comparison == 0: return colors["neutral"]
    if !reverse: return colors["pos"] if comparison > 0 else colors["neg"]
    else: return colors["neg"] if comparison > 0 else colors["pos"]

func ncl_change_weapon_within_run(weapon_position: int, new_weapon_id: int, player_index: int) -> void:
    var player: Player = get_scene_node()._players[player_index]
    var current_weapons: Array = player.current_weapons
    var old_weapon: Weapon = current_weapons[weapon_position]
    var removed_weapon_tracked_value: int = 0

    removed_weapon_tracked_value = RunData.remove_weapon_by_index(weapon_position, player_index)
    current_weapons.erase(old_weapon)

    for current_weapon in current_weapons:
        if current_weapon.weapon_pos > old_weapon.weapon_pos:
            current_weapon.weapon_pos -= 1

    var new_weapon_data: WeaponData = ItemService.get_element(ItemService.weapons, new_weapon_id)
    if old_weapon.is_cursed:
        var new_cursed_weapon_min_factor: float = old_weapon.curse_factor
        for effect in old_weapon.effects: new_cursed_weapon_min_factor = max(new_cursed_weapon_min_factor, effect.curse_factor)
        new_weapon_data = ncl_curse_item(new_weapon_data, player_index, false, new_cursed_weapon_min_factor)

    var new_weapon: WeaponData = RunData.add_weapon(new_weapon_data, player_index)
    new_weapon.tracked_value = removed_weapon_tracked_value

    old_weapon.queue_free()
    player.call_deferred("add_weapon", new_weapon_data, current_weapons.size())

func ncl_change_weapon_within_shop(weapon: WeaponData, new_weapon_id: int, player_index: int, shop: BaseShop) -> void:
    var weapons_container_elements: Inventory = shop._get_gear_container(player_index).weapons_container._elements
    var removed_weapon_tracked_value: int = 0

    removed_weapon_tracked_value = RunData.remove_weapon(weapon, player_index)
    weapons_container_elements.remove_element(weapon)

    var new_weapon_data: WeaponData = ItemService.get_element(ItemService.weapons, new_weapon_id)
    if weapon.is_cursed:
        var new_cursed_weapon_min_factor: float = weapon.curse_factor
        for effect in weapon.effects: new_cursed_weapon_min_factor = max(new_cursed_weapon_min_factor, effect.curse_factor)
        new_weapon_data = ncl_curse_item(new_weapon_data, player_index, false, new_cursed_weapon_min_factor)

    var new_weapon: WeaponData = RunData.add_weapon(new_weapon_data, player_index)
    new_weapon.tracked_value = removed_weapon_tracked_value
    new_weapon.dmg_dealt_last_wave = weapon.dmg_dealt_last_wave

    shop._update_stats(player_index)
    shop._get_shop_items_container(player_index).reload_shop_items()
    weapons_container_elements.add_element(new_weapon)

    if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
        weapons_container_elements.focus_element(new_weapon)

    SoundManager.play(Utils.get_rand_element(shop.combine_sounds), 0, 0.1, true)

func ncl_create_custom_damage_args(player_index: int, color: Color = Color.white, icon_hash: int = Keys.empty_hash) -> TakeDamageArgs:
	var args: TakeDamageArgs = TakeDamageArgs.new(player_index)
	args.set_meta("custom_color", color)
	if icon_hash != Keys.empty_hash: args.set_meta("custom_icon", icon_hash)

	return args

func ncl_get_validate_node_name(name: String) -> String:
    var result: String = name
    var first_index = result.find("@")
    var second_index = result.find("@", 1)
    if second_index == -1: result = result.substr(0, first_index)
    else: result = result.substr(1, second_index - 1)

    return result
