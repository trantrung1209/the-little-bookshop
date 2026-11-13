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
const Data = preload("res://scripts/game_data.gd")

enum Phase { PREP, OPEN, EVENING }
const OPEN_MIN := 600.0     # 10:00
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
var asked_ids: Array = []     # cau da hoi khach nay (doc vi khach)
var ask_ids: Array = []       # lua chon dang hien: "like" / "avoid" / "note" / "choose"
var choosing := ""            # "ask" (dang hoi) hoac "book" (dang chon sach)
var seller_npc: Node2D = null # chu Ba ve chai dung o cua vao ngay co nguoi ban sach
const SELLER_SPOT := Vector2(1780, 949)


func _ready() -> void:
	Engine.max_fps = 60  # game thu gian khong can 120 FPS; giu 60 de do nong may, ton pin
	view = ShopView.new()
	add_child(view)
	ui = UI.new()
	add_child(ui)
	ui.choice_made.connect(_on_choice)
	ui.continue_pressed.connect(_on_continue)
	ui.buy_pressed.connect(_on_buy)
	ui.upgrade_pressed.connect(_on_upgrade)
	ui.rare_pressed.connect(_on_rare)
	ui.feature_pressed.connect(_on_feature)
	ui.open_shop_pressed.connect(_on_open_shop)
	ui.new_day_pressed.connect(_on_new_day)
	ui.continue_game_pressed.connect(_on_continue_game)
	ui.new_game_pressed.connect(_on_new_game)
	ui.main_menu_requested.connect(_on_main_menu)
	ui.ending_finished.connect(_on_ending_finished)
	_show_main_menu()


func _show_main_menu() -> void:
	GameState.in_game = false
	var info := ""
	if GameState.has_save():
		GameState.load_game()
		info = "Ngày %d · %d tiền · %d trang sổ" % [GameState.day, GameState.coins, GameState.pages.size()]
	view.apply_upgrades()
	view.set_weather("sun")
	view.set_time(600.0)
	Audio.play_ambience("rain")  # man hinh chinh la pho cu dang mua
	ui.show_main_menu(info)


func _process(delta: float) -> void:
	if phase == Phase.OPEN and not ui.busy():
		minutes = minf(minutes + delta * MIN_PER_SEC, GameState.close_minutes())
		view.set_time(minutes)
	var m := int(minutes)
	ui.update_hud(
		"Tiền %d · Trúng %d/%d" % [GameState.coins, GameState.hits, GameState.served],
		"%s · Ngày %d · %02d:%02d · %s" % [Data.WEEKDAYS_SHORT[GameState.weekday()], GameState.day,
			floori(m / 60.0), m % 60, Data.WEATHER_NAMES[GameState.weather()]])


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

func _on_continue_game() -> void:
	GameState.load_game()
	GameState.in_game = true
	if GameState.story_complete() and not GameState.ending_seen:
		ui.show_ending()  # thoat game luc toi dung ngay mo het so: van duoc xem doan ket
		return
	_start_prep()


func _on_new_game() -> void:
	GameState.new_game()
	GameState.in_game = true
	_start_prep()


func _on_main_menu() -> void:
	# luu roi tai lai toan bo canh: xoa sach khach dang di, hop thoai... cho gon
	if GameState.in_game:
		GameState.save_game()
	GameState.in_game = false
	get_tree().reload_current_scene()


func _start_prep() -> void:
	Audio.play_music("shop")
	phase = Phase.PREP
	minutes = 480.0
	day_coins_start = GameState.coins
	day_hits_start = GameState.hits
	day_served_start = GameState.served
	ui.close_dialog()
	ui.evening_panel.visible = false
	view.apply_upgrades()
	var w := GameState.weather()
	view.set_weather(w)
	view.set_time(minutes)
	Audio.play_ambience("rain" if w == "rain" else "")
	ui.show_prep()
	ui.set_info("Chuẩn bị mở cửa")
	_check_achievements()
	_seller_leave()
	if GameState.seller_today():
		_spawn_seller()
	_update_tutorial()


## Chu Ba ve chai di vao, dung canh cua kinh trong luc buoi sang.
func _spawn_seller() -> void:
	if view.tex_or_null("chu_ba_walk_0") == null:
		return
	seller_npc = view.spawn_person("chu_ba")
	var tw := create_tween()
	tw.tween_callback(Audio.sfx.bind("door_bell", 0.6))
	tw.tween_interval(0.4)
	_walk(tw, seller_npc, Layout.DOOR, SELLER_SPOT)
	tw.tween_callback(view.face.bind(seller_npc, Layout.DOOR))


func _seller_leave() -> void:
	if seller_npc == null or not is_instance_valid(seller_npc):
		seller_npc = null
		return
	var p := seller_npc
	seller_npc = null
	var tw := create_tween()
	_walk(tw, p, p.position, Layout.DOOR)
	tw.tween_callback(view.remove_person.bind(p))


func _on_buy(title: String) -> void:
	if GameState.buy(title):
		ui.buzz()
		Audio.sfx("book_place")
		ui.refresh_stock()
		_tut_advance(0)


func _on_rare(title: String) -> void:
	if GameState.buy_rare(title):
		ui.buzz(40)
		Audio.sfx("book_place")
		ui.toast("Sách hiếm mới: %s" % title)
		ui.refresh_stock()
		_check_achievements()
		GameState.save_game()


func _on_feature(title: String) -> void:
	var on := GameState.toggle_featured(title)
	ui.buzz(20)
	Audio.sfx("page_flip", 0.6)
	ui.refresh_stock()
	if on:
		_tut_advance(1)


## Danh hieu moi -> thong bao + thuong tien.
func _check_achievements() -> void:
	var got := GameState.check_achievements()
	for i in got.size():
		var a: Dictionary = got[i]
		var tw := create_tween()
		tw.tween_interval(0.4 + 3.6 * i)
		tw.tween_callback(ui.toast.bind("Danh hiệu mới: %s  (+%d tiền)" % [a["name"], Data.ACHIEVEMENT_REWARD]))
		tw.tween_callback(Audio.sfx.bind("new_page"))
	if not got.is_empty():
		ui.refresh_stock()
		GameState.save_game()


func _on_upgrade(id: String) -> void:
	if GameState.buy_upgrade(id):
		ui.buzz(40)
		Audio.sfx("coin")
		view.apply_upgrades(id)
		ui.refresh_stock()
		ui.peek_shop()
		_check_achievements()
		GameState.save_game()


func _on_open_shop() -> void:
	ui.buzz(40)
	ui.prep_panel.visible = false
	_seller_leave()
	if GameState.tutorial <= 2:  # bo qua buoc nhap/bay sach cung duoc
		GameState.tutorial = 3
	ui.hide_tutorial()
	phase = Phase.OPEN
	minutes = OPEN_MIN
	GameState.save_game()
	_spawn_customer()


func _start_evening() -> void:
	phase = Phase.EVENING
	minutes = GameState.close_minutes()
	var served_today := GameState.served - day_served_start
	ui.show_evening("Ngày %d kết thúc\n\nLãi hôm nay: %d tiền\nKhách đã phục vụ: %d\nTư vấn trúng ý: %d/%d\nSách còn trên kệ: %d cuốn\n\nTổng tiền: %d" % [
		GameState.day, GameState.coins - day_coins_start, served_today,
		GameState.hits - day_hits_start, served_today, GameState.total_stock(), GameState.coins])
	ui.set_info("Tiệm đã đóng cửa")
	view.set_time(minutes)
	# luu san sang ngay moi: thoat game luc nay thi lan sau vao la ngay ke tiep
	GameState.day += 1
	_check_achievements()
	GameState.save_game()


func _on_new_day() -> void:
	ui.buzz(40)
	if GameState.story_complete() and not GameState.ending_seen:
		ui.show_ending()  # mo het so cua ong -> doan ket truoc khi sang ngay moi
		return
	_start_prep()


func _on_ending_finished() -> void:
	GameState.ending_seen = true
	GameState.save_game()
	_start_prep()
	GameState.save_game()


# ---------- Khach hang ----------

func _walk(tw: Tween, p: Node2D, from: Vector2, to: Vector2) -> void:
	tw.tween_callback(view.face.bind(p, to))
	# di deu toc do de buoc chan khop voi quang duong (khong bi truot)
	tw.tween_property(p, "position", to, from.distance_to(to) / Layout.WALK_SPEED)


func _spawn_customer() -> void:
	current_customer = GameState.next_customer()
	customer = view.spawn_person(current_customer.get("sprite", "walkin_young_man"))
	var shelf: Dictionary = Layout.SHELVES.pick_random()
	var stand: Vector2 = shelf["stand"]
	ui.set_info("%s vào tiệm" % current_customer["name"])
	var tw := create_tween()
	tw.tween_callback(Audio.sfx.bind("door_bell", 0.8))
	tw.tween_interval(0.4)  # cho hien dan o cua
	_walk(tw, customer, Layout.DOOR, stand)
	tw.tween_interval(1.8)  # dung xem sach
	_walk(tw, customer, stand, Layout.COUNTER_STAND)
	tw.tween_callback(_customer_at_counter)


func _customer_leave() -> void:
	var leaving := customer
	var tw := create_tween()
	tw.tween_interval(0.3)
	_walk(tw, leaving, Layout.COUNTER_STAND, Layout.DOOR)
	tw.tween_callback(Audio.sfx.bind("door_bell", 0.5))
	tw.tween_callback(view.remove_person.bind(leaving))
	tw.tween_interval(_customer_gap())
	tw.tween_callback(_after_customer_left)


## Thoi gian cho khach ke tiep (giay): tiem cang dep, khach toi cang nhanh.
func _customer_gap() -> float:
	var g := 9.0 - 2.0 * GameState.charm()
	if GameState.weekday() == 5:
		g -= 2.0   # Thu Bay dong khach
	if GameState.weather() == "rain":
		g += 3.0   # troi mua khach thua
	return maxf(1.0, g)


func _after_customer_left() -> void:
	if phase == Phase.OPEN and minutes < GameState.close_minutes():
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
	asked_ids = []
	for line in current_visit.get("lines", []):
		dialog_queue.append("“%s”" % line)
	dialog_queue.append("“%s”" % current_visit["request"])
	_next_line()


func _next_line() -> void:
	ui.say(dialog_queue.pop_front())
	if dialog_queue.is_empty() and dialog_mode == "intro":
		_show_ask()


# ---------- Doc vi khach: hoi them truoc khi chon sach ----------

func _show_ask() -> void:
	if GameState.books_in_stock().is_empty():
		_show_choices()
		return
	ask_ids = []
	var texts: Array = []
	if not "like" in asked_ids:
		ask_ids.append("like")
		texts.append("Hỏi: thích đọc gì?")
	if not "avoid" in asked_ids:
		ask_ids.append("avoid")
		texts.append("Hỏi: ngại đọc gì?")
	if str(current_customer.get("hint", "")) != "" and not "note" in asked_ids:
		ask_ids.append("note")
		texts.append("Xem sổ của ông")
	ask_ids.append("choose")
	texts.append("Chọn sách luôn")
	choosing = "ask"
	ui.show_options(texts)
	_update_tutorial()
	if asked_ids.is_empty():
		ui.set_info("Hỏi thêm, hoặc đoán luôn (+5 tiền nếu trúng)")


func _phrases(tags: Array, table: Dictionary) -> String:
	var out: Array = []
	for t in tags:
		out.append(str(table.get(t, t)))
	return " hay ".join(out)


func _answer(id: String) -> void:
	asked_ids.append(id)
	match id:
		"like":
			var want: Array = current_visit["want"]
			ui.say("“Tôi thích cuốn nào %s.”" % _phrases(want, Data.TAG_LIKE))
		"avoid":
			var avoid: Array = current_visit["avoid"]
			if avoid.is_empty():
				ui.say("“Tôi không kén lắm đâu, cuốn nào hay là được.”")
			else:
				ui.say("“Đừng đưa tôi cuốn nào %s nhé.”" % _phrases(avoid, Data.TAG_AVOID))
		"note":
			ui.show_hint(str(current_customer["hint"]))
	_show_ask()


func _on_continue() -> void:
	if ui.finish_typing():
		return
	if not dialog_queue.is_empty():
		_next_line()
		return
	if dialog_mode == "outro":
		dialog_mode = ""
		_tut_advance(5)
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
	choosing = "book"
	# Luon co 1 cuon hop nhat + sach tren ke trung bay + cho du 3 cuon ngau nhien
	books.shuffle()
	var best: Dictionary = books[0]
	for b in books:
		if GameState.score(b, current_visit) > GameState.score(best, current_visit):
			best = b
	choices = [best]
	for b in books:
		if choices.size() < 3 and b != best and b["title"] in GameState.featured:
			choices.append(b)
	for b in books:
		if choices.size() >= 3:
			break
		if not b in choices:
			choices.append(b)
	choices.shuffle()
	var items: Array = []
	for bk in choices:
		items.append({"title": bk["title"], "genre": bk["genre"], "stock": GameState.stock_of(bk["title"]),
			"featured": bk["title"] in GameState.featured})
	ui.show_choices(items)
	ui.set_info("Chọn sách phù hợp cho khách")
	_update_tutorial()


func _on_choice(i: int) -> void:
	if not customer_waiting:
		return
	if choosing == "ask":
		ui.buzz(20)
		if i >= ask_ids.size():
			return
		_tut_advance(3, false)
		if ask_ids[i] == "choose":
			_show_choices()
		else:
			_answer(ask_ids[i])
		return
	if i >= choices.size():
		return
	ui.buzz(35)
	customer_waiting = false
	_tut_advance(4, false)
	var bk: Dictionary = choices[i]
	var res := GameState.record_result(current_customer, current_visit, bk, asked_ids.size())
	Audio.sfx("coin")
	if res["new_page"]:
		create_tween().tween_interval(0.7).finished.connect(Audio.sfx.bind("new_page"))
	ui.hide_choices()
	var notes := ""
	if res["noask"]:
		notes += " · đoán trúng không cần hỏi"
	if res["featured"]:
		notes += " · sách trưng bày"
	ui.show_hint("Bạn đã gợi ý: %s  (+%d tiền%s)" % [bk["title"], res["reward"], notes])
	ui.set_portrait(_portrait(res["mood"]))
	ui.show_emote(res["mood"])
	ui.set_info("Khách đã chọn sách")
	dialog_mode = "outro"
	dialog_queue = []
	if res["new_page"]:
		dialog_queue.append("~ Một trang mới trong sổ của ông vừa mở ra.")
	ui.say("“%s”" % res["line"])
	ui.show_continue(true)
	_check_achievements()
	_update_tutorial()
	GameState.save_game()



# ---------- Huong dan choi lan dau (chi o van moi) ----------

const TUT_TEXT := [
	"Chào mừng tới tiệm! Bấm +1 để nhập thêm một cuốn sách lên kệ.",
	"Bấm \"Bày\" để đưa sách lên kệ trưng bày. Khách hay để ý những cuốn này, bán được thêm 3 tiền.",
	"Thẻ \"Sửa sang tiệm\" để dọn dẹp và trang trí dần. Giờ bấm \"Mở cửa tiệm\" để đón khách nhé!",
	"Khách vừa nói điều họ cần. Bấm \"Hỏi\" để biết thêm, hoặc đoán luôn: trúng ý mà không hỏi được thêm 5 tiền.",
	"Chọn cuốn hợp với khách nhất. Mỗi thẻ ghi thể loại và số cuốn còn lại.",
	"Trúng ý thì được nhiều tiền hơn. Với khách quen, mỗi lần trúng ý sẽ mở một trang trong \"Sổ của ông\". Chạm vào khung chữ để tiếp tục.",
]


## Hien loi nhac cua buoc hien tai, neu dung luc (vd. buoc 4 chi khi dang chon sach).
func _update_tutorial() -> void:
	var step := GameState.tutorial
	if step >= TUT_TEXT.size():
		ui.hide_tutorial()
		return
	var target: Control = null
	match step:
		0:
			if phase == Phase.PREP:
				target = ui.first_book_button(1)
		1:
			if phase == Phase.PREP:
				target = ui.first_book_button(2)
		2:
			if phase == Phase.PREP:
				target = ui.open_btn
		3:
			if choosing == "ask" and customer_waiting:
				target = ui.choice_box
		4:
			if choosing == "book" and customer_waiting:
				target = ui.choice_box
		5:
			if dialog_mode == "outro":
				target = ui.book_btn
	if target == null:
		ui.hide_tutorial()
	else:
		ui.show_tutorial(TUT_TEXT[step], target)


## Xong buoc `step` -> sang buoc ke tiep. refresh=false: de buoc sau tu hien dung luc.
func _tut_advance(step: int, refresh: bool = true) -> void:
	if GameState.tutorial != step:
		return
	GameState.tutorial = step + 1
	if GameState.tutorial >= TUT_TEXT.size():
		GameState.tutorial = GameState.TUTORIAL_DONE
	ui.hide_tutorial()
	if refresh:
		_update_tutorial()
