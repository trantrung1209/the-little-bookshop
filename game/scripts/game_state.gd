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
var sold := {}             # ten sach -> so cuon da ban (bo suu tap)
var featured: Array = []   # toi da 3 tua sach dang bay tren ke trung bay
var rare_owned: Array = [] # sach hiem da mua tu nguoi ban (mo khoa de nhap tiep)
var achievements: Array = []
var noask_hits := 0        # so lan doan trung y ma khong can hoi
var tutorial := 0          # buoc huong dan choi lan dau; TUTORIAL_DONE = da xong
const TUTORIAL_DONE := 99
var menu_seen := false      # da cham "Cham de bat dau" trong lan mo app nay (khong luu)
const MAX_FEATURED := 3

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
	sold = {}
	featured = []
	rare_owned = []
	achievements = []
	noask_hits = 0
	tutorial = 0
	stock = {}
	for b in Data.BOOKS:
		stock[b["title"]] = 2


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var d := {
		"version": SAVE_VERSION, "day": day, "coins": coins, "hits": hits, "served": served,
		"stock": stock, "customer_index": customer_index, "npc_progress": npc_progress, "pages": pages,
		"ending_seen": ending_seen, "upgrades": upgrades, "sold": sold, "featured": featured,
		"rare_owned": rare_owned, "achievements": achievements, "noask_hits": noask_hits,
		"tutorial": tutorial,
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
	noask_hits = int(d.get("noask_hits", 0))
	tutorial = int(d.get("tutorial", TUTORIAL_DONE))  # ban luu cu: bo qua huong dan
	for key in ["featured", "rare_owned", "achievements"]:
		var arr = d.get(key, [])
		if typeof(arr) == TYPE_ARRAY:
			var target: Array = get(key)
			for x in arr:
				target.append(str(x))
	var so = d.get("sold", {})
	if typeof(so) == TYPE_DICTIONARY:
		for t in so:
			sold[t] = int(so[t])
	var st = d.get("stock", {})
	if typeof(st) == TYPE_DICTIONARY:
		for t in st:
			if stock.has(t) or t in rare_owned:
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


## Moi sach dang ban duoc: sach co san + sach hiem da mo khoa.
func all_books() -> Array:
	var out: Array = Data.BOOKS.duplicate()
	for b in Data.RARE_BOOKS:
		if b["title"] in rare_owned:
			out.append(b)
	return out


## Sach co san luon mo; sach hiem chi mo khi da mua tu nguoi ban.
func is_unlocked(title: String) -> bool:
	for b in Data.BOOKS:
		if b["title"] == title:
			return true
	return title in rare_owned


func book_by_title(title: String) -> Dictionary:
	for b in Data.BOOKS + Data.RARE_BOOKS:
		if b["title"] == title:
			return b
	return {}


func books_in_stock() -> Array:
	var out: Array = []
	for b in all_books():
		if stock_of(b["title"]) > 0:
			out.append(b)
	return out


func buy_price() -> int:
	return 6 if weekday() == 2 else BUY_PRICE  # Thu Tu: ngay giao sach


func buy(title: String) -> bool:
	if coins < buy_price():
		return false
	coins -= buy_price()
	stock[title] = stock_of(title) + 1
	return true


## Bat / tat trung bay mot cuon. Tra ve true neu sau khi bam cuon do dang duoc bay.
func toggle_featured(title: String) -> bool:
	if title in featured:
		featured.erase(title)
		return false
	if featured.size() >= MAX_FEATURED:
		return false
	featured.append(title)
	return true


# ---------- Lich tuan, thoi tiet, nguoi ban sach ----------

func weekday() -> int:
	return (day - 1) % 7


func week_event() -> String:
	return Data.WEEK_EVENTS.get(weekday(), "")


## So ngau nhien co dinh theo ngay (cung mot ngay luon ra cung ket qua).
func _day_rand(salt: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + salt
	return rng.randf()


## "sun" / "cloud" / "rain"
func weather() -> String:
	if day == 1:
		return "sun"
	var r := _day_rand(13)
	if r < 0.3:
		return "rain"
	if r < 0.5:
		return "cloud"
	return "sun"


func seller_today() -> bool:
	if seller_offer().is_empty():
		return false
	return weekday() == 6 or (day > 2 and _day_rand(31) < 0.2)


## Toi da 3 cuon sach hiem chua co, chon co dinh theo ngay.
func seller_offer() -> Array:
	var left: Array = []
	for b in Data.RARE_BOOKS:
		if not b["title"] in rare_owned:
			left.append(b)
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 104729 + 5
	for i in range(left.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = left[i]
		left[i] = left[j]
		left[j] = tmp
	return left.slice(0, 3)


func buy_rare(title: String) -> bool:
	if coins < Data.RARE_PRICE or title in rare_owned:
		return false
	coins -= Data.RARE_PRICE
	rare_owned.append(title)
	stock[title] = stock_of(title) + 2
	return true


# ---------- Danh hieu ----------

func _genres_sold() -> Dictionary:
	var g := {}
	for t in sold:
		var b := book_by_title(t)
		if not b.is_empty():
			g[b["genre"]] = int(g.get(b["genre"], 0)) + int(sold[t])
	return g


func _achieved(id: String) -> bool:
	match id:
		"first":
			return served >= 1
		"hits10":
			return hits >= 10
		"sold30":
			return served >= 30
		"genres":
			return _genres_sold().size() >= 4
		"mystery10":
			return int(_genres_sold().get("Trinh thám", 0)) >= 10
		"noask5":
			return noask_hits >= 5
		"rare5":
			return rare_owned.size() >= 5
		"clean":
			return cleaning_done()
		"decor":
			for u in Data.UPGRADES:
				if not has_upgrade(u["id"]):
					return false
			return true
		"week":
			return day >= 8
		"pages":
			return story_complete()
	return false


## Kiem tra danh hieu moi; cong thuong va tra ve danh sach danh hieu vua dat.
func check_achievements() -> Array:
	var got: Array = []
	for a in Data.ACHIEVEMENTS:
		if not a["id"] in achievements and _achieved(a["id"]):
			achievements.append(a["id"])
			coins += Data.ACHIEVEMENT_REWARD
			got.append(a)
	return got


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
## asked = so cau da hoi khach truoc khi chon. Doan trung ma khong hoi: +5 tien.
func record_result(customer: Dictionary, visit: Dictionary, book: Dictionary, asked: int = 1) -> Dictionary:
	var sc := score(book, visit)
	var res := {"line": visit["ok"], "reward": 15, "mood": "neutral", "new_page": false,
		"noask": false, "featured": false}
	if sc >= 2:
		res["line"] = visit["great"]
		res["reward"] = 25
		res["mood"] = "happy"
		hits += 1
		if asked == 0:
			noask_hits += 1
			res["reward"] = int(res["reward"]) + 5
			res["noask"] = true
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
	if book["title"] in featured:  # khach de y cuon tren ke trung bay
		res["reward"] = int(res["reward"]) + 3
		res["featured"] = true
	sold[book["title"]] = int(sold.get(book["title"], 0)) + 1
	served += 1
	coins += int(res["reward"])
	stock[book["title"]] = stock_of(book["title"]) - 1
	return res
