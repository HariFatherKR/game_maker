# IdleFarm Roguelike - 프로젝트 가이드

## 프로젝트 개요

방치형 농사 게임 + 로그라이트 증강체 시스템을 결합한 Steam/모바일 멀티플랫폼 게임

- **장르**: Idle Farm + Roguelite Augment System
- **플랫폼**: Steam (PC), iOS, Android
- **엔진**: Godot 4.5+ (GDScript)
- **모바일**: React Native + @borndotcom/react-native-godot

---

## 아키텍처 (5계층 구조)

```
┌─────────────────────────────────────────────────────┐
│  Layer 5: Platform (Steam/Mobile)                   │
│  - steam_integration.gd, mobile_bridge.gd           │
├─────────────────────────────────────────────────────┤
│  Layer 4: UI/Presentation                           │
│  - scenes/ui/, HUD, menus, dialogs                  │
├─────────────────────────────────────────────────────┤
│  Layer 3: Game Systems                              │
│  - Farm, Roguelike Augment, Economy, Progression    │
├─────────────────────────────────────────────────────┤
│  Layer 2: Core Services (Autoload)                  │
│  - GameManager, SaveManager, TimeManager, EventBus  │
├─────────────────────────────────────────────────────┤
│  Layer 1: Data/Resources                            │
│  - resources/, shared/schemas/, shared/constants/   │
└─────────────────────────────────────────────────────┘
```

---

## 디렉토리 구조

```
game_maker/
├── godot/                    # Godot 핵심 게임
│   ├── project.godot         # 프로젝트 설정
│   ├── addons/godotsteam/    # Steam SDK GDExtension
│   ├── assets/               # 에셋 파일
│   │   ├── sprites/          # 스프라이트 이미지
│   │   ├── audio/            # 사운드/음악
│   │   └── data/             # JSON 데이터 파일
│   ├── scenes/               # 씬 파일 (.tscn)
│   │   ├── main/             # 메인 씬, 부트스트랩
│   │   ├── farm/             # 농장 관련 씬
│   │   ├── roguelike/        # 로그라이트 관련 씬
│   │   └── ui/               # UI 씬
│   ├── scripts/              # GDScript 파일
│   │   ├── autoload/         # 싱글톤 (자동 로드)
│   │   ├── core/             # 핵심 클래스
│   │   ├── farm/             # 농사 시스템
│   │   ├── roguelike/        # 증강체 시스템
│   │   └── platform/         # 플랫폼별 코드
│   └── resources/            # .tres 리소스 파일
├── mobile/                   # React Native 모바일 앱
│   ├── src/
│   │   ├── components/       # React 컴포넌트
│   │   ├── services/godot/   # Godot 브릿지 서비스
│   │   └── hooks/            # React 훅
│   └── package.json
├── shared/                   # 공유 데이터
│   ├── schemas/              # 데이터 스키마 (JSON Schema)
│   ├── constants/            # 상수 정의
│   └── localization/         # 다국어 번역
└── scripts/                  # 빌드/배포 스크립트
```

---

## 핵심 파일 설명

### Autoload 싱글톤 (godot/scripts/autoload/)

| 파일 | 역할 |
|------|------|
| `event_bus.gd` | 시그널 중앙화, 느슨한 결합 |
| `game_manager.gd` | 게임 전역 상태, 게임 루프, 재화 관리 |
| `save_manager.gd` | 세이브/로드, AES-256 암호화, 버전 마이그레이션 |
| `time_manager.gd` | 게임 시간, 일일 사이클, 오프라인 보상 계산 |
| `platform_bridge.gd` | Steam/Mobile API 추상화 레이어 |
| `run_manager.gd` | 런 생명주기, 시즌 전환, 증강체 제공 |
| `augment_manager.gd` | 증강체 풀 관리, 시너지 계산, 스탯 적용 |
| `farm_manager.gd` | 농지 등록/해금, 대량 작업, 자동화 |

### 게임 시스템 (godot/scripts/)

| 디렉토리 | 역할 |
|----------|------|
| `farm/` | 농지, 작물, 수확, 자동화 시스템 |
| `roguelike/` | 증강체, 런, 메타 진행도, 시너지 |
| `core/` | GameData, 재화, 인벤토리, 스탯 시스템 |

### 구현 완료 시스템

| 시스템 | 상태 | 설명 |
|--------|------|------|
| GameData | ✅ | 전체 게임 상태 클래스 (CurrencyData, FarmData, RunData, MetaProgressData, StatsData, SettingsData) |
| RunManager | ✅ | 런 생명주기, 시즌 시스템 (봄/여름/가을/겨울), 증강체 제공 |
| AugmentManager | ✅ | 증강체 선택, 적용, 시너지 계산, 신 호감도 |
| FarmPlot | ✅ | 농지 상태, 작물 성장, 수확, 증강체 보너스 적용 |
| FarmManager | ✅ | 농지 등록, 해금, 대량 수확/심기, 자동화 |
| 증강체 데이터베이스 | ✅ | 17개 증강체 (Common~Legendary) |
| 작물 데이터베이스 | ✅ | 12개 작물 (Common~Legendary) |
| UI 시스템 | ✅ | HUD, 런 정보 패널, 증강체 선택 팝업, 토스트 알림 |

---

## 코드 컨벤션

### GDScript

```gdscript
# 클래스명: PascalCase
class_name FarmPlot

# 상수: SCREAMING_SNAKE_CASE
const MAX_CROPS: int = 100

# 변수/함수: snake_case
var current_crop: Crop
func harvest_crop() -> int:
    pass

# 시그널: snake_case, 과거형
signal crop_harvested(crop: Crop, amount: int)

# private: 언더스코어 접두사
var _internal_state: Dictionary
func _calculate_yield() -> float:
    pass

# 타입 힌트 필수
func grow(delta: float) -> void:
    pass
```

### TypeScript (Mobile)

```typescript
// 인터페이스: I 접두사
interface ICropData {
  id: string;
  growthTime: number;
}

// 서비스: camelCase
const godotBridge = {
  sendMessage: (type: string, payload: object) => void,
  onMessage: (callback: MessageCallback) => void,
};

// 훅: use 접두사
function useGodotState<T>(key: string): T;
```

---

## 빌드 명령어

### Godot (개발)

```bash
# 에디터 실행
cd godot && godot --path . --editor

# 디버그 실행
cd godot && godot --path . --debug

# 헤드리스 테스트
cd godot && godot --path . --headless --script res://tests/run_tests.gd
```

### Steam 빌드

```bash
# 디버그 빌드
./scripts/build_steam.sh --debug

# 릴리스 빌드
./scripts/build_steam.sh --release

# Steam 업로드
./scripts/upload_steam.sh --branch beta
```

### Mobile 빌드

```bash
# iOS
cd mobile && pnpm install && pnpm ios

# Android
cd mobile && pnpm install && pnpm android

# Godot 라이브러리 빌드 (for mobile)
./scripts/build_godot_lib.sh --platform ios
./scripts/build_godot_lib.sh --platform android
```

---

## Steam 통합 가이드

### GodotSteam 설정

1. [GodotSteam](https://godotsteam.com/)에서 GDExtension 다운로드
2. `godot/addons/godotsteam/`에 복사
3. `project.godot`에서 확장 활성화

### 주요 API

```gdscript
# 초기화 (platform_bridge.gd에서)
func init_steam() -> bool:
    var result = Steam.steamInit()
    return result.status == 1

# 업적
Steam.setAchievement("FIRST_HARVEST")

# 클라우드 세이브
Steam.fileWrite("save.dat", save_data)
var data = Steam.fileRead("save.dat")

# 리더보드
Steam.findLeaderboard("HighScore")
Steam.uploadLeaderboardScore(score)
```

---

## Mobile 연동 가이드

### react-native-godot 설정

```typescript
import { GodotView } from '@borndotcom/react-native-godot';

// Godot 뷰 렌더링
<GodotView
  source={require('./godot/build/mobile.pck')}
  onMessage={handleGodotMessage}
  sendMessage={messageRef}
/>
```

### 브릿지 통신 프로토콜

```typescript
// Godot -> React Native
interface GodotMessage {
  type: 'SAVE_GAME' | 'PURCHASE' | 'NOTIFICATION' | 'ANALYTICS';
  payload: object;
}

// React Native -> Godot
interface NativeMessage {
  type: 'RESTORE_PURCHASE' | 'PUSH_TOKEN' | 'OFFLINE_REWARD';
  payload: object;
}
```

---

## 핵심 게임 시스템

### 농사 시스템 (Farm)

```gdscript
# 작물 성장 공식
growth_per_tick = base_growth * (1 + augment_bonus) * time_multiplier

# 오프라인 보상
offline_production = production_rate * offline_duration * offline_efficiency
```

### 증강체 시스템 (Roguelike Augment)

```gdscript
# 증강체 레어리티
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# 증강체 선택 (런마다 3개 중 선택)
func offer_augments(pool: Array[Augment], count: int = 3) -> Array[Augment]:
    return weighted_random_selection(pool, count)

# 시너지 보너스
func calculate_synergy(augments: Array[Augment]) -> float:
    # 같은 카테고리 증강체 시너지
    pass
```

### 재화 시스템 (Economy)

| 재화 | 용도 |
|------|------|
| `gold` | 기본 재화, 작물 판매로 획득 |
| `gems` | 프리미엄 재화, 증강체 리롤 |
| `seeds` | 작물 심기용 |
| `meta_points` | 영구 업그레이드용 (런 종료 시 획득) |

---

## 성능 가이드라인

1. **오브젝트 풀링**: 반복 생성되는 작물/파티클 풀링
2. **청크 로딩**: 큰 농장은 화면 밖 청크 비활성화
3. **틱 최적화**: 모든 작물을 매 프레임 업데이트하지 않음
4. **모바일 배터리**: 백그라운드 시 프레임레이트 제한

---

## 테스트

```bash
# 유닛 테스트
cd godot && godot --headless --script res://tests/run_tests.gd

# 통합 테스트 (자동화)
./scripts/run_integration_tests.sh
```

---

## 참고 자료

- [Godot 4.5 Documentation](https://docs.godotengine.org/)
- [GodotSteam Documentation](https://godotsteam.com/)
- [react-native-godot](https://github.com/nicovank/react-native-godot)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
