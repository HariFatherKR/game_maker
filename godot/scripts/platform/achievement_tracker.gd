extends Node
class_name AchievementTrackerClass
## AchievementTracker - 업적 추적 시스템
##
## 게임 이벤트를 모니터링하고 업적 조건 달성 시 자동으로 해금합니다.

# =============================================================================
# 클래스 프리로드
# =============================================================================

const SteamIntegrationClass := preload("res://scripts/platform/steam_integration.gd")
const AugmentDatabaseScript := preload("res://scripts/roguelike/augment_database.gd")
const AugmentClass := preload("res://scripts/roguelike/augment.gd")

var _augment_db_instance = null

func _get_augment_db():
	if _augment_db_instance == null:
		_augment_db_instance = AugmentDatabaseScript.new()
	return _augment_db_instance

# =============================================================================
# 업적 조건 정의
# =============================================================================

const ACHIEVEMENT_CONDITIONS := {
	"FIRST_HARVEST": {
		"type": "stat",
		"stat": "total_crops_harvested",
		"threshold": 1
	},
	"HUNDRED_HARVESTS": {
		"type": "stat",
		"stat": "total_crops_harvested",
		"threshold": 100
	},
	"THOUSAND_GOLD": {
		"type": "stat",
		"stat": "total_gold_from_crops",
		"threshold": 1000
	},
	"FIRST_RUN": {
		"type": "meta",
		"stat": "total_runs",
		"threshold": 1
	},
	"TEN_RUNS": {
		"type": "meta",
		"stat": "total_runs",
		"threshold": 10
	},
	"LEGENDARY_AUGMENT": {
		"type": "event",
		"event": "legendary_augment_obtained"
	},
	"ALL_CROPS": {
		"type": "collection",
		"collection": "unlocked_crops",
		"count": 12
	},
	"MAX_PLOTS": {
		"type": "farm",
		"stat": "unlocked_plots",
		"threshold": 25
	},
	# 추가 업적
	"FIRST_SYNERGY": {
		"type": "stat",
		"stat": "synergies_activated",
		"threshold": 1
	},
	"SYNERGY_MASTER": {
		"type": "stat",
		"stat": "synergies_activated",
		"threshold": 10
	},
	"GOLD_HOARDER": {
		"type": "stat",
		"stat": "total_gold_from_crops",
		"threshold": 100000
	},
	"SPEED_FARMER": {
		"type": "event",
		"event": "run_completed_under_10min"
	},
	"WINTER_SURVIVOR": {
		"type": "event",
		"event": "completed_winter"
	},
	"AUGMENT_COLLECTOR": {
		"type": "stat",
		"stat": "total_augments_selected",
		"threshold": 50
	}
}

# =============================================================================
# 변수
# =============================================================================

## 해금된 업적 캐시
var _unlocked_achievements: Array[String] = []

## 마지막 체크 통계 (변경 감지용)
var _last_stats: Dictionary = {}

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[AchievementTracker] Initialized")
	_connect_events()

	# 초기 체크 (로드된 데이터에 대해)
	call_deferred("_check_all_achievements")


func _connect_events() -> void:
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.augment_selected.connect(_on_augment_selected)
	EventBus.synergy_activated.connect(_on_synergy_activated)
	EventBus.plot_unlocked.connect(_on_plot_unlocked)
	EventBus.season_changed.connect(_on_season_changed)

# =============================================================================
# 업적 체크
# =============================================================================

## 모든 업적 체크
func _check_all_achievements() -> void:
	for achievement_id in ACHIEVEMENT_CONDITIONS:
		_check_achievement(achievement_id)


## 단일 업적 체크
func _check_achievement(achievement_id: String) -> void:
	if _unlocked_achievements.has(achievement_id):
		return

	var condition: Dictionary = ACHIEVEMENT_CONDITIONS.get(achievement_id, {})
	if condition.is_empty():
		return

	var achieved := false

	match condition.type:
		"stat":
			achieved = _check_stat_achievement(condition)
		"meta":
			achieved = _check_meta_achievement(condition)
		"farm":
			achieved = _check_farm_achievement(condition)
		"collection":
			achieved = _check_collection_achievement(condition)
		"event":
			# 이벤트 업적은 이벤트 발생 시 별도 처리
			pass

	if achieved:
		_unlock_achievement(achievement_id)


func _check_stat_achievement(condition: Dictionary) -> bool:
	var stat_name: String = condition.stat
	var threshold: int = condition.threshold

	var current_value := 0
	var stats = GameManager.game_data.stats

	match stat_name:
		"total_crops_harvested":
			current_value = stats.total_crops_harvested
		"total_gold_from_crops":
			current_value = stats.total_gold_from_crops
		"synergies_activated":
			current_value = stats.synergies_activated
		"total_augments_selected":
			current_value = stats.total_augments_selected

	return current_value >= threshold


func _check_meta_achievement(condition: Dictionary) -> bool:
	var stat_name: String = condition.stat
	var threshold: int = condition.threshold

	var current_value := 0
	var meta = GameManager.game_data.meta

	match stat_name:
		"total_runs":
			current_value = meta.total_runs
		"total_gold_earned":
			current_value = meta.total_gold_earned
		"total_harvests":
			current_value = meta.total_harvests

	return current_value >= threshold


func _check_farm_achievement(condition: Dictionary) -> bool:
	var stat_name: String = condition.stat
	var threshold: int = condition.threshold

	var current_value := 0
	var farm = GameManager.game_data.farm

	match stat_name:
		"unlocked_plots":
			current_value = farm.unlocked_plots

	return current_value >= threshold


func _check_collection_achievement(condition: Dictionary) -> bool:
	var collection_name: String = condition.collection
	var required_count: int = condition.count

	var current_count := 0
	var meta = GameManager.game_data.meta

	match collection_name:
		"unlocked_crops":
			current_count = meta.unlocked_crops.size()

	return current_count >= required_count


## 업적 해금
func _unlock_achievement(achievement_id: String) -> void:
	if _unlocked_achievements.has(achievement_id):
		return

	_unlocked_achievements.append(achievement_id)

	# Steam/플랫폼 업적 해금
	PlatformBridge.unlock_achievement(achievement_id)

	# 알림 표시
	var achievement_name := _get_achievement_name(achievement_id)
	EventBus.notification_shown.emit("🏆 업적 달성: %s" % achievement_name, "success")
	EventBus.achievement_unlocked.emit(achievement_id)

	print("[AchievementTracker] Achievement unlocked: %s" % achievement_id)


func _get_achievement_name(achievement_id: String) -> String:
	if SteamIntegrationClass.ACHIEVEMENTS.has(achievement_id):
		return SteamIntegrationClass.ACHIEVEMENTS[achievement_id].name
	return achievement_id

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_crop_harvested(_plot_id: int, _crop_type: String, _amount: int) -> void:
	_check_achievement("FIRST_HARVEST")
	_check_achievement("HUNDRED_HARVESTS")
	_check_achievement("THOUSAND_GOLD")
	_check_achievement("GOLD_HOARDER")


func _on_run_ended(_run_id: int, _meta_points: int) -> void:
	_check_achievement("FIRST_RUN")
	_check_achievement("TEN_RUNS")

	# 빠른 클리어 체크
	var run_time: float = GameManager.game_data.run.total_run_time
	if run_time < 600.0:  # 10분 미만
		_unlock_achievement("SPEED_FARMER")


func _on_augment_selected(augment_id: String) -> void:
	_check_achievement("AUGMENT_COLLECTOR")

	# 레전더리 증강체 체크
	var augment = _get_augment_db().get_augment(augment_id)
	if augment and augment.rarity == AugmentClass.Rarity.LEGENDARY:
		_unlock_achievement("LEGENDARY_AUGMENT")


func _on_synergy_activated(_synergy_id: String, _bonus: float) -> void:
	_check_achievement("FIRST_SYNERGY")
	_check_achievement("SYNERGY_MASTER")


func _on_plot_unlocked(_plot_id: int) -> void:
	_check_achievement("MAX_PLOTS")


func _on_season_changed(_old_season: int, new_season: int) -> void:
	# 겨울 완료 체크 (다음 시즌으로 넘어갈 때)
	if new_season == 0 and GameManager.game_data.run.current_season == 3:
		_unlock_achievement("WINTER_SURVIVOR")

# =============================================================================
# 세이브/로드
# =============================================================================

func get_save_data() -> Array[String]:
	return _unlocked_achievements.duplicate()


func load_save_data(data: Array) -> void:
	_unlocked_achievements.clear()
	for achievement_id in data:
		_unlocked_achievements.append(achievement_id)
