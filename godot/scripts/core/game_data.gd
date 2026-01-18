extends RefCounted
class_name GameData
## GameData - 게임 저장 데이터 구조체
##
## 모든 게임 상태를 담는 메인 데이터 클래스입니다.

# =============================================================================
# 상수
# =============================================================================

const CURRENT_VERSION: String = "1.0.0"

# =============================================================================
# 데이터 필드
# =============================================================================

## 버전 정보
var version: String = CURRENT_VERSION
var last_save_time: int = 0

## 플레이어 정보
var player_name: String = "Farmer"

## 재화
var currencies: CurrencyData = CurrencyData.new()

## 농장 데이터
var farm: FarmData = FarmData.new()

## 런 데이터 (현재 진행 중인 런)
var run: RunData = RunData.new()

## 메타 진행도
var meta: MetaProgressData = MetaProgressData.new()

## 통계
var stats: StatsData = StatsData.new()

## 설정
var settings: SettingsData = SettingsData.new()

# =============================================================================
# 직렬화
# =============================================================================

func to_dict() -> Dictionary:
	return {
		"version": version,
		"last_save_time": last_save_time,
		"player_name": player_name,
		"currencies": currencies.to_dict(),
		"farm": farm.to_dict(),
		"run": run.to_dict(),
		"meta": meta.to_dict(),
		"stats": stats.to_dict(),
		"settings": settings.to_dict(),
	}


static func from_dict(data: Dictionary):
	var script = load("res://scripts/core/game_data.gd")
	var result = script.new()

	result.version = data.get("version", CURRENT_VERSION)
	result.last_save_time = data.get("last_save_time", 0)
	result.player_name = data.get("player_name", "Farmer")

	if data.has("currencies"):
		result.currencies = CurrencyData.from_dict(data.currencies)
	if data.has("farm"):
		result.farm = FarmData.from_dict(data.farm)
	if data.has("run"):
		result.run = RunData.from_dict(data.run)
	if data.has("meta"):
		result.meta = MetaProgressData.from_dict(data.meta)
	if data.has("stats"):
		result.stats = StatsData.from_dict(data.stats)
	if data.has("settings"):
		result.settings = SettingsData.from_dict(data.settings)

	return result


# =============================================================================
# CurrencyData
# =============================================================================

class CurrencyData extends RefCounted:
	var gold: int = 100
	var gems: int = 0
	var seeds: int = 10
	var meta_points: int = 0

	func get_amount(currency_type: String) -> int:
		match currency_type:
			"gold": return gold
			"gems": return gems
			"seeds": return seeds
			"meta_points": return meta_points
		return 0

	func set_amount(currency_type: String, amount: int) -> void:
		match currency_type:
			"gold": gold = amount
			"gems": gems = amount
			"seeds": seeds = amount
			"meta_points": meta_points = amount

	func add(currency_type: String, amount: int) -> void:
		set_amount(currency_type, get_amount(currency_type) + amount)

	func spend(currency_type: String, amount: int) -> bool:
		var current := get_amount(currency_type)
		if current < amount:
			return false
		set_amount(currency_type, current - amount)
		return true

	func to_dict() -> Dictionary:
		return {
			"gold": gold,
			"gems": gems,
			"seeds": seeds,
			"meta_points": meta_points,
		}

	static func from_dict(data: Dictionary) -> CurrencyData:
		var result := CurrencyData.new()
		result.gold = data.get("gold", 100)
		result.gems = data.get("gems", 0)
		result.seeds = data.get("seeds", 10)
		result.meta_points = data.get("meta_points", 0)
		return result


# =============================================================================
# FarmData
# =============================================================================

class FarmData extends RefCounted:
	var unlocked_plots: int = 1
	var plots: Array[PlotSaveData] = []
	var auto_harvest_enabled: bool = false
	var auto_plant_enabled: bool = false
	var auto_plant_crop_id: String = "wheat"

	func to_dict() -> Dictionary:
		var plots_array := []
		for plot in plots:
			plots_array.append(plot.to_dict())

		return {
			"unlocked_plots": unlocked_plots,
			"plots": plots_array,
			"auto_harvest_enabled": auto_harvest_enabled,
			"auto_plant_enabled": auto_plant_enabled,
			"auto_plant_crop_id": auto_plant_crop_id,
		}

	static func from_dict(data: Dictionary) -> FarmData:
		var result := FarmData.new()
		result.unlocked_plots = data.get("unlocked_plots", 1)
		result.auto_harvest_enabled = data.get("auto_harvest_enabled", false)
		result.auto_plant_enabled = data.get("auto_plant_enabled", false)
		result.auto_plant_crop_id = data.get("auto_plant_crop_id", "wheat")

		if data.has("plots"):
			for plot_data in data.plots:
				result.plots.append(PlotSaveData.from_dict(plot_data))

		return result


class PlotSaveData extends RefCounted:
	var plot_id: int = 0
	var crop_id: String = ""
	var growth_progress: float = 0.0
	var planted_at: int = 0

	func to_dict() -> Dictionary:
		return {
			"plot_id": plot_id,
			"crop_id": crop_id,
			"growth_progress": growth_progress,
			"planted_at": planted_at,
		}

	static func from_dict(data: Dictionary) -> PlotSaveData:
		var result := PlotSaveData.new()
		result.plot_id = data.get("plot_id", 0)
		result.crop_id = data.get("crop_id", "")
		result.growth_progress = data.get("growth_progress", 0.0)
		result.planted_at = data.get("planted_at", 0)
		return result


# =============================================================================
# RunData
# =============================================================================

class RunData extends RefCounted:
	var is_active: bool = false
	var run_number: int = 0
	var current_season: int = 0  # 0=봄, 1=여름, 2=가을, 3=겨울
	var season_time_remaining: float = 300.0  # 5분
	var total_run_time: float = 0.0

	## 현재 런 증강체
	var active_augments: Array[String] = []

	## 현재 런 통계
	var run_gold: int = 0
	var run_harvests: int = 0
	var run_synergies: Array[String] = []

	## 목표 달성
	var completed_objectives: Array[String] = []

	func reset() -> void:
		is_active = false
		current_season = 0
		season_time_remaining = 300.0
		total_run_time = 0.0
		active_augments.clear()
		run_gold = 0
		run_harvests = 0
		run_synergies.clear()
		completed_objectives.clear()

	func to_dict() -> Dictionary:
		return {
			"is_active": is_active,
			"run_number": run_number,
			"current_season": current_season,
			"season_time_remaining": season_time_remaining,
			"total_run_time": total_run_time,
			"active_augments": active_augments.duplicate(),
			"run_gold": run_gold,
			"run_harvests": run_harvests,
			"run_synergies": run_synergies.duplicate(),
			"completed_objectives": completed_objectives.duplicate(),
		}

	static func from_dict(data: Dictionary) -> RunData:
		var result := RunData.new()
		result.is_active = data.get("is_active", false)
		result.run_number = data.get("run_number", 0)
		result.current_season = data.get("current_season", 0)
		result.season_time_remaining = data.get("season_time_remaining", 300.0)
		result.total_run_time = data.get("total_run_time", 0.0)

		if data.has("active_augments"):
			for aug in data.active_augments:
				result.active_augments.append(aug)

		result.run_gold = data.get("run_gold", 0)
		result.run_harvests = data.get("run_harvests", 0)

		if data.has("run_synergies"):
			for syn in data.run_synergies:
				result.run_synergies.append(syn)

		if data.has("completed_objectives"):
			for obj in data.completed_objectives:
				result.completed_objectives.append(obj)

		return result


# =============================================================================
# MetaProgressData
# =============================================================================

class MetaProgressData extends RefCounted:
	var total_runs: int = 0
	var total_gold_earned: int = 0
	var total_harvests: int = 0
	var best_run_gold: int = 0
	var best_run_harvests: int = 0

	## 영구 업그레이드 레벨
	var upgrades: Dictionary = {
		"starting_plots": 0,      # 최대 5
		"base_growth_rate": 0,    # 최대 10
		"starting_gold": 0,       # 최대 10
		"auto_harvest_speed": 0,  # 최대 5
		"rare_crop_chance": 0,    # 최대 10
		"offline_efficiency": 0,  # 최대 5
	}

	## 신 호감도
	var god_affinity: Dictionary = {
		"ceres": 0,
		"plutus": 0,
		"chronos": 0,
		"tyche": 0,
		"hephaestus": 0,
	}

	## 잠금해제된 펫
	var unlocked_pets: Array[String] = ["cat"]
	var active_pet: String = "cat"

	## 잠금해제된 작물
	var unlocked_crops: Array[String] = ["wheat", "carrot", "potato"]

	## 완료한 엔딩
	var completed_endings: Array[String] = []

	func get_upgrade_level(upgrade_id: String) -> int:
		return upgrades.get(upgrade_id, 0)

	func set_upgrade_level(upgrade_id: String, level: int) -> void:
		upgrades[upgrade_id] = level

	func get_god_affinity(god_id: String) -> int:
		return god_affinity.get(god_id, 0)

	func add_god_affinity(god_id: String, amount: int) -> void:
		god_affinity[god_id] = god_affinity.get(god_id, 0) + amount

	func to_dict() -> Dictionary:
		return {
			"total_runs": total_runs,
			"total_gold_earned": total_gold_earned,
			"total_harvests": total_harvests,
			"best_run_gold": best_run_gold,
			"best_run_harvests": best_run_harvests,
			"upgrades": upgrades.duplicate(),
			"god_affinity": god_affinity.duplicate(),
			"unlocked_pets": unlocked_pets.duplicate(),
			"active_pet": active_pet,
			"unlocked_crops": unlocked_crops.duplicate(),
			"completed_endings": completed_endings.duplicate(),
		}

	static func from_dict(data: Dictionary) -> MetaProgressData:
		var result := MetaProgressData.new()
		result.total_runs = data.get("total_runs", 0)
		result.total_gold_earned = data.get("total_gold_earned", 0)
		result.total_harvests = data.get("total_harvests", 0)
		result.best_run_gold = data.get("best_run_gold", 0)
		result.best_run_harvests = data.get("best_run_harvests", 0)

		if data.has("upgrades"):
			for key in data.upgrades:
				result.upgrades[key] = data.upgrades[key]

		if data.has("god_affinity"):
			for key in data.god_affinity:
				result.god_affinity[key] = data.god_affinity[key]

		if data.has("unlocked_pets"):
			result.unlocked_pets.clear()
			for pet in data.unlocked_pets:
				result.unlocked_pets.append(pet)

		result.active_pet = data.get("active_pet", "cat")

		if data.has("unlocked_crops"):
			result.unlocked_crops.clear()
			for crop in data.unlocked_crops:
				result.unlocked_crops.append(crop)

		if data.has("completed_endings"):
			result.completed_endings.clear()
			for ending in data.completed_endings:
				result.completed_endings.append(ending)

		return result


# =============================================================================
# StatsData
# =============================================================================

class StatsData extends RefCounted:
	var playtime_seconds: int = 0
	var session_count: int = 0
	var first_play_time: int = 0

	## 농사 통계
	var total_crops_planted: int = 0
	var total_crops_harvested: int = 0
	var total_gold_from_crops: int = 0

	## 증강체 통계
	var total_augments_selected: int = 0
	var favorite_augment: String = ""
	var synergies_activated: int = 0

	## 위협 통계
	var threats_encountered: int = 0
	var threats_survived: int = 0

	func to_dict() -> Dictionary:
		return {
			"playtime_seconds": playtime_seconds,
			"session_count": session_count,
			"first_play_time": first_play_time,
			"total_crops_planted": total_crops_planted,
			"total_crops_harvested": total_crops_harvested,
			"total_gold_from_crops": total_gold_from_crops,
			"total_augments_selected": total_augments_selected,
			"favorite_augment": favorite_augment,
			"synergies_activated": synergies_activated,
			"threats_encountered": threats_encountered,
			"threats_survived": threats_survived,
		}

	static func from_dict(data: Dictionary) -> StatsData:
		var result := StatsData.new()
		result.playtime_seconds = data.get("playtime_seconds", 0)
		result.session_count = data.get("session_count", 0)
		result.first_play_time = data.get("first_play_time", 0)
		result.total_crops_planted = data.get("total_crops_planted", 0)
		result.total_crops_harvested = data.get("total_crops_harvested", 0)
		result.total_gold_from_crops = data.get("total_gold_from_crops", 0)
		result.total_augments_selected = data.get("total_augments_selected", 0)
		result.favorite_augment = data.get("favorite_augment", "")
		result.synergies_activated = data.get("synergies_activated", 0)
		result.threats_encountered = data.get("threats_encountered", 0)
		result.threats_survived = data.get("threats_survived", 0)
		return result


# =============================================================================
# SettingsData
# =============================================================================

class SettingsData extends RefCounted:
	var master_volume: float = 1.0
	var music_volume: float = 0.8
	var sfx_volume: float = 1.0
	var vibration_enabled: bool = true
	var notifications_enabled: bool = true
	var language: String = "ko"
	var auto_save_interval: int = 60  # 초

	func to_dict() -> Dictionary:
		return {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"vibration_enabled": vibration_enabled,
			"notifications_enabled": notifications_enabled,
			"language": language,
			"auto_save_interval": auto_save_interval,
		}

	static func from_dict(data: Dictionary) -> SettingsData:
		var result := SettingsData.new()
		result.master_volume = data.get("master_volume", 1.0)
		result.music_volume = data.get("music_volume", 0.8)
		result.sfx_volume = data.get("sfx_volume", 1.0)
		result.vibration_enabled = data.get("vibration_enabled", true)
		result.notifications_enabled = data.get("notifications_enabled", true)
		result.language = data.get("language", "ko")
		result.auto_save_interval = data.get("auto_save_interval", 60)
		return result
