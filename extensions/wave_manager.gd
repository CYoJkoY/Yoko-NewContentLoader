extends "res://zones/wave_manager.gd"

func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void:
    .init(p_wave_timer, zone_data, wave_data)
    for content in ProgressData.ncl_get_registered_contents():
        for group in content.groups_in_all_zones:
            current_wave_data.groups_data.append(group.duplicate())
