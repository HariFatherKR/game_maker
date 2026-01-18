extends Node
class_name AugmentDatabaseClass
## AugmentDatabase - 증강체 데이터베이스
##
## 모든 증강체 데이터를 관리합니다.

# =============================================================================
# 변수
# =============================================================================

var _augments: Dictionary = {}
var _loaded: bool = false

# =============================================================================
# 초기화
# =============================================================================

func _init() -> void:
	_load_default_augments()


func _load_default_augments() -> void:
	if _loaded:
		return

	var augments_data := [
		# ===== COMMON (성장) =====
		{
			"id": "quick_growth",
			"name": "Quick Growth",
			"description": "Crops grow 10% faster.",
			"rarity": Augment.Rarity.COMMON,
			"category": Augment.Category.GROWTH,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "growth_speed",
			"effect_value": 0.1,
			"max_stacks": 5,
			"synergy_tags": ["nature", "speed"]
		},
		{
			"id": "fertile_soil",
			"name": "Fertile Soil",
			"description": "Increase base growth by 5 per tick.",
			"rarity": Augment.Rarity.COMMON,
			"category": Augment.Category.GROWTH,
			"effect_type": Augment.EffectType.ADDITIVE,
			"target_stat": "growth_flat",
			"effect_value": 5.0,
			"max_stacks": 10,
			"synergy_tags": ["nature", "earth"]
		},

		# ===== COMMON (수확) =====
		{
			"id": "bountiful_harvest",
			"name": "Bountiful Harvest",
			"description": "Increase crop yield by 15%.",
			"rarity": Augment.Rarity.COMMON,
			"category": Augment.Category.YIELD,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "yield_bonus",
			"effect_value": 0.15,
			"max_stacks": 5,
			"synergy_tags": ["harvest", "abundance"]
		},

		# ===== UNCOMMON (성장) =====
		{
			"id": "sunlight_blessing",
			"name": "Sunlight Blessing",
			"description": "Crops grow 25% faster during day.",
			"rarity": Augment.Rarity.UNCOMMON,
			"category": Augment.Category.GROWTH,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "day_growth_speed",
			"effect_value": 0.25,
			"max_stacks": 3,
			"synergy_tags": ["light", "time"]
		},
		{
			"id": "moonlight_growth",
			"name": "Moonlight Growth",
			"description": "Crops continue to grow at full speed when offline.",
			"rarity": Augment.Rarity.UNCOMMON,
			"category": Augment.Category.GROWTH,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "offline_efficiency",
			"effect_value": 0.5,
			"max_stacks": 2,
			"synergy_tags": ["dark", "time"]
		},

		# ===== UNCOMMON (경제) =====
		{
			"id": "merchant_friend",
			"name": "Merchant's Friend",
			"description": "Sell crops for 20% more gold.",
			"rarity": Augment.Rarity.UNCOMMON,
			"category": Augment.Category.ECONOMY,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "sell_price",
			"effect_value": 0.2,
			"max_stacks": 3,
			"synergy_tags": ["economy", "trade"]
		},
		{
			"id": "bargain_hunter",
			"name": "Bargain Hunter",
			"description": "Seeds cost 15% less.",
			"rarity": Augment.Rarity.UNCOMMON,
			"category": Augment.Category.ECONOMY,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "seed_cost",
			"effect_value": -0.15,
			"max_stacks": 4,
			"synergy_tags": ["economy", "discount"]
		},

		# ===== RARE (자동화) =====
		{
			"id": "auto_harvester",
			"name": "Auto Harvester",
			"description": "Automatically harvest ready crops.",
			"rarity": Augment.Rarity.RARE,
			"category": Augment.Category.AUTOMATION,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "auto_harvest",
			"effect_value": 1.0,
			"max_stacks": 1,
			"synergy_tags": ["machine", "automation"]
		},
		{
			"id": "auto_planter",
			"name": "Auto Planter",
			"description": "Automatically replant after harvest.",
			"rarity": Augment.Rarity.RARE,
			"category": Augment.Category.AUTOMATION,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "auto_plant",
			"effect_value": 1.0,
			"max_stacks": 1,
			"synergy_tags": ["machine", "automation"]
		},

		# ===== RARE (특수) =====
		{
			"id": "lucky_clover",
			"name": "Lucky Clover",
			"description": "5% chance for double yield.",
			"rarity": Augment.Rarity.RARE,
			"category": Augment.Category.SPECIAL,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "double_yield_chance",
			"effect_value": 0.05,
			"max_stacks": 4,
			"synergy_tags": ["luck", "nature"]
		},
		{
			"id": "time_warp",
			"name": "Time Warp",
			"description": "1% chance for instant growth.",
			"rarity": Augment.Rarity.RARE,
			"category": Augment.Category.SPECIAL,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "instant_grow_chance",
			"effect_value": 0.01,
			"max_stacks": 5,
			"synergy_tags": ["time", "magic"]
		},

		# ===== EPIC =====
		{
			"id": "golden_touch",
			"name": "Golden Touch",
			"description": "All gold gains increased by 50%.",
			"rarity": Augment.Rarity.EPIC,
			"category": Augment.Category.ECONOMY,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "gold_multiplier",
			"effect_value": 0.5,
			"max_stacks": 2,
			"synergy_tags": ["gold", "wealth"]
		},
		{
			"id": "natures_fury",
			"name": "Nature's Fury",
			"description": "Growth speed doubled. Yield -20%.",
			"rarity": Augment.Rarity.EPIC,
			"category": Augment.Category.GROWTH,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "natures_fury",
			"effect_value": 1.0,
			"max_stacks": 1,
			"synergy_tags": ["nature", "chaos"]
		},
		{
			"id": "harvester_prime",
			"name": "Harvester Prime",
			"description": "Auto harvest yields 25% more.",
			"rarity": Augment.Rarity.EPIC,
			"category": Augment.Category.AUTOMATION,
			"effect_type": Augment.EffectType.MULTIPLICATIVE,
			"target_stat": "auto_harvest_bonus",
			"effect_value": 0.25,
			"max_stacks": 3,
			"synergy_tags": ["machine", "automation"]
		},

		# ===== LEGENDARY =====
		{
			"id": "eternal_spring",
			"name": "Eternal Spring",
			"description": "All crops grow 100% faster. New plots unlock 50% cheaper.",
			"rarity": Augment.Rarity.LEGENDARY,
			"category": Augment.Category.GROWTH,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "eternal_spring",
			"effect_value": 1.0,
			"max_stacks": 1,
			"synergy_tags": ["nature", "eternal", "legend"]
		},
		{
			"id": "midas_blessing",
			"name": "Midas Blessing",
			"description": "Triple gold from all sources. 10% chance to destroy crop on harvest.",
			"rarity": Augment.Rarity.LEGENDARY,
			"category": Augment.Category.ECONOMY,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "midas_blessing",
			"effect_value": 1.0,
			"max_stacks": 1,
			"synergy_tags": ["gold", "curse", "legend"]
		},
		{
			"id": "void_farmer",
			"name": "Void Farmer",
			"description": "Gain a shadow plot that duplicates a random crop's yield each harvest.",
			"rarity": Augment.Rarity.LEGENDARY,
			"category": Augment.Category.SPECIAL,
			"effect_type": Augment.EffectType.SPECIAL,
			"target_stat": "void_farmer",
			"effect_value": 1.0,
			"max_stacks": 1,
			"synergy_tags": ["void", "shadow", "legend"]
		}
	]

	for data in augments_data:
		var aug := Augment.from_dict(data)
		_augments[aug.id] = aug

	_loaded = true
	print("[AugmentDatabase] Loaded %d augments" % _augments.size())

# =============================================================================
# 공개 API
# =============================================================================

func get_augment(augment_id: String) -> Augment:
	if _augments.has(augment_id):
		return _augments[augment_id].duplicate_augment()
	push_warning("[AugmentDatabase] Augment not found: %s" % augment_id)
	return null


func get_all_augments() -> Array[Augment]:
	var result: Array[Augment] = []
	for aug in _augments.values():
		result.append(aug)
	return result


func get_augments_by_rarity(rarity: Augment.Rarity) -> Array[Augment]:
	var result: Array[Augment] = []
	for aug in _augments.values():
		if aug.rarity == rarity:
			result.append(aug)
	return result


func get_augments_by_category(category: Augment.Category) -> Array[Augment]:
	var result: Array[Augment] = []
	for aug in _augments.values():
		if aug.category == category:
			result.append(aug)
	return result


func has_augment(augment_id: String) -> bool:
	return _augments.has(augment_id)

# =============================================================================
# 싱글톤
# =============================================================================

static var _instance: AugmentDatabaseClass = null

static func get_instance() -> AugmentDatabaseClass:
	if _instance == null:
		_instance = AugmentDatabaseClass.new()
	return _instance


static func get_augment(augment_id: String) -> Augment:
	return get_instance().get_augment(augment_id)
