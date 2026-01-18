extends Control
class_name DialogueBox
## DialogueBox - 대화창 UI
##
## 스토리 대화 및 튜토리얼 메시지를 표시합니다.

# =============================================================================
# 시그널
# =============================================================================

signal dialogue_advanced
signal choice_selected(choice_index: int)

# =============================================================================
# 노드 참조
# =============================================================================

var _panel: PanelContainer
var _character_label: Label
var _text_label: RichTextLabel
var _continue_indicator: Label
var _choices_container: VBoxContainer
var _skip_button: Button

# =============================================================================
# 변수
# =============================================================================

## 타이핑 효과 속도 (초당 글자 수)
@export var typing_speed: float = 30.0

## 타이핑 중 여부
var _is_typing: bool = false
var _full_text: String = ""
var _visible_chars: int = 0
var _typing_timer: float = 0.0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	hide()


func _process(delta: float) -> void:
	if _is_typing:
		_typing_timer += delta
		var chars_to_show := int(_typing_timer * typing_speed)

		if chars_to_show > _visible_chars:
			_visible_chars = chars_to_show
			_text_label.visible_characters = _visible_chars

			if _visible_chars >= _full_text.length():
				_finish_typing()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):
		if _is_typing:
			_finish_typing()
		else:
			_advance_dialogue()
		get_viewport().set_input_as_handled()


func _setup_ui() -> void:
	# 전체 화면 오버레이
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 배경 딤
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	add_child(dim)

	# 대화창 패널 (하단)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -200
	_panel.offset_left = 50
	_panel.offset_right = -50
	_panel.offset_bottom = -20
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# 캐릭터 이름
	_character_label = Label.new()
	_character_label.add_theme_font_size_override("font_size", 24)
	_character_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(_character_label)

	# 대화 텍스트
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.custom_minimum_size = Vector2(0, 80)
	_text_label.add_theme_font_size_override("normal_font_size", 18)
	vbox.add_child(_text_label)

	# 선택지 컨테이너
	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 5)
	_choices_container.hide()
	vbox.add_child(_choices_container)

	# 계속 표시기
	_continue_indicator = Label.new()
	_continue_indicator.text = "▼ 클릭하여 계속"
	_continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_indicator.add_theme_font_size_override("font_size", 14)
	_continue_indicator.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_continue_indicator.hide()
	vbox.add_child(_continue_indicator)

	# 스킵 버튼 (우상단)
	_skip_button = Button.new()
	_skip_button.text = "스킵 >>"
	_skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_button.offset_left = -100
	_skip_button.offset_top = 20
	_skip_button.offset_right = -20
	_skip_button.offset_bottom = 50
	add_child(_skip_button)


func _connect_signals() -> void:
	_skip_button.pressed.connect(_on_skip_pressed)

	if TutorialManager:
		TutorialManager.dialogue_line_shown.connect(_on_dialogue_line_shown)
		TutorialManager.dialogue_ended.connect(_on_dialogue_ended)

# =============================================================================
# 대화 표시
# =============================================================================

## 대화 라인 표시
func show_dialogue_line(line: Dictionary) -> void:
	# 캐릭터 정보
	var character: StoryData.Character = line.get("character", StoryData.Character.NARRATOR)
	var char_data := StoryData.get_character_data(character)

	_character_label.text = char_data.get("name", "???")
	_character_label.add_theme_color_override("font_color", char_data.get("color", Color.WHITE))

	# 텍스트 설정
	_full_text = line.get("text", "")
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_visible_chars = 0
	_typing_timer = 0.0
	_is_typing = true

	# 선택지 처리
	var choices: Array = line.get("choices", [])
	_setup_choices(choices)

	# 계속 표시기 숨김
	_continue_indicator.hide()

	show()


## 선택지 설정
func _setup_choices(choices: Array) -> void:
	# 기존 선택지 제거
	for child in _choices_container.get_children():
		child.queue_free()

	if choices.is_empty():
		_choices_container.hide()
		return

	_choices_container.show()

	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", "선택지 %d" % (i + 1))
		btn.pressed.connect(_on_choice_selected.bind(i))
		_choices_container.add_child(btn)


func _finish_typing() -> void:
	_is_typing = false
	_text_label.visible_characters = -1
	_continue_indicator.show()


func _advance_dialogue() -> void:
	if _choices_container.visible and _choices_container.get_child_count() > 0:
		return  # 선택지가 있으면 클릭으로 진행 안됨

	dialogue_advanced.emit()

	if TutorialManager:
		TutorialManager.advance_dialogue()

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_dialogue_line_shown(line: Dictionary) -> void:
	show_dialogue_line(line)


func _on_dialogue_ended() -> void:
	hide()


func _on_skip_pressed() -> void:
	if TutorialManager:
		TutorialManager.end_dialogue()
	hide()


func _on_choice_selected(index: int) -> void:
	choice_selected.emit(index)
	_advance_dialogue()
