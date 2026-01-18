extends Resource
class_name Crop
## Crop - 작물 데이터 클래스
##
## 작물의 속성을 정의하는 리소스 클래스입니다.

# =============================================================================
# 작물 속성
# =============================================================================

## 작물 고유 ID
@export var id: String = ""

## 작물 이름 (표시용)
@export var crop_type: String = ""

## 작물 설명
@export var description: String = ""

## 성장 시간 (초)
@export var grow_time: float = 10.0

## 기본 수확량
@export var base_yield: int = 1

## 개당 판매 가격
@export var base_value: int = 10

## 씨앗 비용
@export var seed_cost: int = 1

## 레어리티 (0: Common, 1: Uncommon, 2: Rare, 3: Epic, 4: Legendary)
@export_range(0, 4) var rarity: int = 0

## 해금 조건 (레벨)
@export var unlock_level: int = 1

## 스프라이트 경로
@export var sprite_path: String = ""

# =============================================================================
# 생성자
# =============================================================================

func _init(
	p_id: String = "",
	p_type: String = "",
	p_grow_time: float = 10.0,
	p_yield: int = 1,
	p_value: int = 10
) -> void:
	id = p_id
	crop_type = p_type
	grow_time = p_grow_time
	base_yield = p_yield
	base_value = p_value

# =============================================================================
# 헬퍼 메서드
# =============================================================================

## 총 수익 계산 (수확량 * 가치)
func get_total_value() -> int:
	return base_yield * base_value


## 시간당 수익률 계산
func get_value_per_second() -> float:
	if grow_time <= 0:
		return 0.0
	return float(get_total_value()) / grow_time


## 레어리티 이름 반환
func get_rarity_name() -> String:
	match rarity:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		3: return "Epic"
		4: return "Legendary"
		_: return "Unknown"


## 레어리티 색상 반환
func get_rarity_color() -> Color:
	match rarity:
		0: return Color(0.7, 0.7, 0.7)      # Gray
		1: return Color(0.2, 0.8, 0.2)      # Green
		2: return Color(0.2, 0.4, 0.9)      # Blue
		3: return Color(0.7, 0.3, 0.9)      # Purple
		4: return Color(1.0, 0.8, 0.2)      # Gold
		_: return Color.WHITE


## 딕셔너리로 변환
func to_dict() -> Dictionary:
	return {
		"id": id,
		"crop_type": crop_type,
		"description": description,
		"grow_time": grow_time,
		"base_yield": base_yield,
		"base_value": base_value,
		"seed_cost": seed_cost,
		"rarity": rarity,
		"unlock_level": unlock_level
	}


## 딕셔너리에서 생성
static func from_dict(data: Dictionary):
	var script = load("res://scripts/farm/crop.gd")
	var crop = script.new()
	crop.id = data.get("id", "")
	crop.crop_type = data.get("crop_type", "")
	crop.description = data.get("description", "")
	crop.grow_time = data.get("grow_time", 10.0)
	crop.base_yield = data.get("base_yield", 1)
	crop.base_value = data.get("base_value", 10)
	crop.seed_cost = data.get("seed_cost", 1)
	crop.rarity = data.get("rarity", 0)
	crop.unlock_level = data.get("unlock_level", 1)
	return crop
