extends Control
class_name FarmPlot
## FarmPlot - 개별 농지 클래스
##
## 농지의 상태를 관리하고 작물을 재배합니다.

# =============================================================================
# 클래스 프리로드
# =============================================================================

const CropDatabaseScript := preload("res://scripts/farm/crop_database.gd")

var _crop_db_instance = null

func _get_crop_db():
	if _crop_db_instance == null:
		_crop_db_instance = CropDatabaseScript.new()
	return _crop_db_instance

# =============================================================================
# 시그널
# =============================================================================

signal clicked(plot: FarmPlot)
signal crop_ready(plot: FarmPlot)

# =============================================================================
# 상수
# =============================================================================

const COLORS := {
	"empty": Color(0.4, 0.3, 0.2),        # 빈 땅
	"planted": Color(0.3, 0.5, 0.2),       # 작물 심어짐
	"growing": Color(0.4, 0.6, 0.3),       # 성장 중
	"ready": Color(0.2, 0.8, 0.3),         # 수확 가능
	"locked": Color(0.2, 0.2, 0.2, 0.5)    # 잠금
}

# =============================================================================
# 상태 열거형
# =============================================================================

enum PlotState {
	LOCKED,
	EMPTY,
	PLANTED,
	GROWING,
	READY
}

# =============================================================================
# 변수
# =============================================================================

## 농지 ID
var plot_id: int = 0

## 현재 상태
var state: PlotState = PlotState.EMPTY

## 해금 여부
var is_unlocked: bool = false

## 현재 작물
var current_crop = null

## 성장률 (0.0 ~ 1.0)
var growth_progress: float = 0.0

# =============================================================================
# 노드 참조
# =============================================================================

var _background: ColorRect
var _progress_bar: ProgressBar
var _label: Label
var _button: Button

# =============================================================================
# 라이프사이클
# =============================================================================

func _init() -> void:
	_setup_ui()


func _ready() -> void:
	_update_visual()
	EventBus.tick.connect(_on_tick)


func _setup_ui() -> void:
	# 배경
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.color = COLORS.empty
	add_child(_background)

	# 버튼 (클릭 감지용)
	_button = Button.new()
	_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_button.flat = true
	_button.pressed.connect(_on_pressed)
	add_child(_button)

	# 진행률 바
	_progress_bar = ProgressBar.new()
	_progress_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_progress_bar.offset_top = -20
	_progress_bar.offset_left = 10
	_progress_bar.offset_right = -10
	_progress_bar.offset_bottom = -10
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	add_child(_progress_bar)

	# 라벨
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.text = "Empty"
	add_child(_label)

# =============================================================================
# 공개 API
# =============================================================================

## 해금 상태 설정
func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked
	if unlocked:
		state = PlotState.EMPTY
	else:
		state = PlotState.LOCKED
	_update_visual()


## 작물 심기
func plant_crop(crop) -> bool:
	if state != PlotState.EMPTY:
		return false

	if not GameManager.spend_currency("seeds", 1):
		print("[FarmPlot] Not enough seeds!")
		return false

	current_crop = crop
	growth_progress = 0.0
	state = PlotState.PLANTED

	EventBus.crop_planted.emit(plot_id, crop.crop_type)
	_update_visual()

	print("[FarmPlot] Planted %s on plot %d" % [crop.crop_type, plot_id])
	return true


## 수확
func harvest() -> int:
	if state != PlotState.READY:
		return 0

	var yield_amount := _calculate_yield()

	# 골드 배율 적용
	var gold_mult := 1.0
	gold_mult += AugmentManager.get_stat("gold_multiplier", 0.0)
	gold_mult += AugmentManager.get_stat("sell_price", 0.0)

	# 미다스 축복 체크
	if AugmentManager.has_effect("midas_blessing"):
		gold_mult *= 3.0
		# 10% 확률로 작물 소멸 (다음 수확 불가)
		if randf() < 0.1:
			print("[FarmPlot] Midas curse activated! Crop destroyed.")

	var gold_value := int(current_crop.base_value * yield_amount * gold_mult)
	GameManager.add_currency("gold", gold_value)

	# 통계 업데이트
	GameManager.game_data.stats.total_crops_harvested += 1
	GameManager.game_data.stats.total_gold_from_crops += gold_value

	EventBus.crop_harvested.emit(plot_id, current_crop.crop_type, gold_value)

	print("[FarmPlot] Harvested %d %s for %d gold (x%.1f mult)" % [
		yield_amount, current_crop.crop_type, gold_value, gold_mult
	])

	# 상태 초기화
	current_crop = null
	growth_progress = 0.0
	state = PlotState.EMPTY
	_update_visual()

	return gold_value


## 성장 적용 (틱당)
func apply_growth(delta: float) -> void:
	if state not in [PlotState.PLANTED, PlotState.GROWING]:
		return

	if current_crop == null:
		return

	# 성장률 계산
	var growth_rate := _calculate_growth_rate()
	growth_progress += growth_rate * delta

	# 상태 업데이트
	if growth_progress >= 1.0:
		growth_progress = 1.0
		state = PlotState.READY
		crop_ready.emit(self)
	elif growth_progress > 0.1:
		state = PlotState.GROWING

	_update_visual()
	EventBus.crop_grown.emit(plot_id, growth_progress)


## 세이브용 데이터 추출
func get_save_data() -> Dictionary:
	return {
		"id": plot_id,
		"unlocked": is_unlocked,
		"state": state,
		"crop": current_crop.crop_type if current_crop else null,
		"growth": growth_progress
	}


## 세이브 데이터 로드
func load_save_data(data: Dictionary) -> void:
	plot_id = data.get("id", 0)
	is_unlocked = data.get("unlocked", false)
	growth_progress = data.get("growth", 0.0)

	var crop_type: String = data.get("crop", "")
	if crop_type != "":
		current_crop = _get_crop_db().get_crop(crop_type)

	state = data.get("state", PlotState.LOCKED if not is_unlocked else PlotState.EMPTY)
	_update_visual()

# =============================================================================
# 내부 로직
# =============================================================================

## 성장률 계산 (증강체 보너스 포함)
func _calculate_growth_rate() -> float:
	if current_crop == null:
		return 0.0

	var base_rate = 1.0 / current_crop.grow_time
	var augment_bonus := _get_augment_growth_bonus()

	return base_rate * (1.0 + augment_bonus)


## 수확량 계산
func _calculate_yield() -> int:
	if current_crop == null:
		return 0

	var base_yield = current_crop.base_yield
	var augment_bonus := _get_augment_yield_bonus()

	return int(base_yield * (1.0 + augment_bonus))


## 증강체 성장 보너스 계산
func _get_augment_growth_bonus() -> float:
	var bonus := 0.0

	# 메타 업그레이드 보너스
	bonus += GameManager.game_data.meta.get_upgrade_level("base_growth_rate") * 0.05

	# 증강체 보너스
	bonus += AugmentManager.get_stat("growth_speed", 0.0)
	bonus += AugmentManager.get_stat("growth_flat", 0.0) / 100.0  # flat to percentage

	# 시즌 보너스
	if GameManager.game_data.run.is_active:
		bonus += RunManager.get_season_growth_multiplier() - 1.0

	return bonus


## 증강체 수확량 보너스 계산
func _get_augment_yield_bonus() -> float:
	var bonus := 0.0

	# 증강체 보너스
	bonus += AugmentManager.get_stat("yield_bonus", 0.0)

	# 시즌 보너스
	if GameManager.game_data.run.is_active:
		bonus += RunManager.get_season_harvest_multiplier() - 1.0

	# 더블 수확 체크
	var double_chance := AugmentManager.get_stat("double_yield_chance", 0.0)
	if randf() < double_chance:
		bonus += 1.0  # 더블 = +100%

	return bonus


## 비주얼 업데이트
func _update_visual() -> void:
	match state:
		PlotState.LOCKED:
			_background.color = COLORS.locked
			_label.text = "Locked"
			_progress_bar.visible = false
			_button.disabled = true
		PlotState.EMPTY:
			_background.color = COLORS.empty
			_label.text = "Empty\n(Click)"
			_progress_bar.visible = false
			_button.disabled = false
		PlotState.PLANTED, PlotState.GROWING:
			_background.color = COLORS.growing
			_label.text = current_crop.crop_type if current_crop else ""
			_progress_bar.visible = true
			_progress_bar.value = growth_progress * 100
			_button.disabled = false
		PlotState.READY:
			_background.color = COLORS.ready
			_label.text = "Ready!\n(Harvest)"
			_progress_bar.visible = true
			_progress_bar.value = 100
			_button.disabled = false

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_tick(delta: float) -> void:
	apply_growth(delta)


func _on_pressed() -> void:
	match state:
		PlotState.EMPTY:
			# 기본 작물 심기 (임시)
			var wheat = _get_crop_db().get_crop("wheat")
			if wheat:
				plant_crop(wheat)
		PlotState.READY:
			harvest()

	clicked.emit(self)
