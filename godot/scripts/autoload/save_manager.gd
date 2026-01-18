extends Node
## SaveManager - 세이브/로드 시스템
##
## 게임 데이터의 저장 및 로드를 담당합니다.
## 로컬 저장, 암호화, 클라우드 동기화를 지원합니다.

# =============================================================================
# 클래스 프리로드
# =============================================================================

const GameDataClass := preload("res://scripts/core/game_data.gd")

# =============================================================================
# 상수
# =============================================================================

const SAVE_PATH: String = "user://save.dat"
const BACKUP_PATH: String = "user://save_backup.dat"
const ENCRYPTION_KEY: String = "IdleFarmRoguelike2025_SecretKey_v1"
const SAVE_VERSION: int = 1

# =============================================================================
# 변수
# =============================================================================

var _is_saving: bool = false
var _is_loading: bool = false
var _last_save_time: int = 0

# =============================================================================
# 라이프사이클
# =============================================================================

func _ready() -> void:
	print("[SaveManager] Initialized")
	print("[SaveManager] Save path: %s" % ProjectSettings.globalize_path(SAVE_PATH))

# =============================================================================
# 공개 API
# =============================================================================

## 세이브 파일 존재 여부 확인
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 게임 저장
func save_game(data) -> bool:
	if _is_saving:
		push_warning("[SaveManager] Already saving")
		return false

	_is_saving = true
	print("[SaveManager] Saving game...")

	# 저장할 데이터 준비
	var save_data := _prepare_save_data(data)

	# 기존 세이브 백업
	_create_backup()

	# 저장 실행
	var success := _write_save_file(save_data)

	if success:
		_last_save_time = Time.get_unix_time_from_system()
		EventBus.game_saved.emit()
		print("[SaveManager] Save successful")

		# 클라우드 동기화 시도
		_sync_to_cloud(data)
	else:
		push_error("[SaveManager] Save failed!")

	_is_saving = false
	return success


## 게임 로드
func load_game():
	if _is_loading:
		push_warning("[SaveManager] Already loading")
		return null

	if not has_save():
		print("[SaveManager] No save file found")
		return null

	_is_loading = true
	print("[SaveManager] Loading game...")

	var save_data := _read_save_file()

	if save_data.is_empty():
		push_error("[SaveManager] Failed to read save file, trying backup...")
		save_data = _read_backup_file()

		if save_data.is_empty():
			push_error("[SaveManager] Backup also failed!")
			_is_loading = false
			return null

	# 버전 마이그레이션
	save_data = _migrate_save(save_data)

	# GameData 클래스로 변환
	var game_data = null

	if save_data.has("game_data"):
		game_data = GameDataClass.from_dict(save_data.game_data)
	else:
		push_error("[SaveManager] Invalid save data format")
		_is_loading = false
		return null

	# 시간 데이터 복원
	if save_data.has("time_data"):
		TimeManager.last_exit_time = save_data.time_data.get("last_exit_time", 0)

	EventBus.game_loaded.emit()
	print("[SaveManager] Load successful")

	_is_loading = false
	return game_data


## 세이브 파일 삭제 (주의: 되돌릴 수 없음)
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
	print("[SaveManager] Save files deleted")


## 마지막 저장 시간 반환
func get_last_save_time() -> int:
	return _last_save_time

# =============================================================================
# 내부 구현
# =============================================================================

## 저장할 데이터 준비
func _prepare_save_data(data) -> Dictionary:
	data.last_save_time = Time.get_unix_time_from_system()

	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": data.to_dict(),
		"time_data": {
			"last_exit_time": TimeManager.last_exit_time,
			"total_playtime": data.stats.playtime_seconds
		}
	}


## 세이브 파일 쓰기
func _write_save_file(data: Dictionary) -> bool:
	var json_string := JSON.stringify(data)

	# 암호화
	var encrypted := _encrypt(json_string)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to open save file: %s" % FileAccess.get_open_error())
		return false

	file.store_buffer(encrypted)
	file.close()
	return true


## 세이브 파일 읽기
func _read_save_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var encrypted := file.get_buffer(file.get_length())
	file.close()

	var json_string := _decrypt(encrypted)
	if json_string.is_empty():
		return {}

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[SaveManager] JSON parse error: %s" % json.get_error_message())
		return {}

	return json.data


## 백업 생성
func _create_backup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)


## 백업에서 읽기
func _read_backup_file() -> Dictionary:
	if not FileAccess.file_exists(BACKUP_PATH):
		return {}

	# 백업 파일을 메인으로 복사 후 읽기
	DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
	return _read_save_file()


## 버전 마이그레이션
func _migrate_save(data: Dictionary) -> Dictionary:
	var version: int = data.get("version", 0)

	if version < SAVE_VERSION:
		print("[SaveManager] Migrating save from v%d to v%d" % [version, SAVE_VERSION])

		# v0 -> v1: 신규 필드 추가
		if version < 1:
			data = _migrate_v0_to_v1(data)

	data.version = SAVE_VERSION
	return data


func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	# 레거시 Dictionary 형식에서 새 형식으로 변환
	if data.has("game_data"):
		var game_data: Dictionary = data.game_data

		# meta 필드 추가
		if not game_data.has("meta"):
			game_data["meta"] = {
				"total_runs": 0,
				"total_gold_earned": 0,
				"total_harvests": 0,
				"best_run_gold": 0,
				"best_run_harvests": 0,
				"upgrades": {},
				"god_affinity": {
					"ceres": 0,
					"plutus": 0,
					"chronos": 0,
					"tyche": 0,
					"hephaestus": 0,
				},
				"unlocked_pets": ["cat"],
				"active_pet": "cat",
				"unlocked_crops": ["wheat", "carrot", "potato"],
				"completed_endings": [],
			}

		# run 필드 추가
		if not game_data.has("run"):
			game_data["run"] = {
				"is_active": false,
				"run_number": 0,
				"current_season": 0,
				"season_time_remaining": 300.0,
				"total_run_time": 0.0,
				"active_augments": [],
				"run_gold": 0,
				"run_harvests": 0,
				"run_synergies": [],
				"completed_objectives": [],
			}

		# settings 필드 추가
		if not game_data.has("settings"):
			game_data["settings"] = {
				"master_volume": 1.0,
				"music_volume": 0.8,
				"sfx_volume": 1.0,
				"vibration_enabled": true,
				"notifications_enabled": true,
				"language": "ko",
				"auto_save_interval": 60,
			}

		data.game_data = game_data

	return data


## 암호화 (AES-256-CBC)
func _encrypt(text: String) -> PackedByteArray:
	var key := ENCRYPTION_KEY.sha256_buffer()
	var data := text.to_utf8_buffer()

	# AES 암호화
	var aes := AESContext.new()
	var iv := key.slice(0, 16)  # 첫 16바이트를 IV로 사용

	# 패딩 추가 (PKCS7)
	var block_size := 16
	var padding_len := block_size - (data.size() % block_size)
	for i in padding_len:
		data.append(padding_len)

	if aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv) != OK:
		push_error("[SaveManager] AES encryption start failed")
		return _simple_encrypt(text)

	var encrypted := aes.update(data)
	aes.finish()

	return encrypted


## 복호화 (AES-256-CBC)
func _decrypt(data: PackedByteArray) -> String:
	if data.is_empty():
		return ""

	var key := ENCRYPTION_KEY.sha256_buffer()
	var iv := key.slice(0, 16)

	var aes := AESContext.new()

	if aes.start(AESContext.MODE_CBC_DECRYPT, key, iv) != OK:
		push_error("[SaveManager] AES decryption start failed")
		return _simple_decrypt(data)

	var decrypted := aes.update(data)
	aes.finish()

	# PKCS7 패딩 제거
	if decrypted.size() > 0:
		var padding_len: int = decrypted[-1]
		if padding_len > 0 and padding_len <= 16:
			decrypted = decrypted.slice(0, decrypted.size() - padding_len)

	return decrypted.get_string_from_utf8()


## 간단한 XOR 암호화 (AES 실패 시 폴백)
func _simple_encrypt(text: String) -> PackedByteArray:
	var key := ENCRYPTION_KEY.to_utf8_buffer()
	var data := text.to_utf8_buffer()
	var result := PackedByteArray()
	result.resize(data.size())

	for i in range(data.size()):
		result[i] = data[i] ^ key[i % key.size()]

	return result


## 간단한 XOR 복호화 (AES 실패 시 폴백)
func _simple_decrypt(data: PackedByteArray) -> String:
	var key := ENCRYPTION_KEY.to_utf8_buffer()
	var result := PackedByteArray()
	result.resize(data.size())

	for i in range(data.size()):
		result[i] = data[i] ^ key[i % key.size()]

	return result.get_string_from_utf8()


## 클라우드 동기화
func _sync_to_cloud(data) -> void:
	if PlatformBridge.is_steam():
		PlatformBridge.steam_cloud_save(data.to_dict())
	elif PlatformBridge.is_mobile():
		PlatformBridge.mobile_cloud_save(data.to_dict())
