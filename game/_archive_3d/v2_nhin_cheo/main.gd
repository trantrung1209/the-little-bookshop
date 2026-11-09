extends Node
## Dieu phoi van choi: ngay lam viec, khach hang, hoi thoai tu van sach.
##   shop_view.gd  -> hien thi tiem 2D (hinh trong assets/art)
##   ui.gd         -> giao dien
##   game_state.gd -> tien, kho, tien trinh, luu game (Autoload "GameState")
##   game_data.gd  -> noi dung sach va khach
##   shop_layout.gd-> toa do tren anh nen

const Layout = preload("res://scripts/shop_layout.gd")
const ShopView = preload("res://scripts/shop_view.gd")
const UI = preload("res://scripts/ui.gd")

enum Phase { PREP, OPEN, EVENING }
const OPEN_MIN := 600.0     # 10:00
const CLOSE_MIN := 1020.0   # 17:00
const MIN_PER_SEC := 2.5    # 1 giay that = 2,5 phut trong game

var view: ShopView
var ui: UI
var phase := Phase.PREP
var minutes := 480.0
var day_coins_start := 0
var day_hits_start := 0
var day_served_start := 0

var customer: Node2D = null
var current_customer: Dictionary = {}
var current_visit: Dictionary = {}
var customer_waiting := false
var choices: Array = []
var dialog_queue: Array = []
var dialog_mode := ""


func _ready() -> void:
	Engine.max_fps = 60  # game thu gian khong can 120 FPS; giu 60 de do nong may, ton pin
	view = ShopView.new()
	add_child(view)
	ui = UI.new()
	add_child(ui)
	ui.choice_made.connect(_on_choice)
	ui.continue_pressed.connect(_on_continue)
	ui.buy_pressed.connect(_on_buy)
	ui.open_shop_pressed.connect(_on_open_shop)
	ui.new_day_pressed.connect(_on_new_day)
	ui.title_start_pressed.connect(_on_title_start)
	GameState.load_game()
	_start_prep()
	var label := "Bắt đầu"
	if GameState.has_save():
		label = "Chơi tiếp · Ngày %d" % GameState.day
	ui.show_title(label)


func _process(delta: float) -> void:
	if phase == Phase.OPEN and not ui.busy():
		minutes = minf(minutes + delta * MIN_PER_SEC, CLOSE_MIN)
	var m := int(minutes)
	ui.update_hud(
		"Tiền: %d · Trúng ý: %d/%d" % [GameState.coins, GameState.hits, GameState.served],
		"Ngày %d · %02d:%02d" % [GameState.day, floori(m / 60.0), m % 60])


func _unhandled_input(event: InputEvent) -> void:
	if ui.busy():
		return
	var touch := event as InputEventScreenTouch
	if touch == null or touch.pressed:
		return  # chi xu ly luc nhac ngon tay len
	var i: int = view.shelf_at(touch.position)
	view.highlight(i)
	if i >= 0:
		ui.buzz(15)
		ui.set_info(Layout.SHELVES[i]["label"])
	else:
		ui.set_info("Chạm vào kệ sách để xem")


# ---------- Ngay lam viec ----------

func _on_title_start() -> void:
	if phase == Phase.PREP:
		ui.show_prep()


func _start_prep() -> void:
	phase = Phase.PREP
	minutes = 480.0
	day_coins_start = GameState.coins
	day_hits_start = GameState.hits
	day_served_start = GameState.served
	ui.close_dialog()
	ui.evening_panel.visible = false
	ui.show_prep()
	ui.set_info("Chuẩn bị mở cửa")


func _on_buy(title: String) -> void:
	if GameState.buy(title):
		ui.buzz()
		ui.refresh_stock()


func _on_open_shop() -> void:
	ui.buzz(40)
	ui.prep_panel.visible = false
	phase = Phase.OPEN
	minutes = OPEN_MIN
	GameState.save_game()
	_spawn_customer()


func _start_evening() -> void:
	phase = Phase.EVENING
	minutes = CLOSE_MIN
	var served_today := GameState.served - day_served_start
	ui.show_evening("Ngày %d kết thúc\n\nLãi hôm nay: %d tiền\nKhách đã phục vụ: %d\nTư vấn trúng ý: %d/%d\nSách còn trên kệ: %d cuốn\n\nTổng tiền: %d" % [
		GameState.day, GameState.coins - day_coins_start, served_today,
		GameState.hits - day_hits_start, served_today, GameState.total_stock(), GameState.coins])
	ui.set_info("Tiệm đã đóng cửa")
	GameState.save_game()


func _on_new_day() -> void:
	ui.buzz(40)
	GameState.day += 1
	_start_prep()
	GameState.save_game()


# ---------- Khach hang ----------

func _walk(tw: Tween, p: Node2D, from: Vector2, to: Vector2) -> void:
	tw.tween_callback(view.face.bind(p, to))
	tw.tween_property(p, "position", to, from.distance_to(to) / Layout.WALK_SPEED) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_customer() -> void:
	current_customer = GameState.next_customer()
	customer = view.spawn_person(current_customer.get("sprite", "walkin_young_man"))
	var shelf: Dictionary = Layout.SHELVES.pick_random()
	var stand: Vector2 = shelf["stand"]
	ui.set_info("%s vào tiệm" % current_customer["name"])
	var tw := create_tween()
	tw.tween_interval(0.4)  # cho hien dan o cua
	_walk(tw, customer, Layout.DOOR, Layout.DOOR_STEP)
	_walk(tw, customer, Layout.DOOR_STEP, stand)
	tw.tween_interval(1.8)  # dung xem sach
	_walk(tw, customer, stand, Layout.COUNTER_STAND)
	tw.tween_callback(_customer_at_counter)


func _customer_leave() -> void:
	var leaving := customer
	var tw := create_tween()
	tw.tween_interval(0.3)
	_walk(tw, leaving, Layout.COUNTER_STAND, Layout.DOOR_STEP)
	_walk(tw, leaving, Layout.DOOR_STEP, Layout.DOOR)
	tw.tween_callback(view.remove_person.bind(leaving))
	tw.tween_interval(1.5)
	tw.tween_callback(_after_customer_left)


func _after_customer_left() -> void:
	if phase == Phase.OPEN and minutes < CLOSE_MIN:
		_spawn_customer()
	else:
		_start_evening()


func _portrait(mood: String) -> Texture2D:
	var sid: String = current_customer.get("sprite", "")
	var t := view.tex_or_null("portrait_%s_%s" % [sid, mood])
	if t == null:
		t = view.tex_or_null("portrait_%s_neutral" % sid)
	if t == null:
		t = view.sprite_portrait(sid)  # khach vang lai: cat phan dau tu hinh toan than
	return t


# ---------- Hoi thoai tu van ----------

func _customer_at_counter() -> void:
	customer_waiting = true
	view.highlight(-1)
	current_visit = GameState.current_visit(current_customer)
	ui.open_dialog(current_customer["name"], _portrait("neutral"))
	ui.set_info("Khách đang nói chuyện ở quầy")
	dialog_mode = "intro"
	dialog_queue = []
	for line in current_visit.get("lines", []):
		dialog_queue.append("“%s”" % line)
	dialog_queue.append("“%s”" % current_visit["request"])
	_next_line()


func _next_line() -> void:
	ui.say(dialog_queue.pop_front())
	if dialog_queue.is_empty() and dialog_mode == "intro":
		_show_choices()


func _on_continue() -> void:
	if ui.finish_typing():
		return
	if not dialog_queue.is_empty():
		_next_line()
		return
	if dialog_mode == "outro":
		dialog_mode = ""
		ui.close_dialog()
		_customer_leave()


func _show_choices() -> void:
	var books := GameState.books_in_stock()
	if books.is_empty():
		customer_waiting = false
		ui.set_info("Hết sách! Nhớ nhập thêm vào buổi sáng")
		dialog_mode = "outro"
		dialog_queue = ["“Tiệm hết sách rồi à? Hôm khác tôi quay lại vậy.”"]
		return
	ui.show_hint(current_customer.get("hint", ""))
	# Luon co 1 cuon hop nhat (trong so sach con) + toi da 2 cuon ngau nhien
	books.shuffle()
	var best: Dictionary = books[0]
	for b in books:
		if GameState.score(b, current_visit) > GameState.score(best, current_visit):
			best = b
	choices = [best]
	for b in books:
		if choices.size() >= 3:
			break
		if b != best:
			choices.append(b)
	choices.shuffle()
	var items: Array = []
	for bk in choices:
		items.append({"title": bk["title"], "genre": bk["genre"], "stock": GameState.stock_of(bk["title"])})
	ui.show_choices(items)
	ui.set_info("Chọn sách phù hợp cho khách")


func _on_choice(i: int) -> void:
	if not customer_waiting:
		return
	ui.buzz(35)
	customer_waiting = false
	var bk: Dictionary = choices[i]
	var res := GameState.record_result(current_customer, current_visit, bk)
	ui.hide_choices()
	ui.show_hint("Bạn đã gợi ý: %s  (+%d tiền)" % [bk["title"], res["reward"]])
	ui.set_portrait(_portrait(res["mood"]))
	ui.set_info("Khách đã chọn sách")
	dialog_mode = "outro"
	dialog_queue = []
	if res["new_page"]:
		dialog_queue.append("~ Một trang mới trong sổ của ông vừa mở ra.")
	ui.say("“%s”" % res["line"])
	ui.show_continue(true)
	GameState.save_game()
