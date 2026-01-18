extends RefCounted
class_name ExtendedGodsData
## ExtendedGodsData - 추가 신 데이터
##
## Phase 4 엔드게임용 추가 신 정의

# =============================================================================
# 추가 신 정의
# =============================================================================

enum ExtendedGod {
	DEMETER,    # 대지의 신
	POSEIDON,   # 물의 신
	APOLLO,     # 빛의 신
	HADES,      # 지하세계의 신 (하드모드)
	GAIA        # 대지 어머니 (최종 엔딩)
}

const EXTENDED_GOD_DATA := {
	ExtendedGod.DEMETER: {
		"id": "demeter",
		"name": "데메테르",
		"title": "대지의 여신",
		"description": "풍요와 대지를 관장합니다. 모든 작물에 축복을 내립니다.",
		"color": Color(0.4, 0.6, 0.2),
		"unlock_condition": "all_biomes_unlocked",
		"max_favor": 200,
		"synergy_bonuses": {
			50: {"yield_bonus": 0.15, "name": "대지의 축복"},
			100: {"growth_speed": 0.2, "name": "풍요의 땅"},
			150: {"all_stats": 0.1, "name": "어머니의 은총"},
			200: {"legendary_chance": 0.1, "name": "대지의 화신"}
		}
	},
	ExtendedGod.POSEIDON: {
		"id": "poseidon",
		"name": "포세이돈",
		"title": "바다의 신",
		"description": "물을 지배하며 가뭄을 물리칩니다.",
		"color": Color(0.2, 0.4, 0.8),
		"unlock_condition": "desert_biome_mastered",
		"max_favor": 200,
		"synergy_bonuses": {
			50: {"drought_resistance": 0.5, "name": "바다의 가호"},
			100: {"water_efficiency": 0.3, "name": "물의 축복"},
			150: {"flood_prevention": 1.0, "name": "파도의 통제"},
			200: {"rain_summon": 1.0, "name": "폭풍의 지배자"}
		}
	},
	ExtendedGod.APOLLO: {
		"id": "apollo",
		"name": "아폴로",
		"title": "태양의 신",
		"description": "빛과 예술의 신. 성장을 촉진합니다.",
		"color": Color(1.0, 0.85, 0.3),
		"unlock_condition": "50_perfect_harvests",
		"max_favor": 200,
		"synergy_bonuses": {
			50: {"day_bonus": 0.2, "name": "태양의 축복"},
			100: {"xp_bonus": 0.25, "name": "빛의 계시"},
			150: {"quality_bonus": 0.3, "name": "예술의 손길"},
			200: {"instant_growth": 0.1, "name": "태양의 기적"}
		}
	},
	ExtendedGod.HADES: {
		"id": "hades",
		"name": "하데스",
		"title": "지하세계의 신",
		"description": "죽음과 부활을 관장합니다. 위험하지만 강력합니다.",
		"color": Color(0.4, 0.2, 0.5),
		"unlock_condition": "hard_mode_complete",
		"max_favor": 200,
		"synergy_bonuses": {
			50: {"death_prevention": 0.3, "name": "죽음의 회피"},
			100: {"revival": 0.2, "name": "부활의 힘"},
			150: {"risk_reward": 0.5, "name": "지하의 보물"},
			200: {"underworld_harvest": 1.0, "name": "죽음의 수확"}
		}
	},
	ExtendedGod.GAIA: {
		"id": "gaia",
		"name": "가이아",
		"title": "대지 어머니",
		"description": "모든 신의 어머니. 궁극의 축복을 내립니다.",
		"color": Color(0.3, 0.8, 0.5),
		"unlock_condition": "true_ending",
		"max_favor": 300,
		"synergy_bonuses": {
			75: {"all_god_favor": 0.2, "name": "신들의 화합"},
			150: {"nature_harmony": 0.5, "name": "자연의 조화"},
			225: {"eternal_growth": 1.0, "name": "영원한 성장"},
			300: {"world_tree": 1.0, "name": "세계수의 축복"}
		}
	}
}

# =============================================================================
# 추가 증강체 (신별 6종)
# =============================================================================

const EXTENDED_AUGMENTS := {
	# 데메테르 증강체
	"demeter_blessing": {
		"id": "demeter_blessing",
		"name": "데메테르의 축복",
		"god": "demeter",
		"rarity": 1,
		"effects": [{"type": "yield_bonus", "value": 0.1}]
	},
	"fertile_soil": {
		"id": "fertile_soil",
		"name": "비옥한 토양",
		"god": "demeter",
		"rarity": 2,
		"effects": [{"type": "growth_speed", "value": 0.15}]
	},
	"earth_mother_grace": {
		"id": "earth_mother_grace",
		"name": "어머니의 은총",
		"god": "demeter",
		"rarity": 3,
		"effects": [{"type": "all_crop_bonus", "value": 0.2}]
	},
	"gaia_touch": {
		"id": "gaia_touch",
		"name": "대지의 손길",
		"god": "demeter",
		"rarity": 4,
		"effects": [{"type": "instant_grow_chance", "value": 0.1}]
	},

	# 포세이돈 증강체
	"poseidon_blessing": {
		"id": "poseidon_blessing",
		"name": "포세이돈의 축복",
		"god": "poseidon",
		"rarity": 1,
		"effects": [{"type": "water_efficiency", "value": 0.2}]
	},
	"ocean_mist": {
		"id": "ocean_mist",
		"name": "바다 안개",
		"god": "poseidon",
		"rarity": 2,
		"effects": [{"type": "drought_resistance", "value": 0.3}]
	},
	"tidal_wave": {
		"id": "tidal_wave",
		"name": "조류의 힘",
		"god": "poseidon",
		"rarity": 3,
		"effects": [{"type": "flood_bonus", "value": 0.5}]
	},
	"trident_power": {
		"id": "trident_power",
		"name": "삼지창의 힘",
		"god": "poseidon",
		"rarity": 4,
		"effects": [{"type": "all_water_control", "value": 1.0}]
	},

	# 아폴로 증강체
	"apollo_blessing": {
		"id": "apollo_blessing",
		"name": "아폴로의 축복",
		"god": "apollo",
		"rarity": 1,
		"effects": [{"type": "day_growth", "value": 0.15}]
	},
	"sunlight_focus": {
		"id": "sunlight_focus",
		"name": "햇빛 집중",
		"god": "apollo",
		"rarity": 2,
		"effects": [{"type": "light_bonus", "value": 0.2}]
	},
	"muse_inspiration": {
		"id": "muse_inspiration",
		"name": "뮤즈의 영감",
		"god": "apollo",
		"rarity": 3,
		"effects": [{"type": "xp_bonus", "value": 0.3}]
	},
	"solar_flare": {
		"id": "solar_flare",
		"name": "태양 폭발",
		"god": "apollo",
		"rarity": 4,
		"effects": [{"type": "instant_mature", "value": 0.15}]
	},

	# 하데스 증강체
	"hades_blessing": {
		"id": "hades_blessing",
		"name": "하데스의 축복",
		"god": "hades",
		"rarity": 1,
		"effects": [{"type": "death_resist", "value": 0.2}]
	},
	"underworld_soil": {
		"id": "underworld_soil",
		"name": "지하의 토양",
		"god": "hades",
		"rarity": 2,
		"effects": [{"type": "dark_growth", "value": 0.25}]
	},
	"soul_harvest": {
		"id": "soul_harvest",
		"name": "영혼 수확",
		"god": "hades",
		"rarity": 3,
		"effects": [{"type": "death_yield", "value": 0.5}]
	},
	"cerberus_guard": {
		"id": "cerberus_guard",
		"name": "케르베로스의 수호",
		"god": "hades",
		"rarity": 4,
		"effects": [{"type": "threat_immune", "value": 0.3}]
	},

	# 가이아 증강체 (전설)
	"gaia_blessing": {
		"id": "gaia_blessing",
		"name": "가이아의 축복",
		"god": "gaia",
		"rarity": 4,
		"effects": [{"type": "all_stats", "value": 0.1}]
	},
	"primordial_power": {
		"id": "primordial_power",
		"name": "원초의 힘",
		"god": "gaia",
		"rarity": 5,
		"effects": [{"type": "universal_bonus", "value": 0.2}]
	}
}

# =============================================================================
# 헬퍼 함수
# =============================================================================

static func get_god_data(god: ExtendedGod) -> Dictionary:
	return EXTENDED_GOD_DATA.get(god, {})


static func get_god_by_id(god_id: String) -> int:
	for god in EXTENDED_GOD_DATA:
		if EXTENDED_GOD_DATA[god].id == god_id:
			return god
	return -1


static func get_augment_data(augment_id: String) -> Dictionary:
	return EXTENDED_AUGMENTS.get(augment_id, {})


static func get_augments_by_god(god_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for augment_id in EXTENDED_AUGMENTS:
		if EXTENDED_AUGMENTS[augment_id].god == god_id:
			result.append(EXTENDED_AUGMENTS[augment_id])
	return result
