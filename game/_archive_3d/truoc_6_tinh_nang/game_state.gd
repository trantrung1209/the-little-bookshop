extends Node
## Trang thai van choi + luu / tai game.
## Dang ky trong project.godot la Autoload ten "GameState": goi duoc tu moi script.

const Data = preload("res://scripts/game_data.gd")
const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 3
const START_COINS := 50
const BUY_PRICE := 8

var day := 1
var coins := START_COINS
var hits := 0
var served := 0
var stock := {}
var customer_index := 0
var npc_progress := {}
var pages: Array = []
var ending_seen := false
var upgrades: Array = []   # id cac mon sua sang da mua

# ---- Cai dat (luu rieng, khong mat khi choi van moi) ----
const SETTINGS_PATH := "user://settings.cfg"
const TEXT_SPEEDS := [0.045, 0.025, 0.012]  # giay moi chu: Cham / Vua / Nhanh
var vibrate := true
var text_speed := 1
var show_fps := false
var music_volume := 3   # chi so trong Audio.VOLUME_STEPS (3 = 75%)
var sfx_volume := 4
var in_game := false  # true khi dang choi (khong phai o menu)


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	vibrate = bool(cf.get_value("game", "vibrate", true))
	text_speed = clampi(int(cf.get_value("game", "text_speed", 1)), 0, 2)
	show_fps = bool(cf.get_value("game", "show_fps", false))
	music_volume = clampi(int(cf.get_value("audio", "music", 3)), 0, 4)
	sfx_volume = clampi(int(cf.get_value("audio", "sfx", 4)), 0, 4)


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("game", "vibrate", vibrate)
	cf.set_value("game", "text_speed", text_speed)
	cf.set_value("game", "show_fps", show_fps)
	cf.set_value("audio", "music", music_volume)
	cf.set_value("audio", "sfx", sfx_volume)
	cf.save(SETTINGS_PATH)


func _ready() -> void:
	load_settings()


## Xoa ban luu cu va bat dau lai tu ngay 1.
func new_game() -> void:
	reset()
	save_game()


func reset() -> void:
	day = 1
	coins = START_COINS
	hits = 0
	served = 0
	customer_index = 0
	npc_progress = {}
	pages = []
	ending_seen = false
	upgrades = []
	stock = {}
	for b in Data.BOOKS:
		stock[b["title"]] = 2


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var d := {
		"version": SAVE_VERSION, "day": day, "coins": coins, "hits": hits, "served": served,
		"stock": stock, "customer_index": customer_index, "npc_progress": npc_progress, "pages": pages,
		"ending_seen": ending_seen, "upgrades": upgrades,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))


func load_game() -> void:
	reset()
	if not has_save():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	# Ban luu version 1-2 co cung ten truong nen doc thang duoc.
	# Khi doi cau truc o version sau: them buoc chuyen doi o day.
	day = int(d.get("day", 1))
	coins = int(d.get("coins", START_COINS))
	hits = int(d.get("hits", 0))
	served = int(d.get("served", 0))
	customer_index = int(d.get("customer_index", 0))
	var st = d.get("stock", {})
	if typeof(st) == TYPE_DICTIONARY:
		for t in st:
			if stock.has(t):
				stock[t] = int(st[t])
	var np = d.get("npc_progress", {})
	if typeof(np) == TYPE_DICTIONARY:
		for k in np:
			npc_progress[k] = int(np[k])
	ending_seen = bool(d.get("ending_seen", false))
	var up = d.get("upgrades", [])
	if typeof(up) == TYPE_ARRAY:
		for u in up:
			upgrades.append(str(u))
	var pg = d.get("pages", [])
	if typeof(pg) == TYPE_ARRAY:
		pages = pg


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if in_game:  # dang o man hinh chinh thi khong tu tao ban luu
			save_game()


# ---------- Kho sach ----------

func stock_of(title: String) -> int:
	return int(stock.get(title, 0))


func total_stock() -> int:
	var n := 0
	for t in stock:
		n += int(stock[t])
	return n


func books_in_stock() -> Array:
	var out: Array = []
	for b in Data.BOOKS:
		if stock_of(b["title"]) > 0:
			out.append(b)
	return out


func buy(title: String) -> bool:
	if coins < BUY_PRICE:
		return false
	coins -= BUY_PRICE
	stock[title] = stock_of(title) + 1
	return true


# ---------- Sua sang tiem ----------

func has_upgrade(id: String) -> bool:
	return id in upgrades


func cleaning_done() -> bool:
	for u in Data.UPGRADES:
		if u["kind"] == "clean" and not has_upgrade(u["id"]):
			return false
	return true


## "owned" / "locked" (chua don dep xong) / "poor" (thieu tien) / "ok"
func upgrade_state(u: Dictionary) -> String:
	if has_upgrade(u["id"]):
		return "owned"
	if u["kind"] == "decor" and not cleaning_done():
		return "locked"
	if coins < int(u["price"]):
		return "poor"
	return "ok"


func buy_upgrade(id: String) -> bool:
	for u in Data.UPGRADES:
		if u["id"] == id and upgrade_state(u) == "ok":
			coins -= int(u["price"])
			upgrades.append(id)
			return true
	return false


## Suc hut cua tiem: cang cao khach toi cang nhanh.
func charm() -> int:
	var n := 0
	for u in Data.UPGRADES:
		if has_upgrade(u["id"]):
			n += int(u.get("charm", 0))
	return n


func tip_bonus() -> int:
	var n := 0
	for u in Data.UPGRADES:
		if has_upgrade(u["id"]):
			n += int(u.get("tip", 0))
	return n


func close_minutes() -> float:
	var m := 1020.0  # 17:00
	for u in Data.UPGRADES:
		if has_upgrade(u["id"]) and u.has("close"):
			m = maxf(m, float(u["close"]))
	return m


# ---------- Khach hang va tu van ----------

## true khi moi NPC co cot truyen deu da mo het trang so -> du dieu kien xem doan ket.
func story_complete() -> bool:
	for c in Data.CUSTOMERS:
		if c.has("visits") and int(npc_progress.get(c["name"], 0)) < c["visits"].size():
			return false
	return true


func next_customer() -> Dictionary:
	var n: int = Data.CUSTOMERS.size()
	for k in n:
		var c: Dictionary = Data.CUSTOMERS[(customer_index + k) % n]
		if c.has("visits") and int(npc_progress.get(c["name"], 0)) >= c["visits"].size():
			continue  # NPC da xong cot truyen
		customer_index += k + 1
		return c
	customer_index += 1
	return Data.CUSTOMERS[customer_index % n]


func current_visit(c: Dictionary) -> Dictionary:
	if c.has("visits"):
		var v: Array = c["visits"]
		var k := mini(int(npc_progress.get(c["name"], 0)), v.size() - 1)
		return v[k]
	return c


func score(book: Dictionary, visit: Dictionary) -> int:
	var s := 0
	for t in book["tags"]:
		if t in visit["want"]:
			s += 1
		if t in visit["avoid"]:
			s -= 2
	return s


## Ghi ket qua mot lan tu van. Tra ve: line, reward, mood, new_page.
func record_result(customer: Dictionary, visit: Dictionary, book: Dictionary) -> Dictionary:
	var sc := score(book, visit)
	var res := {"line": visit["ok"], "reward": 15, "mood": "neutral", "new_page": false}
	if sc >= 2:
		res["line"] = visit["great"]
		res["reward"] = 25
		res["mood"] = "happy"
		hits += 1
		if customer.has("visits"):
			var nm: String = customer["name"]
			npc_progress[nm] = int(npc_progress.get(nm, 0)) + 1
			pages.append({"name": nm, "text": visit["page"]})
			res["new_page"] = true
	elif sc <= 0:
		res["line"] = visit["miss"]
		res["reward"] = 10
		res["mood"] = "sad"
	res["reward"] = int(res["reward"]) + tip_bonus()  # tien them tu do trang tri
	served += 1
	coins += int(res["reward"])
	stock[book["title"]] = stock_of(book["title"]) - 1
	return res
