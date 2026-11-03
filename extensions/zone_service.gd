extends "res://singletons/zone_service.gd"

var _ncl_unavailable_zones: Array = []
var _ncl_zones_initialized: bool = false

func ncl_filter_owned_zones() -> void:
    var all_zones: Array = zones.duplicate()
    all_zones.append_array(_ncl_unavailable_zones)
    zones = []
    _ncl_unavailable_zones = []
    for source in all_zones:
        var zone: ZoneData = source
        if !_ncl_zones_initialized:
            zone = source.duplicate()
            zone.default_backgrounds = source.default_backgrounds.duplicate()
        if zone.dlc_id == "" or ProgressData.is_dlc_available(zone.dlc_id):
            zones.append(zone)
        else:
            _ncl_unavailable_zones.append(zone)
    _ncl_zones_initialized = true

func get_zone_data(id: int) -> Resource:
    for zone in _ncl_unavailable_zones:
        if zone.my_id == id:
            return zone
    return.get_zone_data(id)
