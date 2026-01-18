extends Node
class_name BattlePassManagerClass
## BattlePassManager - 시즌 배틀패스 시스템
##
## 시즌별 보상 트랙과 프리미엄 패스를 관리합니다.

# =============================================================================
# 상수
# =============================================================================

const MAX_LEVEL: int = 50
const XP_PER_LEVEL: int = 1000

## 시즌 지속 기간 (일)
const SEASON_DURATION_DAYS: int = 90

# =============================================================================
# 보상 정의
# =============================================================================

enum RewardType {
	GOLD,
	GEMS,
	SEEDS,
	AUGMENT_REROLL,
	PET_UNLOCK,
	COSMETIC,
	TITLE,
	META_POINTS
}

## 무료 트랙 보상 (레벨별)
const FREE_TRACK_REWARDS := {
	1: {"type": RewardType.GOLD, "amount": 100},
	2: {"type": RewardType.SEEDS, "amount": 10},
	3: {"type": RewardType.GOLD, "amount": 200},
	4: {"type": RewardType.GEMS, "amount": 5},
	5: {"type": RewardType.GOLD, "amount": 300},
	10: {"type": RewardType.SEEDS, "amount": 25},
	15: {"type": RewardType.GEMS, "amount": 10},
	20: {"type": RewardType.AUGMENT_REROLL, "amount": 3},
	25: {"type": RewardType.GOLD, "amount": 1000},
	30: {"type": RewardType.SEEDS, "amount": 50},
	35: {"type": RewardType.GEMS, "amount": 20},
	40: {"type": RewardType.META_POINTS, "amount": 100},
	45: {"type": RewardType.GOLD, "amount": 2000},
	50: {"type": RewardType.TITLE, "id": "season_1_veteran"}
}

## 프리미엄 트랙 보상 (레벨별)
const PREMIUM_TRACK_REWARDS := {
	1: {"type": RewardType.GEMS, "amount": 10},
	2: {"type": RewardType.GOLD, "amount": 500},
	3: {"type": RewardType.AUGMENT_REROLL, "amount": 2},
	4: {"type": RewardType.SEEDS, "amount": 20},
	5: {"type": RewardType.COSMETIC, "id": "golden_hoe"},
	10: {"type": RewardType.GEMS, "amount": 25},
	15: {"type": RewardType.GOLD, "amount": 2000},
	20: {"type": RewardType.PET_UNLOCK, "id": "golden_chicken"},
	25: {"type": RewardType.COSMETIC, "id": "starry_field"},
	30: {"type": RewardType.GEMS, "amount": 50},
	35: {"type": RewardType.META_POINTS, "amount": 250},
	40: {"type": RewardType.AUGMENT_REROLL, "amount": 10},
	45: {"type": RewardType.COSMETIC, "id": "rainbow_crops"},
	50: {"type": RewardType.TITLE, "id": "season_1_champion"}
}

# =============================================================================
# 시그널
# =============================================================================

signal xp_gained(amount: int, new_total: int)
signal level_up(new_level: int)
signal reward_claimed(track: String, level: int, reward: Dictionary)
signal premium_purchased

# =============================================================================
# 변수
# =============================================================================

## 현재 시즌 ID
var current_season_id: int = 1

## 현재 경험치
var current_xp: int = 0

## 현재 레벨
var current_level: int = 1

## 프리미엄 패스 보유 여부
var has_premium: bool = false

## 수령한 보상 (free/premium -> [levels])
var claimed_rewards: Dictionary = {
	"free": [],
	"premium": []
}

## 시즌 시작 시간
var season_start_time: int = 0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[BattlePassManager] Initialized")
	_connect_signals()
	_load_data()


func _connect_signals() -> void:
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.augment_selected.connect(_on_augment_selected)
	EventBus.threat_resolved.connect(_on_threat_resolved)

# =============================================================================
# XP 시스템
# =============================================================================

## XP 획득
func gain_xp(amount: int) -> void:
	if current_level >= MAX_LEVEL:
		return

	current_xp += amount
	xp_gained.emit(amount, current_xp)

	# 레벨업 체크
	while current_xp >= XP_PER_LEVEL and current_level < MAX_LEVEL:
		current_xp -= XP_PER_LEVEL
		current_level += 1
		level_up.emit(current_level)
		EventBus.notification_shown.emit("🎉 배틀패스 레벨 %d 달성!" % current_level, "success")

	_save_data()
	print("[BattlePassManager] XP gained: %d, Level: %d, XP: %d/%d" % [amount, current_level, current_xp, XP_PER_LEVEL])


## 현재 진행률 (0.0 ~ 1.0)
func get_level_progress() -> float:
	if current_level >= MAX_LEVEL:
		return 1.0
	return float(current_xp) / float(XP_PER_LEVEL)


## 다음 레벨까지 필요 XP
func get_xp_to_next_level() -> int:
	if current_level >= MAX_LEVEL:
		return 0
	return XP_PER_LEVEL - current_xp

# =============================================================================
# 보상 시스템
# =============================================================================

## 무료 트랙 보상 수령
func claim_free_reward(level: int) -> bool:
	if level > current_level:
		return false

	if claimed_rewards.free.has(level):
		return false

	if not FREE_TRACK_REWARDS.has(level):
		return false

	var reward: Dictionary = FREE_TRACK_REWARDS[level]
	_apply_reward(reward)

	claimed_rewards.free.append(level)
	reward_claimed.emit("free", level, reward)
	_save_data()

	print("[BattlePassManager] Claimed free reward level %d" % level)
	return true


## 프리미엄 트랙 보상 수령
func claim_premium_reward(level: int) -> bool:
	if not has_premium:
		return false

	if level > current_level:
		return false

	if claimed_rewards.premium.has(level):
		return false

	if not PREMIUM_TRACK_REWARDS.has(level):
		return false

	var reward: Dictionary = PREMIUM_TRACK_REWARDS[level]
	_apply_reward(reward)

	claimed_rewards.premium.append(level)
	reward_claimed.emit("premium", level, reward)
	_save_data()

	print("[BattlePassManager] Claimed premium reward level %d" % level)
	return true


## 보상 적용
func _apply_reward(reward: Dictionary) -> void:
	var reward_type: RewardType = reward.type

	match reward_type:
		RewardType.GOLD:
			GameManager.add_currency("gold", reward.amount)
		RewardType.GEMS:
			GameManager.add_currency("gems", reward.amount)
		RewardType.SEEDS:
			GameManager.add_currency("seeds", reward.amount)
		RewardType.META_POINTS:
			GameManager.add_currency("meta_points", reward.amount)
		RewardType.AUGMENT_REROLL:
			GameManager.game_data.run.reroll_count += reward.amount
		RewardType.PET_UNLOCK:
			if PetManager:
				# 강제 해금 (비용 없이)
				if not GameManager.game_data.meta.unlocked_pets.has(reward.id):
					GameManager.game_data.meta.unlocked_pets.append(reward.id)
		RewardType.COSMETIC:
			# 코스메틱 해금 (나중에 구현)
			if not GameManager.game_data.meta.unlocked_cosmetics.has(reward.id):
				GameManager.game_data.meta.unlocked_cosmetics.append(reward.id)
		RewardType.TITLE:
			# 칭호 해금 (나중에 구현)
			if not GameManager.game_data.meta.unlocked_titles.has(reward.id):
				GameManager.game_data.meta.unlocked_titles.append(reward.id)


## 수령 가능한 보상 확인
func get_claimable_rewards() -> Dictionary:
	var claimable := {
		"free": [],
		"premium": []
	}

	for level in FREE_TRACK_REWARDS:
		if level <= current_level and not claimed_rewards.free.has(level):
			claimable.free.append(level)

	if has_premium:
		for level in PREMIUM_TRACK_REWARDS:
			if level <= current_level and not claimed_rewards.premium.has(level):
				claimable.premium.append(level)

	return claimable


## 모든 수령 가능 보상 일괄 수령
func claim_all_available() -> int:
	var claimed_count := 0
	var claimable := get_claimable_rewards()

	for level in claimable.free:
		if claim_free_reward(level):
			claimed_count += 1

	for level in claimable.premium:
		if claim_premium_reward(level):
			claimed_count += 1

	return claimed_count

# =============================================================================
# 프리미엄 패스
# =============================================================================

## 프리미엄 패스 구매
func purchase_premium() -> bool:
	# 실제 구매 로직은 PlatformBridge에서 처리
	# 여기서는 구매 성공 후 호출됨
	has_premium = true
	premium_purchased.emit()
	_save_data()

	EventBus.notification_shown.emit("✨ 프리미엄 배틀패스 활성화!", "success")
	print("[BattlePassManager] Premium pass purchased")
	return true

# =============================================================================
# 시즌 정보
# =============================================================================

## 시즌 남은 시간 (초)
func get_season_remaining_time() -> int:
	var now := Time.get_unix_time_from_system()
	var season_end := season_start_time + (SEASON_DURATION_DAYS * 24 * 60 * 60)
	return maxi(0, int(season_end - now))


## 시즌 남은 일수
func get_season_remaining_days() -> int:
	return get_season_remaining_time() / (24 * 60 * 60)


## 시즌 진행률 (0.0 ~ 1.0)
func get_season_progress() -> float:
	var total_time := SEASON_DURATION_DAYS * 24 * 60 * 60
	var elapsed := total_time - get_season_remaining_time()
	return float(elapsed) / float(total_time)

# =============================================================================
# 이벤트 핸들러 (XP 획득)
# =============================================================================

func _on_crop_harvested(_plot_id: int, _crop_type: String, amount: int) -> void:
	# 수확당 XP
	gain_xp(amount * 2)


func _on_run_ended(_run_id: int, _meta_points: int) -> void:
	# 런 완료 XP
	gain_xp(100)


func _on_augment_selected(_augment_id: String) -> void:
	# 증강체 선택 XP
	gain_xp(25)


func _on_threat_resolved(_threat_id: String, success: bool) -> void:
	if success:
		# 위협 해결 XP
		gain_xp(50)

# =============================================================================
# 저장/로드
# =============================================================================

func _load_data() -> void:
	var bp_data: Dictionary = GameManager.game_data.meta.get("battle_pass", {})

	current_season_id = bp_data.get("season_id", 1)
	current_xp = bp_data.get("xp", 0)
	current_level = bp_data.get("level", 1)
	has_premium = bp_data.get("has_premium", false)
	claimed_rewards = bp_data.get("claimed_rewards", {"free": [], "premium": []})
	season_start_time = bp_data.get("season_start", int(Time.get_unix_time_from_system()))


func _save_data() -> void:
	GameManager.game_data.meta["battle_pass"] = {
		"season_id": current_season_id,
		"xp": current_xp,
		"level": current_level,
		"has_premium": has_premium,
		"claimed_rewards": claimed_rewards,
		"season_start": season_start_time
	}

# =============================================================================
# 유틸리티
# =============================================================================

## 보상 타입 이름
static func get_reward_type_name(reward_type: RewardType) -> String:
	match reward_type:
		RewardType.GOLD: return "골드"
		RewardType.GEMS: return "젬"
		RewardType.SEEDS: return "씨앗"
		RewardType.AUGMENT_REROLL: return "리롤권"
		RewardType.PET_UNLOCK: return "펫 해금"
		RewardType.COSMETIC: return "코스메틱"
		RewardType.TITLE: return "칭호"
		RewardType.META_POINTS: return "메타 포인트"
		_: return "보상"


## 보상 정보 표시 문자열
func format_reward(reward: Dictionary) -> String:
	var type_name := get_reward_type_name(reward.type)
	if reward.has("amount"):
		return "%s x%d" % [type_name, reward.amount]
	elif reward.has("id"):
		return "%s: %s" % [type_name, reward.id]
	return type_name
