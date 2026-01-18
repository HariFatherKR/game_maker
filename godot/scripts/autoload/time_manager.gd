extends Node
## TimeManager - 시간 및 오프라인 보상 관리
##
## 게임 내 시간 시스템과 오프라인 보상 계산을 담당합니다.

# =============================================================================
# 상수
# =============================================================================

const MAX_OFFLINE_HOURS: float = 24.0  # 최대 오프라인 보상 시간
const OFFLINE_EFFICIENCY: float = 0.5  # 오프라인 생산 효율 (50%)
const SECONDS_PER_GAME_DAY: float = 300.0  # 5분 = 게임 내 1일

# =============================================================================
# 변수
# =============================================================================

## 마지막 종료 시간 (Unix timestamp)
var last_exit_time: int = 0

## 현재 게임 내 일수
var current_day: int = 1

## 일일 타이머
var _day_timer: float = 0.0

## 계산된 오프라인 보상
var pending_offline_rewards: Dictionary = {}

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[TimeManager] Initialized")
	EventBus.tick.connect(_on_tick)


func _on_tick(delta: float) -> void:
	_update_day_cycle(delta)

# =============================================================================
# 일일 사이클
# =============================================================================

func _update_day_cycle(delta: float) -> void:
	_day_timer += delta

	if _day_timer >= SECONDS_PER_GAME_DAY:
		_day_timer -= SECONDS_PER_GAME_DAY
		current_day += 1
		EventBus.day_passed.emit(current_day)
		print("[TimeManager] Day %d started" % current_day)

# =============================================================================
# 오프라인 보상
# =============================================================================

## 종료 시간 기록
func record_exit_time() -> void:
	last_exit_time = Time.get_unix_time_from_system()
	print("[TimeManager] Exit time recorded: %d" % last_exit_time)


## 오프라인 보상 계산
func calculate_offline_rewards() -> void:
	if last_exit_time == 0:
		print("[TimeManager] No previous session, skipping offline rewards")
		return

	var current_time := Time.get_unix_time_from_system()
	var offline_seconds := current_time - last_exit_time

	if offline_seconds < 60:  # 1분 미만은 무시
		print("[TimeManager] Offline duration too short (%ds)" % offline_seconds)
		return

	# 최대 시간 제한
	var max_seconds := MAX_OFFLINE_HOURS * 3600.0
	offline_seconds = mini(offline_seconds, int(max_seconds))

	print("[TimeManager] Calculating offline rewards for %d seconds (%.1f hours)" % [
		offline_seconds,
		offline_seconds / 3600.0
	])

	pending_offline_rewards = _compute_rewards(offline_seconds)

	if not pending_offline_rewards.is_empty():
		EventBus.offline_reward_calculated.emit(pending_offline_rewards)


## 오프라인 보상 수령
func claim_offline_rewards() -> Dictionary:
	if pending_offline_rewards.is_empty():
		return {}

	var rewards := pending_offline_rewards.duplicate()

	# 재화 지급
	if rewards.has("gold"):
		GameManager.add_currency("gold", rewards.gold)
	if rewards.has("seeds"):
		GameManager.add_currency("seeds", rewards.seeds)

	# 작물 성장 적용
	if rewards.has("growth_ticks"):
		_apply_offline_growth(rewards.growth_ticks)

	pending_offline_rewards.clear()
	EventBus.offline_reward_claimed.emit(rewards)

	print("[TimeManager] Offline rewards claimed: %s" % rewards)
	return rewards


## 보상 계산 로직
func _compute_rewards(offline_seconds: int) -> Dictionary:
	var rewards: Dictionary = {}

	# 기본 골드 생산 (시간당)
	var base_gold_per_hour := _get_base_production_rate()
	var offline_hours := offline_seconds / 3600.0
	var gold_earned := int(base_gold_per_hour * offline_hours * OFFLINE_EFFICIENCY)

	if gold_earned > 0:
		rewards["gold"] = gold_earned

	# 작물 성장 틱 수
	var growth_ticks := int(offline_seconds / GameManager.TICK_RATE)
	if growth_ticks > 0:
		rewards["growth_ticks"] = growth_ticks

	# 오프라인 시간 정보
	rewards["offline_duration"] = offline_seconds
	rewards["offline_hours"] = snapped(offline_hours, 0.1)

	return rewards


## 기본 생산율 계산
func _get_base_production_rate() -> float:
	# TODO: 농장 상태에 따른 생산율 계산
	var unlocked_plots: int = GameManager.game_data.farm.unlocked_plots
	return 10.0 * unlocked_plots  # 농지당 시간당 10골드


## 오프라인 성장 적용
func _apply_offline_growth(ticks: int) -> void:
	# TODO: 각 작물에 오프라인 성장 적용
	pass

# =============================================================================
# 유틸리티
# =============================================================================

## 시간 포맷팅 (초 -> "1h 30m" 형식)
func format_duration(seconds: int) -> String:
	if seconds < 60:
		return "%ds" % seconds
	elif seconds < 3600:
		return "%dm" % (seconds / 60)
	else:
		var hours := seconds / 3600
		var minutes := (seconds % 3600) / 60
		if minutes > 0:
			return "%dh %dm" % [hours, minutes]
		else:
			return "%dh" % hours


## 다음 날까지 남은 시간
func get_time_until_next_day() -> float:
	return SECONDS_PER_GAME_DAY - _day_timer


## 현재 오프라인 시간 (게임 실행 중)
func get_current_session_duration() -> int:
	return Time.get_unix_time_from_system() - last_exit_time
