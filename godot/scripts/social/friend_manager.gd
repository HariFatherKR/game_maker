extends Node
class_name FriendManagerClass
## FriendManager - 친구 시스템
##
## 친구 추가, 농장 방문, 선물 교환을 관리합니다.

# =============================================================================
# 상수
# =============================================================================

const MAX_FRIENDS: int = 50
const MAX_DAILY_GIFTS: int = 5
const VISIT_COOLDOWN: int = 3600  # 1시간

## 선물 종류
enum GiftType {
	GOLD,
	SEEDS,
	ENERGY,
	SPECIAL_SEED
}

const GIFT_DATA := {
	GiftType.GOLD: {
		"id": "gold",
		"name": "골드 주머니",
		"description": "100 골드",
		"amount": 100,
		"currency": "gold"
	},
	GiftType.SEEDS: {
		"id": "seeds",
		"name": "씨앗 봉지",
		"description": "10 씨앗",
		"amount": 10,
		"currency": "seeds"
	},
	GiftType.ENERGY: {
		"id": "energy",
		"name": "에너지 음료",
		"description": "리롤 1회",
		"amount": 1,
		"currency": "reroll"
	},
	GiftType.SPECIAL_SEED: {
		"id": "special_seed",
		"name": "특별한 씨앗",
		"description": "희귀 작물 씨앗",
		"amount": 1,
		"currency": "rare_seed"
	}
}

# =============================================================================
# 시그널
# =============================================================================

signal friend_added(friend_id: String)
signal friend_removed(friend_id: String)
signal gift_sent(friend_id: String, gift_type: GiftType)
signal gift_received(friend_id: String, gift_type: GiftType)
signal farm_visited(friend_id: String)
signal friends_loaded(friends: Array)

# =============================================================================
# 변수
# =============================================================================

## 친구 목록 {friend_id: {name, level, last_online, ...}}
var friends: Dictionary = {}

## 받은 선물 대기열
var pending_gifts: Array[Dictionary] = []

## 오늘 보낸 선물 수
var daily_gifts_sent: int = 0

## 마지막 방문 시간 {friend_id: timestamp}
var _last_visit_times: Dictionary = {}

## 오늘 날짜 (리셋용)
var _last_reset_day: int = 0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[FriendManager] Initialized")
	_load_data()
	_check_daily_reset()


func _check_daily_reset() -> void:
	var today := Time.get_date_dict_from_system().day
	if today != _last_reset_day:
		daily_gifts_sent = 0
		_last_reset_day = today
		_save_data()
		print("[FriendManager] Daily reset")

# =============================================================================
# 친구 관리
# =============================================================================

## 친구 추가
func add_friend(friend_id: String, friend_name: String = "") -> bool:
	if friends.size() >= MAX_FRIENDS:
		EventBus.notification_shown.emit("친구 목록이 가득 찼습니다", "warning")
		return false

	if friends.has(friend_id):
		return false

	friends[friend_id] = {
		"id": friend_id,
		"name": friend_name if friend_name else "Player_%s" % friend_id.substr(0, 6),
		"level": 1,
		"last_online": Time.get_unix_time_from_system(),
		"added_at": Time.get_unix_time_from_system()
	}

	friend_added.emit(friend_id)
	_save_data()

	EventBus.notification_shown.emit("친구 추가: %s" % friends[friend_id].name, "success")
	print("[FriendManager] Friend added: %s" % friend_id)
	return true


## 친구 삭제
func remove_friend(friend_id: String) -> bool:
	if not friends.has(friend_id):
		return false

	var friend_name: String = friends[friend_id].name
	friends.erase(friend_id)

	friend_removed.emit(friend_id)
	_save_data()

	EventBus.notification_shown.emit("친구 삭제: %s" % friend_name, "info")
	print("[FriendManager] Friend removed: %s" % friend_id)
	return true


## 친구 목록 가져오기
func get_friends() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for friend_id in friends:
		result.append(friends[friend_id].duplicate())
	return result


## 친구 수
func get_friend_count() -> int:
	return friends.size()

# =============================================================================
# 선물 시스템
# =============================================================================

## 선물 보내기
func send_gift(friend_id: String, gift_type: GiftType) -> bool:
	if not friends.has(friend_id):
		return false

	if daily_gifts_sent >= MAX_DAILY_GIFTS:
		EventBus.notification_shown.emit("오늘 선물을 모두 보냈습니다", "warning")
		return false

	# 실제로는 서버에 전송
	daily_gifts_sent += 1
	gift_sent.emit(friend_id, gift_type)
	_save_data()

	var friend_name: String = friends[friend_id].name
	var gift_data: Dictionary = GIFT_DATA[gift_type]
	EventBus.notification_shown.emit("🎁 %s에게 %s 전송!" % [friend_name, gift_data.name], "success")
	print("[FriendManager] Gift sent to %s: %s" % [friend_id, gift_data.id])
	return true


## 선물 받기
func receive_gift(friend_id: String, gift_type: GiftType) -> void:
	pending_gifts.append({
		"friend_id": friend_id,
		"gift_type": gift_type,
		"received_at": Time.get_unix_time_from_system()
	})

	gift_received.emit(friend_id, gift_type)
	_save_data()


## 대기 중인 선물 수령
func claim_pending_gift(index: int) -> bool:
	if index < 0 or index >= pending_gifts.size():
		return false

	var gift: Dictionary = pending_gifts[index]
	var gift_data: Dictionary = GIFT_DATA[gift.gift_type]

	# 보상 지급
	match gift_data.currency:
		"gold":
			GameManager.add_currency("gold", gift_data.amount)
		"seeds":
			GameManager.add_currency("seeds", gift_data.amount)
		"reroll":
			GameManager.game_data.run.reroll_count += gift_data.amount
		"rare_seed":
			# 희귀 씨앗 처리 (나중에 구현)
			GameManager.add_currency("seeds", gift_data.amount * 5)

	pending_gifts.remove_at(index)
	_save_data()

	EventBus.notification_shown.emit("🎁 %s 수령!" % gift_data.name, "success")
	return true


## 모든 대기 선물 수령
func claim_all_gifts() -> int:
	var claimed := 0
	while pending_gifts.size() > 0:
		if claim_pending_gift(0):
			claimed += 1
		else:
			break
	return claimed


## 대기 중인 선물 수
func get_pending_gift_count() -> int:
	return pending_gifts.size()


## 남은 선물 가능 횟수
func get_remaining_gifts() -> int:
	return MAX_DAILY_GIFTS - daily_gifts_sent

# =============================================================================
# 농장 방문
# =============================================================================

## 친구 농장 방문
func visit_farm(friend_id: String) -> bool:
	if not friends.has(friend_id):
		return false

	# 쿨다운 체크
	var now := Time.get_unix_time_from_system()
	if _last_visit_times.has(friend_id):
		if now - _last_visit_times[friend_id] < VISIT_COOLDOWN:
			var remaining := VISIT_COOLDOWN - int(now - _last_visit_times[friend_id])
			EventBus.notification_shown.emit("방문 가능: %d분 후" % (remaining / 60), "warning")
			return false

	_last_visit_times[friend_id] = now

	# 방문 보상 (소량의 골드)
	var visit_reward := 10 + randi() % 20
	GameManager.add_currency("gold", visit_reward)

	farm_visited.emit(friend_id)
	_save_data()

	var friend_name: String = friends[friend_id].name
	EventBus.notification_shown.emit("🏠 %s 농장 방문! +%d 골드" % [friend_name, visit_reward], "success")
	print("[FriendManager] Visited farm: %s" % friend_id)
	return true


## 방문 가능 여부
func can_visit_farm(friend_id: String) -> bool:
	if not friends.has(friend_id):
		return false

	if not _last_visit_times.has(friend_id):
		return true

	var now := Time.get_unix_time_from_system()
	return now - _last_visit_times[friend_id] >= VISIT_COOLDOWN


## 방문 쿨다운 남은 시간 (초)
func get_visit_cooldown(friend_id: String) -> int:
	if not _last_visit_times.has(friend_id):
		return 0

	var now := Time.get_unix_time_from_system()
	var elapsed := now - _last_visit_times[friend_id]
	return maxi(0, VISIT_COOLDOWN - int(elapsed))

# =============================================================================
# 플랫폼 연동
# =============================================================================

## Steam/GameCenter 친구 목록 로드
func load_platform_friends() -> void:
	if PlatformBridge.is_steam():
		_load_steam_friends()
	else:
		# 로컬 더미 데이터
		_load_dummy_friends()


func _load_steam_friends() -> void:
	# Steam API 호출
	print("[FriendManager] Loading Steam friends...")
	# 실제 구현 시 Steam.getFriendCount(), Steam.getFriendByIndex() 사용
	await get_tree().create_timer(0.5).timeout
	_load_dummy_friends()


func _load_dummy_friends() -> void:
	# 테스트용 더미 친구
	for i in range(5):
		var dummy_id := "dummy_%d" % i
		if not friends.has(dummy_id):
			add_friend(dummy_id, "친구 %d" % (i + 1))

	friends_loaded.emit(get_friends())

# =============================================================================
# 저장/로드
# =============================================================================

func _load_data() -> void:
	var friend_data: Dictionary = GameManager.game_data.meta.get("friends", {})

	friends = friend_data.get("list", {})
	pending_gifts.clear()
	for gift in friend_data.get("pending_gifts", []):
		pending_gifts.append(gift)
	daily_gifts_sent = friend_data.get("daily_gifts_sent", 0)
	_last_visit_times = friend_data.get("visit_times", {})
	_last_reset_day = friend_data.get("last_reset_day", Time.get_date_dict_from_system().day)


func _save_data() -> void:
	var pending_array: Array = []
	for gift in pending_gifts:
		pending_array.append(gift)

	GameManager.game_data.meta["friends"] = {
		"list": friends,
		"pending_gifts": pending_array,
		"daily_gifts_sent": daily_gifts_sent,
		"visit_times": _last_visit_times,
		"last_reset_day": _last_reset_day
	}
