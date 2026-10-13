extends Node

const SAVE_PATH = "user://highscore.cfg"

# =========================
# HIGH SCORE
# =========================

var high_score_endless: int = 0
var best_time_story: float = 999999.0
var current_score_endless: int = 0

# เวลาของรอบที่เพิ่งเล่นจบ
var current_session_time: float = 0.0


func _ready() -> void:
	load_scores()


# =========================
# ENDLESS
# =========================


func save_endless_score(score: int) -> void:
	if score > high_score_endless:
		high_score_endless = score
		_write_to_file()


func set_current_score(score: int) -> void:
	current_score_endless = score


func get_current_score() -> int:
	return current_score_endless


func get_endless_score(score: int) -> String:
	return "Bruh, you died! And you've did %d Level." % score


# =========================
# STORY
# =========================


func save_story_time(time_in_sec: float) -> void:
	# เก็บเวลารอบล่าสุดเสมอ
	current_session_time = time_in_sec

	print("========== SAVE STORY ==========")
	print("Time received: ", time_in_sec)
	print("Old Best: ", best_time_story)

	# ถ้าเป็นเวลาที่ดีที่สุด
	if time_in_sec > 0.0 and time_in_sec < best_time_story:
		best_time_story = time_in_sec
		_write_to_file()

		print("NEW BEST: ", best_time_story)
	else:
		print("Not a new best")

	print("Current Session: ", current_session_time)
	print("Current Best: ", best_time_story)
	print("================================")


# =========================
# FORMAT STORY TIME
# =========================


func get_formatted_story_time() -> String:
	if best_time_story >= 999999.0:
		return "N/A"

	var total_sec := int(best_time_story)

	var hrs := total_sec / 3600
	var mins := (total_sec % 3600) / 60
	var secs := total_sec % 60

	return "%02d:%02d:%02d" % [hrs, mins, secs]


# =========================
# LOAD SAVE
# =========================


func load_scores() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)

	if err == OK:
		high_score_endless = int(config.get_value("HighScore", "endless_score", 0))

		best_time_story = float(config.get_value("HighScore", "story_time", 999999.0))

		# ถ้าไฟล์เก่ามีค่า 0 ให้ถือว่ายังไม่มีสถิติ
		if best_time_story <= 0.0:
			best_time_story = 999999.0

		print("========== LOAD SCORE ==========")
		print("Loaded Endless: ", high_score_endless)
		print("Loaded Story Best: ", best_time_story)
		print("================================")

	else:
		print("No save file found.")
		print("Using default scores.")


# =========================
# WRITE SAVE
# =========================


func _write_to_file() -> void:
	var config := ConfigFile.new()

	config.set_value("HighScore", "endless_score", high_score_endless)

	config.set_value("HighScore", "story_time", best_time_story)

	var err := config.save(SAVE_PATH)

	print("SAVE FILE RESULT: ", err)
	print("Saved Story Best: ", best_time_story)


# =========================
# VICTORY MESSAGE
# =========================


func get_troll_victory_message_en(current_time_sec: float) -> String:
	var total_sec := int(current_time_sec)

	var mins := total_sec / 60
	var secs := total_sec % 60

	if mins == 0:
		return (
			"Congratulations, you won! And you've successfully wasted %d seconds of your precious life."
			% secs
		)

	return (
		"Congratulations, you won! And you've successfully wasted %d minutes and %d seconds of your precious life."
		% [mins, secs]
	)


# "1 minute and 14 seconds" — ใช้ non-breaking space ระหว่างตัวเลขกับหน่วย
# เพื่อไม่ให้ตัวเลขถูกตัดไปอยู่คนละบรรทัดกับหน่วย
@warning_ignore("integer_division")
func format_duration(total_sec: int) -> String:
	var mins := total_sec / 60
	var secs := total_sec % 60

	var secs_text := "%d\u00a0%s" % [secs, "second" if secs == 1 else "seconds"]
	if mins == 0:
		return secs_text

	return "%d\u00a0%s and %s" % [mins, "minute" if mins == 1 else "minutes", secs_text]


func get_result(current_time_sec: float) -> String:
	return (
		"Bruh, you died!\nAnd you've successfully wasted %s\nof your precious life."
		% format_duration(int(current_time_sec))
	)
