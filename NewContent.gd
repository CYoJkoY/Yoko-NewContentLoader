extends Resource

export(String) var my_id
var my_id_hash: int = Keys.empty_hash

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

# ChallengeService
export(Array, Resource) var challenges = []

# ZoneService
export(Array, Resource) var zones = []

# RunData
export(Dictionary) var tracked_items = {}
var tracked_items_hash: Dictionary = {}
export(Dictionary) var tracked_effects = {}
var tracked_effects_hash: Dictionary = {}

# Text
export(Dictionary) var translation_keys_needing_operator = {}
export(Dictionary) var translation_keys_needing_percent = {}

# EffectBehaviorService
export(Array, Resource) var scene_effect_behaviors = []
export(Array, Resource) var enemy_effect_behaviors = []
export(Array, Resource) var player_effect_behaviors = []

# =========================== Custom =========================== #
func _init() -> void:
    if my_id_hash == Keys.empty_hash:
        call_deferred("_generate_hashes")

func _generate_hashes() -> void:
    my_id_hash = Keys.generate_hash(my_id)

func duplicate(subresources := false) -> Resource:
    var duplication =.duplicate(subresources)

    if my_id_hash == Keys.empty_hash:
        my_id_hash = Keys.generate_hash(my_id)

    duplication.my_id_hash = my_id_hash
    duplication.tracked_items_hash = tracked_items_hash.duplicate()
    duplication.tracked_effects_hash = tracked_effects_hash.duplicate()

    return duplication

func add_resources() -> void:
    _generate_hashes()

    add_if_not_null(ZoneService.zones, zones)

    if backgrounds != null:
        ItemService.add_backgrounds(backgrounds)
        for zone in ZoneService.zones:
            add_if_not_null(zone.default_backgrounds, backgrounds)

    add_if_not_null(ItemService.characters, characters)
    add_if_not_null(ItemService.entities, entities)
    add_if_not_null(ItemService.elites, elites)
    add_if_not_null(ItemService.bosses, bosses)
    add_if_not_null(ItemService.stats, stats)
    add_if_not_null(ItemService.items, items)
    add_if_not_null(ItemService.consumables, consumables)
    add_if_not_null(ItemService.upgrades, upgrades)
    add_if_not_null(ItemService.sets, sets)
    add_if_not_null(ItemService.difficulties, difficulties)
    add_if_not_null(ItemService.icons, icons)
    add_if_not_null(ItemService.title_screen_backgrounds, title_screen_backgrounds)
    add_if_not_null(ItemService.weapons, weapons)
    add_if_not_null(ItemService.effects, effects)

    add_starting_weapons()

    for stat in ItemService.stats:
        stat.generate_hashes()
    
    Utils.reset_stat_keys()

    if challenges != null:
        ChallengeService.challenges.append_array(challenges)
        ChallengeService.set_stat_challenges()
    
    add_if_not_null(EffectBehaviorService.scene_effect_behaviors, scene_effect_behaviors)
    add_if_not_null(EffectBehaviorService.enemy_effect_behaviors, enemy_effect_behaviors)
    add_if_not_null(EffectBehaviorService.player_effect_behaviors, player_effect_behaviors)

    if translation_keys_needing_operator != null:
        Text.keys_needing_operator.merge(translation_keys_needing_operator)
    if translation_keys_needing_percent != null:
        Text.keys_needing_percent.merge(translation_keys_needing_percent)
    
    if tracked_items != null:
        tracked_items_hash = Utils.convert_dictionary_to_hash(tracked_items)
        RunData.init_tracked_items.merge(tracked_items_hash)
    if tracked_effects != null:
        tracked_effects_hash = Utils.convert_dictionary_to_hash(tracked_effects)
        RunData.ncl_init_tracked_effects.merge(tracked_effects_hash)

    ItemService.init_unlocked_pool()

func remove_resources() -> void:
    erase_if_not_null(ZoneService.zones, zones)

    if backgrounds != null:
        ItemService.remove_backgrounds(backgrounds)
        for zone in ZoneService.zones:
            erase_if_not_null(zone.default_backgrounds, backgrounds)
    
    erase_if_not_null(ItemService.characters, characters)
    erase_if_not_null(ItemService.entities, entities)
    erase_if_not_null(ItemService.elites, elites)
    erase_if_not_null(ItemService.bosses, bosses)
    erase_if_not_null(ItemService.stats, stats)
    erase_if_not_null(ItemService.items, items)
    erase_if_not_null(ItemService.consumables, consumables)
    erase_if_not_null(ItemService.upgrades, upgrades)
    erase_if_not_null(ItemService.sets, sets)
    erase_if_not_null(ItemService.difficulties, difficulties)
    erase_if_not_null(ItemService.icons, icons)
    erase_if_not_null(ItemService.title_screen_backgrounds, title_screen_backgrounds)
    erase_if_not_null(ItemService.weapons, weapons)
    erase_if_not_null(ItemService.effects, effects)

    erase_starting_weapons()

    Utils.reset_stat_keys()

    erase_if_not_null(ChallengeService.challenges, challenges)
    erase_if_not_null(ChallengeService.stat_challenges, challenges)

    erase_if_not_null(EffectBehaviorService.scene_effect_behaviors, scene_effect_behaviors)
    erase_if_not_null(EffectBehaviorService.enemy_effect_behaviors, enemy_effect_behaviors)
    erase_if_not_null(EffectBehaviorService.player_effect_behaviors, player_effect_behaviors)

    erase_if_not_null(Text.keys_needing_operator, translation_keys_needing_operator)
    erase_if_not_null(Text.keys_needing_percent, translation_keys_needing_percent)

    erase_if_not_null(RunData.init_tracked_items, tracked_items_hash)
    erase_if_not_null(RunData.ncl_init_tracked_effects, tracked_effects_hash)

    ItemService.init_unlocked_pool()

func update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
	return base_consumable_data

func update_item_effects(item: ItemParentData, _player_index: int) -> ItemParentData:
	return item

# =========================== Method =========================== #
func add_if_not_null(array, _items) -> void:
    if _items.empty(): return
    
    array.append_array(_items)

func erase_if_not_null(array, _items) -> void:
    if _items.empty(): return
    
    for _item in _items:
        array.erase(_item)

func add_starting_weapons() -> void:
    if weapons.empty(): return

    for weapon in weapons:
        if weapon.add_to_chars_as_starting.empty(): continue

        for character_id in weapon.add_to_chars_as_starting:
            var already_has_starting_weapon = false
            var character_data = ItemService.get_element_safe(ItemService.characters, character_id)
            for starting_weapon in character_data.starting_weapons:
                if starting_weapon.my_id_hash == weapon.my_id_hash:
                    already_has_starting_weapon = true

            if !already_has_starting_weapon:
                character_data.starting_weapons.append(weapon)

func erase_starting_weapons() -> void:
    if weapons.empty(): return

    for weapon in weapons:
        if weapon.add_to_chars_as_starting.empty(): continue

        for character_id in weapon.add_to_chars_as_starting:
            var character_data = ItemService.get_element_safe(ItemService.characters, character_id)
            character_data.starting_weapons.erase(weapon)
