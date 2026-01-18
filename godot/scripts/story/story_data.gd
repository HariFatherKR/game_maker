extends RefCounted
class_name StoryData
## StoryData - 스토리 및 대화 데이터
##
## 게임 내 스토리, 대화, 컷씬 데이터를 정의합니다.

# =============================================================================
# 캐릭터 정의
# =============================================================================

enum Character {
	NARRATOR,     # 나레이터
	PLAYER,       # 플레이어
	CERES,        # 농업의 신
	PLUTUS,       # 부의 신
	CHRONOS,      # 시간의 신
	TYCHE,        # 행운의 신
	HEPHAESTUS,   # 대장장이 신
	OLD_FARMER,   # 노농부 NPC
	MERCHANT      # 상인 NPC
}

const CHARACTER_DATA := {
	Character.NARRATOR: {
		"id": "narrator",
		"name": "???",
		"color": Color(0.8, 0.8, 0.8)
	},
	Character.PLAYER: {
		"id": "player",
		"name": "당신",
		"color": Color(0.4, 0.8, 1.0)
	},
	Character.CERES: {
		"id": "ceres",
		"name": "케레스",
		"color": Color(0.4, 0.9, 0.4)
	},
	Character.PLUTUS: {
		"id": "plutus",
		"name": "플루투스",
		"color": Color(1.0, 0.84, 0.0)
	},
	Character.CHRONOS: {
		"id": "chronos",
		"name": "크로노스",
		"color": Color(0.6, 0.4, 0.8)
	},
	Character.TYCHE: {
		"id": "tyche",
		"name": "튀케",
		"color": Color(1.0, 0.6, 0.8)
	},
	Character.HEPHAESTUS: {
		"id": "hephaestus",
		"name": "헤파이스토스",
		"color": Color(1.0, 0.5, 0.2)
	},
	Character.OLD_FARMER: {
		"id": "old_farmer",
		"name": "노농부",
		"color": Color(0.6, 0.5, 0.3)
	},
	Character.MERCHANT: {
		"id": "merchant",
		"name": "상인",
		"color": Color(0.9, 0.7, 0.5)
	}
}

# =============================================================================
# 스토리 액트 정의
# =============================================================================

enum Act {
	PROLOGUE,   # 프롤로그
	ACT_1,      # 1막: 각성
	ACT_2,      # 2막: 시련
	ACT_3,      # 3막: 결전
	EPILOGUE    # 에필로그
}

const ACT_DATA := {
	Act.PROLOGUE: {
		"id": "prologue",
		"name": "프롤로그",
		"description": "황폐한 농장에서 깨어나다",
		"unlock_condition": "game_start"
	},
	Act.ACT_1: {
		"id": "act_1",
		"name": "제1막: 각성",
		"description": "신들의 축복을 받다",
		"unlock_condition": "first_run_complete"
	},
	Act.ACT_2: {
		"id": "act_2",
		"name": "제2막: 시련",
		"description": "고대의 위협에 맞서다",
		"unlock_condition": "10_runs_complete"
	},
	Act.ACT_3: {
		"id": "act_3",
		"name": "제3막: 결전",
		"description": "최종 결전",
		"unlock_condition": "all_gods_max_favor"
	},
	Act.EPILOGUE: {
		"id": "epilogue",
		"name": "에필로그",
		"description": "새로운 시작",
		"unlock_condition": "game_complete"
	}
}

# =============================================================================
# 대화 데이터
# =============================================================================

## 프롤로그 대화
const PROLOGUE_DIALOGUES := [
	{
		"id": "prologue_1",
		"character": Character.NARRATOR,
		"text": "오래전, 이 땅은 풍요로웠습니다...",
		"auto_advance": 3.0
	},
	{
		"id": "prologue_2",
		"character": Character.NARRATOR,
		"text": "하지만 대재앙 이후, 모든 것이 황폐해졌습니다.",
		"auto_advance": 3.0
	},
	{
		"id": "prologue_3",
		"character": Character.NARRATOR,
		"text": "당신은 낡은 농장에서 눈을 뜹니다.",
		"auto_advance": 2.0
	},
	{
		"id": "prologue_4",
		"character": Character.PLAYER,
		"text": "...여기가 어디지?",
		"choices": []
	},
	{
		"id": "prologue_5",
		"character": Character.CERES,
		"text": "드디어 깨어났군요, 선택받은 자여.",
		"choices": []
	},
	{
		"id": "prologue_6",
		"character": Character.CERES,
		"text": "저는 농업의 신, 케레스입니다. 당신의 도움이 필요합니다.",
		"choices": []
	},
	{
		"id": "prologue_7",
		"character": Character.CERES,
		"text": "이 땅을 다시 풍요롭게 만들어주세요. 그것이 당신의 사명입니다.",
		"choices": []
	}
]

## 첫 수확 이벤트
const FIRST_HARVEST_DIALOGUES := [
	{
		"id": "first_harvest_1",
		"character": Character.CERES,
		"text": "잘하셨어요! 첫 수확을 축하합니다.",
		"choices": []
	},
	{
		"id": "first_harvest_2",
		"character": Character.CERES,
		"text": "이제 시작일 뿐입니다. 더 많은 작물을 기르고, 더 넓은 땅을 개간하세요.",
		"choices": []
	},
	{
		"id": "first_harvest_3",
		"character": Character.CERES,
		"text": "다른 신들도 당신에게 관심을 갖기 시작했습니다...",
		"choices": []
	}
]

## 첫 런 완료 이벤트
const FIRST_RUN_COMPLETE_DIALOGUES := [
	{
		"id": "first_run_1",
		"character": Character.NARRATOR,
		"text": "계절의 순환이 끝났습니다.",
		"auto_advance": 2.0
	},
	{
		"id": "first_run_2",
		"character": Character.CHRONOS,
		"text": "인상적이군, 인간이여.",
		"choices": []
	},
	{
		"id": "first_run_3",
		"character": Character.CHRONOS,
		"text": "나는 시간의 신 크로노스다. 네 노력을 지켜보고 있었다.",
		"choices": []
	},
	{
		"id": "first_run_4",
		"character": Character.CHRONOS,
		"text": "시간은 무한히 반복된다. 매 순환마다 더 강해질 것이다.",
		"choices": []
	},
	{
		"id": "first_run_5",
		"character": Character.CHRONOS,
		"text": "내 축복을 받아라. 시간을 다스리는 힘을...",
		"choices": []
	}
]

## 신 조우 이벤트
const GOD_ENCOUNTER_DIALOGUES := {
	"plutus": [
		{
			"id": "plutus_meet_1",
			"character": Character.PLUTUS,
			"text": "허허, 금화 소리가 들리는군!",
			"choices": []
		},
		{
			"id": "plutus_meet_2",
			"character": Character.PLUTUS,
			"text": "나는 부의 신 플루투스다. 네 농장이 번창하길 바란다면...",
			"choices": []
		},
		{
			"id": "plutus_meet_3",
			"character": Character.PLUTUS,
			"text": "나에게 봉헌하거라. 그러면 황금비가 내릴 것이다!",
			"choices": []
		}
	],
	"tyche": [
		{
			"id": "tyche_meet_1",
			"character": Character.TYCHE,
			"text": "오호~ 재미있는 인간이 나타났네요!",
			"choices": []
		},
		{
			"id": "tyche_meet_2",
			"character": Character.TYCHE,
			"text": "저는 행운의 신 튀케예요. 운이 좋으면... 모든 게 잘 풀릴 거예요!",
			"choices": []
		},
		{
			"id": "tyche_meet_3",
			"character": Character.TYCHE,
			"text": "저와 친해지면, 희귀한 증강체가 더 자주 나올지도?",
			"choices": []
		}
	],
	"hephaestus": [
		{
			"id": "hephaestus_meet_1",
			"character": Character.HEPHAESTUS,
			"text": "...누구냐.",
			"choices": []
		},
		{
			"id": "hephaestus_meet_2",
			"character": Character.HEPHAESTUS,
			"text": "나는 대장장이 신 헤파이스토스. 말이 많은 건 싫다.",
			"choices": []
		},
		{
			"id": "hephaestus_meet_3",
			"character": Character.HEPHAESTUS,
			"text": "...농기구가 필요하면 말해. 최고의 것을 만들어주지.",
			"choices": []
		}
	]
}

## 위협 이벤트 대화
const THREAT_DIALOGUES := {
	"first_pest": [
		{
			"id": "pest_1",
			"character": Character.OLD_FARMER,
			"text": "이런! 해충이 나타났어!",
			"choices": []
		},
		{
			"id": "pest_2",
			"character": Character.OLD_FARMER,
			"text": "빨리 처리하지 않으면 작물이 다 망가질 거야.",
			"choices": []
		}
	],
	"first_disaster": [
		{
			"id": "disaster_1",
			"character": Character.NARRATOR,
			"text": "하늘이 어두워집니다...",
			"auto_advance": 2.0
		},
		{
			"id": "disaster_2",
			"character": Character.CHRONOS,
			"text": "재해가 다가온다. 대비하거라.",
			"choices": []
		}
	]
}

# =============================================================================
# 튜토리얼 데이터
# =============================================================================

const TUTORIAL_STEPS := [
	{
		"id": "tutorial_welcome",
		"title": "환영합니다!",
		"text": "IdleFarm Roguelike에 오신 것을 환영합니다.\n이 게임에서는 농장을 가꾸고, 신들의 축복을 받아 성장합니다.",
		"highlight": "",
		"action": "none"
	},
	{
		"id": "tutorial_plot",
		"title": "농지",
		"text": "이것이 농지입니다. 여기에 작물을 심을 수 있습니다.\n농지를 클릭해보세요.",
		"highlight": "farm_plot",
		"action": "click_plot"
	},
	{
		"id": "tutorial_plant",
		"title": "작물 심기",
		"text": "씨앗을 선택하여 작물을 심으세요.\n처음에는 밀을 심어보겠습니다.",
		"highlight": "seed_selector",
		"action": "plant_crop"
	},
	{
		"id": "tutorial_growth",
		"title": "작물 성장",
		"text": "작물은 시간이 지나면 자동으로 자랍니다.\n성장 바가 가득 차면 수확할 수 있습니다.",
		"highlight": "growth_bar",
		"action": "wait_growth"
	},
	{
		"id": "tutorial_harvest",
		"title": "수확",
		"text": "작물이 다 자랐습니다!\n농지를 클릭하여 수확하세요.",
		"highlight": "farm_plot",
		"action": "harvest"
	},
	{
		"id": "tutorial_gold",
		"title": "골드",
		"text": "수확한 작물은 자동으로 골드로 변환됩니다.\n골드로 새 농지를 해금하거나 업그레이드할 수 있습니다.",
		"highlight": "gold_display",
		"action": "none"
	},
	{
		"id": "tutorial_season",
		"title": "계절",
		"text": "게임은 봄, 여름, 가을, 겨울의 4계절로 이루어집니다.\n각 계절마다 다른 작물이 잘 자랍니다.",
		"highlight": "season_display",
		"action": "none"
	},
	{
		"id": "tutorial_augment",
		"title": "증강체",
		"text": "계절이 바뀔 때마다 증강체를 선택할 수 있습니다.\n증강체는 다양한 보너스를 제공합니다.",
		"highlight": "augment_popup",
		"action": "select_augment"
	},
	{
		"id": "tutorial_complete",
		"title": "튜토리얼 완료!",
		"text": "기본적인 게임 방법을 배웠습니다.\n이제 자유롭게 농장을 가꿔보세요!",
		"highlight": "",
		"action": "none"
	}
]

# =============================================================================
# 헬퍼 함수
# =============================================================================

static func get_character_data(character: Character) -> Dictionary:
	return CHARACTER_DATA.get(character, {})


static func get_act_data(act: Act) -> Dictionary:
	return ACT_DATA.get(act, {})


static func get_dialogue_sequence(sequence_id: String) -> Array:
	match sequence_id:
		"prologue":
			return PROLOGUE_DIALOGUES
		"first_harvest":
			return FIRST_HARVEST_DIALOGUES
		"first_run_complete":
			return FIRST_RUN_COMPLETE_DIALOGUES
		"first_pest":
			return THREAT_DIALOGUES.get("first_pest", [])
		"first_disaster":
			return THREAT_DIALOGUES.get("first_disaster", [])
		_:
			if GOD_ENCOUNTER_DIALOGUES.has(sequence_id):
				return GOD_ENCOUNTER_DIALOGUES[sequence_id]
			return []


static func get_tutorial_step(step_id: String) -> Dictionary:
	for step in TUTORIAL_STEPS:
		if step.id == step_id:
			return step
	return {}
