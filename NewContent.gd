extends Resource

export(String) var content_name = ""
export(Texture) var content_icon
export(Texture) var content_logo
export(String) var my_id
var my_id_hash: int = Keys.empty_hash
var _ncl_update_data: UpdateData = null
var _ncl_registered: bool = false

# Other
export(Array, Resource) var groups_in_all_zones = []
export(Array, Resource) var music_tracks = []

# ItemService
export(Array, Resource) var backgrounds = []
export(Array, Resource) var characters = []
export(Array, Resource) var entities = []
export(Array, Resource) var elites = []
export(Array, Resource) var bosses = []
export(Array, Resource) var stats = []
export(Array, Resource) var items = []
export(Array, Resource) var weapons = []
export(Array, Resource) var effects = []
export(Array, Resource) var consumables = []
export(Array, Resource) var upgrades = []
export(Array, Resource) var sets = []
export(Array, Resource) var difficulties = []
export(Array, Resource) var icons = []
export(Array, Resource) var title_screen_backgrounds = []

# Translations
export(Array, Translation) var translations

# ChallengeService
export(Array, Resource) var challenges = []

# ZoneService
export(Array, Resource) var zones = []

# RunData
export(Dictionary) var tracked_items = {}
var tracked_items_hash: Dictionary = {}
export(Dictionary) var tracked_effects = {}
var tracked_effects_hash: Dictionary = {}
export(Array, String) var primary_stats_list = []
var primary_stats_list_hash: Array = []
export(Array, String) var effect_keys_full_serialization = []
var effect_keys_full_serialization_hash = []
export(Array, String) var effect_keys_with_weapon_stats = []
var effect_keys_with_weapon_stats_hash = []

# Text
export(Dictionary) var translation_keys_needing_operator = {}
export(Dictionary) var translation_keys_needing_percent = {}

# EffectBehaviorService
export(Array, Resource) var scene_effect_behaviors = []
export(Array, Resource) var enemy_effect_behaviors = []
export(Array, Resource) var player_effect_behaviors = []

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func _init() -> void:
    if my_id_hash == Keys.empty_hash:
        call_deferred("_generate_hashes")

func _generate_hashes() -> void:
    my_id_hash = Keys.generate_hash(my_id)

func duplicate(subresources:=false) -> Resource:
    var duplication =.duplicate(subresources)

    if my_id_hash == Keys.empty_hash:
        my_id_hash = Keys.generate_hash(my_id)

    duplication.my_id_hash = my_id_hash
    duplication.tracked_items_hash = tracked_items_hash.duplicate()
    duplication.tracked_effects_hash = tracked_effects_hash.duplicate()
    duplication.primary_stats_list_hash = primary_stats_list_hash.duplicate()
    duplication.effect_keys_full_serialization_hash = effect_keys_full_serialization_hash.duplicate()
    duplication.effect_keys_with_weapon_stats_hash = effect_keys_with_weapon_stats_hash.duplicate()

    return duplication

func add_resources() -> void:
    if _ncl_registered: return
    _ncl_registered = true
    ProgressData.ncl_registered_contents.append(self)
    _generate_hashes()
    _ncl_initialize_content_hashes()
    _ncl_register_item_set()

    for translation in translations:
        TranslationServer.add_translation(translation)

    zones = zones.duplicate()
    for i in zones.size():
        var source: ZoneData = zones[i]
        zones[i] = source.duplicate()
        zones[i].default_backgrounds = source.default_backgrounds.duplicate()
    add_if_not_null(ZoneService.zones, zones)

    if !backgrounds.empty():
        ItemService.add_backgrounds(backgrounds)

    add_if_not_null(ItemService.entities, entities)
    add_if_not_null(ZoneService.bosses, bosses)
    for zone in zones:
        zone.elites = zone.elites.duplicate()
        zone.bosses = zone.bosses.duplicate()
        for elite in elites:
            if elite.zone_id == zone.my_id and !zone.elites.has(elite): zone.elites.append(elite)
        for boss in bosses:
            if boss.zone_id == zone.my_id and !zone.bosses.has(boss): zone.bosses.append(boss)
    add_if_not_null(ItemService.stats, stats)
    add_if_not_null(ItemService.consumables, consumables)
    add_if_not_null(ItemService.upgrades, upgrades)
    add_if_not_null(ItemService.sets, sets)
    add_if_not_null(ItemService.difficulties, difficulties)
    add_if_not_null(ItemService.icons, icons)
    add_if_not_null(ItemService.title_screen_backgrounds, title_screen_backgrounds)
    add_if_not_null(ItemService.effects, effects)

    for stat in ItemService.stats:
        stat.generate_hashes()
    
    Utils.reset_stat_keys()

    add_if_not_null(EffectBehaviorService.scene_effect_behaviors, scene_effect_behaviors)
    add_if_not_null(EffectBehaviorService.enemy_effect_behaviors, enemy_effect_behaviors)
    add_if_not_null(EffectBehaviorService.player_effect_behaviors, player_effect_behaviors)

    if !translation_keys_needing_operator.empty():
        Text.keys_needing_operator.merge(translation_keys_needing_operator)
    if !translation_keys_needing_percent.empty():
        Text.keys_needing_percent.merge(translation_keys_needing_percent)

    if !tracked_items.empty():
        tracked_items_hash = Utils.convert_dictionary_to_hash(tracked_items)
        RunData.init_tracked_items.merge(tracked_items_hash)
    if !tracked_effects.empty():
        tracked_effects_hash = Utils.convert_dictionary_to_hash(tracked_effects)
        RunData.ncl_init_tracked_effects.merge(tracked_effects_hash)
    if !primary_stats_list.empty():
        primary_stats_list_hash = Utils.convert_to_hash_array(primary_stats_list)
        RunData.primary_stats_list.append_array(primary_stats_list_hash)
    if !effect_keys_full_serialization.empty():
        effect_keys_full_serialization_hash = Utils.convert_to_hash_array(effect_keys_full_serialization)
        RunData.effect_keys_full_serialization.append_array(effect_keys_full_serialization_hash)
    if !effect_keys_with_weapon_stats.empty():
        effect_keys_with_weapon_stats_hash = Utils.convert_to_hash_array(effect_keys_with_weapon_stats)
        RunData.effect_keys_with_weapon_stats.append_array(effect_keys_with_weapon_stats_hash)

    add_custom_resources()
    if ProgressData.ncl_content_registration_ready:
        for challenge in challenges:
            if !ChallengeService.challenges.has(challenge): ChallengeService.challenges.append(challenge)
            challenge.my_id_hash = Keys.generate_hash(challenge.my_id)
            ChallengeService.hash_to_id[challenge.my_id_hash] = challenge.my_id
        ChallengeService.set_stat_challenges()
        ProgressData.refresh_active_update_data()
        ProgressData.add_unlocked_by_default()
        ItemService.init_unlocked_pool()

func remove_resources() -> void:
    if !_ncl_registered: return
    _ncl_registered = false
    ProgressData.ncl_registered_contents.erase(self)
    ItemService.update_data_list.erase(_ncl_update_data)
    _ncl_update_data = null
    _ncl_invalidate_content_caches()
    ProgressData.refresh_active_update_data()
    for translation in translations:
        TranslationServer.remove_translation(translation)

    if backgrounds != null:
        ItemService.remove_backgrounds(backgrounds)
    erase_if_not_null(ZoneService.zones, zones)
    
    erase_if_not_null(ItemService.entities, entities)
    erase_if_not_null(ZoneService.bosses, bosses)
    for zone in zones:
        erase_if_not_null(zone.elites, elites)
        erase_if_not_null(zone.bosses, bosses)
    erase_if_not_null(ItemService.stats, stats)
    erase_if_not_null(ItemService.consumables, consumables)
    erase_if_not_null(ItemService.upgrades, upgrades)
    erase_if_not_null(ItemService.sets, sets)
    erase_if_not_null(ItemService.difficulties, difficulties)
    erase_if_not_null(ItemService.icons, icons)
    erase_if_not_null(ItemService.title_screen_backgrounds, title_screen_backgrounds)
    erase_if_not_null(ItemService.effects, effects)

    Utils.reset_stat_keys()

    erase_if_not_null(ChallengeService.challenges, challenges)
    erase_if_not_null(ChallengeService.stat_challenges, challenges)
    for challenge in challenges:
        ChallengeService.hash_to_id.erase(challenge.my_id_hash)

    erase_if_not_null(EffectBehaviorService.scene_effect_behaviors, scene_effect_behaviors)
    erase_if_not_null(EffectBehaviorService.enemy_effect_behaviors, enemy_effect_behaviors)
    erase_if_not_null(EffectBehaviorService.player_effect_behaviors, player_effect_behaviors)

    erase_if_not_null(Text.keys_needing_operator, translation_keys_needing_operator)
    erase_if_not_null(Text.keys_needing_percent, translation_keys_needing_percent)

    erase_if_not_null(RunData.init_tracked_items, tracked_items_hash)
    erase_if_not_null(RunData.ncl_init_tracked_effects, tracked_effects_hash)
    erase_if_not_null(RunData.primary_stats_list, primary_stats_list_hash)
    erase_if_not_null(RunData.effect_keys_full_serialization, effect_keys_full_serialization_hash)
    erase_if_not_null(RunData.effect_keys_with_weapon_stats, effect_keys_with_weapon_stats_hash)

    remove_custom_resources()

    ItemService.init_unlocked_pool()

# ══════════════════════════════════════════ Custom ══════════════════════════════════════════ #
func ncl_update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
    return base_consumable_data

# ══════════════════════════════════════════ Method ══════════════════════════════════════════ #
func add_if_not_null(array: Array, _items: Array) -> void:
    if _items.empty(): return

    array.append_array(_items)

func erase_if_not_null(array, _items) -> void:
    if _items.empty(): return

    for _item in _items: array.erase(_item)

func add_custom_resources() -> void:
    pass

func remove_custom_resources() -> void:
    pass

func _ncl_register_item_set() -> void:
    var item_set: ItemSetData = ItemSetData.new()
    item_set.my_id = my_id
    item_set._generate_hashes()
    item_set.items = items.duplicate()
    item_set.weapons = weapons.duplicate()
    item_set.characters = characters.duplicate()
    item_set.stats = stats.duplicate()
    item_set.challenges = challenges.duplicate()
    _ncl_update_data = UpdateData.new()
    _ncl_update_data.id = my_id
    _ncl_update_data.name = content_name if content_name != "" else my_id
    _ncl_update_data.update_type = UpdateData.UpdateType.UPDATE
    _ncl_update_data.item_set = item_set
    _ncl_update_data.icon = content_icon
    _ncl_update_data.baner_logo = content_logo if content_logo != null else content_icon
    _ncl_update_data.color = Color.white
    ItemService.update_data_list.append(_ncl_update_data)
    _ncl_invalidate_content_caches()

func _ncl_invalidate_content_caches() -> void:
    ItemService.invalidate_items_cache()
    ItemService.invalidate_weapons_cache()
    ItemService.invalidate_characters_cache()

func _ncl_initialize_content_hashes() -> void:
    for collection in [characters, items, weapons, consumables, upgrades, sets, elites, bosses, icons, challenges]:
        for resource in collection:
            if resource.has_method("_generate_hashes"): resource._generate_hashes()
    for weapon in weapons:
        if weapon.upgrades_into != null: weapon.upgrades_into.previous_upgrade = weapon
