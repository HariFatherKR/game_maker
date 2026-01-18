extends Node
class_name TutorialManagerClass
## TutorialManager - 튜토리얼 시스템
##
## 신규 플레이어를 위한 튜토리얼 흐름을 관리합니다.

# =============================================================================
# 클래스 프리로드
# =============================================================================

const StoryDataClass := preload("res://scripts/story/story_data.gd")

# =============================================================================
# 시그널
# =============================================================================

signal tutorial_started
signal tutorial_step_changed(step_id: String)
signal tutorial_completed
signal dialogue_started(sequence_id: String)
signal dialogue_line_shown(line: Dictionary)
signal dialogue_ended

# =============================================================================
# 변수
# =============================================================================

## 튜토리얼 활성화 여부
var is_tutorial_active: bool = false

## 현재 튜토리얼 단계 인덱스
var _current_step_index: int = 0

## 튜토리얼 완료 여부
var _tutorial_completed: bool = false

## 현재 진행 중인 대화 시퀀스
var _current_dialogue: Array = []
var _current_dialogue_index: int = 0
var _is_dialogue_active: bool = false

## 시청한 스토리 이벤트
var _viewed_story_events: Array[String] = []

## 자동 진행 타이머
var _auto_advance_timer: float = 0.0
var _auto_advance_duration: float = 0.0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[TutorialManager] Initialized")
	_connect_signals()


func _process(delta: float) -> void:
	if _auto_advance_duration > 0:
		_auto_advance_timer += delta
		if _auto_advance_timer >= _auto_advance_duration:
			_auto_advance_timer = 0.0
			_auto_advance_duration = 0.0
			advance_dialogue()


func _connect_signals() -> void:
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.threat_spawned.connect(_on_threat_spawned)
	EventBus.disaster_started.connect(_on_disaster_started)

# =============================================================================
# 튜토리얼 제어
# =============================================================================

## 튜토리얼 시작
func start_tutorial() -> void:
	if _tutorial_completed:
		return

	is_tutorial_active = true
	_current_step_index = 0

	tutorial_started.emit()
	_show_current_step()

	print("[TutorialManager] Tutorial started")


## 다음 튜토리얼 단계로
func advance_tutorial() -> void:
	if not is_tutorial_active:
		return

	_current_step_index += 1

	if _current_step_index >= StoryDataClass.TUTORIAL_STEPS.size():
		complete_tutorial()
	else:
		_show_current_step()


## 튜토리얼 완료
func complete_tutorial() -> void:
	is_tutorial_active = false
	_tutorial_completed = true

	GameManager.game_data.meta.tutorial_completed = true

	tutorial_completed.emit()
	EventBus.notification_shown.emit("🎓 튜토리얼 완료!", "success")

	print("[TutorialManager] Tutorial completed")


## 튜토리얼 스킵
func skip_tutorial() -> void:
	if not is_tutorial_active:
		return

	is_tutorial_active = false
	_tutorial_completed = true

	GameManager.game_data.meta.tutorial_completed = true

	tutorial_completed.emit()
	print("[TutorialManager] Tutorial skipped")


## 현재 튜토리얼 단계 가져오기
func get_current_step() -> Dictionary:
	if _current_step_index < StoryDataClass.TUTORIAL_STEPS.size():
		return StoryDataClass.TUTORIAL_STEPS[_current_step_index]
	return {}


func _show_current_step() -> void:
	var step := get_current_step()
	if step.is_empty():
		return

	tutorial_step_changed.emit(step.id)
	print("[TutorialManager] Step: %s" % step.id)

# =============================================================================
# 대화 시스템
# =============================================================================

## 대화 시퀀스 시작
func start_dialogue(sequence_id: String) -> void:
	if _is_dialogue_active:
		return

	_current_dialogue = StoryDataClass.get_dialogue_sequence(sequence_id)
	if _current_dialogue.is_empty():
		push_warning("[TutorialManager] Unknown dialogue: %s" % sequence_id)
		return

	_current_dialogue_index = 0
	_is_dialogue_active = true

	dialogue_started.emit(sequence_id)
	_show_current_dialogue_line()

	print("[TutorialManager] Dialogue started: %s" % sequence_id)


## 대화 진행
func advance_dialogue() -> void:
	if not _is_dialogue_active:
		return

	_current_dialogue_index += 1

	if _current_dialogue_index >= _current_dialogue.size():
		end_dialogue()
	else:
		_show_current_dialogue_line()


## 대화 종료
func end_dialogue() -> void:
	_is_dialogue_active = false
	_current_dialogue.clear()
	_current_dialogue_index = 0
	_auto_advance_duration = 0.0

	dialogue_ended.emit()
	print("[TutorialManager] Dialogue ended")


## 현재 대화 라인 가져오기
func get_current_dialogue_line() -> Dictionary:
	if _current_dialogue_index < _current_dialogue.size():
		return _current_dialogue[_current_dialogue_index]
	return {}


## 대화 활성화 여부
func is_dialogue_active() -> bool:
	return _is_dialogue_active


func _show_current_dialogue_line() -> void:
	var line := get_current_dialogue_line()
	if line.is_empty():
		return

	dialogue_line_shown.emit(line)

	# 자동 진행 설정
	if line.has("auto_advance") and line.auto_advance > 0:
		_auto_advance_timer = 0.0
		_auto_advance_duration = line.auto_advance
	else:
		_auto_advance_duration = 0.0

# =============================================================================
# 스토리 이벤트
# =============================================================================

## 스토리 이벤트 트리거
func trigger_story_event(event_id: String) -> void:
	if _viewed_story_events.has(event_id):
		return

	_viewed_story_events.append(event_id)
	start_dialogue(event_id)

	print("[TutorialManager] Story event triggered: %s" % event_id)


## 스토리 이벤트 시청 여부
func has_viewed_event(event_id: String) -> bool:
	return _viewed_story_events.has(event_id)

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_crop_harvested(_plot_id: int, _crop_type: String, _amount: int) -> void:
	# 첫 수확 이벤트
	if GameManager.game_data.stats.total_crops_harvested == 1:
		trigger_story_event("first_harvest")

	# 튜토리얼 진행
	if is_tutorial_active:
		var step := get_current_step()
		if step.get("action") == "harvest":
			advance_tutorial()


func _on_run_ended(run_id: int, _meta_points: int) -> void:
	# 첫 런 완료 이벤트
	if run_id == 1 or GameManager.game_data.meta.total_runs == 1:
		trigger_story_event("first_run_complete")


func _on_threat_spawned(threat_id: String, _target_plot: int) -> void:
	# 첫 해충 이벤트
	if not has_viewed_event("first_pest"):
		trigger_story_event("first_pest")


func _on_disaster_started(disaster_id: String) -> void:
	# 첫 재해 이벤트
	if not has_viewed_event("first_disaster"):
		trigger_story_event("first_disaster")

# =============================================================================
# 세이브/로드
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"tutorial_completed": _tutorial_completed,
		"viewed_events": _viewed_story_events
	}


func load_save_data(data: Dictionary) -> void:
	_tutorial_completed = data.get("tutorial_completed", false)
	_viewed_story_events.clear()
	for event_id in data.get("viewed_events", []):
		_viewed_story_events.append(event_id)
