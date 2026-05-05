extends "res://singletons/item_service.gd"

# =========================== Extension =========================== #
func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
	var consumable: ConsumableData =.get_consumable_to_drop(unit, item_chance)
	for dlc_id in RunData.enabled_dlcs:
		var dlc_data = ProgressData.get_dlc_data(dlc_id)
		if !dlc_data or !dlc_data.has_method("ncl_update_consumable_to_get"): continue

		consumable = dlc_data.ncl_update_consumable_to_get(consumable)

	return consumable
