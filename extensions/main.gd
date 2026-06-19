extends "res://main.gd"

const NCL_END_WAVE_BEFORE_REWARDS: String = "before_wave_rewards"
const NCL_END_WAVE_AFTER_REWARDS: String = "after_wave_rewards"
const NCL_END_WAVE_BEFORE_END_RUN_SCENE: String = "before_end_run_scene"
const NCL_END_WAVE_BEFORE_CHANGE_SCENE: String = "before_change_scene"

var ncl_end_wave_hooks: Dictionary = {
	NCL_END_WAVE_BEFORE_REWARDS: [],
	NCL_END_WAVE_AFTER_REWARDS: [],
	NCL_END_WAVE_BEFORE_END_RUN_SCENE: [],
	NCL_END_WAVE_BEFORE_CHANGE_SCENE: [],
}

# =========================== Extension =========================== #
func _on_EndWaveTimer_timeout() -> void:
	_coop_upgrades_ui.propagate_call("set_process_input", [true])
	DebugService.log_data("_on_EndWaveTimer_timeout")
	SoundManager.clear_queue()
	SoundManager2D.clear_queue()
	InputService.set_gamepad_echo_processing(true)

	_end_wave_timer_timedout = true

	if _is_wave_failed and RunData.current_wave > 0:
		_retry_wave.show()
		_pause_menu.enabled = false
		return

	_wave_cleared_label.hide()
	_wave_timer_label.hide()

	_camera.move_speed_factor = 0.0
	_camera.zoom_in_speed_factor = 0.0
	_camera.zoom_out_speed_factor = 0.0

	RunData.on_wave_end()
	LinkedStats.reset()

	var scene: String
	var _args: Entity.DieArgs = Utils.default_die_args
	if _is_run_lost or _is_run_won:
		DebugService.log_data("end run...")
		var before_end_run_state = ncl_run_end_wave_hooks(NCL_END_WAVE_BEFORE_END_RUN_SCENE)
		if before_end_run_state is GDScriptFunctionState:
			yield(before_end_run_state, "completed")
		scene = RunData.get_end_run_scene_path()
	else:
		DebugService.log_data("process end-wave hooks, consumables and upgrades...")
		MusicManager.tween(-8)

		var before_rewards_state = ncl_run_end_wave_hooks(NCL_END_WAVE_BEFORE_REWARDS)
		if before_rewards_state is GDScriptFunctionState:
			yield(before_rewards_state, "completed")

		var rewards_state = ncl_process_wave_rewards()
		if rewards_state is GDScriptFunctionState:
			yield(rewards_state, "completed")

		var after_rewards_state = ncl_run_end_wave_hooks(NCL_END_WAVE_AFTER_REWARDS)
		if after_rewards_state is GDScriptFunctionState:
			yield(after_rewards_state, "completed")

		DebugService.log_data("display challenge ui...")
		if _is_chal_ui_displayed:
			yield(_challenge_completed_ui, "finished")

		scene = RunData.get_shop_scene_path()

	var before_change_scene_state = ncl_run_end_wave_hooks(NCL_END_WAVE_BEFORE_CHANGE_SCENE, [scene])
	if before_change_scene_state is GDScriptFunctionState:
		yield(before_change_scene_state, "completed")
	_change_scene(scene)

# =========================== Method =========================== #
func ncl_register_end_wave_hook(hook_name: String, owner: Object, method_name: String, priority: int = 100) -> void:
	if !ncl_end_wave_hooks.has(hook_name):
		ncl_end_wave_hooks[hook_name] = []

	var hooks: Array = ncl_end_wave_hooks[hook_name]
	for hook in hooks:
		if hook["owner"] == owner and hook["method_name"] == method_name:
			hook["priority"] = priority
			hooks.sort_custom(self, "ncl_sort_end_wave_hooks")
			return

	hooks.append({
		"owner": owner,
		"method_name": method_name,
		"priority": priority,
	})
	hooks.sort_custom(self, "ncl_sort_end_wave_hooks")

func ncl_unregister_end_wave_hook(hook_name: String, owner: Object, method_name: String) -> void:
	if !ncl_end_wave_hooks.has(hook_name):
		return

	var hooks: Array = ncl_end_wave_hooks[hook_name]
	for i in range(hooks.size() - 1, -1, -1):
		var hook: Dictionary = hooks[i]
		if hook["owner"] == owner and hook["method_name"] == method_name:
			hooks.remove(i)

func ncl_sort_end_wave_hooks(a: Dictionary, b: Dictionary) -> bool:
	if int(a["priority"]) == int(b["priority"]):
		return str(a["method_name"]) < str(b["method_name"])
	return int(a["priority"]) < int(b["priority"])

func ncl_run_end_wave_hooks(hook_name: String, args: Array = []):
	if !ncl_end_wave_hooks.has(hook_name):
		return

	for hook in ncl_end_wave_hooks[hook_name].duplicate():
		var owner: Object = hook["owner"]
		var method_name: String = hook["method_name"]
		if owner == null or !owner.has_method(method_name):
			continue

		var result = owner.callv(method_name, args)
		if result is GDScriptFunctionState:
			yield(result, "completed")

func ncl_process_wave_rewards():
	if RunData.is_coop_run:
		_hud.hide()
		if _coop_upgrades_ui.show_options(_consumables_to_process, _upgrades_to_process):
			yield(_coop_upgrades_ui, "options_processed")
		_coop_upgrades_ui.hide()
	else:
		if _upgrades_ui.show_options(_consumables_to_process, _upgrades_to_process):
			var things_to_process_player_container = _things_to_process_player_containers[0]
			var ui_consumables_to_process = things_to_process_player_container.consumables
			var ui_upgrades_to_process = things_to_process_player_container.upgrades
			while not ui_consumables_to_process.is_empty():
				var consumable = yield(_upgrades_ui, "consumable_selected")
				ui_consumables_to_process.remove_element(consumable.consumable_data)
			while not ui_upgrades_to_process.is_empty():
				var args = yield(_upgrades_ui, "upgrade_selected")
				var upgrade = args[1]
				ui_upgrades_to_process.remove_element(upgrade.level)
			yield(_upgrades_ui, "options_processed")
		_upgrades_ui.hide()
