extends Node
class_name SteamIntegration
## SteamIntegration - Steam SDK 통합 래퍼
##
## GodotSteam을 래핑하여 Steam 기능에 대한
## 통합 인터페이스를 제공합니다.

# =============================================================================
# 상수
# =============================================================================

## Steam 앱 ID (Steamworks에서 발급받은 ID로 교체)
const APP_ID: int = 480  # SpaceWar 테스트 앱 ID (개발용)

# =============================================================================
# 업적 정의
# =============================================================================

const ACHIEVEMENTS := {
	"FIRST_HARVEST": {
		"id": "FIRST_HARVEST",
		"name": "First Harvest",
		"description": "Harvest your first crop"
	},
	"HUNDRED_HARVESTS": {
		"id": "HUNDRED_HARVESTS",
		"name": "Seasoned Farmer",
		"description": "Harvest 100 crops"
	},
	"THOUSAND_GOLD": {
		"id": "THOUSAND_GOLD",
		"name": "Wealthy Farmer",
		"description": "Earn 1000 gold"
	},
	"FIRST_RUN": {
		"id": "FIRST_RUN",
		"name": "Beginning of Journey",
		"description": "Complete your first run"
	},
	"TEN_RUNS": {
		"id": "TEN_RUNS",
		"name": "Veteran Farmer",
		"description": "Complete 10 runs"
	},
	"LEGENDARY_AUGMENT": {
		"id": "LEGENDARY_AUGMENT",
		"name": "Legendary Power",
		"description": "Obtain a legendary augment"
	},
	"ALL_CROPS": {
		"id": "ALL_CROPS",
		"name": "Crop Collector",
		"description": "Grow every type of crop"
	},
	"MAX_PLOTS": {
		"id": "MAX_PLOTS",
		"name": "Land Baron",
		"description": "Unlock all farm plots"
	}
}

# =============================================================================
# 리더보드 정의
# =============================================================================

const LEADERBOARDS := {
	"TOTAL_GOLD": "TotalGoldEarned",
	"BEST_RUN": "BestRunScore",
	"TOTAL_HARVESTS": "TotalHarvests",
	"RUNS_COMPLETED": "RunsCompleted"
}

# =============================================================================
# 변수
# =============================================================================

var steam: Object = null  # Steam 싱글톤 참조
var is_initialized: bool = false
var steam_id: int = 0
var steam_username: String = ""

## 캐시된 업적 상태
var _achievement_cache: Dictionary = {}

## 리더보드 핸들 캐시
var _leaderboard_handles: Dictionary = {}

# =============================================================================
# 시그널
# =============================================================================

signal steam_ready()
signal achievement_unlocked(achievement_id: String)
signal leaderboard_uploaded(leaderboard_name: String, success: bool)
signal leaderboard_downloaded(leaderboard_name: String, entries: Array)

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[SteamIntegration] Initializing...")


func _process(_delta: float) -> void:
	if is_initialized and steam != null:
		steam.run_callbacks()

# =============================================================================
# 초기화
# =============================================================================

## Steam 초기화
func initialize() -> bool:
	if is_initialized:
		return true

	if not Engine.has_singleton("Steam"):
		push_warning("[SteamIntegration] Steam singleton not found")
		return false

	steam = Engine.get_singleton("Steam")

	# Steam 초기화
	var init_result: Dictionary = steam.steamInit(false, APP_ID)

	if init_result.status != 1:
		push_error("[SteamIntegration] Init failed: %s" % init_result.verbal)
		return false

	is_initialized = true
	steam_id = steam.getSteamID()
	steam_username = steam.getPersonaName()

	print("[SteamIntegration] Initialized!")
	print("[SteamIntegration] User: %s (ID: %d)" % [steam_username, steam_id])

	# 콜백 연결
	_connect_callbacks()

	# 업적 상태 로드
	_load_achievement_status()

	steam_ready.emit()
	return true


func _connect_callbacks() -> void:
	if steam == null:
		return

	steam.current_stats_received.connect(_on_stats_received)
	steam.achievement_stored.connect(_on_achievement_stored)
	steam.leaderboard_find_result.connect(_on_leaderboard_found)
	steam.leaderboard_score_uploaded.connect(_on_score_uploaded)
	steam.leaderboard_scores_downloaded.connect(_on_scores_downloaded)


func _load_achievement_status() -> void:
	if steam == null:
		return

	steam.requestCurrentStats()

# =============================================================================
# 업적 시스템
# =============================================================================

## 업적 해금
func unlock_achievement(achievement_id: String) -> bool:
	if not is_initialized or steam == null:
		print("[SteamIntegration] (Mock) Achievement: %s" % achievement_id)
		return false

	if not ACHIEVEMENTS.has(achievement_id):
		push_warning("[SteamIntegration] Unknown achievement: %s" % achievement_id)
		return false

	# 이미 해금된 경우 스킵
	if _achievement_cache.get(achievement_id, false):
		return true

	var success: bool = steam.setAchievement(achievement_id)

	if success:
		steam.storeStats()
		_achievement_cache[achievement_id] = true
		print("[SteamIntegration] Achievement unlocked: %s" % achievement_id)
	else:
		push_error("[SteamIntegration] Failed to unlock: %s" % achievement_id)

	return success


## 업적 해금 여부 확인
func is_achievement_unlocked(achievement_id: String) -> bool:
	if not is_initialized:
		return false

	return _achievement_cache.get(achievement_id, false)


## 모든 업적 상태 가져오기
func get_all_achievements() -> Dictionary:
	var result: Dictionary = {}

	for id in ACHIEVEMENTS:
		result[id] = {
			"info": ACHIEVEMENTS[id],
			"unlocked": _achievement_cache.get(id, false)
		}

	return result


## 업적 진행도 설정 (특정 업적용)
func set_achievement_progress(achievement_id: String, progress: int, max_progress: int) -> void:
	if not is_initialized or steam == null:
		return

	# Steam은 직접적인 진행도를 지원하지 않으므로
	# 스탯을 통해 간접적으로 처리
	var stat_name := "progress_%s" % achievement_id
	steam.setStatInt(stat_name, progress)
	steam.storeStats()

	# 진행도 달성 시 업적 해금
	if progress >= max_progress:
		unlock_achievement(achievement_id)

# =============================================================================
# 리더보드 시스템
# =============================================================================

## 리더보드 점수 업로드
func upload_score(leaderboard_name: String, score: int) -> void:
	if not is_initialized or steam == null:
		print("[SteamIntegration] (Mock) Leaderboard: %s = %d" % [leaderboard_name, score])
		return

	if not LEADERBOARDS.has(leaderboard_name):
		push_warning("[SteamIntegration] Unknown leaderboard: %s" % leaderboard_name)
		return

	var steam_leaderboard_name: String = LEADERBOARDS[leaderboard_name]

	# 리더보드 찾기
	steam.findLeaderboard(steam_leaderboard_name)

	# 핸들을 받으면 점수 업로드 (콜백에서 처리)
	# _pending_upload = {"name": leaderboard_name, "score": score}


## 리더보드 순위 가져오기
func download_scores(leaderboard_name: String, start: int = 1, end: int = 10) -> void:
	if not is_initialized or steam == null:
		return

	if not LEADERBOARDS.has(leaderboard_name):
		push_warning("[SteamIntegration] Unknown leaderboard: %s" % leaderboard_name)
		return

	var steam_leaderboard_name: String = LEADERBOARDS[leaderboard_name]
	steam.findLeaderboard(steam_leaderboard_name)

	# 핸들을 받으면 순위 다운로드 (콜백에서 처리)

# =============================================================================
# 클라우드 세이브
# =============================================================================

## 클라우드에 저장
func cloud_save(filename: String, data: Dictionary) -> bool:
	if not is_initialized or steam == null:
		return false

	var json_string := JSON.stringify(data)
	var bytes := json_string.to_utf8_buffer()

	var success: bool = steam.fileWrite(filename, bytes)

	if success:
		print("[SteamIntegration] Cloud save: %s" % filename)
	else:
		push_error("[SteamIntegration] Cloud save failed: %s" % filename)

	return success


## 클라우드에서 로드
func cloud_load(filename: String) -> Dictionary:
	if not is_initialized or steam == null:
		return {}

	if not steam.fileExists(filename):
		print("[SteamIntegration] Cloud file not found: %s" % filename)
		return {}

	var result: Dictionary = steam.fileRead(filename)

	if not result.ret:
		push_error("[SteamIntegration] Cloud load failed: %s" % filename)
		return {}

	var json := JSON.new()
	var error := json.parse(result.buf.get_string_from_utf8())

	if error != OK:
		push_error("[SteamIntegration] Cloud data parse failed")
		return {}

	print("[SteamIntegration] Cloud load: %s" % filename)
	return json.data


## 클라우드 파일 존재 확인
func cloud_file_exists(filename: String) -> bool:
	if not is_initialized or steam == null:
		return false

	return steam.fileExists(filename)


## 클라우드 파일 삭제
func cloud_delete(filename: String) -> bool:
	if not is_initialized or steam == null:
		return false

	return steam.fileDelete(filename)

# =============================================================================
# 유틸리티
# =============================================================================

## Steam 오버레이 열기
func open_overlay(type: String = "Friends") -> void:
	if not is_initialized or steam == null:
		return

	steam.activateGameOverlay(type)


## 스토어 페이지 열기
func open_store_page() -> void:
	if not is_initialized or steam == null:
		return

	steam.activateGameOverlayToStore(APP_ID)


## 친구 목록 가져오기
func get_friends() -> Array:
	if not is_initialized or steam == null:
		return []

	var friends: Array = []
	var count: int = steam.getFriendCount(0x04)  # k_EFriendFlagImmediate

	for i in range(count):
		var friend_id: int = steam.getFriendByIndex(i, 0x04)
		var friend_name: String = steam.getFriendPersonaName(friend_id)
		friends.append({
			"id": friend_id,
			"name": friend_name
		})

	return friends

# =============================================================================
# 콜백 핸들러
# =============================================================================

func _on_stats_received(_game_id: int, result: int, _user_id: int) -> void:
	if result != 1:  # k_EResultOK
		push_error("[SteamIntegration] Stats receive failed")
		return

	# 업적 상태 캐시 업데이트
	for achievement_id in ACHIEVEMENTS:
		var unlocked: Dictionary = steam.getAchievement(achievement_id)
		_achievement_cache[achievement_id] = unlocked.achieved

	print("[SteamIntegration] Stats and achievements loaded")


func _on_achievement_stored(_game_id: int, group_achievement: bool, achievement_name: String, cur_progress: int, max_progress: int) -> void:
	print("[SteamIntegration] Achievement stored: %s" % achievement_name)
	achievement_unlocked.emit(achievement_name)


func _on_leaderboard_found(handle: int, found: int) -> void:
	if found == 0:
		push_error("[SteamIntegration] Leaderboard not found")
		return

	# TODO: 대기 중인 업로드/다운로드 처리
	print("[SteamIntegration] Leaderboard found: %d" % handle)


func _on_score_uploaded(success: int, handle: int, score_details: Dictionary) -> void:
	var is_success := success == 1
	print("[SteamIntegration] Score uploaded: %s" % ("success" if is_success else "failed"))
	leaderboard_uploaded.emit("", is_success)


func _on_scores_downloaded(handle: int, result: Array) -> void:
	print("[SteamIntegration] Scores downloaded: %d entries" % result.size())
	leaderboard_downloaded.emit("", result)
