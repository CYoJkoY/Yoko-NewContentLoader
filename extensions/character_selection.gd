extends "res://ui/menus/run/character_selection.gd"

var _ncl_zone_selection_initialized: bool = false

func _on_ZoneSelectionButton_item_selected(index: int) -> void:
    var random_index: int = _zone_selection_button.get_item_count() - 1
    if !_ncl_zone_selection_initialized:
        _ncl_zone_selection_initialized = true
        index = (
            random_index if ProgressData.settings.zone_is_random
            else _zone_selection_button.get_item_index(int(ProgressData.settings.zone_selected))
        )
        if index < 0:
            index = 0
    elif index < 0 or index >= random_index:
        index = random_index
    _zone_selection_button.select(index)
    if index != random_index:
        ProgressData.settings.zone_is_random = false
        _setup_zone(index)
        return

    var available_zones: Array = ProgressData.ncl_get_available_zones()
    var zone: ZoneData = Utils.get_rand_element(available_zones)
    RunData.current_zone = zone.my_id
    ProgressData.settings.zone_selected = zone.my_id
    ProgressData.settings.zone_is_random = true
    RunData.reset_background()
    _background.texture = _ui_random_zone_background.texture
    _inventory1.update_elements_color(-1)
    reload_info_panel()
    for panel in _get_panels():
        panel._update_bg()

func _setup_zone(index: int) -> void:
    if ProgressData.settings.zone_is_random:
        index = _zone_selection_button.get_item_index(int(ProgressData.settings.zone_selected))
    ._setup_zone(index)
