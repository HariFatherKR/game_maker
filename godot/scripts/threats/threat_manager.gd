extends Node
class_name ThreatManagerClass
## ThreatManager - 위협 시스템 관리
##
## 해충, 재해 등 농장에 대한 위협을 관리합니다.

# =============================================================================
# 상수
# =============================================================================

const PEST_CHECK_INTERVAL: float = 30.0  # 30초마다 해충 체크
const DISASTER_CHECK_INTERVAL: float = 60.0  # 60초마다 재해 체크

# =============================================================================
# 해충 정의
# =============================================================================

enum PestType {
	APHID,      # 진딧물 - 성장 속도 감소
	LOCUST,     # 메뚜기 - 작물 먹어치움
	MOLE,       # 두더지 - 뿌리 손상
	CROW,       # 까마귀 - 씨앗 훔쳐감
	CATERPILLAR # 애벌레 - 잎 손상
}

const PEST_DATA := {
	PestType.APHID: {
		"id": "aphid",
		"name": "진딧물",
		"description": "작물의 성장 속도를 50% 감소시킵니다.",
		"effect": "growth_penalty",
		"value": 0.5,
		"duration": 60.0,
		"spawn_weight": 30
	},
	PestType.LOCUST: {
		"id": "locust",
		"name": "메뚜기",
		"description": "작물의 수확량을 30% 감소시킵니다.",
		"effect": "yield_penalty",
		"value": 0.3,
		"duration": 45.0,
		"spawn_weight": 25
	},
	PestType.MOLE: {
		"id": "mole",
		"name": "두더지",
		"description": "농지를 일시적으로 사용 불가능하게 만듭니다.",
		"effect": "plot_disable",
		"value": 1.0,
		"duration": 30.0,
		"spawn_weight": 15
	},
	PestType.CROW: {
		"id": "crow",
		"name": "까마귀",
		"description": "씨앗을 훔쳐갑니다.",
		"effect": "steal_seeds",
		"value": 3,
		"duration": 0.0,  # 즉시 효과
		"spawn_weight": 20
	},
	PestType.CATERPILLAR: {
		"id": "caterpillar",
		"name": "애벌레",
		"description": "작물 성장을 20% 후퇴시킵니다.",
		"effect": "growth_regress",
		"value": 0.2,
		"duration": 0.0,  # 즉시 효과
		"spawn_weight": 10
	}
}

# =============================================================================
# 재해 정의
# =============================================================================

enum DisasterType {
	DROUGHT,    # 가뭄 - 여름
	FROST,      # 서리 - 겨울
	STORM,      # 폭풍 - 가을
	FLOOD,      # 홍수 - 봄
	HEATWAVE    # 폭염 - 여름
}

const DISASTER_DATA := {
	DisasterType.DROUGHT: {
		"id": "drought",
		"name": "가뭄",
		"description": "모든 작물의 성장 속도가 70% 감소합니다.",
		"season": 1,  # 여름
		"effect": "global_growth_penalty",
		"value": 0.7,
		"duration": 120.0,
		"spawn_chance": 0.15
	},
	DisasterType.FROST: {
		"id": "frost",
		"name": "서리",
		"description": "보호되지 않은 작물이 피해를 입습니다.",
		"season": 3,  # 겨울
		"effect": "crop_damage",
		"value": 0.5,
		"duration": 90.0,
		"spawn_chance": 0.20
	},
	DisasterType.STORM: {
		"id": "storm",
		"name": "폭풍",
		"description": "일부 작물이 손상될 수 있습니다.",
		"season": 2,  # 가을
		"effect": "random_crop_damage",
		"value": 0.3,
		"duration": 60.0,
		"spawn_chance": 0.10
	},
	DisasterType.FLOOD: {
		"id": "flood",
		"name": "홍수",
		"description": "농지 일부가 일시적으로 침수됩니다.",
		"season": 0,  # 봄
		"effect": "plot_flood",
		"value": 3,  # 침수 농지 수
		"duration": 90.0,
		"spawn_chance": 0.10
	},
	DisasterType.HEATWAVE: {
		"id": "heatwave",
		"name": "폭염",
		"description": "물을 더 자주 주어야 합니다.",
		"season": 1,  # 여름
		"effect": "water_requirement",
		"value": 2.0,
		"duration": 150.0,
		"spawn_chance": 0.12
	}
}

# =============================================================================
# 변수
# =============================================================================

## 현재 활성 해충 {plot_id: {pest_type, remaining_time}}
var active_pests: Dictionary = {}

## 현재 활성 재해
var active_disaster: Dictionary = {}

## 타이머
var _pest_timer: float = 0.0
var _disaster_timer: float = 0.0

## 위협 저항 (증강체/펫 보너스)
var pest_resistance: float = 0.0
var disaster_resistance: float = 0.0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[ThreatManager] Initialized")
	_connect_signals()


func _connect_signals() -> void:
	EventBus.tick.connect(_on_tick)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)

# =============================================================================
# 메인 업데이트
# =============================================================================

func _on_tick(delta: float) -> void:
	if not GameManager.game_data.run.is_active:
		return

	_update_active_threats(delta)
	_check_new_threats(delta)


func _update_active_threats(delta: float) -> void:
	# 해충 업데이트
	var expired_pests: Array[int] = []
	for plot_id in active_pests:
		active_pests[plot_id].remaining_time -= delta
		if active_pests[plot_id].remaining_time <= 0:
			expired_pests.append(plot_id)

	for plot_id in expired_pests:
		_remove_pest(plot_id)

	# 재해 업데이트
	if not active_disaster.is_empty():
		active_disaster.remaining_time -= delta
		if active_disaster.remaining_time <= 0:
			_end_disaster()


func _check_new_threats(delta: float) -> void:
	# 해충 체크
	_pest_timer += delta
	if _pest_timer >= PEST_CHECK_INTERVAL:
		_pest_timer = 0.0
		_try_spawn_pest()

	# 재해 체크
	_disaster_timer += delta
	if _disaster_timer >= DISASTER_CHECK_INTERVAL:
		_disaster_timer = 0.0
		_try_spawn_disaster()

# =============================================================================
# 해충 시스템
# =============================================================================

func _try_spawn_pest() -> void:
	# 저항 체크
	if randf() < pest_resistance:
		return

	# 농지 수에 따른 스폰 확률
	var unlocked_plots: int = GameManager.game_data.farm.unlocked_plots
	var spawn_chance := 0.05 + (unlocked_plots * 0.02)  # 기본 5% + 농지당 2%

	if randf() > spawn_chance:
		return

	# 빈 농지가 아닌 곳에 스폰
	var available_plots := _get_occupied_plots()
	if available_plots.is_empty():
		return

	var target_plot: int = available_plots[randi() % available_plots.size()]

	# 이미 해충이 있는 농지 스킵
	if active_pests.has(target_plot):
		return

	# 해충 선택 (가중치 기반)
	var pest_type := _select_random_pest()
	_spawn_pest(target_plot, pest_type)


func _select_random_pest() -> PestType:
	var total_weight := 0.0
	for pest_type in PEST_DATA:
		total_weight += PEST_DATA[pest_type].spawn_weight

	var roll := randf() * total_weight
	var current := 0.0

	for pest_type in PEST_DATA:
		current += PEST_DATA[pest_type].spawn_weight
		if roll <= current:
			return pest_type

	return PestType.APHID


func _spawn_pest(plot_id: int, pest_type: PestType) -> void:
	var pest_data: Dictionary = PEST_DATA[pest_type]

	active_pests[plot_id] = {
		"pest_type": pest_type,
		"remaining_time": pest_data.duration
	}

	# 즉시 효과 적용
	_apply_pest_effect(plot_id, pest_data)

	EventBus.threat_spawned.emit(pest_data.id, plot_id)
	EventBus.notification_shown.emit("🐛 %s 발생! 농지 %d" % [pest_data.name, plot_id + 1], "warning")

	print("[ThreatManager] Pest spawned: %s on plot %d" % [pest_data.id, plot_id])


func _apply_pest_effect(plot_id: int, pest_data: Dictionary) -> void:
	match pest_data.effect:
		"steal_seeds":
			var stolen: int = mini(pest_data.value, GameManager.get_currency("seeds"))
			GameManager.spend_currency("seeds", stolen)
			print("[ThreatManager] Crow stole %d seeds" % stolen)
		"growth_regress":
			# 성장 후퇴 (FarmPlot에서 처리)
			pass


func _remove_pest(plot_id: int) -> void:
	if not active_pests.has(plot_id):
		return

	var pest_type: PestType = active_pests[plot_id].pest_type
	var pest_data: Dictionary = PEST_DATA[pest_type]

	active_pests.erase(plot_id)

	EventBus.threat_resolved.emit(pest_data.id, true)
	print("[ThreatManager] Pest removed from plot %d" % plot_id)


## 수동으로 해충 제거 (아이템 사용 등)
func remove_pest_manually(plot_id: int) -> bool:
	if not active_pests.has(plot_id):
		return false

	_remove_pest(plot_id)
	GameManager.game_data.stats.threats_survived += 1
	return true

# =============================================================================
# 재해 시스템
# =============================================================================

func _try_spawn_disaster() -> void:
	# 이미 재해 진행 중이면 스킵
	if not active_disaster.is_empty():
		return

	# 저항 체크
	if randf() < disaster_resistance:
		return

	var current_season: int = GameManager.game_data.run.current_season

	# 현재 시즌에 맞는 재해만 체크
	for disaster_type in DISASTER_DATA:
		var data: Dictionary = DISASTER_DATA[disaster_type]
		if data.season != current_season:
			continue

		if randf() < data.spawn_chance:
			_start_disaster(disaster_type)
			break


func _start_disaster(disaster_type: DisasterType) -> void:
	var disaster_data: Dictionary = DISASTER_DATA[disaster_type]

	active_disaster = {
		"disaster_type": disaster_type,
		"remaining_time": disaster_data.duration
	}

	GameManager.game_data.stats.threats_encountered += 1

	EventBus.disaster_started.emit(disaster_data.id)
	EventBus.notification_shown.emit("⚠️ 재해: %s!" % disaster_data.name, "error")

	print("[ThreatManager] Disaster started: %s" % disaster_data.id)


func _end_disaster() -> void:
	if active_disaster.is_empty():
		return

	var disaster_type: DisasterType = active_disaster.disaster_type
	var disaster_data: Dictionary = DISASTER_DATA[disaster_type]

	active_disaster.clear()

	GameManager.game_data.stats.threats_survived += 1

	EventBus.disaster_ended.emit(disaster_data.id)
	EventBus.notification_shown.emit("✅ %s이(가) 끝났습니다" % disaster_data.name, "success")

	print("[ThreatManager] Disaster ended: %s" % disaster_data.id)

# =============================================================================
# 효과 조회
# =============================================================================

## 농지의 성장 페널티 가져오기
func get_growth_penalty(plot_id: int) -> float:
	var penalty := 0.0

	# 해충 페널티
	if active_pests.has(plot_id):
		var pest_type: PestType = active_pests[plot_id].pest_type
		var pest_data: Dictionary = PEST_DATA[pest_type]
		if pest_data.effect == "growth_penalty":
			penalty += pest_data.value

	# 재해 페널티
	if not active_disaster.is_empty():
		var disaster_type: DisasterType = active_disaster.disaster_type
		var disaster_data: Dictionary = DISASTER_DATA[disaster_type]
		if disaster_data.effect == "global_growth_penalty":
			penalty += disaster_data.value

	return penalty


## 농지의 수확량 페널티 가져오기
func get_yield_penalty(plot_id: int) -> float:
	var penalty := 0.0

	# 해충 페널티
	if active_pests.has(plot_id):
		var pest_type: PestType = active_pests[plot_id].pest_type
		var pest_data: Dictionary = PEST_DATA[pest_type]
		if pest_data.effect == "yield_penalty":
			penalty += pest_data.value

	return penalty


## 농지가 비활성화되었는지 확인
func is_plot_disabled(plot_id: int) -> bool:
	if active_pests.has(plot_id):
		var pest_type: PestType = active_pests[plot_id].pest_type
		var pest_data: Dictionary = PEST_DATA[pest_type]
		if pest_data.effect == "plot_disable":
			return true

	if not active_disaster.is_empty():
		var disaster_type: DisasterType = active_disaster.disaster_type
		var disaster_data: Dictionary = DISASTER_DATA[disaster_type]
		if disaster_data.effect == "plot_flood":
			# 침수 농지인지 체크 (간단히 랜덤)
			pass

	return false

# =============================================================================
# 헬퍼
# =============================================================================

func _get_occupied_plots() -> Array[int]:
	var result: Array[int] = []
	for plot in FarmManager.plots:
		if plot.state in [FarmPlot.PlotState.PLANTED, FarmPlot.PlotState.GROWING]:
			result.append(plot.plot_id)
	return result

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_season_changed(_old: int, _new: int) -> void:
	# 시즌 변경 시 일부 재해 즉시 종료
	if not active_disaster.is_empty():
		var disaster_type: DisasterType = active_disaster.disaster_type
		var disaster_data: Dictionary = DISASTER_DATA[disaster_type]
		if disaster_data.season != _new:
			_end_disaster()


func _on_run_started(_run_id: int) -> void:
	active_pests.clear()
	active_disaster.clear()
	_pest_timer = 0.0
	_disaster_timer = 0.0


func _on_run_ended(_run_id: int, _meta_points: int) -> void:
	active_pests.clear()
	active_disaster.clear()
