extends Node

const SAVE_PATH = "user://highscore.cfg"

# ตัวแปรเก็บค่า High Score
var high_score_endless: int = 0         # ระยะทาง Endless (Chunks)
var best_time_story: float = 999999.0   # เวลา Best Time ใน Story Mode (วินาที) - ค่าน้อยสุดคือดีสุด
var current_session_time: float = 0.0   # เวลาที่ทำได้ในรอบล่าสุดที่เพิ่งเล่นจบ

func _ready() -> void:
	load_scores()

# บันทึกคะแนน Endless
func save_endless_score(score: int) -> void:
	if score > high_score_endless:
		high_score_endless = score
		_write_to_file()

# บันทึกเวลา Story Mode (ส่งค่าเวลาเป็นวินาทีเข้ามา)
func save_story_time(time_in_sec: float) -> void:
	current_session_time = time_in_sec # บันทึกเวลาของรอบล่าสุดไว้
	if time_in_sec < best_time_story:
		best_time_story = time_in_sec
		_write_to_file()

# แปลงเวลา Best Time Story (วินาที) ออกมาเป็น String ฟอร์แมต "00:00:00"
func get_formatted_story_time() -> String:
	if best_time_story >= 999999.0:
		return "N/A"
		
	var total_sec := int(best_time_story)
	var hrs := total_sec / 3600
	var mins := (total_sec % 3600) / 60
	var secs := total_sec % 60
	return "%02d:%02d:%02d" % [hrs, mins, secs]

# อ่านไฟล์เซฟจาก disk
func load_scores() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		high_score_endless = config.get_value("HighScore", "endless_score", 0)
		best_time_story = config.get_value("HighScore", "story_time", 999999.0)

# เขียนลง disk
func _write_to_file() -> void:
	var config := ConfigFile.new()
	config.set_value("HighScore", "endless_score", high_score_endless)
	config.set_value("HighScore", "story_time", best_time_story)
	config.save(SAVE_PATH)

# ข้อความกวน ๆ ภาษาอังกฤษ บอกเวลาที่เสียไป
func get_troll_victory_message_en(current_time_sec: float) -> String:
	var total_sec := int(current_time_sec)
	var mins := total_sec / 60
	var secs := total_sec % 60
	
	if mins == 0:
		return "Congratulations, you won! And you've successfully wasted %d seconds of your precious life." % secs
	
	return "Congratulations, you won! And you've successfully wasted %d minutes and %d seconds of your precious life." % [mins, secs]
