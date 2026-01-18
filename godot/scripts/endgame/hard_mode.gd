extends Node
class_name HardModeManagerClass
## HardModeManager - 하드모드 시스템
##
## 고난이도 게임플레이와 특별 보상을 관리합니다.

# =============================================================================
# 하드모드 수정자
# =============================================================================

const HARD_MODE_MODIFIERS := {
	# 기본 난이도 증가
	"growth_speed": 0.7,          # 성장 속도 30% 감소
	"yield_penalty": 0.2,         # 수확량 20% 감소
	"gold_penalty": 0.3,          # 골드 획득 30% 감소

	# 위협 증가
	"threat_frequency": 2.0,      # 위협 빈도 2배
	"threat_damage": 1.5,         # 위협 피해 50% 증가
	"disaster_duration": 1.5,     # 재해 지속시간 50% 증가

	# 자원 제한
	"starting_gold": 0.5,         # 시작 골드 50%
	"seed_cost": 1.5,             # 씨앗 비용 50% 증가
	"plot_cost": 2.0,             # 농지 비용 2배

	# 증강체 제한
	"reroll_cost": 2.0,           # 리롤 비용 2배
	"legendary_chance": 0.5,      # 전설 확률 50% 감소

	# 보상 증가
	"meta_point_bonus": 2.0,      # 메타 포인트 2배
	"xp_bonus": 1.5               # 경험치 50% 증가
}

# =============================================================================
# 하드모드 도전과제
# =============================================================================

const HARD_MODE_CHALLENGES := {
	"no_death_run": {
		"id": "no_death_run",
		"name": "완벽한 런",
		"description": "작물 손실 없이 런 완료",
		"reward": {"meta_points": 500}
	},
	"speedrun_hard": {
		"id": "speedrun_hard",
		"name": "극한 스피드런",
		"description": "하드모드에서 10분 이내 클리어",
		"reward": {"meta_points": 750}
	},
	"no_augment_run": {
		"id": "no_augment_run",
		"name": "맨손 농부",
		"description": "증강체 없이 런 완료",
		"reward": {"meta_points": 1000}
	},
	"all_threats_survived": {
		"id": "all_threats_survived",
		"name": "불굴의 의지",
		"description": "모든 위협 생존",
		"reward": {"meta_points": 600}
	},
	"max_gold_hard": {
		"id": "max_gold_hard",
		"name": "하드코어 수확왕",
		"description": "하드모드에서 10,000골드 획득",
		"reward": {"meta_points": 800}
	}
}

# =============================================================================
# 하드모드 전용 위협
# =============================================================================

const HARD_MODE_THREATS := {
	"blight": {
		"id": "blight",
		"name": "역병",
		"description": "모든 작물에 퍼지는 역병",
		"effect": "spread_damage",
		"value": 0.3,
		"spread_chance": 0.4,
		"duration": 90.0
	},
	"drought_extreme": {
		"id": "drought_extreme",
		"name": "극심한 가뭄",
		"description": "물이 완전히 마릅니다",
		"effect": "growth_stop",
		"value": 1.0,
		"duration": 120.0
	},
	"swarm": {
		"id": "swarm",
		"name": "해충 떼",
		"description": "대량의 해충 습격",
		"effect": "mass_pest",
		"value": 5,  # 동시 해충 수
		"duration": 60.0
	},
	"cursed_soil": {
		"id": "cursed_soil",
		"name": "저주받은 땅",
		"description": "농지가 일시적으로 쓸 수 없게 됩니다",
		"effect": "plot_curse",
		"value": 3,  # 영향 농지 수
		"duration": 180.0
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal hard_mode_enabled
signal hard_mode_disabled
signal challenge_completed(challenge_id: String)
signal hard_mode_run_complete(stats: Dictionary)

# =============================================================================
# 변수
# =============================================================================

## 하드모드 활성화 여부
var is_hard_mode: bool = false

## 하드모드 해금 여부
var is_hard_mode_unlocked: bool = false

## 완료한 도전과제
var completed_challenges: Array[String] = []

## 하드모드 통계
var hard_mode_stats: Dictionary = {
	"runs_completed": 0,
	"best_time": 0,
	"best_gold": 0,
	"total_threats_survived": 0
}

## 현재 런 추적
var _current_run_crops_lost: int = 0
var _current_run_augments: int = 0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[HardModeManager] Initialized")
	_connect_signals()
	_load_data()


func _connect_signals() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.threat_resolved.connect(_on_threat_resolved)
	EventBus.augment_selected.connect(_on_augment_selected)

# =============================================================================
# 하드모드 제어
# =============================================================================

## 하드모드 해금
func unlock_hard_mode() -> void:
	if is_hard_mode_unlocked:
		return

	is_hard_mode_unlocked = true
	_save_data()

	EventBus.notification_shown.emit("💀 하드모드 해금!", "success")
	print("[HardModeManager] Hard mode unlocked")


## 하드모드 활성화
func enable_hard_mode() -> bool:
	if not is_hard_mode_unlocked:
		return false

	if GameManager.game_data.run.is_active:
		EventBus.notification_shown.emit("런 진행 중에는 변경할 수 없습니다", "warning")
		return false

	is_hard_mode = true
	hard_mode_enabled.emit()
	_save_data()

	EventBus.notification_shown.emit("💀 하드모드 활성화", "warning")
	print("[HardModeManager] Hard mode enabled")
	return true


## 하드모드 비활성화
func disable_hard_mode() -> bool:
	if GameManager.game_data.run.is_active:
		EventBus.notification_shown.emit("런 진행 중에는 변경할 수 없습니다", "warning")
		return false

	is_hard_mode = false
	hard_mode_disabled.emit()
	_save_data()

	EventBus.notification_shown.emit("하드모드 비활성화", "info")
	print("[HardModeManager] Hard mode disabled")
	return true

# =============================================================================
# 수정자 적용
# =============================================================================

## 성장 속도 수정자
func get_growth_modifier() -> float:
	if not is_hard_mode:
		return 1.0
	return HARD_MODE_MODIFIERS.growth_speed


## 수확량 수정자
func get_yield_modifier() -> float:
	if not is_hard_mode:
		return 1.0
	return 1.0 - HARD_MODE_MODIFIERS.yield_penalty


## 골드 수정자
func get_gold_modifier() -> float:
	if not is_hard_mode:
		return 1.0
	return 1.0 - HARD_MODE_MODIFIERS.gold_penalty


## 위협 빈도 수정자
func get_threat_frequency_modifier() -> float:
	if not is_hard_mode:
		return 1.0
	return HARD_MODE_MODIFIERS.threat_frequency


## 메타 포인트 수정자
func get_meta_point_modifier() -> float:
	if not is_hard_mode:
		return 1.0
	return HARD_MODE_MODIFIERS.meta_point_bonus


## 비용 수정자
func get_cost_modifier(cost_type: String) -> float:
	if not is_hard_mode:
		return 1.0

	match cost_type:
		"seed":
			return HARD_MODE_MODIFIERS.seed_cost
		"plot":
			return HARD_MODE_MODIFIERS.plot_cost
		"reroll":
			return HARD_MODE_MODIFIERS.reroll_cost
		_:
			return 1.0

# =============================================================================
# 도전과제
# =============================================================================

## 도전과제 완료 체크
func check_challenges() -> void:
	for challenge_id in HARD_MODE_CHALLENGES:
		if not completed_challenges.has(challenge_id):
			if _check_challenge_condition(challenge_id):
				complete_challenge(challenge_id)


func _check_challenge_condition(challenge_id: String) -> bool:
	if not is_hard_mode:
		return false

	var run := GameManager.game_data.run
	var stats := GameManager.game_data.stats

	match challenge_id:
		"no_death_run":
			return _current_run_crops_lost == 0 and run.seasons_completed >= 4
		"speedrun_hard":
			return run.total_run_time < 600.0 and run.seasons_completed >= 4
		"no_augment_run":
			return _current_run_augments == 0 and run.seasons_completed >= 4
		"all_threats_survived":
			return stats.threats_encountered > 0 and stats.threats_survived == stats.threats_encountered
		"max_gold_hard":
			return stats.total_gold_from_crops >= 10000

	return false


## 도전과제 완료
func complete_challenge(challenge_id: String) -> void:
	if completed_challenges.has(challenge_id):
		return

	completed_challenges.append(challenge_id)

	var challenge: Dictionary = HARD_MODE_CHALLENGES[challenge_id]

	# 보상 지급
	if challenge.reward.has("meta_points"):
		GameManager.add_currency("meta_points", challenge.reward.meta_points)

	challenge_completed.emit(challenge_id)
	_save_data()

	EventBus.notification_shown.emit("🏆 도전과제 완료: %s" % challenge.name, "success")
	print("[HardModeManager] Challenge completed: %s" % challenge_id)

# =============================================================================
# 정보 조회
# =============================================================================

## 도전과제 정보
func get_challenge_data(challenge_id: String) -> Dictionary:
	var data: Dictionary = HARD_MODE_CHALLENGES.get(challenge_id, {}).duplicate()
	data["completed"] = completed_challenges.has(challenge_id)
	return data


## 모든 도전과제
func get_all_challenges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for challenge_id in HARD_MODE_CHALLENGES:
		var data := get_challenge_data(challenge_id)
		result.append(data)

	return result


## 하드모드 통계
func get_hard_mode_stats() -> Dictionary:
	return hard_mode_stats.duplicate()

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_run_started(_run_id: int) -> void:
	_current_run_crops_lost = 0
	_current_run_augments = 0


func _on_run_ended(_run_id: int, _meta_points: int) -> void:
	if is_hard_mode:
		hard_mode_stats.runs_completed += 1

		var run := GameManager.game_data.run
		if hard_mode_stats.best_time == 0 or run.total_run_time < hard_mode_stats.best_time:
			hard_mode_stats.best_time = int(run.total_run_time)

		var stats := GameManager.game_data.stats
		if stats.total_gold_from_crops > hard_mode_stats.best_gold:
			hard_mode_stats.best_gold = stats.total_gold_from_crops

		check_challenges()
		_save_data()

		var run_stats := {
			"time": run.total_run_time,
			"gold": stats.total_gold_from_crops,
			"crops_lost": _current_run_crops_lost
		}
		hard_mode_run_complete.emit(run_stats)


func _on_threat_resolved(_threat_id: String, success: bool) -> void:
	if is_hard_mode and success:
		hard_mode_stats.total_threats_survived += 1


func _on_augment_selected(_augment_id: String) -> void:
	_current_run_augments += 1

# =============================================================================
# 저장/로드
# =============================================================================

func _load_data() -> void:
	var hm_data: Dictionary = GameManager.game_data.meta.get("hard_mode", {})

	is_hard_mode_unlocked = hm_data.get("unlocked", false)
	is_hard_mode = hm_data.get("enabled", false)

	completed_challenges.clear()
	for challenge_id in hm_data.get("completed_challenges", []):
		completed_challenges.append(challenge_id)

	hard_mode_stats = hm_data.get("stats", {
		"runs_completed": 0,
		"best_time": 0,
		"best_gold": 0,
		"total_threats_survived": 0
	})


func _save_data() -> void:
	GameManager.game_data.meta["hard_mode"] = {
		"unlocked": is_hard_mode_unlocked,
		"enabled": is_hard_mode,
		"completed_challenges": completed_challenges,
		"stats": hard_mode_stats
	}
