# IdleFarm Roguelike - 개발 Phase 및 Task 정의

> **버전**: 1.1.0
> **최종 업데이트**: 2026-01-19
> **기준 문서**:
> - docs/GAME_DESIGN_DOCUMENT.md
> - .claude/TECHNICAL_SPEC.md

---

## 진행 상황 요약

| Phase | 상태 | 진행률 | 비고 |
|-------|------|--------|------|
| **Phase 1: MVP** | ✅ 완료 | 100% | 커밋 완료 |
| **Phase 2: 확장** | ✅ 완료 | 100% | 신, 위협, 스토리, 펫 |
| **Phase 3: 소셜** | ⏳ 대기 | 0% | 랭킹, 배틀패스 |
| **Phase 4: 엔드게임** | ⏳ 대기 | 0% | 추가 콘텐츠 |

---

## Phase 개요

| Phase | 기간 | 목표 | 산출물 |
|-------|------|------|--------|
| **Phase 1: MVP** | 12주 | 핵심 게임플레이 완성 | Steam/모바일 출시 가능 빌드 |
| **Phase 2: 확장** | 8주 | 깊이 있는 콘텐츠 | 신 시스템, 스토리 |
| **Phase 3: 소셜** | 8주 | 리텐션 강화 | 랭킹, 시즌 |
| **Phase 4: 엔드게임** | 12주 | 장기 플레이 | 추가 바이옴, 엔딩 |

---

## Phase 1: MVP (12주) ✅ 완료

### Sprint 1-2: 핵심 인프라 (2주) ✅

#### 1.1 프로젝트 구조 완성
- [x] Godot 프로젝트 최종 설정
  - 파일: `godot/project.godot`
  - 작업: 렌더링, 입력, 오디오 설정 최적화
- [x] React Native 프로젝트 구조
  - 파일: `mobile/`
  - 작업: 기본 구조 생성
- [x] Steam SDK 연동 준비
  - 파일: `godot/addons/godotsteam/`

#### 1.2 Autoload 시스템 강화
- [x] EventBus 시그널 확장
  - 파일: `godot/scripts/autoload/event_bus.gd`
  - 추가: 런 관련 시그널, 위협 시그널
- [x] TimeManager 개선
  - 파일: `godot/scripts/autoload/time_manager.gd`
  - 작업: 틱 시스템 최적화, 일시정지 처리
- [x] SaveManager 암호화 구현
  - 파일: `godot/scripts/autoload/save_manager.gd`
  - 작업: AES-256-CBC 암호화, 백업 시스템

---

### Sprint 3-4: 농사 시스템 (2주) ✅

#### 3.1 작물 데이터베이스
- [x] CropData 정의
  - 파일: `godot/scripts/farm/crop_database.gd`
  - 작업: 티어, 성장시간, 가치 등 필드 완성
- [x] 작물 12종 데이터 입력
  - 내용: Common 3, Uncommon 3, Rare 3, Epic 2, Legendary 1

#### 3.2 농지 시스템
- [x] FarmPlot 클래스 완성
  - 파일: `godot/scripts/farm/farm_plot.gd`
  - 작업: 상태별 시각 피드백
- [x] FarmManager 기능 확장
  - 파일: `godot/scripts/farm/farm_manager.gd`
  - 추가: 해금 비용 계산, 일괄 작업, 자동화

#### 3.3 수확 시스템
- [x] 수확 계산 로직
  - 작업: 배율 적용, 더블 수확 판정

---

### Sprint 5-6: 런 시스템 (2주) ✅

#### 5.1 런 상태 관리
- [x] RunManager 싱글톤 생성
  - 파일: `godot/scripts/autoload/run_manager.gd`
  - 작업: 런 시작/종료, 시즌 전환

#### 5.2 시즌 시스템
- [x] 시즌 전환 로직
  - 작업: 5분 타이머, 시즌별 이벤트

#### 5.3 런 결과 처리
- [x] 런 평가 시스템
  - 작업: 목표 체크, 메타 포인트 계산

---

### Sprint 7-8: 증강체 시스템 (2주) ✅

#### 7.1 증강체 데이터
- [x] Augment Resource 정의
  - 파일: `godot/scripts/roguelike/augment.gd`
  - 필드: 신, 등급, 효과, 제한
- [x] AugmentEffect 시스템
  - 파일: `godot/scripts/roguelike/augment_effect.gd`
- [x] 증강체 17종 데이터 입력
  - 파일: `godot/scripts/roguelike/augment_database.gd`

#### 7.2 증강체 선택 시스템
- [x] AugmentManager 풀 시스템
  - 파일: `godot/scripts/roguelike/augment_manager.gd`
  - 작업: 가중치 풀링, 배타 처리
- [x] 증강체 선택 UI (동적 생성)
  - 3개 카드 표시, 리롤 버튼

#### 7.3 증강체 효과 적용
- [x] 스탯 계산 시스템
  - 신 호감도, 시너지 보너스
- [x] 활성 증강체 UI
  - 아이콘 목록, 개수 표시

---

### Sprint 9-10: UI/UX (2주) ✅

#### 9.1 메인 HUD
- [x] 상단 리소스 바
  - 표시: 골드, 젬, 씨앗
- [x] 런 정보 패널
  - 시즌, 타이머 표시

#### 9.2 팝업 시스템
- [x] 증강체 팝업 (동적 생성)
- [x] 토스트 알림 시스템
  - 타입별 색상, 애니메이션

#### 9.3 튜토리얼
- [x] 튜토리얼 매니저
  - 파일: `godot/scripts/story/tutorial_manager.gd`
  - 작업: 단계별 진행
- [x] 튜토리얼 데이터
  - 파일: `godot/scripts/story/story_data.gd`

---

### Sprint 11-12: 플랫폼 통합 및 QA (2주) ✅

#### 11.1 Steam 빌드
- [x] Steam 업적 연동
  - 파일: `godot/scripts/platform/steam_integration.gd`
  - 업적: 15개 업적
- [x] AchievementTracker
  - 파일: `godot/scripts/platform/achievement_tracker.gd`

#### 11.2 모바일 준비
- [x] 모바일 설정
  - portrait 모드, 터치 입력

---

## Phase 2: 확장 (8주) ✅ 완료

### Sprint 1-2: 신 시스템 (2주) ✅

#### 신 호감도
- [x] 신 호감도 데이터 구조
  - 5신: Ceres, Plutus, Chronos, Tyche, Hephaestus
- [x] 호감도 획득 로직
  - 조건: 증강체 선택, 특정 행동
- [x] 시너지 시스템
  - AugmentManager에 통합

---

### Sprint 3-4: 위협 시스템 (2주) ✅

#### 해충
- [x] ThreatManager
  - 파일: `godot/scripts/threats/threat_manager.gd`
- [x] 해충 5종 구현
  - 진딧물, 메뚜기, 두더지, 까마귀, 애벌레

#### 재해
- [x] 시즌별 재해 시스템
  - 가뭄, 서리, 폭풍, 홍수, 폭염

---

### Sprint 5-6: 스토리 Act 1 (2주) ✅

#### 내러티브
- [x] 스토리 데이터 구조
  - 파일: `godot/scripts/story/story_data.gd`
  - 캐릭터, 대화, 튜토리얼 데이터
- [x] 대화 시스템
  - 파일: `godot/scripts/ui/dialogue_box.gd`
  - 타이핑 효과, 선택지, 자동 진행
- [x] TutorialManager
  - 파일: `godot/scripts/story/tutorial_manager.gd`

---

### Sprint 7-8: 펫 시스템 (2주) ✅

#### 펫 기능
- [x] PetManager
  - 파일: `godot/scripts/pets/pet_manager.gd`
- [x] 펫 5종 구현
  - 고양이, 강아지, 부엉이, 황금닭, 드래곤
- [x] 펫 능력 시스템
  - 패시브 스탯, 활성 능력

---

## Phase 3: 소셜 (8주) ⏳ 대기

### Sprint 1-2: 랭킹 시스템

- [ ] 리더보드 백엔드 연동
  - Steam/GameCenter/Play Games
- [ ] 랭킹 UI
  - 전체, 친구, 주간
- [ ] 스코어 계산 로직

---

### Sprint 3-4: 시즌 배틀패스

- [ ] 배틀패스 데이터 구조
  - 무료/프리미엄 트랙
- [ ] 보상 시스템
  - 50레벨 보상
- [ ] 배틀패스 UI
  - 진행도, 보상 수령

---

### Sprint 5-6: 친구 시스템

- [ ] 친구 초대/추가
- [ ] 친구 농장 방문
- [ ] 선물 시스템

---

### Sprint 7-8: 이벤트 시스템

- [ ] 시즌 이벤트 프레임워크
- [ ] 첫 이벤트 컨텐츠
- [ ] 이벤트 상점

---

## Phase 4: 엔드게임 (12주) ⏳ 대기

### Sprint 1-3: 추가 바이옴

- [ ] 사막 바이옴
- [ ] 눈 바이옴
- [ ] 화산 바이옴
- [ ] 바이옴별 작물/위협

---

### Sprint 4-6: 추가 신

- [ ] 데메테르 (대지)
- [ ] 포세이돈 (물)
- [ ] 아폴로 (빛)
- [ ] 신별 증강체 6종씩

---

### Sprint 7-9: 엔딩 콘텐츠

- [ ] 5개 엔딩 구현
- [ ] Act 2, 3 스토리
- [ ] 진정한 엔딩 보상

---

### Sprint 10-12: 하드모드

- [ ] 하드모드 규칙
- [ ] 추가 위협
- [ ] 하드모드 전용 보상

---

## 작업 우선순위 매트릭스

### 🔴 Critical (필수) - ✅ 완료
- Autoload 시스템
- 농사 핵심 로직
- 저장/로드
- 기본 UI

### 🟠 High (중요) - ✅ 완료
- 런/시즌 시스템
- 증강체 선택
- Steam/모바일 빌드
- 튜토리얼

### 🟡 Medium (권장) - ✅ 완료
- 시너지 시스템
- 위협 시스템
- 스토리 Act 1
- 펫 시스템

### 🟢 Low (선택) - ⏳ 대기
- 추가 바이옴
- 소셜 기능
- 엔드게임 콘텐츠
- 하드모드

---

## 구현된 시스템 목록

### Autoload 싱글톤 (13개)
| 파일 | 역할 |
|------|------|
| `event_bus.gd` | 시그널 중앙화, 느슨한 결합 |
| `game_manager.gd` | 게임 전역 상태, 게임 루프, 재화 관리 |
| `save_manager.gd` | 세이브/로드, AES-256 암호화 |
| `time_manager.gd` | 게임 시간, 틱 시스템, 오프라인 보상 |
| `platform_bridge.gd` | Steam/Mobile API 추상화 |
| `run_manager.gd` | 런 생명주기, 시즌 전환 |
| `augment_manager.gd` | 증강체 풀, 시너지 계산 |
| `farm_manager.gd` | 농지 관리, 자동화 |
| `achievement_tracker.gd` | Steam 업적 추적 |
| `threat_manager.gd` | 해충/재해 관리 |
| `pet_manager.gd` | 펫 시스템 |
| `tutorial_manager.gd` | 튜토리얼/스토리 |

### 데이터 클래스
| 파일 | 내용 |
|------|------|
| `game_data.gd` | 전체 게임 상태 |
| `crop_database.gd` | 작물 12종 |
| `augment_database.gd` | 증강체 17종 |
| `story_data.gd` | 스토리/대화 데이터 |

### UI 컴포넌트
| 파일 | 역할 |
|------|------|
| `main.gd` | 메인 씬, 동적 UI 생성 |
| `dialogue_box.gd` | 대화창 UI |

---

## 릴리스 체크리스트

### Pre-Release
- [ ] 모든 테스트 통과
- [ ] 버전 번호 업데이트
- [ ] 변경 로그 작성
- [ ] 빌드 성공 확인

### Release
- [ ] Steam/앱스토어 업로드
- [ ] 릴리스 노트 작성
- [ ] 태그 생성
- [ ] 백업 확인

### Post-Release
- [ ] 모니터링 확인
- [ ] 핫픽스 대기
- [ ] 유저 피드백 수집
