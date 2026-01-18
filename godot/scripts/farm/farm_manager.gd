extends Node
class_name FarmManagerClass
## FarmManager - 농장 시스템 관리자
##
## 모든 농지와 작물을 중앙에서 관리합니다.

# =============================================================================
# 상수
# =============================================================================

const MAX_PLOTS: int = 25  # 최대 농지 수 (5x5)
const PLOT_UNLOCK_COSTS: Array[int] = [
	0,      # 1번 농지 (무료)
	100,    # 2번 농지
	250,    # 3번 농지
	500,    # 4번 농지
	1000,   # 5번 농지
	2000,   # 6번 농지
	4000,   # 7번 농지
	8000,   # 8번 농지
	15000,  # 9번 농지
	30000,  # 10번 농지 이후...
]

# =============================================================================
# 변수
# =============================================================================

## 농지 목록 (런타임에 UI에서 등록)
var plots: Array[FarmPlot] = []

## 자동 수확 활성화 여부
var auto_harvest_enabled: bool = false

## 자동 심기 활성화 여부
var auto_plant_enabled: bool = false

## 기본 자동 심기 작물
var auto_plant_crop_id: String = "wheat"

# =============================================================================
# 초기화
# =============================================================================

func _ready() -> void:
	print("[FarmManager] Initialized")
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.tick.connect(_on_tick)

# =============================================================================
# 농지 관리
# =============================================================================

## 농지 등록
func register_plot(plot: FarmPlot) -> void:
	if not plots.has(plot):
		plots.append(plot)
		print("[FarmManager] Registered plot %d" % plot.plot_id)


## 농지 해제
func unregister_plot(plot: FarmPlot) -> void:
	plots.erase(plot)


## 새 농지 해금
func unlock_plot(plot_id: int) -> bool:
	if plot_id >= MAX_PLOTS:
		push_warning("[FarmManager] Cannot unlock plot %d, max reached" % plot_id)
		return false

	var cost := get_plot_unlock_cost(plot_id)

	if not GameManager.spend_currency("gold", cost):
		print("[FarmManager] Not enough gold to unlock plot %d" % plot_id)
		return false

	GameManager.game_data.farm.unlocked_plots = plot_id + 1

	# 해당 농지 찾아서 해금
	for plot in plots:
		if plot.plot_id == plot_id:
			plot.set_unlocked(true)
			break

	EventBus.plot_unlocked.emit(plot_id)
	print("[FarmManager] Unlocked plot %d for %d gold" % [plot_id, cost])
	return true


## 농지 해금 비용 조회
func get_plot_unlock_cost(plot_id: int) -> int:
	if plot_id < PLOT_UNLOCK_COSTS.size():
		return PLOT_UNLOCK_COSTS[plot_id]
	else:
		# 10번 이후는 지수적 증가
		var base_cost := PLOT_UNLOCK_COSTS[-1]
		var extra_plots := plot_id - PLOT_UNLOCK_COSTS.size() + 1
		return int(base_cost * pow(2, extra_plots))

# =============================================================================
# 대량 작업
# =============================================================================

## 모든 농지 수확
func harvest_all() -> int:
	var total_harvested := 0

	for plot in plots:
		if plot.state == FarmPlot.PlotState.READY:
			total_harvested += plot.harvest()

	if total_harvested > 0:
		EventBus.auto_harvest_triggered.emit(_get_ready_plot_ids())
		print("[FarmManager] Harvested all: %d total" % total_harvested)

	return total_harvested


## 모든 빈 농지에 작물 심기
func plant_all(crop_id: String) -> int:
	var crop := CropDatabaseClass.get_crop(crop_id)
	if crop == null:
		push_error("[FarmManager] Unknown crop: %s" % crop_id)
		return 0

	var total_planted := 0

	for plot in plots:
		if plot.state == FarmPlot.PlotState.EMPTY:
			if plot.plant_crop(crop):
				total_planted += 1

	print("[FarmManager] Planted %s on %d plots" % [crop_id, total_planted])
	return total_planted


## 수확 가능한 농지 ID 목록
func _get_ready_plot_ids() -> Array[int]:
	var result: Array[int] = []
	for plot in plots:
		if plot.state == FarmPlot.PlotState.READY:
			result.append(plot.plot_id)
	return result

# =============================================================================
# 자동화
# =============================================================================

## 자동 수확 토글
func toggle_auto_harvest() -> void:
	auto_harvest_enabled = not auto_harvest_enabled
	print("[FarmManager] Auto harvest: %s" % ("ON" if auto_harvest_enabled else "OFF"))


## 자동 심기 토글
func toggle_auto_plant() -> void:
	auto_plant_enabled = not auto_plant_enabled
	print("[FarmManager] Auto plant: %s" % ("ON" if auto_plant_enabled else "OFF"))


## 자동 심기 작물 설정
func set_auto_plant_crop(crop_id: String) -> void:
	if CropDatabaseClass.has_crop(crop_id):
		auto_plant_crop_id = crop_id
		print("[FarmManager] Auto plant crop set to: %s" % crop_id)

# =============================================================================
# 통계
# =============================================================================

## 해금된 농지 수
func get_unlocked_plot_count() -> int:
	return GameManager.game_data.farm.unlocked_plots


## 현재 재배 중인 농지 수
func get_growing_plot_count() -> int:
	var count := 0
	for plot in plots:
		if plot.state in [FarmPlot.PlotState.PLANTED, FarmPlot.PlotState.GROWING]:
			count += 1
	return count


## 수확 가능한 농지 수
func get_ready_plot_count() -> int:
	var count := 0
	for plot in plots:
		if plot.state == FarmPlot.PlotState.READY:
			count += 1
	return count


## 시간당 예상 수입
func get_estimated_income_per_hour() -> float:
	var total := 0.0
	for plot in plots:
		if plot.current_crop != null:
			total += plot.current_crop.get_value_per_second() * 3600
	return total

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_tick(_delta: float) -> void:
	# 자동 수확 처리
	if auto_harvest_enabled:
		harvest_all()

	# 자동 심기 처리
	if auto_plant_enabled:
		plant_all(auto_plant_crop_id)


func _on_crop_harvested(_plot_id: int, _crop_type: String, _amount: int) -> void:
	# 자동 심기가 활성화되어 있으면 바로 다시 심기
	if auto_plant_enabled:
		for plot in plots:
			if plot.plot_id == _plot_id and plot.state == FarmPlot.PlotState.EMPTY:
				var crop := CropDatabaseClass.get_crop(auto_plant_crop_id)
				if crop:
					plot.plant_crop(crop)
				break
