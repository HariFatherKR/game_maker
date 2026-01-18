extends Node
class_name EventManagerClass
## EventManager - 시즌 이벤트 시스템
##
## 시간 한정 이벤트와 특별 보상을 관리합니다.

# =============================================================================
# 이벤트 타입
# =============================================================================

enum EventType {
	HARVEST_FESTIVAL,   # 수확 축제 - 수확량 보너스
	GOLDEN_HOUR,        # 황금 시간 - 골드 보너스
	SEED_RAIN,          # 씨앗 비 - 무료 씨앗
	DOUBLE_XP,          # 더블 XP - 배틀패스 경험치 2배
	RARE_AUGMENT,       # 희귀 증강체 - 레어 이상 확률 증가
	PET_PARADE,         # 펫 퍼레이드 - 펫 효과 2배
	SPEED_GROWTH,       # 빠른 성장 - 작물 성장 속도 증가
	THREAT_FREE         # 평화로운 시간 - 위협 스폰 안됨
}

# =============================================================================
# 이벤트 데이터
# =============================================================================

const EVENT_DATA := {
	EventType.HARVEST_FESTIVAL: {
		"id": "harvest_festival",
		"name": "수확 축제",
		"description": "수확량이 50% 증가합니다!",
		"icon": "🌾",
		"duration_hours": 24,
		"effect": "yield_bonus",
		"value": 0.5
	},
	EventType.GOLDEN_HOUR: {
		"id": "golden_hour",
		"name": "황금 시간",
		"description": "골드 획득량이 2배!",
		"icon": "💰",
		"duration_hours": 2,
		"effect": "gold_multiplier",
		"value": 2.0
	},
	EventType.SEED_RAIN: {
		"id": "seed_rain",
		"name": "씨앗 비",
		"description": "수확 시 씨앗도 함께 획득!",
		"icon": "🌧️",
		"duration_hours": 6,
		"effect": "seed_bonus",
		"value": 1.0
	},
	EventType.DOUBLE_XP: {
		"id": "double_xp",
		"name": "더블 경험치",
		"description": "배틀패스 경험치 2배!",
		"icon": "⭐",
		"duration_hours": 12,
		"effect": "xp_multiplier",
		"value": 2.0
	},
	EventType.RARE_AUGMENT: {
		"id": "rare_augment",
		"name": "희귀 증강체 축제",
		"description": "레어 이상 증강체 확률 증가!",
		"icon": "✨",
		"duration_hours": 8,
		"effect": "rare_chance_bonus",
		"value": 0.3
	},
	EventType.PET_PARADE: {
		"id": "pet_parade",
		"name": "펫 퍼레이드",
		"description": "펫 효과가 2배!",
		"icon": "🐾",
		"duration_hours": 4,
		"effect": "pet_multiplier",
		"value": 2.0
	},
	EventType.SPEED_GROWTH: {
		"id": "speed_growth",
		"name": "급속 성장",
		"description": "작물 성장 속도 2배!",
		"icon": "🚀",
		"duration_hours": 3,
		"effect": "growth_multiplier",
		"value": 2.0
	},
	EventType.THREAT_FREE: {
		"id": "threat_free",
		"name": "평화로운 농장",
		"description": "해충과 재해가 발생하지 않습니다.",
		"icon": "🕊️",
		"duration_hours": 1,
		"effect": "no_threats",
		"value": 1.0
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal event_started(event_type: EventType)
signal event_ended(event_type: EventType)
signal special_reward_available(reward: Dictionary)

# =============================================================================
# 변수
# =============================================================================

## 현재 활성 이벤트
var active_events: Array[Dictionary] = []

## 이벤트 체크 타이머
var _check_timer: float = 0.0
const CHECK_INTERVAL: float = 60.0  # 1분마다 체크

## 예정된 이벤트 (시뮬레이션용)
var _scheduled_events: Array[Dictionary] = []

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[EventManager] Initialized")
	_connect_signals()
	_load_data()
	_schedule_random_events()


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_check_events()


func _connect_signals() -> void:
	EventBus.tick.connect(_on_tick)

# =============================================================================
# 이벤트 관리
# =============================================================================

## 이벤트 시작
func start_event(event_type: EventType, duration_override: float = 0.0) -> void:
	if is_event_active(event_type):
		return

	var event_info: Dictionary = EVENT_DATA[event_type].duplicate()
	var duration = duration_override if duration_override > 0 else event_info.duration_hours * 3600.0

	event_info["start_time"] = Time.get_unix_time_from_system()
	event_info["end_time"] = event_info.start_time + duration
	event_info["event_type"] = event_type

	active_events.append(event_info)
	event_started.emit(event_type)

	EventBus.notification_shown.emit("%s %s 시작!" % [event_info.icon, event_info.name], "info")
	print("[EventManager] Event started: %s" % event_info.id)


## 이벤트 종료
func end_event(event_type: EventType) -> void:
	for i in range(active_events.size() - 1, -1, -1):
		if active_events[i].event_type == event_type:
			var event_info: Dictionary = active_events[i]
			active_events.remove_at(i)
			event_ended.emit(event_type)
			EventBus.notification_shown.emit("%s %s 종료" % [event_info.icon, event_info.name], "info")
			print("[EventManager] Event ended: %s" % event_info.id)
			break


## 이벤트 활성화 여부
func is_event_active(event_type: EventType) -> bool:
	for event in active_events:
		if event.event_type == event_type:
			return true
	return false


## 이벤트 효과 값 가져오기
func get_event_effect_value(effect_name: String) -> float:
	var total := 0.0

	for event in active_events:
		if event.effect == effect_name:
			total += event.value

	return total


## 이벤트 체크 (만료 및 시작)
func _check_events() -> void:
	var now := Time.get_unix_time_from_system()

	# 만료된 이벤트 종료
	for i in range(active_events.size() - 1, -1, -1):
		if now >= active_events[i].end_time:
			var event_type: EventType = active_events[i].event_type
			end_event(event_type)

	# 예정된 이벤트 시작
	for i in range(_scheduled_events.size() - 1, -1, -1):
		if now >= _scheduled_events[i].start_time:
			var event_type: EventType = _scheduled_events[i].event_type
			_scheduled_events.remove_at(i)
			start_event(event_type)

# =============================================================================
# 이벤트 스케줄링
# =============================================================================

## 랜덤 이벤트 스케줄링 (테스트/데모용)
func _schedule_random_events() -> void:
	# 게임 시작 후 10분 뒤 황금 시간 이벤트
	schedule_event(EventType.GOLDEN_HOUR, 600)

	# 30분 뒤 수확 축제
	schedule_event(EventType.HARVEST_FESTIVAL, 1800)


## 이벤트 스케줄링
func schedule_event(event_type: EventType, delay_seconds: int) -> void:
	var start_time := int(Time.get_unix_time_from_system()) + delay_seconds

	_scheduled_events.append({
		"event_type": event_type,
		"start_time": start_time
	})

	print("[EventManager] Scheduled %s in %d seconds" % [EventType.keys()[event_type], delay_seconds])

# =============================================================================
# 효과 적용 헬퍼
# =============================================================================

## 수확량 보너스 (이벤트)
func get_yield_bonus() -> float:
	return get_event_effect_value("yield_bonus")


## 골드 배율 (이벤트)
func get_gold_multiplier() -> float:
	var multiplier := get_event_effect_value("gold_multiplier")
	return multiplier if multiplier > 0 else 1.0


## 씨앗 보너스 (이벤트)
func get_seed_bonus() -> float:
	return get_event_effect_value("seed_bonus")


## XP 배율 (이벤트)
func get_xp_multiplier() -> float:
	var multiplier := get_event_effect_value("xp_multiplier")
	return multiplier if multiplier > 0 else 1.0


## 레어 확률 보너스 (이벤트)
func get_rare_chance_bonus() -> float:
	return get_event_effect_value("rare_chance_bonus")


## 펫 효과 배율 (이벤트)
func get_pet_multiplier() -> float:
	var multiplier := get_event_effect_value("pet_multiplier")
	return multiplier if multiplier > 0 else 1.0


## 성장 배율 (이벤트)
func get_growth_multiplier() -> float:
	var multiplier := get_event_effect_value("growth_multiplier")
	return multiplier if multiplier > 0 else 1.0


## 위협 비활성화 (이벤트)
func is_threat_disabled() -> bool:
	return is_event_active(EventType.THREAT_FREE)

# =============================================================================
# 이벤트 정보
# =============================================================================

## 활성 이벤트 목록 가져오기
func get_active_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in active_events:
		result.append(event.duplicate())
	return result


## 이벤트 남은 시간 (초)
func get_event_remaining_time(event_type: EventType) -> int:
	for event in active_events:
		if event.event_type == event_type:
			var now := Time.get_unix_time_from_system()
			return maxi(0, int(event.end_time - now))
	return 0


## 이벤트 남은 시간 포맷
func format_remaining_time(seconds: int) -> String:
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var secs := seconds % 60

	if hours > 0:
		return "%d시간 %d분" % [hours, minutes]
	elif minutes > 0:
		return "%d분 %d초" % [minutes, secs]
	else:
		return "%d초" % secs

# =============================================================================
# 이벤트 핸들러
# =============================================================================

func _on_tick(_delta: float) -> void:
	# 실시간 이벤트 체크는 _process에서 처리
	pass

# =============================================================================
# 저장/로드
# =============================================================================

func _load_data() -> void:
	# MetaProgressData는 Dictionary가 아니므로 별도 저장소 사용 안함
	# 세션 시작 시 active_events는 비어있음
	pass


func _save_data() -> void:
	# 이벤트는 세션 기반이므로 저장하지 않음
	pass
