# IdleFarm Roguelike - 기술 명세서 (Technical Specification)

> **버전**: 1.0.0
> **작성일**: 2025-01-18
> **기반 문서**: docs/GAME_DESIGN_DOCUMENT.md

---

## 1. 시스템 아키텍처

### 1.1 5계층 구조

```
┌─────────────────────────────────────────────────────────────┐
│                     Platform Layer (5)                       │
│  Steam API / iOS SDK / Android SDK / React Native            │
├─────────────────────────────────────────────────────────────┤
│                     Bridge Layer (4)                         │
│  PlatformBridge.gd ←→ GodotBridge.ts                        │
├─────────────────────────────────────────────────────────────┤
│                     Manager Layer (3)                        │
│  GameManager / SaveManager / TimeManager / AugmentManager    │
├─────────────────────────────────────────────────────────────┤
│                     System Layer (2)                         │
│  FarmSystem / RunSystem / EconomySystem / ThreatSystem       │
├─────────────────────────────────────────────────────────────┤
│                     Data Layer (1)                           │
│  Crop / Augment / Plot / SaveData / Config                   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Autoload 싱글톤

| 파일 | 클래스 | 역할 | 의존성 |
|-----|--------|------|--------|
| `event_bus.gd` | EventBus | 전역 시그널 버스 | 없음 |
| `game_manager.gd` | GameManager | 게임 상태 관리 | EventBus |
| `save_manager.gd` | SaveManager | 저장/로드 | GameManager |
| `time_manager.gd` | TimeManager | 시간, 오프라인 보상 | GameManager, EventBus |
| `platform_bridge.gd` | PlatformBridge | 플랫폼 API 추상화 | SaveManager |

---

## 2. 데이터 스키마

### 2.1 저장 데이터 구조 (GameData)

```gdscript
class_name GameData

# 메타 정보
var version: String = "1.0.0"
var last_save_time: int = 0

# 재화
var currencies: Dictionary = {
    "gold": 0,
    "gems": 0,
    "meta_points": 0,
}

# 농장 상태
var farm: FarmData = FarmData.new()

# 런 상태
var run: RunData = RunData.new()

# 메타 진행도
var meta: MetaProgressData = MetaProgressData.new()

# 통계
var stats: StatsData = StatsData.new()

# 잠금해제
var unlocks: UnlocksData = UnlocksData.new()
```

### 2.2 농장 데이터 (FarmData)

```gdscript
class_name FarmData

var unlocked_plots: int = 1
var plots: Array[PlotData] = []

class PlotData:
    var plot_id: int
    var crop_id: String = ""
    var growth_progress: float = 0.0
    var planted_at: int = 0
```

### 2.3 런 데이터 (RunData)

```gdscript
class_name RunData

var is_active: bool = false
var run_number: int = 0
var current_season: int = 0  # 0=봄, 1=여름, 2=가을, 3=겨울
var season_time_remaining: float = 300.0  # 5분
var total_run_time: float = 0.0

# 현재 런 증강체
var active_augments: Array[String] = []

# 현재 런 통계
var run_gold: int = 0
var run_harvests: int = 0
var run_synergies: Array[String] = []

# 목표 달성
var completed_objectives: Array[String] = []
```

### 2.4 메타 진행도 (MetaProgressData)

```gdscript
class_name MetaProgressData

var total_runs: int = 0
var total_gold_earned: int = 0
var total_harvests: int = 0

# 영구 업그레이드 레벨
var upgrades: Dictionary = {
    "starting_plots": 0,      # 최대 5
    "base_growth_rate": 0,    # 최대 10
    "starting_gold": 0,       # 최대 10
    "auto_harvest_speed": 0,  # 최대 5
    "rare_crop_chance": 0,    # 최대 10
}

# 신 호감도
var god_affinity: Dictionary = {
    "ceres": 0,
    "plutus": 0,
    "chronos": 0,
    "tyche": 0,
    "hephaestus": 0,
}

# 잠금해제된 펫
var unlocked_pets: Array[String] = ["cat"]
var active_pet: String = "cat"

# 완료한 엔딩
var completed_endings: Array[String] = []
```

### 2.5 작물 데이터 스키마 (Resource)

```gdscript
class_name CropData extends Resource

@export var id: String
@export var name_key: String  # 번역 키
@export var tier: int  # 1=Common ~ 5=Legendary
@export var growth_time: float  # 초
@export var harvest_amount: int
@export var base_value: int
@export var seed_cost: int
@export var unlock_requirement: String = ""
@export var sprite: Texture2D
```

### 2.6 증강체 데이터 스키마 (Resource)

```gdscript
class_name AugmentData extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum GodType { CERES, PLUTUS, CHRONOS, TYCHE, HEPHAESTUS }

@export var id: String
@export var name_key: String
@export var description_key: String
@export var god: GodType
@export var rarity: Rarity
@export var icon: Texture2D

# 효과
@export var effects: Array[AugmentEffect]

# 조건/제한
@export var max_stack: int = 1
@export var prerequisite_augments: Array[String] = []
@export var exclusive_with: Array[String] = []
```

### 2.7 증강체 효과 구조

```gdscript
class_name AugmentEffect extends Resource

enum EffectType {
    GROWTH_SPEED_MULT,      # 성장 속도 배율
    GROWTH_SPEED_ADD,       # 성장 속도 추가
    HARVEST_MULT,           # 수확량 배율
    GOLD_MULT,              # 골드 배율
    OFFLINE_MULT,           # 오프라인 효율
    AUTO_HARVEST,           # 자동 수확 활성화
    AUTO_PLANT,             # 자동 심기 활성화
    DOUBLE_HARVEST_CHANCE,  # 더블 수확 확률
    RARE_CROP_CHANCE,       # 희귀 작물 확률
    SEED_COST_MULT,         # 씨앗 비용 배율
    IMMUNITY_DROUGHT,       # 가뭄 면역
    IMMUNITY_FROST,         # 서리 면역
    INSTANT_GROW_CHANCE,    # 즉시 성장 확률
}

@export var type: EffectType
@export var value: float
@export var is_percentage: bool = true
```

---

## 3. 이벤트 시스템

### 3.1 EventBus 시그널 정의

```gdscript
# event_bus.gd

# === 시스템 이벤트 ===
signal game_ready
signal game_paused(is_paused: bool)
signal tick(delta: float)

# === 농장 이벤트 ===
signal crop_planted(plot_id: int, crop_id: String)
signal crop_growing(plot_id: int, progress: float)
signal crop_ready(plot_id: int, crop_id: String)
signal crop_harvested(plot_id: int, crop_type: String, amount: int)
signal plot_unlocked(plot_id: int)

# === 재화 이벤트 ===
signal currency_changed(type: String, old_value: int, new_value: int)
signal gold_earned(amount: int, source: String)

# === 런 이벤트 ===
signal run_started(run_number: int)
signal run_ended(result: Dictionary)
signal season_changed(old_season: int, new_season: int)
signal objective_completed(objective_id: String)

# === 증강체 이벤트 ===
signal augment_offered(choices: Array[String])
signal augment_selected(augment_id: String)
signal synergy_activated(synergy_id: String)

# === 위협 이벤트 ===
signal threat_spawned(threat_id: String, target_plot: int)
signal threat_resolved(threat_id: String, success: bool)

# === 메타 이벤트 ===
signal meta_points_earned(amount: int)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal achievement_unlocked(achievement_id: String)

# === 플랫폼 이벤트 ===
signal app_background
signal app_foreground
signal offline_reward_available(duration: float, rewards: Dictionary)
signal save_requested
signal save_completed(success: bool)
```

---

## 4. 시스템별 상세 스펙

### 4.1 농사 시스템 (FarmSystem)

#### 성장 공식

```gdscript
# 초당 성장 진행도
func calculate_growth_per_second(crop: CropData) -> float:
    var base_growth := 1.0 / crop.growth_time

    # 메타 업그레이드 적용
    var meta_mult := 1.0 + (GameManager.meta.upgrades.base_growth_rate * 0.05)

    # 증강체 적용
    var augment_mult := AugmentManager.get_stat(AugmentEffect.GROWTH_SPEED_MULT)
    var augment_add := AugmentManager.get_stat(AugmentEffect.GROWTH_SPEED_ADD)

    # 시즌 보너스
    var season_mult := get_season_growth_multiplier()

    return (base_growth * meta_mult * augment_mult * season_mult) + augment_add
```

#### 수확 계산

```gdscript
func calculate_harvest(crop: CropData) -> Dictionary:
    var base_amount := crop.harvest_amount
    var base_value := crop.base_value

    # 증강체 수확량 배율
    var harvest_mult := AugmentManager.get_stat(AugmentEffect.HARVEST_MULT)

    # 더블 수확 판정
    var double_chance := AugmentManager.get_stat(AugmentEffect.DOUBLE_HARVEST_CHANCE)
    var is_double := randf() < double_chance

    # 골드 배율
    var gold_mult := AugmentManager.get_stat(AugmentEffect.GOLD_MULT)

    var final_amount := int(base_amount * harvest_mult * (2.0 if is_double else 1.0))
    var final_gold := int(base_value * final_amount * gold_mult)

    return {
        "amount": final_amount,
        "gold": final_gold,
        "is_double": is_double,
    }
```

### 4.2 런 시스템 (RunSystem)

#### 런 상태 머신

```
[IDLE] ──start_run()──> [RUNNING] ──end_run()──> [RESULT] ──confirm()──> [IDLE]
                            │
                            ├── [SEASON_TRANSITION]
                            │         └── next_season()
                            │
                            └── [AUGMENT_SELECTION]
                                      └── select_augment()
```

#### 시즌 전환 로직

```gdscript
func transition_season() -> void:
    var old_season := current_season
    current_season = (current_season + 1) % 4

    EventBus.season_changed.emit(old_season, current_season)

    # 시즌별 특수 효과
    match current_season:
        Season.SPRING:
            apply_spring_bonus()
        Season.SUMMER:
            start_drought_timer()
        Season.FALL:
            trigger_festival_event()
        Season.WINTER:
            start_frost_timer()

    season_time_remaining = SEASON_DURATION
```

#### 런 종료 평가

```gdscript
func evaluate_run() -> Dictionary:
    var result := {
        "run_number": run_number,
        "total_gold": run_gold,
        "total_harvests": run_harvests,
        "synergies_activated": run_synergies.size(),
        "objectives_completed": completed_objectives.size(),
    }

    # 메타 포인트 계산
    var meta_points := 10
    meta_points += run_harvests / 10
    meta_points += run_gold / 1000
    meta_points += completed_objectives.size() * 5

    result["meta_points"] = meta_points

    return result
```

### 4.3 증강체 시스템 (AugmentManager)

#### 증강체 제공 알고리즘

```gdscript
func offer_augments(count: int = 3) -> Array[String]:
    var pool := build_weighted_pool()
    var offered: Array[String] = []

    for i in count:
        if pool.is_empty():
            break

        var selected := weighted_random_pick(pool)
        offered.append(selected)

        # 중복 방지
        pool.erase(selected)

        # 상호 배타적 증강체 제거
        var augment := AugmentDatabase.get_augment(selected)
        for exclusive in augment.exclusive_with:
            pool.erase(exclusive)

    EventBus.augment_offered.emit(offered)
    return offered

func build_weighted_pool() -> Dictionary:
    var pool := {}

    for augment in AugmentDatabase.get_all():
        # 이미 최대 스택
        if active_augments.count(augment.id) >= augment.max_stack:
            continue

        # 선행 조건 미충족
        if not has_prerequisites(augment):
            continue

        # 가중치 계산
        var weight := get_rarity_weight(augment.rarity)

        # 신 호감도 보너스
        weight *= 1.0 + (GameManager.meta.god_affinity[augment.god] * 0.1)

        pool[augment.id] = weight

    return pool

func get_rarity_weight(rarity: AugmentData.Rarity) -> float:
    match rarity:
        AugmentData.Rarity.COMMON: return 50.0
        AugmentData.Rarity.UNCOMMON: return 30.0
        AugmentData.Rarity.RARE: return 15.0
        AugmentData.Rarity.EPIC: return 4.0
        AugmentData.Rarity.LEGENDARY: return 1.0
    return 0.0
```

#### 시너지 체크

```gdscript
func check_synergies() -> void:
    for god in AugmentData.GodType.values():
        var count := count_augments_by_god(god)
        var god_name := AugmentData.GodType.keys()[god].to_lower()

        if count >= 3 and not has_synergy("%s_minor" % god_name):
            activate_synergy("%s_minor" % god_name)

        if count >= 5 and not has_synergy("%s_major" % god_name):
            activate_synergy("%s_major" % god_name)

        if count >= 7 and not has_synergy("%s_ultimate" % god_name):
            activate_synergy("%s_ultimate" % god_name)
```

### 4.4 위협 시스템 (ThreatSystem)

#### 위협 스폰 규칙

```gdscript
const THREAT_CONFIG := {
    "caterpillar": {
        "interval": 60.0,     # 1분마다
        "seasons": [0, 1, 2], # 봄, 여름, 가을
        "effect": "growth_slow",
        "value": 0.2,         # 20% 감소
        "duration": 30.0,
    },
    "locusts": {
        "interval": 120.0,
        "seasons": [1, 2],    # 여름, 가을
        "effect": "harvest_reduce",
        "value": 0.1,
        "duration": 45.0,
    },
    "storm": {
        "interval": 180.0,
        "seasons": [0, 1, 2, 3],
        "effect": "plant_disable",
        "duration": 30.0,
    },
    "drought": {
        "interval": 0.0,      # 여름 시작 시 자동
        "seasons": [1],
        "effect": "water_required",
        "duration": 300.0,    # 시즌 전체
    },
    "frost": {
        "interval": 0.0,      # 겨울 시작 시 자동
        "seasons": [3],
        "effect": "emergency_harvest",
        "duration": 30.0,
    },
}
```

### 4.5 오프라인 시스템

#### 오프라인 보상 계산

```gdscript
func calculate_offline_rewards(offline_seconds: float) -> Dictionary:
    var max_offline := 8 * 3600  # 최대 8시간
    var effective_time := min(offline_seconds, max_offline)

    # 오프라인 효율 계산
    var base_efficiency := 0.5  # 기본 50%
    var augment_bonus := AugmentManager.get_stat(AugmentEffect.OFFLINE_MULT)
    var meta_bonus := GameManager.meta.upgrades.get("offline_efficiency", 0) * 0.1

    var efficiency := base_efficiency + augment_bonus + meta_bonus
    efficiency = min(efficiency, 1.0)  # 최대 100%

    # 수확 계산 (현재 농장 상태 기준)
    var gold := 0
    var growth_ticks := 0

    for plot in GameManager.game_data.farm.plots:
        if plot.crop_id.is_empty():
            continue

        var crop := CropDatabase.get_crop(plot.crop_id)
        var growth_per_sec := calculate_growth_per_second(crop)
        var harvests := int(effective_time * efficiency * growth_per_sec)

        gold += harvests * crop.base_value * crop.harvest_amount
        growth_ticks += harvests

    return {
        "offline_duration": offline_seconds,
        "effective_duration": effective_time * efficiency,
        "gold": gold,
        "growth_ticks": growth_ticks,
    }
```

---

## 5. 플랫폼 연동

### 5.1 메시지 프로토콜

#### Godot → Native

```gdscript
# PlatformBridge.gd
enum MessageType {
    SAVE_GAME,
    LOAD_GAME,
    PURCHASE_REQUEST,
    NOTIFICATION_SCHEDULE,
    ANALYTICS_EVENT,
    CLOUD_SAVE,
    CLOUD_LOAD,
    HAPTIC_FEEDBACK,
    REVIEW_REQUEST,
    SHARE,
    AD_SHOW,
}

func send_message(type: MessageType, payload: Dictionary) -> void:
    var message := {
        "type": MessageType.keys()[type],
        "payload": payload,
        "timestamp": Time.get_unix_time_from_system(),
    }

    match OS.get_name():
        "Android", "iOS":
            _send_to_native(message)
        "Windows", "macOS", "Linux":
            _send_to_steam(message)
```

#### Native → Godot

```typescript
// GodotBridge.ts
export type NativeMessageType =
    | 'PURCHASE_RESULT'
    | 'OFFLINE_REWARD'
    | 'PUSH_TOKEN'
    | 'CLOUD_DATA'
    | 'AD_COMPLETED'
    | 'APP_STATE_CHANGE'
    | 'DEEP_LINK';

interface NativeMessage<T> {
    type: NativeMessageType;
    payload: T;
    timestamp: number;
}
```

### 5.2 Steam 연동

```gdscript
# steam_integration.gd

## 업적 목록
const ACHIEVEMENTS := {
    "first_harvest": "ACH_FIRST_HARVEST",
    "gold_1000": "ACH_GOLD_1000",
    "gold_10000": "ACH_GOLD_10000",
    "run_complete": "ACH_RUN_COMPLETE",
    "synergy_3": "ACH_SYNERGY_3",
    "all_gods": "ACH_ALL_GODS",
}

## 리더보드
const LEADERBOARDS := {
    "high_score": "LB_HIGH_SCORE",
    "fastest_run": "LB_FASTEST_RUN",
    "total_harvests": "LB_TOTAL_HARVESTS",
}

## 통계
const STATS := {
    "total_gold": "STAT_TOTAL_GOLD",
    "total_runs": "STAT_TOTAL_RUNS",
    "total_harvests": "STAT_TOTAL_HARVESTS",
    "total_playtime": "STAT_TOTAL_PLAYTIME",
}
```

### 5.3 모바일 인앱 결제

```typescript
// IAPService.ts
export const PRODUCTS = {
    vip: {
        id: 'com.snovium.idlefarm.vip',
        type: 'non-consumable',
        price: 9.99,
    },
    battlepass: {
        id: 'com.snovium.idlefarm.battlepass',
        type: 'subscription',
        price: 4.99,
        period: 'monthly',
    },
    starter_pack: {
        id: 'com.snovium.idlefarm.starter',
        type: 'non-consumable',
        price: 1.99,
    },
    gems_100: {
        id: 'com.snovium.idlefarm.gems100',
        type: 'consumable',
        price: 0.99,
    },
};
```

---

## 6. 저장 시스템

### 6.1 저장 파일 형식

```
user://
├── save_slot_0.sav      # 메인 세이브 (암호화)
├── save_slot_0.sav.bak  # 백업
├── settings.cfg         # 설정 (평문)
└── cache/
    └── crops.cache      # 작물 데이터 캐시
```

### 6.2 암호화

```gdscript
# save_manager.gd

const SAVE_KEY := "IdleFarm_SaveKey_2025_v1"

func save_to_file(data: GameData, slot: int = 0) -> bool:
    var json := JSON.stringify(data.to_dict())
    var encrypted := encrypt_data(json)

    var path := "user://save_slot_%d.sav" % slot
    var backup_path := path + ".bak"

    # 기존 파일 백업
    if FileAccess.file_exists(path):
        DirAccess.copy_absolute(path, backup_path)

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(encrypted)
    file.close()
    return true

func encrypt_data(data: String) -> String:
    var aes := AESContext.new()
    var key := SAVE_KEY.sha256_buffer()
    var iv := key.slice(0, 16)

    aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
    var encrypted := aes.update(data.to_utf8_buffer())
    aes.finish()

    return Marshalls.raw_to_base64(encrypted)
```

### 6.3 클라우드 저장

```gdscript
# Steam Cloud
func save_to_steam_cloud() -> bool:
    if not SteamIntegration.is_available():
        return false

    var data := GameManager.game_data.to_dict()
    var json := JSON.stringify(data)

    return Steam.fileWrite("cloud_save.json", json.to_utf8_buffer())

# Mobile Cloud
func save_to_mobile_cloud() -> void:
    var data := GameManager.game_data.to_dict()
    PlatformBridge.send_message(
        PlatformBridge.MessageType.CLOUD_SAVE,
        {"data": data}
    )
```

---

## 7. 성능 최적화

### 7.1 틱 시스템

```gdscript
# time_manager.gd

const TICK_RATE := 10.0  # 초당 10틱 (100ms)

var tick_accumulator := 0.0

func _process(delta: float) -> void:
    tick_accumulator += delta

    while tick_accumulator >= 1.0 / TICK_RATE:
        tick_accumulator -= 1.0 / TICK_RATE
        _process_tick(1.0 / TICK_RATE)

func _process_tick(tick_delta: float) -> void:
    EventBus.tick.emit(tick_delta)
```

### 7.2 오브젝트 풀링

```gdscript
# object_pool.gd

var pools: Dictionary = {}

func get_object(scene_path: String) -> Node:
    if not pools.has(scene_path):
        pools[scene_path] = []

    var pool: Array = pools[scene_path]

    if pool.is_empty():
        return load(scene_path).instantiate()

    return pool.pop_back()

func return_object(scene_path: String, obj: Node) -> void:
    obj.get_parent().remove_child(obj)
    pools[scene_path].append(obj)
```

### 7.3 배칭 최적화

```gdscript
# 대량 작업은 프레임 분산
func harvest_all_batched() -> void:
    var ready_plots := get_ready_plots()
    var batch_size := 5
    var index := 0

    while index < ready_plots.size():
        for i in range(batch_size):
            if index + i >= ready_plots.size():
                break
            ready_plots[index + i].harvest()

        index += batch_size
        await get_tree().process_frame
```

---

## 8. 테스트 전략

### 8.1 단위 테스트

```gdscript
# tests/test_farm_system.gd
extends GutTest

func test_crop_growth_calculation():
    var wheat := CropDatabase.get_crop("wheat")
    var growth := FarmManager.calculate_growth_per_second(wheat)

    assert_almost_eq(growth, 0.1, 0.01)  # 10초 성장 = 0.1/초

func test_harvest_gold_calculation():
    var wheat := CropDatabase.get_crop("wheat")
    var result := FarmManager.calculate_harvest(wheat)

    assert_eq(result.gold, 10)  # 5골드 × 2개

func test_augment_stacking():
    AugmentManager.add_augment("fast_growth")
    AugmentManager.add_augment("fast_growth")  # 최대 스택 1

    assert_eq(AugmentManager.count_augment("fast_growth"), 1)
```

### 8.2 통합 테스트

```gdscript
# tests/test_run_flow.gd
extends GutTest

func test_complete_run():
    # 런 시작
    RunManager.start_run()
    assert_true(RunManager.is_active)

    # 시뮬레이션 (4시즌)
    for season in 4:
        simulate_season()
        RunManager.transition_season()

    # 런 종료
    var result := RunManager.end_run()
    assert_false(RunManager.is_active)
    assert_gt(result.meta_points, 0)
```

---

## 9. 빌드 설정

### 9.1 Export Presets

```ini
# godot/export_presets.cfg

[preset.0]
name="Steam Windows"
platform="Windows Desktop"
export_filter="all_resources"
custom_features="steam"
script_export_mode=1

[preset.1]
name="Steam macOS"
platform="macOS"
export_filter="all_resources"
custom_features="steam"

[preset.2]
name="Steam Linux"
platform="Linux/X11"
export_filter="all_resources"
custom_features="steam"

[preset.3]
name="Android"
platform="Android"
export_filter="all_resources"
custom_features="mobile"

[preset.4]
name="iOS"
platform="iOS"
export_filter="all_resources"
custom_features="mobile"
```

### 9.2 환경 변수

```bash
# .env.example
STEAM_APP_ID=0000000
STEAM_API_KEY=your_steam_api_key

GOOGLE_PLAY_KEY=path/to/key.json
APPLE_TEAM_ID=XXXXXXXXXX

SENTRY_DSN=https://xxx@sentry.io/xxx
AMPLITUDE_API_KEY=your_amplitude_key
```

---

## 10. 버전 관리

### 10.1 세이브 마이그레이션

```gdscript
# save_migration.gd

const MIGRATIONS := {
    "1.0.0": "_migrate_1_0_0",
    "1.1.0": "_migrate_1_1_0",
}

func migrate(data: Dictionary, from_version: String) -> Dictionary:
    var versions := MIGRATIONS.keys()
    var start_index := versions.find(from_version) + 1

    for i in range(start_index, versions.size()):
        var version := versions[i]
        var method := MIGRATIONS[version]
        data = call(method, data)
        data.version = version

    return data

func _migrate_1_0_0(data: Dictionary) -> Dictionary:
    # 예: 신규 필드 추가
    if not data.has("meta"):
        data["meta"] = {}
    if not data.meta.has("god_affinity"):
        data.meta["god_affinity"] = {}
    return data
```
