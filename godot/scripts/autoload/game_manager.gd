extends Node
## GameManager - 게임 전역 상태 관리
##
## 게임의 핵심 상태를 관리하고, 게임 루프를 제어합니다.
## 모든 게임 시스템의 중앙 허브 역할을 합니다.

# =============================================================================
# 상수
# =============================================================================

const VERSION: String = "1.0.0"
const TICK_RATE: float = 0.1  # 100ms마다 틱
const AUTO_SAVE_INTERVAL: float = 60.0  # 60초마다 자동 저장

# =============================================================================
# 게임 상태 열거형
# =============================================================================

enum GameState {
	INITIALIZING,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	LOADING,
	SAVING
}

# =============================================================================
# 게임 상태 변수
# =============================================================================

var current_state: GameState = GameState.INITIALIZING
var is_first_launch: bool = true

## 게임 데이터 (타입 안전한 클래스)
var game_data: GameData = GameData.new()

# =============================================================================
# 내부 변수
# =============================================================================

var _tick_timer: float = 0.0
var _playtime_timer: float = 0.0
var _auto_save_timer: float = 0.0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[GameManager] Initializing v%s" % VERSION)
	_setup_signals()

	# 게임 로드 시도
	await get_tree().process_frame
	_initialize_game()


func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	# 플레이타임 추적
	_playtime_timer += delta
	if _playtime_timer >= 1.0:
		game_data.stats.playtime_seconds += int(_playtime_timer)
		_playtime_timer = fmod(_playtime_timer, 1.0)

	# 게임 틱
	_tick_timer += delta
	if _tick_timer >= TICK_RATE:
		EventBus.tick.emit(_tick_timer)
		_tick_timer = 0.0

	# 자동 저장
	_auto_save_timer += delta
	if _auto_save_timer >= game_data.settings.auto_save_interval:
		_auto_save_timer = 0.0
		request_save()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_on_quit_requested()
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()

# =============================================================================
# 초기화
# =============================================================================

func _setup_signals() -> void:
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.game_saved.connect(_on_game_saved)
	EventBus.crop_harvested.connect(_on_crop_harvested)


func _initialize_game() -> void:
	print("[GameManager] Loading game data...")

	# SaveManager를 통해 세이브 데이터 로드 시도
	if SaveManager.has_save():
		var loaded_data := SaveManager.load_game()
		if loaded_data != null:
			game_data = loaded_data
			is_first_launch = false
		else:
			print("[GameManager] Load failed, starting fresh")
			_setup_new_game()
	else:
		print("[GameManager] No save found, starting fresh")
		_setup_new_game()

	# 세션 카운트 증가
	game_data.stats.session_count += 1
	if game_data.stats.first_play_time == 0:
		game_data.stats.first_play_time = Time.get_unix_time_from_system()

	# 플랫폼 초기화
	PlatformBridge.initialize()

	# 오프라인 보상 계산
	TimeManager.calculate_offline_rewards()

	change_state(GameState.MAIN_MENU)
	print("[GameManager] Initialization complete")


func _setup_new_game() -> void:
	game_data = GameData.new()

	# 시작 농지 설정 (메타 업그레이드 적용)
	var starting_plots := 1 + game_data.meta.get_upgrade_level("starting_plots")
	game_data.farm.unlocked_plots = starting_plots

	# 시작 골드 (메타 업그레이드 적용)
	var starting_gold := 100 + (game_data.meta.get_upgrade_level("starting_gold") * 100)
	game_data.currencies.gold = starting_gold

# =============================================================================
# 상태 관리
# =============================================================================

## 게임 상태 변경
func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state

	print("[GameManager] State: %s -> %s" % [
		GameState.keys()[old_state],
		GameState.keys()[new_state]
	])

	match new_state:
		GameState.PLAYING:
			EventBus.game_started.emit()
		GameState.PAUSED:
			EventBus.game_paused.emit(true)


## 게임 시작
func start_game() -> void:
	if current_state == GameState.MAIN_MENU:
		change_state(GameState.PLAYING)

		# 런이 없으면 새 런 시작
		if not game_data.run.is_active:
			RunManager.start_run()


## 게임 일시정지
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		RunManager.pause_run()


## 게임 재개
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		RunManager.resume_run()
		EventBus.game_paused.emit(false)


## 게임 저장 요청
func request_save() -> void:
	if current_state == GameState.SAVING:
		return

	var previous_state := current_state
	change_state(GameState.SAVING)
	SaveManager.save_game(game_data)
	change_state(previous_state)

# =============================================================================
# 재화 관리
# =============================================================================

## 재화 획득
func add_currency(currency_type: String, amount: int) -> void:
	var old_amount := game_data.currencies.get_amount(currency_type)
	game_data.currencies.add(currency_type, amount)
	var new_amount := game_data.currencies.get_amount(currency_type)

	EventBus.currency_changed.emit(currency_type, old_amount, new_amount)

	if currency_type == "gold":
		EventBus.gold_earned.emit(amount, "harvest")


## 재화 소비
func spend_currency(currency_type: String, amount: int) -> bool:
	var old_amount := game_data.currencies.get_amount(currency_type)

	if not game_data.currencies.spend(currency_type, amount):
		return false

	var new_amount := game_data.currencies.get_amount(currency_type)
	EventBus.currency_changed.emit(currency_type, old_amount, new_amount)
	return true


## 재화 조회
func get_currency(currency_type: String) -> int:
	return game_data.currencies.get_amount(currency_type)

# =============================================================================
# 메타 업그레이드
# =============================================================================

## 메타 업그레이드 구매
func purchase_meta_upgrade(upgrade_id: String) -> bool:
	var current_level := game_data.meta.get_upgrade_level(upgrade_id)
	var max_level := get_meta_upgrade_max_level(upgrade_id)

	if current_level >= max_level:
		print("[GameManager] Upgrade %s already at max level" % upgrade_id)
		return false

	var cost := get_meta_upgrade_cost(upgrade_id, current_level + 1)

	if not spend_currency("meta_points", cost):
		print("[GameManager] Not enough meta points for %s" % upgrade_id)
		return false

	game_data.meta.set_upgrade_level(upgrade_id, current_level + 1)
	print("[GameManager] Upgraded %s to level %d" % [upgrade_id, current_level + 1])
	return true


## 메타 업그레이드 비용
func get_meta_upgrade_cost(upgrade_id: String, level: int) -> int:
	# 기본 비용 + 레벨별 증가
	var base_costs := {
		"starting_plots": 50,
		"base_growth_rate": 30,
		"starting_gold": 25,
		"auto_harvest_speed": 75,
		"rare_crop_chance": 40,
		"offline_efficiency": 60,
	}

	var base := base_costs.get(upgrade_id, 50)
	return base * level


## 메타 업그레이드 최대 레벨
func get_meta_upgrade_max_level(upgrade_id: String) -> int:
	var max_levels := {
		"starting_plots": 5,
		"base_growth_rate": 10,
		"starting_gold": 10,
		"auto_harvest_speed": 5,
		"rare_crop_chance": 10,
		"offline_efficiency": 5,
	}
	return max_levels.get(upgrade_id, 10)

# =============================================================================
# 스탯 계산 헬퍼
# =============================================================================

## 성장 속도 배율 계산
func get_growth_multiplier() -> float:
	var base := 1.0

	# 메타 업그레이드
	base += game_data.meta.get_upgrade_level("base_growth_rate") * 0.05

	# 시즌 보너스
	if game_data.run.is_active:
		base *= RunManager.get_season_growth_multiplier()

	# 증강체 보너스
	base *= AugmentManager.get_stat("growth_speed_mult", 1.0)

	return base


## 수확량 배율 계산
func get_harvest_multiplier() -> float:
	var base := 1.0

	# 시즌 보너스
	if game_data.run.is_active:
		base *= RunManager.get_season_harvest_multiplier()

	# 증강체 보너스
	base *= AugmentManager.get_stat("harvest_mult", 1.0)

	return base


## 골드 배율 계산
func get_gold_multiplier() -> float:
	var base := 1.0

	# 증강체 보너스
	base *= AugmentManager.get_stat("gold_mult", 1.0)

	return base


## 희귀 작물 확률
func get_rare_crop_chance() -> float:
	var base := 0.0

	# 메타 업그레이드
	base += game_data.meta.get_upgrade_level("rare_crop_chance") * 0.01

	# 증강체 보너스
	base += AugmentManager.get_stat("rare_crop_chance", 0.0)

	return base

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_game_loaded() -> void:
	print("[GameManager] Game loaded successfully")


func _on_game_saved() -> void:
	print("[GameManager] Game saved successfully")


func _on_crop_harvested(_plot_id: int, _crop_type: String, amount: int) -> void:
	# 통계 업데이트
	game_data.stats.total_crops_harvested += 1
	game_data.stats.total_gold_from_crops += amount


func _on_quit_requested() -> void:
	print("[GameManager] Quit requested, saving...")
	request_save()
	get_tree().quit()


func _on_app_paused() -> void:
	print("[GameManager] App paused")
	request_save()
	TimeManager.record_exit_time()


func _on_app_resumed() -> void:
	print("[GameManager] App resumed")
	TimeManager.calculate_offline_rewards()
