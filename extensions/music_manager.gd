extends "res://singletons/music_manager.gd"

func set_shuffled_tracks() -> void:
    .set_shuffled_tracks()
    var previous_track_count: int = shuffled_tracks.size()
    for content in ProgressData.ncl_get_registered_contents():
        if ProgressData.settings.deactivated_dlc_tracks.has(content.my_id):
            continue
        shuffled_tracks.append_array(content.music_tracks)
    if shuffled_tracks.size() != previous_track_count:
        shuffled_tracks.shuffle()

func has_tracks_to_add() -> bool:
    if.has_tracks_to_add():
        return true
    for content in ProgressData.ncl_get_registered_contents():
        if ProgressData.settings.deactivated_dlc_tracks.has(content.my_id):
            continue
        if !content.music_tracks.empty():
            return true
    return false
