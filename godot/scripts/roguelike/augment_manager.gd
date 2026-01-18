extends Node
class_name AugmentManagerClass
## AugmentManager - 증강체 시스템 관리자
##
## 증강체 선택, 적용, 시너지 계산을 관리합니다.

# =============================================================================
# 상수
# =============================================================================

const AUGMENT_CHOICES: int = 3  # 선택지 개수
const REROLL_BASE_COST: int = 10  # 리롤 기본 비용 (젬)
const REROLL_COST_INCREASE: float = 1.5  # 리롤마다 비용 증가

# =============================================================================
# 신(God) 정의
# =============================================================================

enum GodType {
	CERES,      # 농업/자연 - 성장
	PLUTUS,     # 부/경제 - 골드
	CHRONOS,    # 시간 - 오프라인/자동화
	TYCHE,      # 행운 - 크리티컬/럭키
	HEPHAESTUS, # 도구/제작 - 장비
}

const GOD_NAMES := {
	GodType.CERES: "세레스",
	GodType.PLUTUS: "플루투스",
	GodType.CHRONOS: "크로노스",
	GodType.TYCHE: "티케",
	GodType.HEPHAESTUS: "헤파이스토스",
}

# =============================================================================
# 시너지 정의
# =============================================================================

const SYNERGIES := {
	"ceres_minor": {
		"god": GodType.CERES,
		"required_count": 3,
		"bonus_stat": "growth_speed_mult",
		"bonus_value": 0.15,
		"description": "세레스 3개: 성장 속도 +15%"
	},
	"ceres_major": {
		"god": GodType.CERES,
		"required_count": 5,
		"bonus_stat": "growth_speed_mult",
		"bonus_value": 0.30,
		"description": "세레스 5개: 성장 속도 +30%"
	},
	"plutus_minor": {
		"god": GodType.PLUTUS,
		"required_count": 3,
		"bonus_stat": "gold_mult",
		"bonus_value": 0.15,
		"description": "플루투스 3개: 골드 +15%"
	},
	"plutus_major": {
		"god": GodType.PLUTUS,
		"required_count": 5,
		"bonus_stat": "gold_mult",
		"bonus_value": 0.30,
		"description": "플루투스 5개: 골드 +30%"
	},
	"chronos_minor": {
		"god": GodType.CHRONOS,
		"required_count": 3,
		"bonus_stat": "offline_mult",
		"bonus_value": 0.15,
		"description": "크로노스 3개: 오프라인 효율 +15%"
	},
	"chronos_major": {
		"god": GodType.CHRONOS,
		"required_count": 5,
		"bonus_stat": "offline_mult",
		"bonus_value": 0.30,
		"description": "크로노스 5개: 오프라인 효율 +30%"
	},
	"tyche_minor": {
		"god": GodType.TYCHE,
		"required_count": 3,
		"bonus_stat": "double_harvest_chance",
		"bonus_value": 0.10,
		"description": "티케 3개: 더블 수확 +10%"
	},
	"tyche_major": {
		"god": GodType.TYCHE,
		"required_count": 5,
		"bonus_stat": "double_harvest_chance",
		"bonus_value": 0.20,
		"description": "티케 5개: 더블 수확 +20%"
	},
	"hephaestus_minor": {
		"god": GodType.HEPHAESTUS,
		"required_count": 3,
		"bonus_stat": "auto_speed_mult",
		"bonus_value": 0.15,
		"description": "헤파이스토스 3개: 자동화 속도 +15%"
	},
	"hephaestus_major": {
		"god": GodType.HEPHAESTUS,
		"required_count": 5,
		"bonus_stat": "auto_speed_mult",
		"bonus_value": 0.30,
		"description": "헤파이스토스 5개: 자동화 속도 +30%"
	},
}

# =============================================================================
# 변수
# =============================================================================

## 현재 적용된 증강체 효과 스탯
var _active_stats: Dictionary = {}

## 활성화된 시너지
var _active_synergies: Array[String] = []

## 해금된 증강체 ID 목록
var unlocked_augment_ids: Array[String] = []

## 현재 리롤 횟수 (비용 계산용)
var reroll_count: int = 0

## 현재 제시된 선택지
var current_choices: Array[String] = []

# =============================================================================
# 초기화
# =============================================================================

func _ready() -> void:
	print("[AugmentManager] Initialized")
	_load_unlocked_augments()


func _load_unlocked_augments() -> void:
	# 기본 해금 증강체 (Common 전부)
	var db := AugmentDatabaseClass.get_instance()
	for aug in db.get_augments_by_rarity(Augment.Rarity.COMMON):
		if not unlocked_augment_ids.has(aug.id):
			unlocked_augment_ids.append(aug.id)

	print("[AugmentManager] %d augments unlocked" % unlocked_augment_ids.size())

# =============================================================================
# 런 관리
# =============================================================================

## 런 시작 시 초기화
func start_run() -> void:
	_active_stats.clear()
	_active_synergies.clear()
	reroll_count = 0
	current_choices.clear()
	print("[AugmentManager] Run started, augments reset")


## 런 종료 시 정리
func end_run() -> void:
	var active_count := GameManager.game_data.run.active_augments.size()
	print("[AugmentManager] Run ended with %d augments" % active_count)
	_active_stats.clear()
	_active_synergies.clear()

# =============================================================================
# 증강체 선택 시스템
# =============================================================================

## 새 증강체 선택지 생성 (ID 배열 반환)
func generate_choices(count: int = AUGMENT_CHOICES) -> Array[String]:
	current_choices.clear()
	var available := _get_available_pool()

	if available.is_empty():
		push_warning("[AugmentManager] No available augments!")
		return []

	for i in range(count):
		if available.is_empty():
			break

		var selected := _weighted_random_pick(available)
		if not selected.is_empty():
			current_choices.append(selected)
			available.erase(selected)

			# 상호 배타적 증강체 제거
			var augment := AugmentDatabaseClass.get_augment(selected)
			if augment and augment.exclusive_with.size() > 0:
				for exclusive_id in augment.exclusive_with:
					available.erase(exclusive_id)

	return current_choices


## 증강체 적용
func apply_augment(augment_id: String) -> bool:
	var augment := AugmentDatabaseClass.get_augment(augment_id)
	if augment == null:
		push_error("[AugmentManager] Unknown augment: %s" % augment_id)
		return false

	# 효과 적용 (기존 Augment 클래스 호환)
	_apply_augment_effects(augment)

	# 신 호감도 증가 (카테고리 기반)
	var god_name := _category_to_god(augment.category)
	GameManager.game_data.meta.add_god_affinity(god_name, 1)

	reroll_count = 0
	current_choices.clear()

	print("[AugmentManager] Applied augment: %s" % augment_id)
	return true


## 카테고리를 신으로 변환
func _category_to_god(category: Augment.Category) -> String:
	match category:
		Augment.Category.GROWTH: return "ceres"
		Augment.Category.ECONOMY: return "plutus"
		Augment.Category.AUTOMATION: return "chronos"
		Augment.Category.SPECIAL: return "tyche"
		Augment.Category.YIELD: return "hephaestus"
	return "ceres"


## Augment 효과 적용
func _apply_augment_effects(augment: Augment) -> void:
	var stat_name := augment.target_stat
	var value := augment.effect_value

	match augment.effect_type:
		Augment.EffectType.MULTIPLICATIVE:
			var current := _active_stats.get(stat_name, 1.0)
			_active_stats[stat_name] = current * (1.0 + value)
		Augment.EffectType.ADDITIVE:
			var current := _active_stats.get(stat_name, 0.0)
			_active_stats[stat_name] = current + value
		Augment.EffectType.SPECIAL:
			# 특수 효과는 1.0으로 활성화 표시
			_active_stats[stat_name] = value

	print("[AugmentManager] Effect applied: %s = %.2f" % [stat_name, _active_stats.get(stat_name, 0)])


## 선택지 리롤
func reroll_choices() -> Array[String]:
	var cost := get_reroll_cost()

	if not GameManager.spend_currency("gems", cost):
		print("[AugmentManager] Not enough gems for reroll!")
		return []

	reroll_count += 1
	print("[AugmentManager] Rerolled choices (cost: %d gems)" % cost)
	return generate_choices()


## 리롤 비용 계산
func get_reroll_cost() -> int:
	return int(REROLL_BASE_COST * pow(REROLL_COST_INCREASE, reroll_count))


## 모든 증강체 클리어 (런 종료 시)
func clear_all_augments() -> void:
	_active_stats.clear()
	_active_synergies.clear()
	print("[AugmentManager] Cleared all augments")

# =============================================================================
# 스탯 시스템
# =============================================================================

## 스탯 조회
func get_stat(stat_name: String, default: float = 0.0) -> float:
	return _active_stats.get(stat_name, default)


## 특수 효과 활성화 여부
func has_effect(effect_name: String) -> bool:
	return _active_stats.has(effect_name) and _active_stats[effect_name] > 0



# =============================================================================
# 시너지 시스템
# =============================================================================

## 시너지 체크
func check_synergies() -> void:
	if not GameManager.game_data.run.is_active:
		return

	var active_augments := GameManager.game_data.run.active_augments

	for synergy_id in SYNERGIES:
		if _active_synergies.has(synergy_id):
			continue

		var synergy: Dictionary = SYNERGIES[synergy_id]
		var god: GodType = synergy.god
		var required: int = synergy.required_count

		var count := _count_augments_by_god(active_augments, god)

		if count >= required:
			_activate_synergy(synergy_id, synergy)


func _count_augments_by_god(augments: Array, god: GodType) -> int:
	var count := 0
	for augment_id in augments:
		var augment := AugmentDatabaseClass.get_augment(augment_id)
		if augment == null:
			continue
		# 카테고리를 신으로 변환하여 비교
		var augment_god := _category_to_god_type(augment.category)
		if augment_god == god:
			count += 1
	return count


## 카테고리를 GodType으로 변환
func _category_to_god_type(category: Augment.Category) -> GodType:
	match category:
		Augment.Category.GROWTH: return GodType.CERES
		Augment.Category.ECONOMY: return GodType.PLUTUS
		Augment.Category.AUTOMATION: return GodType.CHRONOS
		Augment.Category.SPECIAL: return GodType.TYCHE
		Augment.Category.YIELD: return GodType.HEPHAESTUS
	return GodType.CERES


func _activate_synergy(synergy_id: String, synergy: Dictionary) -> void:
	_active_synergies.append(synergy_id)
	GameManager.game_data.run.run_synergies.append(synergy_id)

	# 시너지 효과 적용
	var stat_name: String = synergy.bonus_stat
	var bonus_value: float = synergy.bonus_value

	var current := _active_stats.get(stat_name, 1.0 if "mult" in stat_name else 0.0)
	if "mult" in stat_name:
		_active_stats[stat_name] = current + bonus_value
	else:
		_active_stats[stat_name] = current + bonus_value

	# 통계 업데이트
	GameManager.game_data.stats.synergies_activated += 1

	EventBus.synergy_activated.emit(synergy_id, bonus_value)
	EventBus.notification_shown.emit("✨ 시너지 활성화: %s" % synergy.description, "success")

	print("[AugmentManager] Synergy activated: %s (bonus: %.0f%%)" % [synergy_id, bonus_value * 100])


## 활성 시너지 목록
func get_active_synergies() -> Array[String]:
	return _active_synergies.duplicate()

# =============================================================================
# 증강체 풀 관리
# =============================================================================

## 사용 가능한 증강체 풀 (ID -> 가중치)
func _get_available_pool() -> Dictionary:
	var pool := {}
	var active_augments := GameManager.game_data.run.active_augments

	for aug_id in unlocked_augment_ids:
		var augment := AugmentDatabaseClass.get_augment(aug_id)
		if augment == null:
			continue

		# 최대 스택 체크
		var current_count := active_augments.count(aug_id)
		if current_count >= augment.max_stacks:
			continue

		# 선행 조건 체크
		if not _has_prerequisites(augment, active_augments):
			continue

		# 가중치 계산
		var weight := _get_rarity_weight(augment.rarity)

		# 신 호감도 보너스 (카테고리 기반)
		var god_name := _category_to_god(augment.category)
		var affinity := GameManager.game_data.meta.get_god_affinity(god_name)
		weight *= 1.0 + (affinity * 0.1)

		pool[aug_id] = weight

	return pool


func _has_prerequisites(augment: Augment, active_augments: Array) -> bool:
	# 기존 Augment 클래스는 prerequisites가 없으므로 항상 true
	return true


func _get_rarity_weight(rarity: int) -> float:
	match rarity:
		0: return 50.0   # Common
		1: return 30.0   # Uncommon
		2: return 15.0   # Rare
		3: return 4.0    # Epic
		4: return 1.0    # Legendary
	return 10.0


func _weighted_random_pick(pool: Dictionary) -> String:
	if pool.is_empty():
		return ""

	var total_weight := 0.0
	for weight in pool.values():
		total_weight += weight

	var roll := randf() * total_weight
	var current := 0.0

	for id in pool:
		current += pool[id]
		if roll <= current:
			return id

	# Fallback
	return pool.keys()[0] if not pool.is_empty() else ""

# =============================================================================
# 메타 진행도
# =============================================================================

## 새 증강체 해금
func unlock_augment(augment_id: String) -> bool:
	if unlocked_augment_ids.has(augment_id):
		return false

	var augment := AugmentDatabaseClass.get_augment(augment_id)
	if augment == null:
		push_error("[AugmentManager] Unknown augment: %s" % augment_id)
		return false

	unlocked_augment_ids.append(augment_id)
	print("[AugmentManager] Unlocked augment: %s" % augment_id)
	return true
