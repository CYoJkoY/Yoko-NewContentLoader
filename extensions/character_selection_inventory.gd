extends "res://ui/menus/run/character_selection_inventory.gd"

func update_elements_color(current_zone_id: int) -> void:
    if current_zone_id != -1:
        .update_elements_color(current_zone_id)
        return
    for element in get_children():
        if element.item == null: continue
        var item = element.item.duplicate()
        var info: ZoneDifficultyInfo = ProgressData.get_character_difficulty_info(item.my_id_hash, -1, true)
        var difficulty: int = info.max_difficulty_beaten.difficulty_value
        item.tier = Tier.COMMON if difficulty < 0 else (Tier.DANGER_0 if difficulty == 0 else difficulty)
        element.item = item
        element.update_background_color()
