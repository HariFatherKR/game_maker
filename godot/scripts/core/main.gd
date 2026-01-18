extends Node2D
## Main - 메인 게임 씬 컨트롤러
##
## 게임의 메인 화면을 관리하고, UI와 게임 시스템을 연결합니다.

# =============================================================================
# 노드 참조
# =============================================================================

@onready var hud: Control = $UILayer/HUD
@onready var gold_label: Label = $UILayer/HUD/TopBar/GoldContainer/GoldLabel
@onready var gems_label: Label = $UILayer/HUD/TopBar/GemsContainer/GemsLabel
@onready var seeds_label: Label = $UILayer/HUD/TopBar/SeedsContainer/SeedsLabel
@onready var day_label: Label = $UILayer/HUD/TopBar/DayLabel

@onready var farm_button: Button = $UILayer/HUD/BottomBar/FarmButton
@onready var augments_button: Button = $UILayer/HUD/BottomBar/AugmentsButton
@onready var shop_button: Button = $UILayer/HUD/BottomBar/ShopButton
@onready var settings_button: Button = $UILayer/HUD/BottomBar/SettingsButton

@onready var game_container: Control = $GameContainer
@onready var farm_view: Control = $GameContainer/FarmView
@onready var farm_grid: GridContainer = $GameContainer/FarmView/FarmGrid

# Run/Season UI (동적 생성)
var run_info_panel: Control
var season_label: Label
var season_timer_bar: ProgressBar
var run_stats_label: Label

# 증강체 선택 팝업
var augment_popup: Control

# 토스트 알림
var toast_container: VBoxContainer

# =============================================================================
# 변수
# =============================================================================

var current_view: String = "farm"
var farm_plots: Array[FarmPlot] = []

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[Main] Scene ready")
	_setup_signals()
	_setup_buttons()
	_setup_run_info_panel()
	_setup_augment_popup()
	_setup_toast_container()
	_initialize_farm()
	_update_ui()

	# 게임 시작
	await get_tree().process_frame
	GameManager.start_game()

	# 오프라인 보상 확인
	_check_offline_rewards()


func _setup_signals() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.offline_reward_calculated.connect(_on_offline_reward_calculated)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.augments_offered.connect(_on_augments_offered)
	EventBus.augment_selected.connect(_on_augment_selected)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.tick.connect(_on_tick)
	EventBus.notification_shown.connect(_on_notification_shown)


func _setup_buttons() -> void:
	farm_button.pressed.connect(_on_farm_button_pressed)
	augments_button.pressed.connect(_on_augments_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)


# =============================================================================
# Run/Season Info Panel 설정
# =============================================================================

func _setup_run_info_panel() -> void:
	# Run Info Panel (TopBar 아래)
	run_info_panel = PanelContainer.new()
	run_info_panel.name = "RunInfoPanel"
	run_info_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	run_info_panel.offset_top = 60
	run_info_panel.offset_bottom = 120
	run_info_panel.offset_left = 10
	run_info_panel.offset_right = -10
	hud.add_child(run_info_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	run_info_panel.add_child(vbox)

	# 시즌 라벨
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	season_label = Label.new()
	season_label.text = "🌸 Spring"
	season_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(season_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	run_stats_label = Label.new()
	run_stats_label.text = "Run #1 | Harvests: 0"
	run_stats_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(run_stats_label)

	# 시즌 타이머 바
	season_timer_bar = ProgressBar.new()
	season_timer_bar.min_value = 0
	season_timer_bar.max_value = 100
	season_timer_bar.value = 100
	season_timer_bar.show_percentage = false
	season_timer_bar.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(season_timer_bar)

	# 초기 숨김 (런 시작 전)
	run_info_panel.visible = false


# =============================================================================
# 증강체 선택 팝업 설정
# =============================================================================

func _setup_augment_popup() -> void:
	augment_popup = ColorRect.new()
	augment_popup.name = "AugmentPopup"
	augment_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	augment_popup.color = Color(0, 0, 0, 0.7)
	augment_popup.visible = false
	$UILayer.add_child(augment_popup)

	var popup_container := CenterContainer.new()
	popup_container.name = "CenterContainer"
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	augment_popup.add_child(popup_container)

	var popup_panel := PanelContainer.new()
	popup_panel.name = "PanelContainer"
	popup_panel.custom_minimum_size = Vector2(800, 400)
	popup_container.add_child(popup_panel)

	var popup_vbox := VBoxContainer.new()
	popup_vbox.name = "VBoxContainer"
	popup_vbox.add_theme_constant_override("separation", 20)
	popup_panel.add_child(popup_vbox)

	# 타이틀
	var title := Label.new()
	title.text = "Choose an Augment"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	popup_vbox.add_child(title)

	# 선택지 컨테이너
	var choices_container := HBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 20)
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_vbox.add_child(choices_container)

	# 리롤 버튼
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.name = "HBoxContainer"
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_vbox.add_child(bottom_hbox)

	var reroll_button := Button.new()
	reroll_button.name = "RerollButton"
	reroll_button.text = "Reroll (10 Gems)"
	reroll_button.custom_minimum_size = Vector2(200, 50)
	reroll_button.pressed.connect(_on_reroll_pressed)
	bottom_hbox.add_child(reroll_button)


func _show_augment_choices(augment_ids: Array) -> void:
	var choices_container: HBoxContainer = augment_popup.get_node("CenterContainer/PanelContainer/VBoxContainer/ChoicesContainer")
	if choices_container == null:
		return

	# 기존 선택지 제거
	for child in choices_container.get_children():
		child.queue_free()

	# 새 선택지 생성
	for augment_id in augment_ids:
		var augment := AugmentDatabaseClass.get_augment(augment_id)
		if augment == null:
			continue

		var choice_panel := _create_augment_choice_panel(augment)
		choices_container.add_child(choice_panel)

	# 리롤 버튼 비용 업데이트
	var reroll_button: Button = augment_popup.get_node("CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/RerollButton")
	if reroll_button:
		var cost := AugmentManager.get_reroll_cost()
		reroll_button.text = "Reroll (%d Gems)" % cost

	augment_popup.visible = true


func _create_augment_choice_panel(augment: Augment) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 280)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# 이름
	var name_label := Label.new()
	name_label.text = augment.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	# 희귀도 표시
	var rarity_label := Label.new()
	rarity_label.text = _get_rarity_text(augment.rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rarity_label)

	# 설명
	var desc_label := Label.new()
	desc_label.text = augment.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(200, 100)
	vbox.add_child(desc_label)

	# 선택 버튼
	var select_button := Button.new()
	select_button.text = "Select"
	select_button.custom_minimum_size = Vector2(180, 40)
	select_button.pressed.connect(_on_augment_choice_selected.bind(augment.id))
	vbox.add_child(select_button)

	return panel


func _get_rarity_text(rarity: int) -> String:
	match rarity:
		0: return "⚪ Common"
		1: return "🟢 Uncommon"
		2: return "🔵 Rare"
		3: return "🟣 Epic"
		4: return "🟡 Legendary"
	return "Unknown"


func _on_augment_choice_selected(augment_id: String) -> void:
	print("[Main] Augment selected: %s" % augment_id)
	AugmentManager.apply_augment(augment_id)
	augment_popup.visible = false


func _on_reroll_pressed() -> void:
	var new_choices := AugmentManager.reroll_choices()
	if new_choices.is_empty():
		EventBus.notification_shown.emit("Not enough gems!", "error")
		return
	_show_augment_choices(new_choices)


# =============================================================================
# 토스트 알림 시스템
# =============================================================================

func _setup_toast_container() -> void:
	toast_container = VBoxContainer.new()
	toast_container.name = "ToastContainer"
	toast_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toast_container.offset_left = -350
	toast_container.offset_right = -20
	toast_container.offset_top = 140
	toast_container.offset_bottom = 400
	toast_container.add_theme_constant_override("separation", 10)
	hud.add_child(toast_container)


func _show_toast(message: String, toast_type: String = "info") -> void:
	var toast := PanelContainer.new()
	toast.custom_minimum_size = Vector2(300, 50)

	# 타입별 배경색
	var style := StyleBoxFlat.new()
	match toast_type:
		"success":
			style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
		"error":
			style.bg_color = Color(0.7, 0.2, 0.2, 0.9)
		"warning":
			style.bg_color = Color(0.7, 0.5, 0.1, 0.9)
		_:
			style.bg_color = Color(0.3, 0.3, 0.4, 0.9)

	style.set_corner_radius_all(8)
	toast.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_child(label)

	toast_container.add_child(toast)

	# 애니메이션: 페이드인
	toast.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(toast.queue_free)


func _on_notification_shown(message: String, notification_type: String) -> void:
	_show_toast(message, notification_type)


# =============================================================================
# 농장 초기화
# =============================================================================

func _initialize_farm() -> void:
	# 기존 농지 정리
	for child in farm_grid.get_children():
		child.queue_free()

	farm_plots.clear()

	# 농지 생성 (3x3 기본)
	var total_plots := 9
	for i in range(total_plots):
		var plot := _create_farm_plot(i)
		farm_grid.add_child(plot)
		farm_plots.append(plot)

		# 해금 상태 적용
		var unlocked: int = GameManager.game_data.farm.unlocked_plots
		plot.set_unlocked(i < unlocked)


func _create_farm_plot(plot_id: int) -> FarmPlot:
	var plot := FarmPlot.new()
	plot.plot_id = plot_id
	plot.custom_minimum_size = Vector2(120, 120)
	return plot

# =============================================================================
# UI 업데이트
# =============================================================================

func _update_ui() -> void:
	_update_currency_display()
	_update_day_display()


func _update_currency_display() -> void:
	gold_label.text = "Gold: %d" % GameManager.get_currency("gold")
	gems_label.text = "Gems: %d" % GameManager.get_currency("gems")
	seeds_label.text = "Seeds: %d" % GameManager.get_currency("seeds")


func _update_day_display() -> void:
	day_label.text = "Day %d" % TimeManager.current_day

# =============================================================================
# 화면 전환
# =============================================================================

func _switch_view(view_name: String) -> void:
	current_view = view_name

	# 모든 뷰 숨기기
	farm_view.visible = false

	# 선택된 뷰 표시
	match view_name:
		"farm":
			farm_view.visible = true
		"augments":
			# TODO: 증강체 화면 구현
			pass
		"shop":
			# TODO: 상점 화면 구현
			pass
		"settings":
			# TODO: 설정 화면 구현
			pass

	EventBus.screen_changed.emit(current_view, view_name)

# =============================================================================
# 오프라인 보상
# =============================================================================

func _check_offline_rewards() -> void:
	if TimeManager.pending_offline_rewards.is_empty():
		return

	# TODO: 오프라인 보상 팝업 표시
	var rewards := TimeManager.pending_offline_rewards
	print("[Main] Offline rewards available: %s" % rewards)

	# 임시: 자동 수령
	TimeManager.claim_offline_rewards()

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_currency_changed(_type: String, _old: int, _new: int) -> void:
	_update_currency_display()


func _on_day_passed(day: int) -> void:
	day_label.text = "Day %d" % day


func _on_offline_reward_calculated(rewards: Dictionary) -> void:
	print("[Main] Offline rewards calculated: %s" % rewards)
	# TODO: 보상 팝업 표시


func _on_crop_harvested(_plot_id: int, _crop_type: String, amount: int) -> void:
	# 수확 이펙트 및 피드백
	print("[Main] Harvested %d crops" % amount)


func _on_farm_button_pressed() -> void:
	_switch_view("farm")


func _on_augments_button_pressed() -> void:
	_switch_view("augments")


func _on_shop_button_pressed() -> void:
	_switch_view("shop")


func _on_settings_button_pressed() -> void:
	_switch_view("settings")


func _on_season_changed(old_season: int, new_season: int) -> void:
	_update_season_display()
	print("[Main] Season changed: %d -> %d" % [old_season, new_season])


func _on_augments_offered(augments: Array) -> void:
	_show_augment_choices(augments)


func _on_augment_selected(_augment_id: String) -> void:
	_update_run_stats_display()


func _on_run_started(_run_id: int) -> void:
	run_info_panel.visible = true
	_update_season_display()
	_update_run_stats_display()
	print("[Main] Run started, showing run info panel")


func _on_run_ended(_run_id: int, _meta_points: int) -> void:
	run_info_panel.visible = false
	# TODO: 런 결과 팝업 표시
	print("[Main] Run ended, hiding run info panel")


func _on_tick(_delta: float) -> void:
	if GameManager.game_data.run.is_active:
		_update_season_timer()


# =============================================================================
# Run/Season 표시 업데이트
# =============================================================================

func _update_season_display() -> void:
	if not GameManager.game_data.run.is_active:
		return

	var season: int = GameManager.game_data.run.current_season
	var season_names := ["🌸 Spring", "☀️ Summer", "🍂 Fall", "❄️ Winter"]

	if season >= 0 and season < season_names.size():
		season_label.text = season_names[season]


func _update_season_timer() -> void:
	if not GameManager.game_data.run.is_active:
		return

	var remaining: float = GameManager.game_data.run.season_time_remaining
	var total: float = RunManager.SEASON_DURATION
	var percent: float = (remaining / total) * 100.0
	season_timer_bar.value = percent


func _update_run_stats_display() -> void:
	if not GameManager.game_data.run.is_active:
		return

	var run_number: int = GameManager.game_data.run.run_number
	var harvests: int = GameManager.game_data.run.run_harvests
	var augments: int = GameManager.game_data.run.active_augments.size()

	run_stats_label.text = "Run #%d | Harvests: %d | Augments: %d" % [run_number, harvests, augments]
