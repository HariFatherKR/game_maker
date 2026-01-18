extends Node
## PlatformBridge - 플랫폼별 API 추상화
##
## Steam, iOS, Android 등 플랫폼별 기능을 통합 인터페이스로 제공합니다.

# =============================================================================
# 상수
# =============================================================================

const STEAM_APP_ID: int = 0  # TODO: Steam 앱 ID 설정

# =============================================================================
# 플랫폼 열거형
# =============================================================================

enum Platform {
	UNKNOWN,
	STEAM,
	IOS,
	ANDROID,
	WEB
}

# =============================================================================
# 변수
# =============================================================================

var current_platform: Platform = Platform.UNKNOWN
var is_initialized: bool = false

## Steam 관련
var steam_available: bool = false
var steam_id: int = 0
var steam_username: String = ""

## 모바일 관련
var mobile_bridge_connected: bool = false

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[PlatformBridge] Initialized")
	_detect_platform()

# =============================================================================
# 초기화
# =============================================================================

func _detect_platform() -> void:
	match OS.get_name():
		"Windows", "macOS", "Linux":
			# Steam 체크
			if _check_steam_available():
				current_platform = Platform.STEAM
			else:
				current_platform = Platform.UNKNOWN
		"iOS":
			current_platform = Platform.IOS
		"Android":
			current_platform = Platform.ANDROID
		"Web":
			current_platform = Platform.WEB
		_:
			current_platform = Platform.UNKNOWN

	print("[PlatformBridge] Detected platform: %s" % Platform.keys()[current_platform])


func _check_steam_available() -> bool:
	# GodotSteam이 로드되었는지 확인
	return Engine.has_singleton("Steam")


## 플랫폼 초기화
func initialize() -> void:
	if is_initialized:
		return

	print("[PlatformBridge] Initializing platform services...")

	match current_platform:
		Platform.STEAM:
			_init_steam()
		Platform.IOS, Platform.ANDROID:
			_init_mobile()
		_:
			print("[PlatformBridge] No platform-specific initialization needed")

	is_initialized = true

# =============================================================================
# 플랫폼 체크
# =============================================================================

func is_steam() -> bool:
	return current_platform == Platform.STEAM and steam_available


func is_mobile() -> bool:
	return current_platform in [Platform.IOS, Platform.ANDROID]


func is_ios() -> bool:
	return current_platform == Platform.IOS


func is_android() -> bool:
	return current_platform == Platform.ANDROID

# =============================================================================
# Steam 통합
# =============================================================================

func _init_steam() -> void:
	if not Engine.has_singleton("Steam"):
		print("[PlatformBridge] Steam singleton not available")
		steam_available = false
		EventBus.steam_initialized.emit(false)
		return

	var Steam = Engine.get_singleton("Steam")

	# Steam 초기화
	var init_result: Dictionary = Steam.steamInit()

	if init_result.status != 1:
		push_error("[PlatformBridge] Steam init failed: %s" % init_result.verbal)
		steam_available = false
		EventBus.steam_initialized.emit(false)
		return

	steam_available = true
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	print("[PlatformBridge] Steam initialized - User: %s (ID: %d)" % [steam_username, steam_id])
	EventBus.steam_initialized.emit(true)

	# Steam 콜백 연결
	Steam.connect("achievement_stored", _on_steam_achievement_stored)


func _on_steam_achievement_stored(_game_id: int, _result: bool, _achievement_name: String) -> void:
	pass


## Steam 업적 해금
func unlock_achievement(achievement_id: String) -> void:
	if not is_steam():
		print("[PlatformBridge] Achievement unlocked (non-Steam): %s" % achievement_id)
		EventBus.achievement_unlocked.emit(achievement_id)
		return

	var Steam = Engine.get_singleton("Steam")
	Steam.setAchievement(achievement_id)
	Steam.storeStats()
	EventBus.achievement_unlocked.emit(achievement_id)
	print("[PlatformBridge] Steam achievement unlocked: %s" % achievement_id)


## Steam 클라우드 저장
func steam_cloud_save(data: Dictionary) -> bool:
	if not is_steam():
		return false

	var Steam = Engine.get_singleton("Steam")
	var json_data := JSON.stringify(data)
	var bytes := json_data.to_utf8_buffer()

	var success := Steam.fileWrite("cloud_save.json", bytes)
	if success:
		print("[PlatformBridge] Steam cloud save successful")
		EventBus.cloud_sync_completed.emit(true)
	else:
		push_error("[PlatformBridge] Steam cloud save failed")
		EventBus.cloud_sync_completed.emit(false)

	return success


## Steam 클라우드 로드
func steam_cloud_load() -> Dictionary:
	if not is_steam():
		return {}

	var Steam = Engine.get_singleton("Steam")

	if not Steam.fileExists("cloud_save.json"):
		return {}

	var data: Dictionary = Steam.fileRead("cloud_save.json")
	if data.ret:
		var json := JSON.new()
		var error := json.parse(data.buf.get_string_from_utf8())
		if error == OK:
			print("[PlatformBridge] Steam cloud load successful")
			return json.data

	push_error("[PlatformBridge] Steam cloud load failed")
	return {}


## Steam 리더보드 점수 업로드
func upload_leaderboard_score(leaderboard_name: String, score: int) -> void:
	if not is_steam():
		return

	var Steam = Engine.get_singleton("Steam")
	Steam.findLeaderboard(leaderboard_name)
	await Steam.leaderboard_find_result
	Steam.uploadLeaderboardScore(score)
	print("[PlatformBridge] Leaderboard score uploaded: %s = %d" % [leaderboard_name, score])

# =============================================================================
# 모바일 통합
# =============================================================================

func _init_mobile() -> void:
	print("[PlatformBridge] Initializing mobile platform...")
	# React Native 브릿지 연결 대기
	_setup_mobile_bridge()


func _setup_mobile_bridge() -> void:
	# JavaScriptBridge를 통한 React Native 통신 (웹뷰 기반인 경우)
	if OS.has_feature("web") or current_platform in [Platform.IOS, Platform.ANDROID]:
		mobile_bridge_connected = true
		EventBus.mobile_bridge_connected.emit()
		print("[PlatformBridge] Mobile bridge ready")


## 모바일 메시지 전송
func send_to_mobile(message_type: String, payload: Dictionary) -> void:
	if not is_mobile():
		return

	var message := {
		"type": message_type,
		"payload": payload,
		"timestamp": Time.get_unix_time_from_system()
	}

	# JavaScriptBridge를 통해 전송 (웹뷰 환경)
	if Engine.has_singleton("JavaScriptBridge"):
		var js_bridge := Engine.get_singleton("JavaScriptBridge")
		if js_bridge != null:
			js_bridge.eval("window.godotMessage && window.godotMessage(%s)" % JSON.stringify(message))


## 모바일 클라우드 저장
func mobile_cloud_save(data: Dictionary) -> bool:
	send_to_mobile("CLOUD_SAVE", {"data": data})
	return true


## 모바일 인앱 결제 요청
func request_purchase(product_id: String) -> void:
	if not is_mobile():
		return

	send_to_mobile("PURCHASE_REQUEST", {"product_id": product_id})


## 모바일 푸시 알림 예약
func schedule_notification(title: String, body: String, delay_seconds: int) -> void:
	if not is_mobile():
		return

	send_to_mobile("SCHEDULE_NOTIFICATION", {
		"title": title,
		"body": body,
		"delay": delay_seconds
	})

# =============================================================================
# 크로스 플랫폼 유틸리티
# =============================================================================

## 플랫폼 이름 반환
func get_platform_name() -> String:
	return Platform.keys()[current_platform]


## 진동 피드백 (모바일 전용)
func vibrate(duration_ms: int = 50) -> void:
	if is_mobile():
		Input.vibrate_handheld(duration_ms)


## 앱 스토어 리뷰 요청
func request_review() -> void:
	if is_mobile():
		send_to_mobile("REQUEST_REVIEW", {})
