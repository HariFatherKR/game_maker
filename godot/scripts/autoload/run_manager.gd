extends Node
## RunManager - 로그라이트 런 시스템 관리
##
## 런의 시작, 진행, 종료를 관리하고
## 시즌 전환 및 목표 추적을 담당합니다.

# =============================================================================
# 상수
# =============================================================================

const SEASON_DURATION: float = 300.0  # 5분
const HARVEST_AUGMENT_THRESHOLD: int = 5  # N회 수확마다 증강체 제공

enum Season {
	SPRING = 0,
	SUMMER = 1,
	FALL = 2,
	WINTER = 3,
}

enum RunState {
	IDLE,           # 런 대기 중
	RUNNING,        # 런 진행 중
	SEASON_TRANSITION,  # 시즌 전환 중
	AUGMENT_SELECTION,  # 증강체 선택 중
	PAUSED,         # 일시정지
	ENDING,         # 런 종료 처리 중
}

# =============================================================================
# 시그널
# =============================================================================

signal state_changed(old_state: RunState, new_state: RunState)
signal season_warning(seconds_remaining: float)

# =============================================================================
# 변수
# =============================================================================

var current_state: RunState = RunState.IDLE
var run_data: GameData.RunData:
	get:
		return GameManager.game_data.run

## 시즌 타이머
var _season_timer: float = 0.0
var _warning_shown: bool = false
const WARNING_TIME: float = 30.0  # 30초 전 경고

## 수확 카운터 (증강체 제공용)
var _harvest_counter: int = 0

## 현재 제공된 증강체 선택지
var _current_augment_choices: Array[String] = []

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[RunManager] Initialized")
	_connect_signals()


func _process(delta: float) -> void:
	if current_state != RunState.RUNNING:
		return

	_update_season_timer(delta)
	_update_run_time(delta)


func _connect_signals() -> void:
	EventBus.tick.connect(_on_tick)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.augment_selected.connect(_on_augment_selected)

# =============================================================================
# 런 관리 API
# =============================================================================

## 새 런 시작
func start_run() -> bool:
	if current_state != RunState.IDLE:
		push_warning("[RunManager] Cannot start run, current state: %s" % RunState.keys()[current_state])
		return false

	print("[RunManager] Starting new run...")

	# 런 데이터 초기화
	run_data.run_number += 1
	run_data.is_active = true
	run_data.current_season = Season.SPRING
	run_data.season_time_remaining = SEASON_DURATION
	run_data.total_run_time = 0.0
	run_data.active_augments.clear()
	run_data.run_gold = 0
	run_data.run_harvests = 0
	run_data.run_synergies.clear()
	run_data.completed_objectives.clear()

	# 카운터 초기화
	_harvest_counter = 0
	_warning_shown = false
	_season_timer = SEASON_DURATION

	# 상태 변경
	_change_state(RunState.RUNNING)

	# 이벤트 발생
	EventBus.run_started.emit(run_data.run_number)
	EventBus.season_changed.emit(-1, Season.SPRING)

	# 시작 시즌 효과 적용
	_apply_season_effects(Season.SPRING)

	print("[RunManager] Run #%d started (Season: Spring)" % run_data.run_number)
	return true


## 런 종료
func end_run() -> Dictionary:
	if not run_data.is_active:
		push_warning("[RunManager] No active run to end")
		return {}

	_change_state(RunState.ENDING)

	# 런 결과 계산
	var result := _evaluate_run()

	# 메타 진행도 업데이트
	_update_meta_progress(result)

	# 런 데이터 정리
	run_data.is_active = false

	# 상태 변경
	_change_state(RunState.IDLE)

	# 이벤트 발생
	EventBus.run_ended.emit(run_data.run_number, result.meta_points)

	print("[RunManager] Run #%d ended - Gold: %d, Harvests: %d, Meta Points: %d" % [
		run_data.run_number,
		result.total_gold,
		result.total_harvests,
		result.meta_points
	])

	return result


## 런 일시정지
func pause_run() -> void:
	if current_state == RunState.RUNNING:
		_change_state(RunState.PAUSED)


## 런 재개
func resume_run() -> void:
	if current_state == RunState.PAUSED:
		_change_state(RunState.RUNNING)


## 현재 런 활성 여부
func is_run_active() -> bool:
	return run_data.is_active


## 현재 시즌 이름
func get_season_name() -> String:
	return Season.keys()[run_data.current_season]


## 시즌 남은 시간 (초)
func get_season_time_remaining() -> float:
	return _season_timer


## 시즌 진행률 (0.0 ~ 1.0)
func get_season_progress() -> float:
	return 1.0 - (_season_timer / SEASON_DURATION)

# =============================================================================
# 시즌 시스템
# =============================================================================

func _update_season_timer(delta: float) -> void:
	_season_timer -= delta
	run_data.season_time_remaining = _season_timer

	# 경고 체크
	if not _warning_shown and _season_timer <= WARNING_TIME:
		_warning_shown = true
		season_warning.emit(_season_timer)
		print("[RunManager] Season ending in %.0f seconds!" % _season_timer)

	# 시즌 종료 체크
	if _season_timer <= 0.0:
		_transition_season()


func _transition_season() -> void:
	var old_season: int = run_data.current_season
	var new_season: int = (old_season + 1) % 4

	# 겨울 이후면 런 종료
	if old_season == Season.WINTER:
		print("[RunManager] Winter ended, completing run")
		end_run()
		return

	_change_state(RunState.SEASON_TRANSITION)

	# 이전 시즌 효과 제거
	_remove_season_effects(old_season)

	# 시즌 업데이트
	run_data.current_season = new_season
	_season_timer = SEASON_DURATION
	_warning_shown = false

	# 새 시즌 효과 적용
	_apply_season_effects(new_season)

	# 이벤트 발생
	EventBus.season_changed.emit(old_season, new_season)

	_change_state(RunState.RUNNING)

	print("[RunManager] Season changed: %s -> %s" % [
		Season.keys()[old_season],
		Season.keys()[new_season]
	])


func _apply_season_effects(season: int) -> void:
	match season:
		Season.SPRING:
			# 봄: 성장 보너스
			EventBus.notification_shown.emit("🌸 봄이 왔습니다! 성장 속도 +20%", "info")
		Season.SUMMER:
			# 여름: 가뭄 시작
			EventBus.notification_shown.emit("☀️ 여름입니다! 물이 필요할 수 있습니다", "warning")
		Season.FALL:
			# 가을: 수확 보너스
			EventBus.notification_shown.emit("🍂 가을입니다! 수확량 +25%", "info")
		Season.WINTER:
			# 겨울: 서리 위협
			EventBus.notification_shown.emit("❄️ 겨울이 왔습니다! 작물을 보호하세요", "warning")


func _remove_season_effects(_season: int) -> void:
	# 시즌별 임시 효과 제거 (필요시 구현)
	pass


## 시즌별 성장 배율
func get_season_growth_multiplier() -> float:
	match run_data.current_season:
		Season.SPRING: return 1.2   # +20%
		Season.SUMMER: return 1.0   # 기본
		Season.FALL: return 0.9     # -10%
		Season.WINTER: return 0.7   # -30%
	return 1.0


## 시즌별 수확 배율
func get_season_harvest_multiplier() -> float:
	match run_data.current_season:
		Season.SPRING: return 1.0   # 기본
		Season.SUMMER: return 1.1   # +10%
		Season.FALL: return 1.25    # +25%
		Season.WINTER: return 0.8   # -20%
	return 1.0

# =============================================================================
# 증강체 선택
# =============================================================================

func _check_augment_offer() -> void:
	_harvest_counter += 1

	if _harvest_counter >= HARVEST_AUGMENT_THRESHOLD:
		_harvest_counter = 0
		_offer_augments()


func _offer_augments() -> void:
	_change_state(RunState.AUGMENT_SELECTION)

	# AugmentManager에서 선택지 가져오기
	_current_augment_choices = AugmentManager.generate_choices(3)

	EventBus.augments_offered.emit(_current_augment_choices)

	print("[RunManager] Offering augments: %s" % str(_current_augment_choices))


func _on_augment_selected(augment_id: String) -> void:
	if current_state != RunState.AUGMENT_SELECTION:
		return

	# 증강체 추가
	run_data.active_augments.append(augment_id)
	AugmentManager.apply_augment(augment_id)

	# 통계 업데이트
	GameManager.game_data.stats.total_augments_selected += 1

	# 시너지 체크
	AugmentManager.check_synergies()

	# 상태 복원
	_change_state(RunState.RUNNING)

	print("[RunManager] Augment selected: %s (Total: %d)" % [
		augment_id,
		run_data.active_augments.size()
	])

# =============================================================================
# 런 평가
# =============================================================================

func _evaluate_run() -> Dictionary:
	var result := {
		"run_number": run_data.run_number,
		"total_gold": run_data.run_gold,
		"total_harvests": run_data.run_harvests,
		"total_time": run_data.total_run_time,
		"seasons_completed": run_data.current_season,
		"augments_collected": run_data.active_augments.size(),
		"synergies_activated": run_data.run_synergies.size(),
		"objectives_completed": run_data.completed_objectives.size(),
		"meta_points": 0,
	}

	# 메타 포인트 계산
	var meta_points := 10  # 기본
	meta_points += run_data.run_harvests / 10
	meta_points += run_data.run_gold / 1000
	meta_points += run_data.completed_objectives.size() * 5
	meta_points += run_data.run_synergies.size() * 10

	# 시즌 완주 보너스
	if run_data.current_season == Season.WINTER:
		meta_points += 20

	result.meta_points = meta_points

	return result


func _update_meta_progress(result: Dictionary) -> void:
	var meta := GameManager.game_data.meta

	# 누적 통계 업데이트
	meta.total_runs += 1
	meta.total_gold_earned += result.total_gold
	meta.total_harvests += result.total_harvests

	# 최고 기록 업데이트
	if result.total_gold > meta.best_run_gold:
		meta.best_run_gold = result.total_gold
	if result.total_harvests > meta.best_run_harvests:
		meta.best_run_harvests = result.total_harvests

	# 메타 포인트 추가
	GameManager.add_currency("meta_points", result.meta_points)

# =============================================================================
# 내부 헬퍼
# =============================================================================

func _change_state(new_state: RunState) -> void:
	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)


func _update_run_time(delta: float) -> void:
	run_data.total_run_time += delta

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_tick(_delta: float) -> void:
	# 틱마다 처리할 런 관련 로직
	pass


func _on_crop_harvested(_plot_id: int, _crop_type: String, amount: int) -> void:
	if not run_data.is_active:
		return

	run_data.run_harvests += 1
	run_data.run_gold += amount

	_check_augment_offer()

# =============================================================================
# 목표 시스템
# =============================================================================

## 목표 달성 체크
func check_objective(objective_id: String) -> bool:
	if run_data.completed_objectives.has(objective_id):
		return false

	var completed := false

	match objective_id:
		"gold_10000":
			completed = run_data.run_gold >= 10000
		"gold_50000":
			completed = run_data.run_gold >= 50000
		"gold_100000":
			completed = run_data.run_gold >= 100000
		"harvest_100":
			completed = run_data.run_harvests >= 100
		"harvest_500":
			completed = run_data.run_harvests >= 500
		"harvest_1000":
			completed = run_data.run_harvests >= 1000
		"synergy_3":
			completed = run_data.run_synergies.size() >= 3

	if completed:
		run_data.completed_objectives.append(objective_id)
		EventBus.notification_shown.emit("🎯 목표 달성: %s" % objective_id, "success")
		print("[RunManager] Objective completed: %s" % objective_id)

	return completed


## 모든 목표 상태 체크
func check_all_objectives() -> void:
	check_objective("gold_10000")
	check_objective("gold_50000")
	check_objective("gold_100000")
	check_objective("harvest_100")
	check_objective("harvest_500")
	check_objective("harvest_1000")
	check_objective("synergy_3")
