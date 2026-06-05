extends "res://singletons/weapon_service.gd"

# =========================== Extension =========================== #
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure := false, is_special_spawn := false, is_pet := false) -> WeaponStats:
    var class_bonuses: Array = RunData.get_player_effect(Keys.weapon_class_bonus_hash, player_index)
    var crit_chance_class_bonuses: Array = _ncl_take_class_bonus_crit_chance(class_bonuses, args)
    var base_stats: WeaponStats = .init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
    _ncl_restore_class_bonuses(class_bonuses, crit_chance_class_bonuses)
    _ncl_apply_class_bonus_crit_chance(base_stats, crit_chance_class_bonuses)
    return base_stats

# =========================== Custom =========================== #
func _ncl_take_class_bonus_crit_chance(class_bonuses: Array, args: WeaponServiceInitStatsArgs) -> Array:
    var removed_bonuses: Array = []
    for i in range(class_bonuses.size() - 1, -1, -1):
        var class_bonus = class_bonuses[i]
        if !(class_bonus is Array) or class_bonus.size() < 3: continue

        var set_id = class_bonus[0]
        var stat_hash = class_bonus[1]
        if !Keys.hash_to_string.has(stat_hash): continue

        var stat_name: String = Keys.hash_to_string[stat_hash]
        if stat_name != "crit_chance": continue

        for set in args.sets:
            if set.my_id_hash != set_id: continue

            removed_bonuses.append([i, class_bonus])
            class_bonuses.remove(i)
            break

    return removed_bonuses

func _ncl_restore_class_bonuses(class_bonuses: Array, removed_bonuses: Array) -> void:
    for i in range(removed_bonuses.size() - 1, -1, -1):
        var removed_bonus: Array = removed_bonuses[i]
        class_bonuses.insert(removed_bonus[0], removed_bonus[1])

func _ncl_apply_class_bonus_crit_chance(base_stats: WeaponStats, removed_bonuses: Array) -> void:
    for removed_bonus in removed_bonuses:
        var class_bonus: Array = removed_bonus[1]
        base_stats.crit_chance += class_bonus[2] / 100.0
