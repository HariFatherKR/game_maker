extends Node
class_name LeaderboardManagerClass
## LeaderboardManager - 리더보드 시스템
##
## Steam/GameCenter/Play Games 리더보드를 관리합니다.

# =============================================================================
# 상수
# =============================================================================

## 리더보드 종류
enum LeaderboardType {
	TOTAL_GOLD,      # 총 골드 획득량
	BEST_RUN_SCORE,  # 최고 런 점수
	TOTAL_HARVESTS,  # 총 수확 횟수
	SPEEDRUN,        # 최단 런 클리어
	WEEKLY_SCORE     # 주간 점수
}

const LEADERBOARD_NAMES := {
	LeaderboardType.TOTAL_GOLD: "TotalGold",
	LeaderboardType.BEST_RUN_SCORE: "BestRunScore",
	LeaderboardType.TOTAL_HARVESTS: "TotalHarvests",
	LeaderboardType.SPEEDRUN: "SpeedRun",
	LeaderboardType.WEEKLY_SCORE: "WeeklyScore"
}

const LEADERBOARD_DISPLAY := {
	LeaderboardType.TOTAL_GOLD: {
		"name": "총 골드",
		"description": "역대 획득한 총 골드량",
		"format": "gold"
	},
	LeaderboardType.BEST_RUN_SCORE: {
		"name": "최고 점수",
		"description": "단일 런 최고 점수",
		"format": "score"
	},
	LeaderboardType.TOTAL_HARVESTS: {
		"name": "총 수확",
		"description": "역대 수확한 작물 수",
		"format": "count"
	},
	LeaderboardType.SPEEDRUN: {
		"name": "스피드런",
		"description": "최단 런 클리어 시간",
		"format": "time"
	},
	LeaderboardType.WEEKLY_SCORE: {
		"name": "주간 점수",
		"description": "이번 주 획득 점수",
		"format": "score"
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal leaderboard_loaded(leaderboard_type: LeaderboardType, entries: Array)
signal score_uploaded(leaderboard_type: LeaderboardType, success: bool)
signal player_rank_loaded(leaderboard_type: LeaderboardType, rank: int, score: int)

# =============================================================================
# 변수
# =============================================================================

## 캐시된 리더보드 데이터
var _cached_leaderboards: Dictionary = {}

## 로딩 중인 리더보드
var _loading_leaderboards: Array[LeaderboardType] = []

## 마지막 업로드 시간
var _last_upload_time: Dictionary = {}

## 업로드 쿨다운 (초)
const UPLOAD_COOLDOWN: float = 5.0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[LeaderboardManager] Initialized")
	_connect_signals()


func _connect_signals() -> void:
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.crop_harvested.connect(_on_crop_harvested)

# =============================================================================
# 리더보드 조회
# =============================================================================

## 리더보드 로드
func load_leaderboard(leaderboard_type: LeaderboardType, count: int = 10, friends_only: bool = false) -> void:
	if _loading_leaderboards.has(leaderboard_type):
		return

	_loading_leaderboards.append(leaderboard_type)

	var leaderboard_name: String = LEADERBOARD_NAMES[leaderboard_type]

	# 플랫폼별 리더보드 로드
	if PlatformBridge.is_steam():
		_load_steam_leaderboard(leaderboard_name, count, friends_only, leaderboard_type)
	else:
		# 로컬 더미 데이터
		_load_local_leaderboard(leaderboard_type, count)


## Steam 리더보드 로드
func _load_steam_leaderboard(name: String, count: int, friends_only: bool, leaderboard_type: LeaderboardType) -> void:
	# Steam API 호출 (GodotSteam 필요)
	# 실제 구현 시 Steam.findLeaderboard() 사용
	print("[LeaderboardManager] Loading Steam leaderboard: %s" % name)

	# 콜백 대기 후 처리
	# 임시로 로컬 데이터 반환
	await get_tree().create_timer(0.5).timeout
	_load_local_leaderboard(leaderboard_type, count)


## 로컬 리더보드 (오프라인/테스트용)
func _load_local_leaderboard(leaderboard_type: LeaderboardType, count: int) -> void:
	var entries: Array = []

	# 더미 데이터 생성
	for i in range(count):
		entries.append({
			"rank": i + 1,
			"player_name": "Player_%d" % (i + 1),
			"score": randi_range(1000, 100000) / (i + 1),
			"is_local_player": i == 4  # 5등이 현재 플레이어
		})

	# 점수 기준 정렬
	entries.sort_custom(func(a, b): return a.score > b.score)

	# 순위 재할당
	for i in range(entries.size()):
		entries[i].rank = i + 1

	_cached_leaderboards[leaderboard_type] = entries
	_loading_leaderboards.erase(leaderboard_type)

	leaderboard_loaded.emit(leaderboard_type, entries)
	print("[LeaderboardManager] Loaded %d entries for %s" % [entries.size(), LeaderboardType.keys()[leaderboard_type]])

# =============================================================================
# 점수 업로드
# =============================================================================

## 점수 업로드
func upload_score(leaderboard_type: LeaderboardType, score: int) -> void:
	# 쿨다운 체크
	var now := Time.get_unix_time_from_system()
	if _last_upload_time.has(leaderboard_type):
		if now - _last_upload_time[leaderboard_type] < UPLOAD_COOLDOWN:
			return

	_last_upload_time[leaderboard_type] = now

	var leaderboard_name: String = LEADERBOARD_NAMES[leaderboard_type]

	if PlatformBridge.is_steam():
		_upload_steam_score(leaderboard_name, score, leaderboard_type)
	else:
		_upload_local_score(leaderboard_type, score)


func _upload_steam_score(name: String, score: int, leaderboard_type: LeaderboardType) -> void:
	# Steam API 호출
	print("[LeaderboardManager] Uploading to Steam: %s = %d" % [name, score])

	# 콜백 대기 후 처리
	await get_tree().create_timer(0.3).timeout
	score_uploaded.emit(leaderboard_type, true)


func _upload_local_score(leaderboard_type: LeaderboardType, score: int) -> void:
	print("[LeaderboardManager] Local score saved: %s = %d" % [LeaderboardType.keys()[leaderboard_type], score])
	score_uploaded.emit(leaderboard_type, true)

# =============================================================================
# 자동 업로드
# =============================================================================

## 런 종료 시 점수 업로드
func _on_run_ended(run_id: int, meta_points: int) -> void:
	var run_data = GameManager.game_data.run
	var stats = GameManager.game_data.stats

	# 최고 런 점수
	var run_score := _calculate_run_score()
	upload_score(LeaderboardType.BEST_RUN_SCORE, run_score)

	# 스피드런 (시간이 짧을수록 좋음, 역순 점수)
	var run_time := int(run_data.total_run_time)
	var speedrun_score := maxi(0, 1200 - run_time)  # 20분(1200초) 기준
	upload_score(LeaderboardType.SPEEDRUN, speedrun_score)

	# 총 골드
	upload_score(LeaderboardType.TOTAL_GOLD, GameManager.game_data.meta.total_gold_earned)

	# 총 수확
	upload_score(LeaderboardType.TOTAL_HARVESTS, stats.total_crops_harvested)


func _on_crop_harvested(_plot_id: int, _crop_type: String, _amount: int) -> void:
	# 주간 점수 업데이트 (수확마다)
	# 실제로는 주간 리셋 로직 필요
	pass

# =============================================================================
# 점수 계산
# =============================================================================

## 런 점수 계산
func _calculate_run_score() -> int:
	var stats = GameManager.game_data.stats
	var run = GameManager.game_data.run

	var score := 0

	# 수확량 점수
	score += stats.total_crops_harvested * 10

	# 골드 획득 점수
	score += stats.total_gold_from_crops

	# 증강체 시너지 보너스
	score += stats.synergies_activated * 500

	# 위협 생존 보너스
	score += stats.threats_survived * 200

	# 시즌 완료 보너스 (4시즌 모두 완료 시)
	if run.current_season == 0 and run.seasons_completed >= 4:
		score += 5000

	return score

# =============================================================================
# 유틸리티
# =============================================================================

## 캐시된 리더보드 가져오기
func get_cached_leaderboard(leaderboard_type: LeaderboardType) -> Array:
	return _cached_leaderboards.get(leaderboard_type, [])


## 리더보드 표시 정보 가져오기
func get_leaderboard_display_info(leaderboard_type: LeaderboardType) -> Dictionary:
	return LEADERBOARD_DISPLAY.get(leaderboard_type, {})


## 점수 포맷팅
func format_score(score: int, format_type: String) -> String:
	match format_type:
		"gold":
			if score >= 1000000:
				return "%.1fM" % (score / 1000000.0)
			elif score >= 1000:
				return "%.1fK" % (score / 1000.0)
			return str(score)
		"time":
			var seconds := 1200 - score  # 역변환
			var minutes := seconds / 60
			var secs := seconds % 60
			return "%d:%02d" % [minutes, secs]
		"count":
			return str(score)
		_:  # score
			return str(score)


## 플레이어 순위 가져오기
func get_player_rank(leaderboard_type: LeaderboardType) -> void:
	var entries := get_cached_leaderboard(leaderboard_type)
	for entry in entries:
		if entry.get("is_local_player", false):
			player_rank_loaded.emit(leaderboard_type, entry.rank, entry.score)
			return

	player_rank_loaded.emit(leaderboard_type, -1, 0)
