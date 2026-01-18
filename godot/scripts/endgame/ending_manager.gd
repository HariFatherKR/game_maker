extends Node
class_name EndingManagerClass
## EndingManager - 엔딩 시스템
##
## 게임 엔딩 조건과 보상을 관리합니다.

# =============================================================================
# 엔딩 정의
# =============================================================================

enum EndingType {
	NORMAL,         # 일반 엔딩
	GOOD,           # 좋은 엔딩
	PERFECT,        # 완벽한 엔딩
	SECRET,         # 비밀 엔딩
	TRUE            # 진정한 엔딩
}

const ENDING_DATA := {
	EndingType.NORMAL: {
		"id": "normal",
		"name": "새로운 시작",
		"description": "황폐했던 농장에 생명이 돌아왔습니다.",
		"condition": "complete_first_year",
		"requirements": {
			"total_runs": 1,
			"crops_harvested": 100
		},
		"rewards": {
			"meta_points": 100,
			"title": "초보 농부"
		},
		"cutscene_id": "ending_normal"
	},
	EndingType.GOOD: {
		"id": "good",
		"name": "풍요로운 농장",
		"description": "농장이 번영하고, 신들이 미소 짓습니다.",
		"condition": "all_gods_favor_50",
		"requirements": {
			"total_runs": 10,
			"god_favor_total": 250  # 5신 각각 50 이상
		},
		"rewards": {
			"meta_points": 500,
			"title": "축복받은 농부",
			"unlock": "extended_gods"
		},
		"cutscene_id": "ending_good"
	},
	EndingType.PERFECT: {
		"id": "perfect",
		"name": "전설의 농부",
		"description": "당신은 전설이 되었습니다.",
		"condition": "all_achievements",
		"requirements": {
			"total_runs": 50,
			"all_crops_harvested": true,
			"all_augments_collected": true
		},
		"rewards": {
			"meta_points": 1000,
			"title": "전설의 농부",
			"unlock": "crystal_biome"
		},
		"cutscene_id": "ending_perfect"
	},
	EndingType.SECRET: {
		"id": "secret",
		"name": "어둠의 농부",
		"description": "하데스의 축복을 받았습니다...",
		"condition": "hades_max_favor",
		"requirements": {
			"hades_favor": 200,
			"hard_mode_complete": true
		},
		"rewards": {
			"meta_points": 750,
			"title": "지하의 농부",
			"unlock": "underworld_crops"
		},
		"cutscene_id": "ending_secret"
	},
	EndingType.TRUE: {
		"id": "true",
		"name": "세계수의 수호자",
		"description": "세계수를 되살리고, 세상을 구했습니다.",
		"condition": "world_tree_complete",
		"requirements": {
			"all_endings": [EndingType.NORMAL, EndingType.GOOD, EndingType.PERFECT],
			"world_tree_seed": true,
			"gaia_favor": 300
		},
		"rewards": {
			"meta_points": 5000,
			"title": "세계수의 수호자",
			"unlock": "new_game_plus"
		},
		"cutscene_id": "ending_true"
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal ending_achieved(ending_type: EndingType)
signal ending_viewed(ending_type: EndingType)
signal all_endings_complete

# =============================================================================
# 변수
# =============================================================================

## 달성한 엔딩
var achieved_endings: Array[EndingType] = []

## 시청한 엔딩
var viewed_endings: Array[EndingType] = []

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[EndingManager] Initialized")
	_connect_signals()
	_load_data()


func _connect_signals() -> void:
	EventBus.run_ended.connect(_on_run_ended)

# =============================================================================
# 엔딩 체크
# =============================================================================

## 모든 엔딩 조건 체크
func check_all_endings() -> void:
	for ending_type in ENDING_DATA:
		if not achieved_endings.has(ending_type):
			if _check_ending_condition(ending_type):
				achieve_ending(ending_type)


## 특정 엔딩 조건 체크
func _check_ending_condition(ending_type: EndingType) -> bool:
	var requirements: Dictionary = ENDING_DATA[ending_type].requirements

	match ending_type:
		EndingType.NORMAL:
			return _check_normal_ending(requirements)
		EndingType.GOOD:
			return _check_good_ending(requirements)
		EndingType.PERFECT:
			return _check_perfect_ending(requirements)
		EndingType.SECRET:
			return _check_secret_ending(requirements)
		EndingType.TRUE:
			return _check_true_ending(requirements)

	return false


func _check_normal_ending(req: Dictionary) -> bool:
	var meta := GameManager.game_data.meta
	var stats := GameManager.game_data.stats

	return meta.total_runs >= req.total_runs and stats.total_crops_harvested >= req.crops_harvested


func _check_good_ending(req: Dictionary) -> bool:
	var meta := GameManager.game_data.meta

	if meta.total_runs < req.total_runs:
		return false

	# 모든 신 호감도 50 이상 체크
	var total_favor := 0
	for god_id in meta.god_favor:
		if meta.god_favor[god_id] < 50:
			return false
		total_favor += meta.god_favor[god_id]

	return total_favor >= req.god_favor_total


func _check_perfect_ending(req: Dictionary) -> bool:
	var meta := GameManager.game_data.meta

	if meta.total_runs < req.total_runs:
		return false

	# 모든 작물 수확 체크
	if req.all_crops_harvested:
		# 작물 종류 체크 로직 (CropDatabase 참조)
		pass

	# 모든 증강체 수집 체크
	if req.all_augments_collected:
		# 증강체 수집 로직
		pass

	return true


func _check_secret_ending(req: Dictionary) -> bool:
	var meta := GameManager.game_data.meta

	var hades_favor: int = meta.god_favor.get("hades", 0)
	if hades_favor < req.hades_favor:
		return false

	if req.hard_mode_complete and not meta.get("hard_mode_complete", false):
		return false

	return true


func _check_true_ending(req: Dictionary) -> bool:
	# 다른 엔딩들 달성 체크
	for required_ending in req.all_endings:
		if not achieved_endings.has(required_ending):
			return false

	var meta := GameManager.game_data.meta

	# 세계수 씨앗 수확 체크
	if req.world_tree_seed and not meta.get("world_tree_harvested", false):
		return false

	# 가이아 호감도 체크
	var gaia_favor: int = meta.god_favor.get("gaia", 0)
	if gaia_favor < req.gaia_favor:
		return false

	return true

# =============================================================================
# 엔딩 달성
# =============================================================================

## 엔딩 달성
func achieve_ending(ending_type: EndingType) -> void:
	if achieved_endings.has(ending_type):
		return

	achieved_endings.append(ending_type)

	var ending_data: Dictionary = ENDING_DATA[ending_type]

	# 보상 지급
	_grant_ending_rewards(ending_data.rewards)

	ending_achieved.emit(ending_type)
	_save_data()

	EventBus.notification_shown.emit("🎬 엔딩 달성: %s" % ending_data.name, "success")
	print("[EndingManager] Ending achieved: %s" % ending_data.id)

	# 모든 엔딩 달성 체크
	if achieved_endings.size() == ENDING_DATA.size():
		all_endings_complete.emit()


## 보상 지급
func _grant_ending_rewards(rewards: Dictionary) -> void:
	if rewards.has("meta_points"):
		GameManager.add_currency("meta_points", rewards.meta_points)

	if rewards.has("title"):
		if not GameManager.game_data.meta.unlocked_titles.has(rewards.title):
			GameManager.game_data.meta.unlocked_titles.append(rewards.title)

	if rewards.has("unlock"):
		_process_unlock(rewards.unlock)


func _process_unlock(unlock_id: String) -> void:
	var meta := GameManager.game_data.meta

	match unlock_id:
		"extended_gods":
			meta["extended_gods_unlocked"] = true
		"crystal_biome":
			meta["crystal_biome_unlocked"] = true
		"underworld_crops":
			meta["underworld_crops_unlocked"] = true
		"new_game_plus":
			meta["new_game_plus_unlocked"] = true

# =============================================================================
# 엔딩 시청
# =============================================================================

## 엔딩 시청 표시
func mark_ending_viewed(ending_type: EndingType) -> void:
	if not viewed_endings.has(ending_type):
		viewed_endings.append(ending_type)
		ending_viewed.emit(ending_type)
		_save_data()


## 엔딩 시청 여부
func has_viewed_ending(ending_type: EndingType) -> bool:
	return viewed_endings.has(ending_type)

# =============================================================================
# 정보 조회
# =============================================================================

## 엔딩 달성 여부
func has_achieved_ending(ending_type: EndingType) -> bool:
	return achieved_endings.has(ending_type)


## 엔딩 정보 가져오기
func get_ending_data(ending_type: EndingType) -> Dictionary:
	var data: Dictionary = ENDING_DATA[ending_type].duplicate()
	data["achieved"] = achieved_endings.has(ending_type)
	data["viewed"] = viewed_endings.has(ending_type)
	return data


## 모든 엔딩 정보
func get_all_endings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for ending_type in ENDING_DATA:
		var data := get_ending_data(ending_type)
		data["ending_type"] = ending_type
		result.append(data)

	return result


## 달성률
func get_completion_percentage() -> float:
	return float(achieved_endings.size()) / float(ENDING_DATA.size()) * 100.0

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_run_ended(_run_id: int, _meta_points: int) -> void:
	# 런 종료 시 엔딩 조건 체크
	check_all_endings()

# =============================================================================
# 저장/로드
# =============================================================================

func _load_data() -> void:
	var ending_data: Dictionary = GameManager.game_data.meta.get("endings", {})

	achieved_endings.clear()
	for ending_id in ending_data.get("achieved", []):
		var ending_type := _get_ending_type_by_id(ending_id)
		if ending_type != -1:
			achieved_endings.append(ending_type)

	viewed_endings.clear()
	for ending_id in ending_data.get("viewed", []):
		var ending_type := _get_ending_type_by_id(ending_id)
		if ending_type != -1:
			viewed_endings.append(ending_type)


func _save_data() -> void:
	var achieved_ids: Array = []
	for ending in achieved_endings:
		achieved_ids.append(ENDING_DATA[ending].id)

	var viewed_ids: Array = []
	for ending in viewed_endings:
		viewed_ids.append(ENDING_DATA[ending].id)

	GameManager.game_data.meta["endings"] = {
		"achieved": achieved_ids,
		"viewed": viewed_ids
	}


func _get_ending_type_by_id(ending_id: String) -> int:
	for ending_type in ENDING_DATA:
		if ENDING_DATA[ending_type].id == ending_id:
			return ending_type
	return -1
