extends "res://ui/menus/shop/synergy_container.gd"

const NCL_SYNERGY_PANEL_SCENE = preload("res://ui/menus/shop/synergy_panel.tscn")

# ══════════════════════════════════════════ Extension ══════════════════════════════════════════ #
func set_synergies_text(item_data: ItemParentData, player_index: int) -> void:
    if item_data is WeaponData:
        while synergy_panels.size() < item_data.sets.size():
            var template: Control = synergy_panels[0]
            var panel: Control = NCL_SYNERGY_PANEL_SCENE.instance()
            panel.theme = template.theme
            panel.add_stylebox_override("panel", template.get_stylebox("panel"))
            panel.hide()
            add_child(panel)
            synergy_panels.append(panel)

    .set_synergies_text(item_data, player_index)
