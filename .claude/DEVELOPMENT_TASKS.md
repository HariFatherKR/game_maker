# IdleFarm Roguelike - 개발 Phase 및 Task 정의

> **버전**: 1.0.0
> **작성일**: 2025-01-18
> **기준 문서**:
> - docs/GAME_DESIGN_DOCUMENT.md
> - .claude/TECHNICAL_SPEC.md

---

## Phase 개요

| Phase | 기간 | 목표 | 산출물 |
|-------|------|------|--------|
| **Phase 1: MVP** | 12주 | 핵심 게임플레이 완성 | Steam/모바일 출시 가능 빌드 |
| **Phase 2: 확장** | 8주 | 깊이 있는 콘텐츠 | 신 시스템, 스토리 |
| **Phase 3: 소셜** | 8주 | 리텐션 강화 | 랭킹, 시즌 |
| **Phase 4: 엔드게임** | 12주 | 장기 플레이 | 추가 바이옴, 엔딩 |

---

## Phase 1: MVP (12주)

### Sprint 1-2: 핵심 인프라 (2주)

#### 1.1 프로젝트 구조 완성
- [ ] Godot 프로젝트 최종 설정
  - 파일: `godot/project.godot`
  - 작업: 렌더링, 입력, 오디오 설정 최적화
- [ ] React Native 프로젝트 빌드 테스트
  - 파일: `mobile/`
  - 작업: iOS/Android 에뮬레이터 실행 확인
- [ ] Steam SDK 연동 테스트
  - 파일: `godot/addons/godotsteam/`
  - 작업: 초기화, 업적 테스트

#### 1.2 Autoload 시스템 강화
- [ ] EventBus 시그널 확장
  - 파일: `godot/scripts/autoload/event_bus.gd`
  - 추가: 런 관련 시그널, 위협 시그널
- [ ] TimeManager 개선
  - 파일: `godot/scripts/autoload/time_manager.gd`
  - 작업: 틱 시스템 최적화, 일시정지 처리
- [ ] SaveManager 암호화 구현
  - 파일: `godot/scripts/autoload/save_manager.gd`
  - 작업: AES 암호화, 백업 시스템

---

### Sprint 3-4: 농사 시스템 (2주)

#### 3.1 작물 데이터베이스
- [ ] CropData Resource 정의
  - 파일: `godot/scripts/farm/crop.gd`
  - 작업: 티어, 성장시간, 가치 등 필드 완성
- [ ] 작물 12종 데이터 입력
  - 파일: `godot/resources/crops/*.tres`
  - 내용: Common 3, Uncommon 3, Rare 2, Epic 2, Legendary 2
- [ ] 작물 스프라이트 제작
  - 파일: `godot/assets/sprites/crops/`
  - 작업: 성장 단계별 스프라이트 (4단계)

#### 3.2 농지 시스템
- [ ] FarmPlot 씬 완성
  - 파일: `godot/scenes/farm/farm_plot.tscn`
  - 작업: 상태별 시각 피드백, 터치 영역
- [ ] FarmManager 기능 확장
  - 파일: `godot/scripts/farm/farm_manager.gd`
  - 추가: 해금 비용 계산, 일괄 작업
- [ ] 농장 그리드 UI
  - 파일: `godot/scenes/farm/farm_grid.tscn`
  - 작업: 5x5 그리드, 스크롤, 줌

#### 3.3 수확 시스템
- [ ] 수확 계산 로직
  - 파일: `godot/scripts/farm/farm_manager.gd`
  - 작업: 배율 적용, 더블 수확 판정
- [ ] 수확 이펙트
  - 파일: `godot/scenes/fx/harvest_fx.tscn`
  - 작업: 파티클, 사운드, 골드 플로팅 텍스트

---

### Sprint 5-6: 런 시스템 (2주)

#### 5.1 런 상태 관리
- [ ] RunManager 싱글톤 생성
  - 파일: `godot/scripts/autoload/run_manager.gd`
  - 작업: 런 시작/종료, 시즌 전환
- [ ] RunData 구조체 정의
  - 파일: `godot/scripts/core/run_data.gd`
  - 필드: 현재 시즌, 시간, 증강체, 통계

#### 5.2 시즌 시스템
- [ ] 시즌 전환 로직
  - 파일: `godot/scripts/run/season_manager.gd`
  - 작업: 5분 타이머, 시즌별 이벤트
- [ ] 시즌 UI
  - 파일: `godot/scenes/ui/season_indicator.tscn`
  - 작업: 현재 시즌 표시, 남은 시간

#### 5.3 런 결과 처리
- [ ] 런 평가 시스템
  - 파일: `godot/scripts/run/run_evaluator.gd`
  - 작업: 목표 체크, 메타 포인트 계산
- [ ] 런 결과 UI
  - 파일: `godot/scenes/ui/run_result_screen.tscn`
  - 작업: 통계 표시, 보상 애니메이션

---

### Sprint 7-8: 증강체 시스템 (2주)

#### 7.1 증강체 데이터
- [ ] AugmentData Resource 정의
  - 파일: `godot/scripts/roguelike/augment.gd`
  - 필드: 신, 등급, 효과, 제한
- [ ] AugmentEffect 시스템
  - 파일: `godot/scripts/roguelike/augment_effect.gd`
  - 작업: 효과 타입 enum, 스택 처리
- [ ] 증강체 15종 데이터 입력
  - 파일: `godot/resources/augments/*.tres`
  - 내용: 신당 3종씩 (MVP)

#### 7.2 증강체 선택 시스템
- [ ] AugmentManager 풀 시스템
  - 파일: `godot/scripts/autoload/augment_manager.gd`
  - 작업: 가중치 풀링, 배타 처리
- [ ] 증강체 선택 UI
  - 파일: `godot/scenes/ui/augment_selection.tscn`
  - 작업: 3개 카드 표시, 리롤 버튼

#### 7.3 증강체 효과 적용
- [ ] 스탯 계산 시스템
  - 파일: `godot/scripts/roguelike/stat_calculator.gd`
  - 작업: 모든 효과 집계, 실시간 갱신
- [ ] 활성 증강체 UI
  - 파일: `godot/scenes/ui/active_augments.tscn`
  - 작업: 아이콘 목록, 툴팁

---

### Sprint 9-10: UI/UX (2주)

#### 9.1 메인 HUD
- [ ] 상단 리소스 바
  - 파일: `godot/scenes/ui/resource_bar.tscn`
  - 표시: 골드, 젬, 씨앗, 시간
- [ ] 하단 네비게이션
  - 파일: `godot/scenes/ui/bottom_nav.tscn`
  - 탭: 농장, 증강체, 상점, 메타, 설정

#### 9.2 팝업 시스템
- [ ] 팝업 매니저
  - 파일: `godot/scripts/ui/popup_manager.gd`
  - 작업: 스택 관리, 애니메이션
- [ ] 공통 팝업 템플릿
  - 파일: `godot/scenes/ui/popups/`
  - 종류: 확인, 알림, 보상

#### 9.3 튜토리얼
- [ ] 튜토리얼 매니저
  - 파일: `godot/scripts/tutorial/tutorial_manager.gd`
  - 작업: 단계별 진행, 하이라이트
- [ ] 첫 런 튜토리얼
  - 파일: `godot/resources/tutorials/first_run.tres`
  - 내용: 심기, 수확, 증강체 선택

---

### Sprint 11-12: 플랫폼 통합 및 QA (2주)

#### 11.1 Steam 빌드
- [ ] Steam 업적 연동
  - 파일: `godot/scripts/platform/steam_integration.gd`
  - 업적: 5개 기본 업적
- [ ] Steam 클라우드 저장
  - 작업: 저장/로드 테스트
- [ ] Steam 빌드 자동화
  - 파일: `scripts/build_steam.sh`

#### 11.2 모바일 빌드
- [ ] React Native 네이티브 모듈
  - 파일: `mobile/ios/`, `mobile/android/`
  - 작업: Godot 라이브러리 링크
- [ ] 오프라인 보상 연동
  - 파일: `mobile/src/hooks/useOfflineReward.ts`
  - 작업: 앱 백그라운드/포그라운드 처리
- [ ] 푸시 알림 설정
  - 파일: `mobile/src/services/NotificationService.ts`

#### 11.3 QA 및 최적화
- [ ] 성능 프로파일링
  - 목표: 60fps 유지 (모바일)
- [ ] 메모리 최적화
  - 목표: 150MB 이하 (모바일)
- [ ] 버그 수정 및 밸런싱

---

## Phase 2: 확장 (8주)

### Sprint 1-2: 신 시스템 (2주)

#### 신 호감도
- [ ] 신 호감도 데이터 구조
  - 파일: `godot/scripts/gods/god_affinity.gd`
- [ ] 호감도 획득 로직
  - 조건: 증강체 선택, 특정 행동
- [ ] 호감도 UI
  - 파일: `godot/scenes/ui/god_panel.tscn`

#### 시너지 시스템
- [ ] 시너지 정의 (15개)
  - 파일: `godot/resources/synergies/*.tres`
  - 구성: 신당 소/중/대 시너지
- [ ] 시너지 발동 UI
  - 작업: 팝업, 효과 표시

---

### Sprint 3-4: 위협 시스템 (2주)

#### 해충
- [ ] 해충 스폰 매니저
  - 파일: `godot/scripts/threats/threat_spawner.gd`
- [ ] 해충 5종 구현
  - 파일: `godot/scenes/threats/`
- [ ] 해충 대응 도구
  - 허수아비, 고양이, 스프링클러 등

#### 재해
- [ ] 시즌별 재해 시스템
  - 가뭄, 서리, 폭풍
- [ ] 재해 대응 UI
  - 경고, 대응 버튼

---

### Sprint 5-6: 스토리 Act 1 (2주)

#### 내러티브
- [ ] 스토리 데이터 구조
  - 파일: `godot/scripts/story/story_data.gd`
- [ ] 대화 시스템
  - 파일: `godot/scenes/ui/dialogue_box.tscn`
- [ ] Act 1 스크립트
  - 파일: `godot/resources/story/act1/*.tres`

#### 컷씬
- [ ] 컷씬 시스템
  - 파일: `godot/scripts/story/cutscene_player.gd`
- [ ] 3개 주요 컷씬

---

### Sprint 7-8: 펫 시스템 (2주)

#### 펫 기능
- [ ] 펫 데이터 구조
  - 파일: `godot/scripts/pets/pet_data.gd`
- [ ] 펫 5종 구현
  - 고양이, 강아지, 부엉이, 황금닭, 드래곤
- [ ] 펫 능력 시스템
  - 파일: `godot/scripts/pets/pet_ability.gd`

#### 펫 UI
- [ ] 펫 선택 화면
  - 파일: `godot/scenes/ui/pet_selection.tscn`
- [ ] 펫 인게임 표시
  - 파일: `godot/scenes/farm/pet_display.tscn`

---

## Phase 3: 소셜 (8주)

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

## Phase 4: 엔드게임 (12주)

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

### 🔴 Critical (필수)
- Autoload 시스템
- 농사 핵심 로직
- 저장/로드
- 기본 UI

### 🟠 High (중요)
- 런/시즌 시스템
- 증강체 선택
- Steam/모바일 빌드
- 튜토리얼

### 🟡 Medium (권장)
- 시너지 시스템
- 위협 시스템
- 스토리 Act 1
- 펫 시스템

### 🟢 Low (선택)
- 추가 바이옴
- 소셜 기능
- 엔드게임 콘텐츠
- 하드모드

---

## 일일 스탠드업 체크리스트

```markdown
## 오늘 할 일
- [ ] 작업 1
- [ ] 작업 2

## 어제 완료
- [x] 작업 A
- [x] 작업 B

## 블로커
- 이슈 설명
```

---

## 코드 리뷰 체크리스트

```markdown
### 기능
- [ ] 명세대로 동작하는가?
- [ ] 엣지 케이스 처리?

### 코드 품질
- [ ] 네이밍 컨벤션 준수?
- [ ] 불필요한 코드 없음?
- [ ] 적절한 주석?

### 성능
- [ ] 불필요한 연산 없음?
- [ ] 메모리 누수 없음?

### 테스트
- [ ] 단위 테스트 작성?
- [ ] 통합 테스트 통과?
```

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
