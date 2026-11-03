extends "res://singletons/progress_data_loader_v3.gd"

func deserialize_run_state(state: Dictionary) -> Dictionary:
    if !ProgressData.ncl_check_content_valid_for_run_state(state):
        var invalid_state: Dictionary = state.duplicate()
        invalid_state.has_run_state = false
        return invalid_state
    return.deserialize_run_state(state)
