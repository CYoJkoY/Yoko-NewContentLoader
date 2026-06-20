extends "res://singletons/item_service.gd"

var ncl_weapon_my_id_lookup: Dictionary = {}

# =========================== Extension =========================== #
func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
    var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
    for dlc_id in RunData.enabled_dlcs:
        var dlc_data = ProgressData.get_dlc_data(dlc_id)
        if dlc_data == null or !dlc_data.has_method("ncl_update_consumable_to_get"): continue

        consumable = dlc_data.ncl_update_consumable_to_get(consumable)

    return consumable

# =========================== Method =========================== #
func ncl_is_weapon_id(weapon_my_id: int) -> bool:
    if !ncl_weapon_my_id_lookup.has(weapon_my_id): ncl_rebuild_weapon_my_id_lookup()

    return ncl_weapon_my_id_lookup.has(weapon_my_id)

func ncl_get_weapon_from_id(weapon_my_id: int) -> WeaponData:
    if !ncl_weapon_my_id_lookup.has(weapon_my_id): ncl_rebuild_weapon_my_id_lookup()

    assert(ncl_weapon_my_id_lookup.has(weapon_my_id), "weapon_my_id not found in weapons")
    return ncl_weapon_my_id_lookup[weapon_my_id]

func ncl_rebuild_weapon_my_id_lookup() -> void:
    ncl_weapon_my_id_lookup.clear()
    for weapon in weapons: ncl_weapon_my_id_lookup[weapon.my_id_hash] = weapon
