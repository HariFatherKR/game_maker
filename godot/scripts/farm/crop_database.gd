extends Node
class_name CropDatabaseClass
## CropDatabase - 작물 데이터베이스
##
## 모든 작물 데이터를 관리하는 싱글톤 패턴 클래스입니다.

# =============================================================================
# 클래스 프리로드
# =============================================================================

const CropScript := preload("res://scripts/farm/crop.gd")

# =============================================================================
# 작물 데이터
# =============================================================================

## 작물 저장소
var _crops: Dictionary = {}

## 데이터 로드 여부
var _loaded: bool = false

# =============================================================================
# 초기화
# =============================================================================

func _init() -> void:
	_load_default_crops()


## 기본 작물 데이터 로드
func _load_default_crops() -> void:
	if _loaded:
		return

	# 기본 작물들 정의
	var crops_data := [
		# Common 작물 (Tier 1)
		{
			"id": "wheat",
			"crop_type": "Wheat",
			"description": "Basic grain crop. Quick to grow.",
			"grow_time": 10.0,
			"base_yield": 2,
			"base_value": 5,
			"seed_cost": 1,
			"rarity": 0,
			"unlock_level": 1
		},
		{
			"id": "carrot",
			"crop_type": "Carrot",
			"description": "Crunchy orange vegetable.",
			"grow_time": 15.0,
			"base_yield": 3,
			"base_value": 8,
			"seed_cost": 1,
			"rarity": 0,
			"unlock_level": 1
		},
		{
			"id": "potato",
			"crop_type": "Potato",
			"description": "Versatile root vegetable.",
			"grow_time": 20.0,
			"base_yield": 4,
			"base_value": 10,
			"seed_cost": 2,
			"rarity": 0,
			"unlock_level": 2
		},

		# Uncommon 작물 (Tier 2)
		{
			"id": "tomato",
			"crop_type": "Tomato",
			"description": "Juicy red fruit. Wait, is it a vegetable?",
			"grow_time": 30.0,
			"base_yield": 5,
			"base_value": 15,
			"seed_cost": 3,
			"rarity": 1,
			"unlock_level": 3
		},
		{
			"id": "corn",
			"crop_type": "Corn",
			"description": "Tall stalks with golden kernels.",
			"grow_time": 40.0,
			"base_yield": 6,
			"base_value": 20,
			"seed_cost": 4,
			"rarity": 1,
			"unlock_level": 4
		},
		{
			"id": "pumpkin",
			"crop_type": "Pumpkin",
			"description": "Large orange gourd. Great for pies!",
			"grow_time": 60.0,
			"base_yield": 2,
			"base_value": 50,
			"seed_cost": 5,
			"rarity": 1,
			"unlock_level": 5
		},

		# Rare 작물 (Tier 3)
		{
			"id": "strawberry",
			"crop_type": "Strawberry",
			"description": "Sweet red berries. Everyone's favorite!",
			"grow_time": 45.0,
			"base_yield": 8,
			"base_value": 25,
			"seed_cost": 6,
			"rarity": 2,
			"unlock_level": 7
		},
		{
			"id": "melon",
			"crop_type": "Melon",
			"description": "Refreshing summer fruit.",
			"grow_time": 90.0,
			"base_yield": 3,
			"base_value": 80,
			"seed_cost": 8,
			"rarity": 2,
			"unlock_level": 10
		},

		# Epic 작물 (Tier 4)
		{
			"id": "golden_wheat",
			"crop_type": "Golden Wheat",
			"description": "Mystical wheat that glows with golden light.",
			"grow_time": 120.0,
			"base_yield": 10,
			"base_value": 100,
			"seed_cost": 15,
			"rarity": 3,
			"unlock_level": 15
		},
		{
			"id": "crystal_grape",
			"crop_type": "Crystal Grape",
			"description": "Transparent grapes filled with starlight.",
			"grow_time": 180.0,
			"base_yield": 5,
			"base_value": 200,
			"seed_cost": 20,
			"rarity": 3,
			"unlock_level": 20
		},

		# Legendary 작물 (Tier 5)
		{
			"id": "rainbow_rose",
			"crop_type": "Rainbow Rose",
			"description": "A legendary flower said to bloom once in a century.",
			"grow_time": 300.0,
			"base_yield": 1,
			"base_value": 1000,
			"seed_cost": 50,
			"rarity": 4,
			"unlock_level": 30
		},
		{
			"id": "void_fruit",
			"crop_type": "Void Fruit",
			"description": "A fruit from another dimension. Handle with care.",
			"grow_time": 600.0,
			"base_yield": 1,
			"base_value": 5000,
			"seed_cost": 100,
			"rarity": 4,
			"unlock_level": 50
		}
	]

	for data in crops_data:
		var crop = CropScript.from_dict(data)
		_crops[crop.id] = crop

	_loaded = true
	print("[CropDatabase] Loaded %d crops" % _crops.size())

# =============================================================================
# 공개 API
# =============================================================================

## ID로 작물 가져오기
func get_crop(crop_id: String):
	if _crops.has(crop_id):
		return _crops[crop_id]

	push_warning("[CropDatabase] Crop not found: %s" % crop_id)
	return null


## 모든 작물 가져오기
func get_all_crops() -> Array:
	var result: Array = []
	for crop in _crops.values():
		result.append(crop)
	return result


## 레어리티별 작물 가져오기
func get_crops_by_rarity(rarity: int) -> Array:
	var result: Array = []
	for crop in _crops.values():
		if crop.rarity == rarity:
			result.append(crop)
	return result


## 해금된 작물 가져오기 (레벨 기준)
func get_unlocked_crops(player_level: int) -> Array:
	var result: Array = []
	for crop in _crops.values():
		if crop.unlock_level <= player_level:
			result.append(crop)
	return result


## 작물 존재 여부 확인
func has_crop(crop_id: String) -> bool:
	return _crops.has(crop_id)


## 작물 개수
func get_crop_count() -> int:
	return _crops.size()


# =============================================================================
# 글로벌 인스턴스
# =============================================================================

## 싱글톤 인스턴스 (스크립트 로드 시 자동 생성)
static var _instance = null

static func get_instance():
	if _instance == null:
		var script = load("res://scripts/farm/crop_database.gd")
		_instance = script.new()
	return _instance


# =============================================================================
# 정적 헬퍼 (편의 메서드)
# =============================================================================

## 정적 메서드로 작물 가져오기
static func get_crop_static(crop_id: String):
	return get_instance().get_crop(crop_id)
