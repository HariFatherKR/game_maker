extends Node
class_name PetManagerClass
## PetManager - 펫 시스템 관리
##
## 펫 해금, 능력, 효과를 관리합니다.

# =============================================================================
# 펫 정의
# =============================================================================

enum PetType {
	CAT,         # 고양이 - 해충 제거
	DOG,         # 강아지 - 수확 보너스
	OWL,         # 부엉이 - 오프라인 효율
	GOLDEN_CHICKEN, # 황금닭 - 골드 보너스
	DRAGON       # 드래곤 - 모든 효과
}

const PET_DATA := {
	PetType.CAT: {
		"id": "cat",
		"name": "고양이",
		"description": "해충을 자동으로 쫓아냅니다.",
		"rarity": 0,  # Common
		"unlock_cost": 0,  # 시작 펫
		"ability": "pest_removal",
		"ability_value": 0.3,  # 30% 확률로 해충 자동 제거
		"passive_stat": "pest_resistance",
		"passive_value": 0.1
	},
	PetType.DOG: {
		"id": "dog",
		"name": "강아지",
		"description": "수확량이 증가합니다.",
		"rarity": 1,  # Uncommon
		"unlock_cost": 500,
		"ability": "harvest_boost",
		"ability_value": 0.1,  # 10% 수확량 증가
		"passive_stat": "yield_bonus",
		"passive_value": 0.05
	},
	PetType.OWL: {
		"id": "owl",
		"name": "부엉이",
		"description": "오프라인 효율이 증가합니다.",
		"rarity": 1,  # Uncommon
		"unlock_cost": 750,
		"ability": "offline_boost",
		"ability_value": 0.25,  # 25% 오프라인 효율 증가
		"passive_stat": "offline_efficiency",
		"passive_value": 0.1
	},
	PetType.GOLDEN_CHICKEN: {
		"id": "golden_chicken",
		"name": "황금닭",
		"description": "골드 획득량이 증가합니다.",
		"rarity": 2,  # Rare
		"unlock_cost": 2000,
		"ability": "gold_boost",
		"ability_value": 0.15,  # 15% 골드 증가
		"passive_stat": "gold_multiplier",
		"passive_value": 0.05
	},
	PetType.DRAGON: {
		"id": "dragon",
		"name": "드래곤",
		"description": "모든 능력치가 소폭 증가합니다.",
		"rarity": 4,  # Legendary
		"unlock_cost": 10000,
		"ability": "all_boost",
		"ability_value": 0.05,  # 5% 모든 스탯
		"passive_stat": "all_stats",
		"passive_value": 0.03
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal pet_unlocked(pet_id: String)
signal pet_activated(pet_id: String)
signal pet_ability_triggered(pet_id: String)

# =============================================================================
# 변수
# =============================================================================

## 현재 활성화된 펫
var active_pet: String = "cat"

## 펫 능력 쿨다운
var _ability_cooldowns: Dictionary = {}

## 펫 레벨 (향후 확장용)
var _pet_levels: Dictionary = {}

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[PetManager] Initialized")
	_connect_signals()
	_initialize_pet()


func _connect_signals() -> void:
	EventBus.tick.connect(_on_tick)
	EventBus.threat_spawned.connect(_on_threat_spawned)
	EventBus.crop_harvested.connect(_on_crop_harvested)

# =============================================================================
# 초기화
# =============================================================================

func _initialize_pet() -> void:
	active_pet = GameManager.game_data.meta.active_pet
	if active_pet.is_empty():
		active_pet = "cat"

	print("[PetManager] Active pet: %s" % active_pet)

# =============================================================================
# 펫 관리
# =============================================================================

## 펫 해금
func unlock_pet(pet_id: String) -> bool:
	var pet_type := _get_pet_type_by_id(pet_id)
	if pet_type == -1:
		push_error("[PetManager] Unknown pet: %s" % pet_id)
		return false

	var pet_data: Dictionary = PET_DATA[pet_type]

	# 이미 해금됨
	if GameManager.game_data.meta.unlocked_pets.has(pet_id):
		return false

	# 비용 확인
	if not GameManager.spend_currency("gold", pet_data.unlock_cost):
		print("[PetManager] Not enough gold for %s" % pet_id)
		return false

	GameManager.game_data.meta.unlocked_pets.append(pet_id)
	pet_unlocked.emit(pet_id)

	EventBus.notification_shown.emit("🎉 새 펫 해금: %s" % pet_data.name, "success")
	print("[PetManager] Pet unlocked: %s" % pet_id)
	return true


## 펫 활성화
func activate_pet(pet_id: String) -> bool:
	if not GameManager.game_data.meta.unlocked_pets.has(pet_id):
		push_warning("[PetManager] Pet not unlocked: %s" % pet_id)
		return false

	active_pet = pet_id
	GameManager.game_data.meta.active_pet = pet_id

	pet_activated.emit(pet_id)
	print("[PetManager] Pet activated: %s" % pet_id)
	return true


## 펫 해금 여부 확인
func is_pet_unlocked(pet_id: String) -> bool:
	return GameManager.game_data.meta.unlocked_pets.has(pet_id)


## 모든 펫 정보 가져오기
func get_all_pets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for pet_type in PET_DATA:
		var pet_data: Dictionary = PET_DATA[pet_type].duplicate()
		pet_data["unlocked"] = is_pet_unlocked(pet_data.id)
		pet_data["active"] = active_pet == pet_data.id
		result.append(pet_data)

	return result

# =============================================================================
# 스탯 보너스
# =============================================================================

## 현재 펫의 스탯 보너스 가져오기
func get_stat_bonus(stat_name: String) -> float:
	var pet_type := _get_pet_type_by_id(active_pet)
	if pet_type == -1:
		return 0.0

	var pet_data: Dictionary = PET_DATA[pet_type]

	# 드래곤은 모든 스탯에 보너스
	if pet_data.passive_stat == "all_stats":
		return pet_data.passive_value

	if pet_data.passive_stat == stat_name:
		return pet_data.passive_value

	return 0.0


## 현재 펫의 능력 값 가져오기
func get_ability_value(ability_name: String) -> float:
	var pet_type := _get_pet_type_by_id(active_pet)
	if pet_type == -1:
		return 0.0

	var pet_data: Dictionary = PET_DATA[pet_type]

	if pet_data.ability == ability_name:
		return pet_data.ability_value

	# 드래곤은 모든 능력에 소량 보너스
	if pet_data.ability == "all_boost":
		return pet_data.ability_value

	return 0.0

# =============================================================================
# 능력 발동
# =============================================================================

func _trigger_ability(ability_name: String, context: Dictionary = {}) -> void:
	var pet_type := _get_pet_type_by_id(active_pet)
	if pet_type == -1:
		return

	var pet_data: Dictionary = PET_DATA[pet_type]

	if pet_data.ability != ability_name and pet_data.ability != "all_boost":
		return

	pet_ability_triggered.emit(active_pet)

	match ability_name:
		"pest_removal":
			_try_auto_remove_pest(context)
		"harvest_boost":
			# 수확 시 자동 적용
			pass
		"gold_boost":
			# 골드 획득 시 자동 적용
			pass

# =============================================================================
# 펫 특수 능력
# =============================================================================

func _try_auto_remove_pest(context: Dictionary) -> void:
	var plot_id: int = context.get("plot_id", -1)
	if plot_id < 0:
		return

	var ability_value := get_ability_value("pest_removal")
	if ability_value <= 0:
		return

	if randf() < ability_value:
		if ThreatManager.remove_pest_manually(plot_id):
			EventBus.notification_shown.emit("🐱 고양이가 해충을 쫓아냈습니다!", "info")
			print("[PetManager] Cat auto-removed pest from plot %d" % plot_id)

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_tick(_delta: float) -> void:
	# 쿨다운 업데이트
	for ability in _ability_cooldowns:
		_ability_cooldowns[ability] = maxf(0, _ability_cooldowns[ability] - _delta)


func _on_threat_spawned(threat_id: String, target_plot: int) -> void:
	# 해충이 스폰되면 고양이 능력 시도
	_trigger_ability("pest_removal", {"plot_id": target_plot})


func _on_crop_harvested(_plot_id: int, _crop_type: String, _amount: int) -> void:
	# 수확 시 능력 트리거
	_trigger_ability("harvest_boost")
	_trigger_ability("gold_boost")

# =============================================================================
# 헬퍼
# =============================================================================

func _get_pet_type_by_id(pet_id: String) -> int:
	for pet_type in PET_DATA:
		if PET_DATA[pet_type].id == pet_id:
			return pet_type
	return -1


## 현재 펫 정보
func get_current_pet_data() -> Dictionary:
	var pet_type := _get_pet_type_by_id(active_pet)
	if pet_type == -1:
		return {}
	return PET_DATA[pet_type].duplicate()
