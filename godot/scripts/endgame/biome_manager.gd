extends Node
class_name BiomeManagerClass
## BiomeManager - 바이옴 시스템
##
## 다양한 농장 바이옴과 특수 작물/위협을 관리합니다.

# =============================================================================
# 바이옴 정의
# =============================================================================

enum BiomeType {
	PLAINS,     # 평원 (기본)
	DESERT,     # 사막
	SNOW,       # 눈 덮인 땅
	VOLCANO,    # 화산
	SWAMP,      # 늪지대
	CRYSTAL     # 수정 동굴 (엔드게임)
}

const BIOME_DATA := {
	BiomeType.PLAINS: {
		"id": "plains",
		"name": "평원",
		"description": "기본 농장 환경입니다.",
		"unlock_cost": 0,
		"unlock_condition": "none",
		"modifiers": {
			"growth_speed": 1.0,
			"yield_bonus": 0.0,
			"threat_frequency": 1.0
		},
		"special_crops": [],
		"special_threats": [],
		"best_seasons": [0, 1, 2, 3]  # 모든 시즌
	},
	BiomeType.DESERT: {
		"id": "desert",
		"name": "사막",
		"description": "뜨겁고 건조한 사막. 선인장과 특수 작물이 잘 자랍니다.",
		"unlock_cost": 5000,
		"unlock_condition": "10_runs_complete",
		"modifiers": {
			"growth_speed": 0.8,
			"yield_bonus": 0.2,
			"threat_frequency": 0.7,
			"water_requirement": 2.0
		},
		"special_crops": ["cactus", "date_palm", "aloe"],
		"special_threats": ["sandstorm", "scorpion"],
		"best_seasons": [1]  # 여름
	},
	BiomeType.SNOW: {
		"id": "snow",
		"name": "눈 덮인 땅",
		"description": "추운 설원. 겨울 작물에 보너스가 있습니다.",
		"unlock_cost": 5000,
		"unlock_condition": "10_runs_complete",
		"modifiers": {
			"growth_speed": 0.7,
			"yield_bonus": 0.0,
			"threat_frequency": 0.5,
			"cold_resistance": 1.0
		},
		"special_crops": ["ice_berry", "snow_flower", "frost_wheat"],
		"special_threats": ["blizzard", "ice_elemental"],
		"best_seasons": [3]  # 겨울
	},
	BiomeType.VOLCANO: {
		"id": "volcano",
		"name": "화산",
		"description": "위험하지만 보상이 큰 화산 지대.",
		"unlock_cost": 10000,
		"unlock_condition": "all_gods_favor_50",
		"modifiers": {
			"growth_speed": 1.2,
			"yield_bonus": 0.5,
			"threat_frequency": 2.0,
			"fire_resistance": -0.5
		},
		"special_crops": ["fire_fruit", "obsidian_flower", "magma_bean"],
		"special_threats": ["eruption", "lava_slug"],
		"best_seasons": [1, 2]  # 여름, 가을
	},
	BiomeType.SWAMP: {
		"id": "swamp",
		"name": "늪지대",
		"description": "습한 늪지. 특이한 작물이 자랍니다.",
		"unlock_cost": 7500,
		"unlock_condition": "20_runs_complete",
		"modifiers": {
			"growth_speed": 1.1,
			"yield_bonus": 0.3,
			"threat_frequency": 1.5,
			"disease_resistance": -0.3
		},
		"special_crops": ["swamp_lily", "bog_mushroom", "marsh_reed"],
		"special_threats": ["plague", "swamp_creature"],
		"best_seasons": [0, 2]  # 봄, 가을
	},
	BiomeType.CRYSTAL: {
		"id": "crystal",
		"name": "수정 동굴",
		"description": "신비로운 수정 동굴. 전설 작물만 자랍니다.",
		"unlock_cost": 50000,
		"unlock_condition": "true_ending",
		"modifiers": {
			"growth_speed": 0.5,
			"yield_bonus": 2.0,
			"threat_frequency": 0.3,
			"legendary_chance": 0.5
		},
		"special_crops": ["crystal_bloom", "prismatic_fruit", "world_tree_seed"],
		"special_threats": ["crystal_golem"],
		"best_seasons": [0, 1, 2, 3]
	}
}

# =============================================================================
# 특수 작물 정의
# =============================================================================

const SPECIAL_CROPS := {
	# 사막
	"cactus": {
		"name": "선인장",
		"rarity": 2,
		"growth_time": 45.0,
		"base_value": 150,
		"biome": "desert"
	},
	"date_palm": {
		"name": "대추야자",
		"rarity": 3,
		"growth_time": 90.0,
		"base_value": 400,
		"biome": "desert"
	},
	"aloe": {
		"name": "알로에",
		"rarity": 2,
		"growth_time": 60.0,
		"base_value": 200,
		"biome": "desert"
	},
	# 눈
	"ice_berry": {
		"name": "얼음 열매",
		"rarity": 2,
		"growth_time": 50.0,
		"base_value": 180,
		"biome": "snow"
	},
	"snow_flower": {
		"name": "눈꽃",
		"rarity": 3,
		"growth_time": 80.0,
		"base_value": 350,
		"biome": "snow"
	},
	"frost_wheat": {
		"name": "서리 밀",
		"rarity": 1,
		"growth_time": 30.0,
		"base_value": 80,
		"biome": "snow"
	},
	# 화산
	"fire_fruit": {
		"name": "불꽃 열매",
		"rarity": 3,
		"growth_time": 60.0,
		"base_value": 500,
		"biome": "volcano"
	},
	"obsidian_flower": {
		"name": "흑요석 꽃",
		"rarity": 4,
		"growth_time": 120.0,
		"base_value": 1000,
		"biome": "volcano"
	},
	"magma_bean": {
		"name": "용암콩",
		"rarity": 2,
		"growth_time": 40.0,
		"base_value": 200,
		"biome": "volcano"
	},
	# 늪
	"swamp_lily": {
		"name": "늪 백합",
		"rarity": 2,
		"growth_time": 55.0,
		"base_value": 180,
		"biome": "swamp"
	},
	"bog_mushroom": {
		"name": "늪지 버섯",
		"rarity": 3,
		"growth_time": 70.0,
		"base_value": 300,
		"biome": "swamp"
	},
	"marsh_reed": {
		"name": "늪 갈대",
		"rarity": 1,
		"growth_time": 25.0,
		"base_value": 60,
		"biome": "swamp"
	},
	# 수정 동굴
	"crystal_bloom": {
		"name": "수정 꽃",
		"rarity": 4,
		"growth_time": 180.0,
		"base_value": 2000,
		"biome": "crystal"
	},
	"prismatic_fruit": {
		"name": "프리즘 열매",
		"rarity": 4,
		"growth_time": 240.0,
		"base_value": 3000,
		"biome": "crystal"
	},
	"world_tree_seed": {
		"name": "세계수 묘목",
		"rarity": 5,
		"growth_time": 600.0,
		"base_value": 10000,
		"biome": "crystal"
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal biome_unlocked(biome_type: BiomeType)
signal biome_changed(old_biome: BiomeType, new_biome: BiomeType)
signal special_crop_unlocked(crop_id: String)

# =============================================================================
# 변수
# =============================================================================

## 현재 활성 바이옴
var current_biome: BiomeType = BiomeType.PLAINS

## 해금된 바이옴
var unlocked_biomes: Array[BiomeType] = [BiomeType.PLAINS]

## 해금된 특수 작물
var unlocked_special_crops: Array[String] = []

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[BiomeManager] Initialized")
	_load_data()


func _load_data() -> void:
	# MetaProgressData는 Dictionary가 아니므로 기본값으로 시작
	current_biome = BiomeType.PLAINS
	unlocked_biomes.clear()
	unlocked_biomes.append(BiomeType.PLAINS)
	unlocked_special_crops.clear()


func _save_data() -> void:
	# 바이옴 데이터는 별도 저장 시스템 필요 (나중에 구현)
	pass

# =============================================================================
# 바이옴 관리
# =============================================================================

## 바이옴 해금
func unlock_biome(biome_type: BiomeType) -> bool:
	if unlocked_biomes.has(biome_type):
		return false

	var biome_data: Dictionary = BIOME_DATA[biome_type]

	# 비용 확인
	if not GameManager.spend_currency("gold", biome_data.unlock_cost):
		print("[BiomeManager] Not enough gold for %s" % biome_data.id)
		return false

	unlocked_biomes.append(biome_type)

	# 특수 작물 해금
	for crop_id in biome_data.special_crops:
		if not unlocked_special_crops.has(crop_id):
			unlocked_special_crops.append(crop_id)
			special_crop_unlocked.emit(crop_id)

	biome_unlocked.emit(biome_type)
	_save_data()

	EventBus.notification_shown.emit("🌍 새 바이옴 해금: %s" % biome_data.name, "success")
	print("[BiomeManager] Biome unlocked: %s" % biome_data.id)
	return true


## 바이옴 변경
func change_biome(biome_type: BiomeType) -> bool:
	if not unlocked_biomes.has(biome_type):
		return false

	if current_biome == biome_type:
		return false

	var old_biome := current_biome
	current_biome = biome_type

	biome_changed.emit(old_biome, biome_type)
	_save_data()

	var biome_data: Dictionary = BIOME_DATA[biome_type]
	EventBus.notification_shown.emit("🌍 바이옴 변경: %s" % biome_data.name, "info")
	print("[BiomeManager] Biome changed to: %s" % biome_data.id)
	return true


## 바이옴 해금 여부
func is_biome_unlocked(biome_type: BiomeType) -> bool:
	return unlocked_biomes.has(biome_type)

# =============================================================================
# 바이옴 효과
# =============================================================================

## 현재 바이옴의 성장 속도 배율
func get_growth_speed_modifier() -> float:
	return BIOME_DATA[current_biome].modifiers.growth_speed


## 현재 바이옴의 수확량 보너스
func get_yield_bonus() -> float:
	return BIOME_DATA[current_biome].modifiers.yield_bonus


## 현재 바이옴의 위협 빈도 배율
func get_threat_frequency() -> float:
	return BIOME_DATA[current_biome].modifiers.threat_frequency


## 현재 바이옴이 현재 시즌에 적합한지
func is_optimal_season(season: int) -> bool:
	return BIOME_DATA[current_biome].best_seasons.has(season)


## 시즌 보너스 (적합한 시즌이면 추가 보너스)
func get_season_bonus() -> float:
	var current_season: int = GameManager.game_data.run.current_season
	if is_optimal_season(current_season):
		return 0.2  # 20% 추가 보너스
	return 0.0

# =============================================================================
# 특수 작물
# =============================================================================

## 특수 작물 해금 여부
func is_special_crop_unlocked(crop_id: String) -> bool:
	return unlocked_special_crops.has(crop_id)


## 특수 작물 정보
func get_special_crop_data(crop_id: String) -> Dictionary:
	return SPECIAL_CROPS.get(crop_id, {})


## 현재 바이옴의 특수 작물 목록
func get_available_special_crops() -> Array[String]:
	var result: Array[String] = []
	var biome_crops: Array = BIOME_DATA[current_biome].special_crops

	for crop_id in biome_crops:
		if unlocked_special_crops.has(crop_id):
			result.append(crop_id)

	return result

# =============================================================================
# 유틸리티
# =============================================================================

## 바이옴 정보 가져오기
func get_biome_data(biome_type: BiomeType) -> Dictionary:
	return BIOME_DATA.get(biome_type, {})


## 현재 바이옴 정보
func get_current_biome_data() -> Dictionary:
	return BIOME_DATA[current_biome]


## 모든 바이옴 정보
func get_all_biomes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for biome_type in BIOME_DATA:
		var data: Dictionary = BIOME_DATA[biome_type].duplicate()
		data["biome_type"] = biome_type
		data["unlocked"] = unlocked_biomes.has(biome_type)
		data["current"] = current_biome == biome_type
		result.append(data)

	return result


func _get_biome_type_by_id(biome_id: String) -> int:
	for biome_type in BIOME_DATA:
		if BIOME_DATA[biome_type].id == biome_id:
			return biome_type
	return -1
