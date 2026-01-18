extends Node
## EventBus - 중앙화된 시그널 관리 시스템
##
## 게임 전역에서 사용되는 시그널을 중앙에서 관리하여
## 컴포넌트 간 느슨한 결합을 유지합니다.

# =============================================================================
# 게임 상태 시그널
# =============================================================================

## 게임이 시작되었을 때
signal game_started()

## 게임이 일시정지되었을 때
signal game_paused(is_paused: bool)

## 게임이 저장되었을 때
signal game_saved()

## 게임이 로드되었을 때
signal game_loaded()

# =============================================================================
# 농사 시스템 시그널
# =============================================================================

## 작물이 심어졌을 때
signal crop_planted(plot_id: int, crop_type: String)

## 작물이 성장했을 때
signal crop_grown(plot_id: int, growth_percent: float)

## 작물 성장 완료 (수확 가능)
signal crop_ready(plot_id: int, crop_type: String)

## 작물이 수확되었을 때
signal crop_harvested(plot_id: int, crop_type: String, amount: int)

## 농지가 해금되었을 때
signal plot_unlocked(plot_id: int)

## 자동 수확이 발동되었을 때
signal auto_harvest_triggered(plot_ids: Array[int])

## 골드 획득
signal gold_earned(amount: int, source: String)

# =============================================================================
# 증강체 시스템 시그널
# =============================================================================

## 새로운 런이 시작되었을 때
signal run_started(run_id: int)

## 런이 종료되었을 때
signal run_ended(run_id: int, meta_points: int)

## 시즌이 변경되었을 때
signal season_changed(old_season: int, new_season: int)

## 목표 완료
signal objective_completed(objective_id: String)

## 증강체 선택지가 제시되었을 때
signal augments_offered(augments: Array)

## 증강체가 선택되었을 때
signal augment_selected(augment_id: String)

## 증강체가 제거되었을 때
signal augment_removed(augment_id: String)

## 시너지가 활성화되었을 때
signal synergy_activated(synergy_id: String, bonus: float)

# =============================================================================
# 위협 시스템 시그널
# =============================================================================

## 위협 스폰
signal threat_spawned(threat_id: String, target_plot: int)

## 위협 해결
signal threat_resolved(threat_id: String, success: bool)

## 재해 시작
signal disaster_started(disaster_type: String)

## 재해 종료
signal disaster_ended(disaster_type: String)

# =============================================================================
# 경제 시스템 시그널
# =============================================================================

## 재화가 변경되었을 때
signal currency_changed(currency_type: String, old_amount: int, new_amount: int)

## 아이템이 구매되었을 때
signal item_purchased(item_id: String, cost: int)

## 아이템이 판매되었을 때
signal item_sold(item_id: String, revenue: int)

# =============================================================================
# 시간 시스템 시그널
# =============================================================================

## 게임 틱이 발생했을 때 (시간 기반 업데이트)
signal tick(delta: float)

## 하루가 지났을 때 (게임 내 시간)
signal day_passed(day: int)

## 오프라인 보상이 계산되었을 때
signal offline_reward_calculated(rewards: Dictionary)

## 오프라인 보상이 수령되었을 때
signal offline_reward_claimed(rewards: Dictionary)

# =============================================================================
# UI 시그널
# =============================================================================

## UI 화면이 변경되었을 때
signal screen_changed(from_screen: String, to_screen: String)

## 다이얼로그가 열렸을 때
signal dialog_opened(dialog_id: String)

## 다이얼로그가 닫혔을 때
signal dialog_closed(dialog_id: String)

## 알림이 표시되었을 때
signal notification_shown(message: String, type: String)

# =============================================================================
# 플랫폼 시그널
# =============================================================================

## Steam 초기화 완료
signal steam_initialized(success: bool)

## 모바일 브릿지 연결됨
signal mobile_bridge_connected()

## 클라우드 동기화 완료
signal cloud_sync_completed(success: bool)

## 업적 해금됨
signal achievement_unlocked(achievement_id: String)

# =============================================================================
# 헬퍼 메서드
# =============================================================================

func _ready() -> void:
	print("[EventBus] Initialized")


## 시그널 연결을 위한 헬퍼 (타입 안전성)
func safe_connect(signal_name: StringName, callable: Callable) -> void:
	if has_signal(signal_name):
		if not is_connected(signal_name, callable):
			connect(signal_name, callable)
	else:
		push_warning("[EventBus] Signal '%s' does not exist" % signal_name)


## 시그널 연결 해제를 위한 헬퍼
func safe_disconnect(signal_name: StringName, callable: Callable) -> void:
	if has_signal(signal_name) and is_connected(signal_name, callable):
		disconnect(signal_name, callable)
