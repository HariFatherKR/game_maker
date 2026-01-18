# IdleFarm Roguelike - 개발 Phase 및 Task 정의

> **버전**: 1.0.0
> **최종 업데이트**: 2026-01-19
> **상태**: 전 Phase 완료

---

## 진행 상황 요약

| Phase | 상태 | 진행률 | 비고 |
|-------|------|--------|------|
| **Phase 1: MVP** | ✅ 완료 | 100% | 핵심 게임플레이 |
| **Phase 2: 확장** | ✅ 완료 | 100% | 신, 위협, 스토리, 펫 |
| **Phase 3: 소셜** | ✅ 완료 | 100% | 랭킹, 배틀패스, 친구, 이벤트 |
| **Phase 4: 엔드게임** | ✅ 완료 | 100% | 바이옴, 추가 신, 엔딩, 하드모드 |

---

## Phase 1: MVP ✅ 완료

### 핵심 인프라
- [x] Godot 프로젝트 설정
- [x] Autoload 시스템 (EventBus, GameManager, SaveManager, TimeManager, PlatformBridge, RunManager)
- [x] AES-256-CBC 암호화 저장

### 농사 시스템
- [x] 작물 12종 (Common~Legendary)
- [x] FarmPlot 상태 관리
- [x] FarmManager 자동화

### 런/시즌 시스템
- [x] RunManager 런 생명주기
- [x] 4계절 순환 (봄/여름/가을/겨울)
- [x] 런 평가 및 메타 포인트

### 증강체 시스템
- [x] 17종 증강체 (Common~Legendary)
- [x] AugmentManager 풀링/시너지
- [x] 신 호감도 시스템 (5신)

### UI/UX
- [x] HUD, 런 정보 패널
- [x] 증강체 선택 팝업
- [x] 토스트 알림

### 플랫폼
- [x] Steam 업적 15종
- [x] AchievementTracker 자동 해금

---

## Phase 2: 확장 ✅ 완료

### 위협 시스템
- [x] ThreatManager
- [x] 해충 5종 (진딧물, 메뚜기, 두더지, 까마귀, 애벌레)
- [x] 재해 5종 (가뭄, 서리, 폭풍, 홍수, 폭염)
- [x] 시즌별 위협

### 펫 시스템
- [x] PetManager
- [x] 펫 5종 (고양이, 강아지, 부엉이, 황금닭, 드래곤)
- [x] 패시브 보너스 및 활성 능력

### 스토리/튜토리얼
- [x] StoryData (캐릭터 9명, 대화)
- [x] TutorialManager (9단계)
- [x] DialogueBox UI

---

## Phase 3: 소셜 ✅ 완료

### 랭킹 시스템
- [x] LeaderboardManager
- [x] 5종 리더보드 (총 골드, 최고 점수, 총 수확, 스피드런, 주간)
- [x] Steam 리더보드 연동 준비

### 배틀패스
- [x] BattlePassManager
- [x] 50레벨 무료/프리미엄 트랙
- [x] XP 시스템
- [x] 시즌 보상

### 친구 시스템
- [x] FriendManager
- [x] 친구 추가/삭제
- [x] 선물 교환
- [x] 농장 방문

### 이벤트 시스템
- [x] SocialEventManager
- [x] 8종 이벤트 (수확축제, 황금시간, 더블XP 등)
- [x] 시간 한정 보너스

---

## Phase 4: 엔드게임 ✅ 완료

### 바이옴 시스템
- [x] BiomeManager
- [x] 6종 바이옴 (평원, 사막, 눈, 화산, 늪, 수정동굴)
- [x] 15종 특수 작물
- [x] 바이옴별 수정자

### 추가 신
- [x] ExtendedGodsData
- [x] 5명 추가 신 (데메테르, 포세이돈, 아폴로, 하데스, 가이아)
- [x] 22종 추가 증강체

### 엔딩 시스템
- [x] EndingManager
- [x] 5종 엔딩 (일반, 좋은, 완벽, 비밀, 진정한)
- [x] 엔딩별 보상 및 해금

### 하드모드
- [x] HardModeManager
- [x] 난이도 수정자
- [x] 5종 도전과제
- [x] 하드모드 전용 위협 4종

---

## 구현된 시스템 목록

### Autoload 싱글톤 (20개)

| 시스템 | 파일 | 역할 |
|--------|------|------|
| EventBus | autoload/event_bus.gd | 시그널 중앙화 |
| GameManager | autoload/game_manager.gd | 게임 상태 |
| SaveManager | autoload/save_manager.gd | 저장/로드 |
| TimeManager | autoload/time_manager.gd | 시간/오프라인 |
| PlatformBridge | autoload/platform_bridge.gd | 플랫폼 추상화 |
| RunManager | autoload/run_manager.gd | 런 관리 |
| AugmentManager | roguelike/augment_manager.gd | 증강체 |
| FarmManager | farm/farm_manager.gd | 농지 |
| AchievementTracker | platform/achievement_tracker.gd | 업적 |
| ThreatManager | threats/threat_manager.gd | 위협 |
| PetManager | pets/pet_manager.gd | 펫 |
| TutorialManager | story/tutorial_manager.gd | 튜토리얼 |
| LeaderboardManager | social/leaderboard_manager.gd | 랭킹 |
| BattlePassManager | social/battle_pass.gd | 배틀패스 |
| SocialEventManager | social/event_manager.gd | 이벤트 |
| FriendManager | social/friend_manager.gd | 친구 |
| BiomeManager | endgame/biome_manager.gd | 바이옴 |
| EndingManager | endgame/ending_manager.gd | 엔딩 |
| HardModeManager | endgame/hard_mode.gd | 하드모드 |

### 데이터 클래스

| 파일 | 내용 |
|------|------|
| game_data.gd | 전체 게임 상태 |
| crop_database.gd | 작물 12종 |
| augment_database.gd | 증강체 17종 |
| story_data.gd | 스토리/대화 |
| extended_gods.gd | 추가 신 5종 + 증강체 22종 |

---

## 게임 콘텐츠 요약

| 카테고리 | 수량 |
|----------|------|
| 작물 | 27종 (기본 12 + 특수 15) |
| 증강체 | 39종 (기본 17 + 추가 22) |
| 신 | 10명 (기본 5 + 추가 5) |
| 펫 | 5종 |
| 바이옴 | 6종 |
| 해충 | 5종 |
| 재해 | 5종 |
| 하드모드 위협 | 4종 |
| 업적 | 15종 |
| 엔딩 | 5종 |

---

## 버전 히스토리

| 버전 | 날짜 | 내용 |
|------|------|------|
| 0.1.0 | 2026-01-18 | 초기 구조 생성 |
| 0.2.0 | 2026-01-19 | Phase 1-2 완료 |
| 1.0.0 | 2026-01-19 | Phase 3-4 완료, 전체 기능 구현 |

---

## 다음 단계 (출시 준비)

### Pre-Release
- [ ] 전체 테스트 (유닛, 통합)
- [ ] 밸런스 조정
- [ ] 버그 수정
- [ ] 성능 최적화

### Release
- [ ] Steam 빌드 업로드
- [ ] iOS/Android 빌드
- [ ] 릴리스 노트 작성
- [ ] 스토어 페이지 준비

### Post-Release
- [ ] 모니터링
- [ ] 핫픽스 대기
- [ ] 유저 피드백 수집
