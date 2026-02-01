extends Resource

# ItemService
export(Array, Resource) var backgrounds = null
export(Array, Resource) var characters = null
export(Array, Resource) var entities = null
export(Array, Resource) var elites = null
export(Array, Resource) var bosses = null
export(Array, Resource) var stats = null
export(Array, Resource) var items = null
export(Array, Resource) var weapons = null
export(Array, Resource) var effects = null
export(Array, Resource) var consumables = null
export(Array, Resource) var upgrades = null
export(Array, Resource) var sets = null
export(Array, Resource) var difficulties = null
export(Array, Resource) var icons = null
export(Array, Resource) var title_screen_backgrounds = null

# ChallengeService
export(Array, Resource) var challenges = null

# ZoneService
export(Array, Resource) var zones = null

# RunData
export(Dictionary) var tracked_items = null
export(Dictionary) var tracked_effects = null

# Text
export(Dictionary) var translation_keys_needing_operator = null
export(Dictionary) var translation_keys_needing_percent = null

func add_resources() -> void:
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
    
    if challenges != null:
        ChallengeService.challenges.append_array(challenges)
        ChallengeService.set_stat_challenges()

    if zones != null:
        ZoneService.zones.append_array(zones)
    
    if backgrounds != null:
        ItemService.add_backgrounds(backgrounds)
        for zone in ZoneService.zones:
            zone.default_backgrounds.append_array(backgrounds)

    if translation_keys_needing_operator != null:
        Text.keys_needing_operator.merge(translation_keys_needing_operator)
    
    if translation_keys_needing_percent != null:
        Text.keys_needing_percent.merge(translation_keys_needing_percent)
    
    if tracked_items != null:
        var tracked_items_hashes: Dictionary = Utils.convert_dictionary_to_hash(tracked_items)
        RunData.init_tracked_items.merge(tracked_items_hashes)
    
    if tracked_effects != null:
        var tracked_effects_hashes: Dictionary = Utils.convert_dictionary_to_hash(tracked_effects)
        RunData.fa_init_tracked_effects.merge(tracked_effects_hashes)

    ItemService.init_unlocked_pool()

func add_if_not_null(array, _items) -> void:
    if _items != null: array.append_array(_items)

func add_starting_weapons() -> void:
    if weapons == null: return

    for weapon in weapons:
        if weapon.add_to_chars_as_starting.empty(): continue

        for character_id in weapon.add_to_chars_as_starting:
            var character_data = ItemService.get_element(ItemService.characters, Keys.generate_hash(character_id))
            
            for starting_weapon in character_data.starting_weapons:
                if starting_weapon.my_id_hash == weapon.my_id_hash: continue
                
                character_data.starting_weapons.append(weapon)
