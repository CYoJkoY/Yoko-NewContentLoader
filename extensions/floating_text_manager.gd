extends "res://visual_effects/floating_text/floating_text_manager.gd"

# =========================== Extension =========================== #
func _on_unit_took_damage(unit: Unit, value: int, _knockback_direction: Vector2, is_crit: bool, is_dodge: bool, is_protected: bool, armor_did_something: bool, _args: TakeDamageArgs, hit_type: int, is_one_shot: bool) -> void:
    if _args.has_meta("custom_color") or \
    _args.has_meta("csutom_icon"):
        if !ProgressData.settings.damage_display: return
            
        var color: Color = _args.get_meta("custom_color", Color.white)
        var icon_hash: int = _args.get_meta("custom_icon", Keys.empty_hash)
        var text = str(value)
        var icon: Resource = ItemService.get_icon(icon_hash) if icon_hash != Keys.empty_hash else null
        var always_display = true
        var need_translate = false

        display(
            text,
            unit.global_position,
            color,
            icon,
            duration,
            always_display,
            direction,
            need_translate
        )

        return
    
    ._on_unit_took_damage(unit, value, _knockback_direction, is_crit, is_dodge, is_protected, armor_did_something, _args, hit_type, is_one_shot)
