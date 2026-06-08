extends "res://dlcs/dlc_1/dlc_1_data.gd"


func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
    var cursed_item: ItemParentData = .curse_item(item_data, player_index, turn_randomization_off, min_modifier)
    return Utils.ncl_apply_dlc1_curse_item_passes(
        item_data,
        cursed_item,
        player_index,
        turn_randomization_off,
        min_modifier,
        self
    )
