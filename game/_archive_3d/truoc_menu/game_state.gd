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


func reset() -> void:
	day = 1
	coins = START_COINS
	hits = 0
	served = 0
	customer_index = 0
	npc_progress = {}
	pages = []
	stock = {}
	for b in Data.BOOKS:
		stock[b["title"]] = 2


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var d := {
		"version": SAVE_VERSION, "day": day, "coins": coins, "hits": hits, "served": served,
		"stock": stock, "customer_index": customer_index, "npc_progress": npc_progress, "pages": pages,
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
	var pg = d.get("pages", [])
	if typeof(pg) == TYPE_ARRAY:
		pages = pg


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
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


# ---------- Khach hang va tu van ----------

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
	served += 1
	coins += int(res["reward"])
	stock[book["title"]] = stock_of(book["title"]) - 1
	return res
