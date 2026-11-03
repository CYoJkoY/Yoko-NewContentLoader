extends "res://singletons/item_service.gd"

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func get_stat(stat_hash: int) -> StatData:
    var stat: StatData =.get_stat(stat_hash)
    if stat != null: return stat
    for content in ProgressData.ncl_get_registered_contents():
        for content_stat in content.stats:
            if content_stat.stat_hash == stat_hash: return content_stat

    return null

func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
    for content in ProgressData.ncl_get_registered_contents():
        consumable = content.ncl_update_consumable_to_get(consumable)

    return consumable

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func ncl_is_weapon_id(weapon_my_id: int) -> bool:
    return get_base_weapon(weapon_my_id) != null

func ncl_get_weapon_from_id(weapon_my_id: int) -> WeaponData:
    var weapon: WeaponData = get_base_weapon(weapon_my_id)
    assert(weapon != null, "weapon_my_id not found in weapons")
    return weapon

func ncl_rebuild_weapon_my_id_lookup() -> void:
    _base_weapon_lookup = {}

func invalidate_items_cache() -> void:
    .invalidate_items_cache()
    _item_id_lookup = {}

func invalidate_weapons_cache() -> void:
    .invalidate_weapons_cache()
    _weapon_id_lookup = {}
    _base_weapon_lookup = {}
