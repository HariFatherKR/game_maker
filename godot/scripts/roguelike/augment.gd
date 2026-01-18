extends Resource
class_name Augment
## Augment - 증강체 데이터 클래스
##
## 로그라이트 증강체의 속성을 정의합니다.

# =============================================================================
# 열거형
# =============================================================================

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum Category {
	GROWTH,       # 성장 속도 관련
	YIELD,        # 수확량 관련
	ECONOMY,      # 경제/골드 관련
	AUTOMATION,   # 자동화 관련
	SPECIAL       # 특수 효과
}

enum EffectType {
	ADDITIVE,     # 고정값 추가
	MULTIPLICATIVE, # 배율 적용
	SPECIAL       # 특수 효과 (코드로 처리)
}

# =============================================================================
# 속성
# =============================================================================

## 증강체 고유 ID
@export var id: String = ""

## 증강체 이름
@export var name: String = ""

## 설명
@export var description: String = ""

## 레어리티
@export var rarity: Rarity = Rarity.COMMON

## 카테고리
@export var category: Category = Category.GROWTH

## 효과 타입
@export var effect_type: EffectType = EffectType.ADDITIVE

## 효과 대상 스탯
@export var target_stat: String = ""

## 효과 값
@export var effect_value: float = 0.0

## 최대 스택
@export var max_stacks: int = 1

## 현재 스택 수
var current_stacks: int = 1

## 시너지 태그 (같은 태그끼리 시너지)
@export var synergy_tags: Array = []

## 상호 배타적 증강체 ID 목록
@export var exclusive_with: Array = []

## 스프라이트 경로
@export var sprite_path: String = ""

## 해금 조건 (메타 레벨)
@export var unlock_meta_level: int = 0

# =============================================================================
# 헬퍼 메서드
# =============================================================================

## 현재 총 효과값 (스택 적용)
func get_total_effect() -> float:
	return effect_value * current_stacks


## 스택 추가 가능 여부
func can_stack() -> bool:
	return current_stacks < max_stacks


## 스택 추가
func add_stack() -> bool:
	if not can_stack():
		return false
	current_stacks += 1
	return true


## 레어리티 이름
func get_rarity_name() -> String:
	return Rarity.keys()[rarity]


## 레어리티 색상
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.7, 0.7, 0.7)
		Rarity.UNCOMMON: return Color(0.2, 0.8, 0.2)
		Rarity.RARE: return Color(0.2, 0.4, 0.9)
		Rarity.EPIC: return Color(0.7, 0.3, 0.9)
		Rarity.LEGENDARY: return Color(1.0, 0.8, 0.2)
		_: return Color.WHITE


## 카테고리 이름
func get_category_name() -> String:
	return Category.keys()[category]


## 레어리티별 가중치 (드롭 확률용)
func get_rarity_weight() -> float:
	match rarity:
		Rarity.COMMON: return 50.0
		Rarity.UNCOMMON: return 30.0
		Rarity.RARE: return 15.0
		Rarity.EPIC: return 4.0
		Rarity.LEGENDARY: return 1.0
		_: return 0.0


## 딕셔너리로 변환
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"category": category,
		"effect_type": effect_type,
		"target_stat": target_stat,
		"effect_value": effect_value,
		"max_stacks": max_stacks,
		"current_stacks": current_stacks,
		"synergy_tags": synergy_tags,
		"exclusive_with": exclusive_with
	}


## 딕셔너리에서 생성
static func from_dict(data: Dictionary):
	var script = load("res://scripts/roguelike/augment.gd")
	var aug = script.new()
	aug.id = data.get("id", "")
	aug.name = data.get("name", "")
	aug.description = data.get("description", "")
	aug.rarity = data.get("rarity", Rarity.COMMON)
	aug.category = data.get("category", Category.GROWTH)
	aug.effect_type = data.get("effect_type", EffectType.ADDITIVE)
	aug.target_stat = data.get("target_stat", "")
	aug.effect_value = data.get("effect_value", 0.0)
	aug.max_stacks = data.get("max_stacks", 1)
	aug.current_stacks = data.get("current_stacks", 1)
	aug.synergy_tags = data.get("synergy_tags", [])
	aug.exclusive_with = data.get("exclusive_with", [])
	return aug


## 복제
func duplicate_augment():
	return from_dict(to_dict())
