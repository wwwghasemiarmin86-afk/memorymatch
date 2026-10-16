extends Node
# Local database for Memory Match - Created by Armin
# Tables: players (with per-level progress), games (history), settings
# Stored as JSON in user:// (on the phone's private storage)

const PATH := "user://memory_match_db.json"

var data: Dictionary = {}

func _ready() -> void:
	_load()

func _defaults() -> Dictionary:
	return {
		"version": 2,
		"seq": {"players": 0, "games": 0},
		"players": [],
		"games": [],
		"settings": {"sound": true, "music": true, "vibrate": true, "last_player": ""},
	}

func _load() -> void:
	data = _defaults()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for k in ["seq", "players", "games"]:
		if parsed.has(k):
			data[k] = parsed[k]
	if parsed.has("settings") and typeof(parsed["settings"]) == TYPE_DICTIONARY:
		for s in parsed["settings"].keys():
			data["settings"][s] = parsed["settings"][s]

func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# ---------- settings ----------
func get_setting(key: String, default_value = null):
	return data["settings"].get(key, default_value)

func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	save()

# ---------- players ----------
func _player_ref(pid: int) -> Dictionary:
	for pl in data["players"]:
		if int(pl["id"]) == pid:
			return pl
	return {}

func find_player(pname: String) -> Dictionary:
	var key := pname.strip_edges().to_lower()
	for pl in data["players"]:
		if String(pl["name"]).to_lower() == key:
			return pl
	return {}

func get_or_create_player(pname: String) -> Dictionary:
	var existing := find_player(pname)
	if not existing.is_empty():
		return existing
	data["seq"]["players"] = int(data["seq"]["players"]) + 1
	var pl := {
		"id": int(data["seq"]["players"]),
		"name": pname.strip_edges(),
		"created": Time.get_datetime_string_from_system(),
		"progress": {},
	}
	data["players"].append(pl)
	save()
	return pl

func player_name(pid: int) -> String:
	var pl := _player_ref(pid)
	return String(pl["name"]) if not pl.is_empty() else "?"

# ---------- level progress ----------
func _level_entry(pid: int, diff: String, level: int) -> Dictionary:
	var pl := _player_ref(pid)
	if pl.is_empty():
		return {}
	var prog: Dictionary = pl.get("progress", {})
	var d: Dictionary = prog.get(diff, {})
	return d.get(str(level), {})

func level_stars(pid: int, diff: String, level: int) -> int:
	return int(_level_entry(pid, diff, level).get("stars", 0))

func level_best(pid: int, diff: String, level: int) -> int:
	return int(_level_entry(pid, diff, level).get("score", 0))

# returns true when this is a new best score for the level
func set_level_result(pid: int, diff: String, level: int, stars: int, score: int) -> bool:
	var pl := _player_ref(pid)
	if pl.is_empty():
		return false
	if not pl.has("progress"):
		pl["progress"] = {}
	if not pl["progress"].has(diff):
		pl["progress"][diff] = {}
	var d: Dictionary = pl["progress"][diff]
	var key := str(level)
	var old: Dictionary = d.get(key, {})
	var old_score := int(old.get("score", 0))
	d[key] = {
		"stars": max(int(old.get("stars", 0)), stars),
		"score": max(old_score, score),
	}
	save()
	return score > old_score

func unlocked_level(pid: int, diff: String, max_level: int) -> int:
	var n := 1
	while n < max_level and level_stars(pid, diff, n) > 0:
		n += 1
	return n

# ---------- games (history) ----------
func add_game(pid: int, diff: String, level: int, moves: int, time_sec: float, score: int, stars: int) -> void:
	data["seq"]["games"] = int(data["seq"]["games"]) + 1
	data["games"].append({
		"id": int(data["seq"]["games"]),
		"player_id": pid,
		"difficulty": diff,
		"level": level,
		"moves": moves,
		"time": snappedf(time_sec, 0.1),
		"score": score,
		"stars": stars,
		"date": Time.get_datetime_string_from_system(),
	})
	save()

# ---------- leaderboard ----------
func leaderboard(diff: String, limit: int = 10) -> Array:
	var rows: Array = []
	for pl in data["players"]:
		var prog: Dictionary = pl.get("progress", {})
		var d: Dictionary = prog.get(diff, {})
		if d.is_empty():
			continue
		var stars := 0
		var score := 0
		for key in d.keys():
			stars += int(d[key].get("stars", 0))
			score += int(d[key].get("score", 0))
		rows.append({"name": String(pl["name"]), "levels": d.size(), "stars": stars, "score": score})
	rows.sort_custom(func(a, b):
		if a["stars"] != b["stars"]:
			return a["stars"] > b["stars"]
		return a["score"] > b["score"])
	var n: int = min(limit, rows.size())
	return rows.slice(0, n)

func player_stats(pid: int) -> Dictionary:
	var pl := _player_ref(pid)
	var stars := 0
	var levels := 0
	var best := 0
	if not pl.is_empty():
		var prog: Dictionary = pl.get("progress", {})
		for diff in prog.keys():
			for key in prog[diff].keys():
				stars += int(prog[diff][key].get("stars", 0))
				levels += 1
				best = max(best, int(prog[diff][key].get("score", 0)))
	var games := 0
	for g in data["games"]:
		if int(g["player_id"]) == pid:
			games += 1
	return {"games": games, "stars": stars, "levels": levels, "best": best}

func clear_all_progress() -> void:
	data["games"] = []
	for pl in data["players"]:
		pl["progress"] = {}
	save()
