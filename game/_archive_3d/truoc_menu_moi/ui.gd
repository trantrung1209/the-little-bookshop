extends CanvasLayer
## Giao dien phong cach PIXEL ART: khung o vuong vien dam, font pixel Unifont (du dau tieng Viet).
## Hop thoai co chan dung + bang ten, the sach de chon,
## bang chuan bi / tong ket / so cua ong, man gioi thieu. Bao cho main.gd qua signal.

signal choice_made(index: int)
signal continue_pressed
signal buy_pressed(title: String)
signal upgrade_pressed(id: String)
signal rare_pressed(title: String)
signal feature_pressed(title: String)
signal open_shop_pressed
signal new_day_pressed
signal continue_game_pressed   # man hinh chinh: Choi tiep
signal new_game_pressed        # da xem xong phan mo dau cua Van moi
signal main_menu_requested     # menu tam dung: ve man hinh chinh
signal ending_finished         # xem xong doan ket + credits

const Data = preload("res://scripts/game_data.gd")
const FONT_PATH := "res://assets/fonts/unifont_vi.otf"

const PAPER := Color("fbf1da")
const PAPER_DARK := Color("efdcb8")
const TEAL := Color("4f8f8c")
const OUTLINE := 3
const UI_PX := 3  # 1 o pixel cua khung = 3 diem anh
const WOOD := Color("8b5e3c")
const INK := Color("2e2019")
const ACCENT := Color("c8553d")
const MOSS := Color("4f7a5a")
const LIGHT := Color("fff4e0")
const GENRE_COLORS := {
	"Tiểu thuyết": Color("c8553d"), "Trinh thám": Color("3f5e7a"),
	"Lịch sử": Color("b9770e"), "Thiếu nhi": Color("4f7a5a"),
}

var root: Control
var coins_label: Label
var day_label: Label
var info_label: Label
var fps_label: Label
var dialog: Control
var box_panel: PanelContainer
var portrait_frame: PanelContainer
var portrait: TextureRect
var emote: TextureRect
var name_label: Label
var text_label: Label
var hint_label: Label
var more_label: Label
var choice_box: VBoxContainer
var choice_buttons: Array = []
var prep_panel: PanelContainer
var prep_title: Label
var stock_rows := {}
var upgrade_rows := {}     # id -> [nut mua, nhan ten]
var prep_sub: Label
var book_scroll: ScrollContainer
var upgrade_scroll: ScrollContainer
var tab_books: Button
var tab_upgrades: Button
var prep_event: Label
var seller_box: VBoxContainer
var nb_tabs: Array = []
var _nb_tab := 0
var _toast: PanelContainer
var open_btn: Button
var book_btn: Button
var _seller_open := false
# huong dan choi lan dau
var tut_frame: ReferenceRect
var tut_box: PanelContainer
var tut_label: Label
var _tut_target: Control = null
var _tut_t := 0.0
var evening_panel: PanelContainer
var evening_label: Label
var notebook_panel: PanelContainer
var notebook_title: Label
var notebook_list: VBoxContainer
var title_root: Control = null   # man hinh chinh / mo dau / xac nhan (che toan bo)
var hud: Control
var pause_panel: PanelContainer
var settings_panel: PanelContainer
var credits_panel: PanelContainer
var confirm_panel: PanelContainer
var _settings_back_to_pause := false
var _press_scroll := {}   # vi tri cuon luc bat dau cham nut +1 (de phan biet vuot va bam)
var _intro_pages: Array = []
var _intro_i := 0
var _intro_label: Label
var _save_info := ""
var _story_pages: Array = []
var _story_mode := ""   # "intro" hoac "ending"
var _story_images: Array = []
var _intro_bg: TextureRect
var _typing: Tween
var _can_continue := false
var font_body: Font = null
var font_bold: Font = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # menu van chay khi game tam dung
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # giu canh pixel sac net
	root.theme = _make_theme()
	add_child(root)
	_build_hud()
	_build_dialog()
	_build_panels()
	_build_menus()
	_build_tutorial()


func buzz(ms: int = 25) -> void:
	if GameState.vibrate and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func busy() -> bool:
	return title_root != null or dialog.visible or prep_panel.visible or evening_panel.visible \
		or notebook_panel.visible or pause_panel.visible or settings_panel.visible or credits_panel.visible


# ---------- Giao dien chung (theme) ----------

func _sb(bg: Color, border: Color, bw: int, radius: int, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(0)  # pixel art: goc vuong
	s.set_content_margin_all(margin)
	return s


## Khung kieu PIXEL: ve tung o vuong (vien dam, vien sang tren-trai, vien toi duoi-phai,
## bong do 1 o phia duoi), phong to bang UI_PX lan khong lam mo.
func _toon(bg: Color, _radius: int, margin: float, drop: float = 7.0, border: Color = INK) -> StyleBox:
	var n := 12
	var sh := 1 if drop > 2.0 else 0
	var img := Image.create(n, n + sh, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hi := bg.lightened(0.14)
	var lo := bg.darkened(0.14)
	for y in n:
		for x in n:
			var corner := (x == 0 or x == n - 1) and (y == 0 or y == n - 1)
			if corner:
				continue
			var c := bg
			if x == 0 or y == 0 or x == n - 1 or y == n - 1:
				c = border
			elif x == 1 or y == 1:
				c = hi
			elif x == n - 2 or y == n - 2:
				c = lo
			img.set_pixel(x, y, c)
	if sh > 0:
		for x in range(1, n - 1):
			img.set_pixel(x, n, Color(INK, 0.55))
	img.resize(n * UI_PX, (n + sh) * UI_PX, Image.INTERPOLATE_NEAREST)
	var s := StyleBoxTexture.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_margin_left = 3 * UI_PX
	s.texture_margin_top = 3 * UI_PX
	s.texture_margin_right = 3 * UI_PX
	s.texture_margin_bottom = (3 + sh) * UI_PX
	s.expand_margin_bottom = sh * UI_PX
	s.set_content_margin_all(margin)
	return s


func _font(_weight: int) -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		return null
	var f := load(FONT_PATH) as FontFile
	if f == null:
		return null
	# font pixel: tat lam min de chu sac canh
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f


## Font pixel Unifont goc cao 16: chi dung co 16, 32, 48, 64 de chu khong bi mo.
func _px(size: int) -> int:
	if size <= 18:
		return 16
	if size <= 40:
		return 32
	return int(round(size / 16.0)) * 16


func _make_theme() -> Theme:
	var th := Theme.new()
	font_body = _font(500)
	font_bold = _font(700)
	if font_body != null:
		th.default_font = font_body
	th.default_font_size = 32
	th.set_stylebox("normal", "Button", _toon(PAPER, 16, 14, 6.0))
	th.set_stylebox("hover", "Button", _toon(Color("fff8e8"), 16, 14, 6.0))
	th.set_stylebox("pressed", "Button", _toon(PAPER_DARK, 16, 14, 2.0))
	th.set_stylebox("disabled", "Button", _toon(Color(0.88, 0.84, 0.76), 16, 14, 0.0, Color(INK, 0.4)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	# thanh cuon pixel to, de thay va de keo bang ngon tay
	th.set_stylebox("scroll", "VScrollBar", _sb(Color(INK, 0.12), INK, 0, 0, 0))
	th.set_stylebox("grabber", "VScrollBar", _sb(WOOD, INK, 0, 0, 0))
	th.set_stylebox("grabber_highlight", "VScrollBar", _sb(WOOD.lightened(0.15), INK, 0, 0, 0))
	th.set_stylebox("grabber_pressed", "VScrollBar", _sb(WOOD.darkened(0.15), INK, 0, 0, 0))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		th.set_color(c, "Button", INK)
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.38, 0.32, 0.7))
	th.set_stylebox("panel", "PanelContainer", _toon(PAPER, 24, 26, 9.0))
	th.set_color("font_color", "Label", INK)
	return th


func _label(parent: Node, text: String, font_size: int, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", _px(font_size))
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## Chu sang co vien toi, dung khi chu nam thang tren tranh.
func _hud_label(parent: Node, text: String, font_size: int) -> Label:
	var l := _label(parent, text, font_size, LIGHT)
	l.add_theme_color_override("font_outline_color", Color("2b2420"))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _button(parent: Node, text: String, min_size: Vector2 = Vector2(240, 80), font_size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", _px(font_size))
	b.pressed.connect(Audio.sfx.bind("click", 0.6))
	parent.add_child(b)
	return b


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 150
	p.offset_right = -150
	p.offset_top = 90
	p.offset_bottom = -30
	root.add_child(p)
	p.visible = false
	return p


# ---------- Thanh tren ----------

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var pill := PanelContainer.new()
	var ps := _toon(Color(INK, 0.9), 0, 10, 0.0, Color(PAPER, 0.9))
	ps.content_margin_left = 20
	ps.content_margin_right = 20
	pill.add_theme_stylebox_override("panel", ps)
	pill.position = Vector2(20, 14)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	coins_label = _label(row, "", 26, LIGHT)
	day_label = _label(row, "", 26, Color("f4d03f"))

	info_label = _hud_label(hud, "", 26)
	# dong thong bao nam o dong thu 2, duoi khung tien/gio -> khong bi de chu
	info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_label.offset_left = 24
	info_label.offset_right = 900
	info_label.offset_top = 84
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var pause_btn := _button(hud, "II", Vector2(64, 64), 24)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -84
	pause_btn.offset_right = -20
	pause_btn.offset_top = 12
	pause_btn.offset_bottom = 76
	pause_btn.pressed.connect(open_pause)

	book_btn = _button(hud, "Sổ của ông", Vector2(200, 64), 24)
	book_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	book_btn.offset_left = -300
	book_btn.offset_right = -100
	book_btn.offset_top = 12
	book_btn.offset_bottom = 76
	book_btn.pressed.connect(open_notebook)

	fps_label = _label(hud, "", 16, Color(1, 1, 1, 0.55))
	fps_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fps_label.offset_left = 8
	fps_label.offset_top = -24


func update_hud(stats: String, time_text: String) -> void:
	coins_label.text = stats
	day_label.text = time_text
	fps_label.visible = GameState.show_fps
	if fps_label.visible:
		fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func set_info(t: String) -> void:
	info_label.text = t


## Thong bao nho o giua phia tren man hinh (vd. danh hieu moi), tu an sau vai giay.
func toast(text: String) -> void:
	if _toast != null and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", _toon(Color("fff4c2"), 16, 14, 6.0))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 96
	root.add_child(_toast)
	var l := _label(_toast, text, 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t := _toast
	t.modulate.a = 0.0
	var tw := create_tween()
	tw.bind_node(t)
	tw.tween_property(t, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.8)
	tw.tween_property(t, "modulate:a", 0.0, 0.5)
	tw.tween_callback(t.queue_free)


# ---------- Hop thoai ----------

func _build_dialog() -> void:
	dialog = Control.new()
	dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dialog)

	# Cac the sach de chon: cot ben phai, phia tren khung chu
	choice_box = VBoxContainer.new()
	choice_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	choice_box.offset_left = -520
	choice_box.offset_right = -40
	choice_box.offset_top = -560
	choice_box.offset_bottom = -272
	choice_box.alignment = BoxContainer.ALIGNMENT_END
	choice_box.add_theme_constant_override("separation", 12)
	dialog.add_child(choice_box)
	for i in 4:
		var b := _button(choice_box, "", Vector2(0, 88), 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_choice_button.bind(i))
		# gay sach mau theo the loai, nam ben trai the
		var spine := ColorRect.new()
		spine.name = "Spine"
		spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spine.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		spine.offset_left = OUTLINE
		spine.offset_right = OUTLINE + 16
		spine.offset_top = OUTLINE
		spine.offset_bottom = -OUTLINE
		b.add_child(spine)
		choice_buttons.append(b)

	# Khung chu
	box_panel = PanelContainer.new()
	box_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box_panel.add_theme_stylebox_override("panel", _toon(PAPER, 26, 26, 9.0))
	box_panel.offset_left = 290
	box_panel.offset_right = -36
	box_panel.offset_top = -246
	box_panel.offset_bottom = -26
	box_panel.gui_input.connect(_on_box_input)
	dialog.add_child(box_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box_panel.add_child(v)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	text_label = _label(v, "", 29)
	text_label.add_theme_constant_override("line_spacing", 4)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint_label = _label(v, "", 21, MOSS)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	more_label = _label(v, "chạm để tiếp  »", 19, ACCENT)
	more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if font_bold != null:
		more_label.add_theme_font_override("font", font_bold)
	var blink := create_tween().set_loops()
	blink.tween_property(more_label, "modulate:a", 0.4, 0.55)
	blink.tween_property(more_label, "modulate:a", 1.0, 0.55)

	# Bang ten
	var plate := PanelContainer.new()
	var ns := _toon(ACCENT, 14, 8, 5.0)
	ns.content_margin_left = 22
	ns.content_margin_right = 22
	plate.add_theme_stylebox_override("panel", ns)
	plate.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	plate.offset_left = 318
	plate.offset_top = -282
	plate.offset_bottom = -226
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(plate)
	name_label = _label(plate, "", 26, LIGHT)
	if font_bold != null:
		name_label.add_theme_font_override("font", font_bold)

	# Khung chan dung
	portrait_frame = PanelContainer.new()
	portrait_frame.add_theme_stylebox_override("panel", _toon(TEAL, 26, 8, 9.0))
	portrait_frame.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait_frame.offset_left = 36
	portrait_frame.offset_right = 266
	portrait_frame.offset_top = -290
	portrait_frame.offset_bottom = -26
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(portrait_frame)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_frame.add_child(portrait)

	# Bieu tuong cam xuc (tim / giot mo hoi) bat len o goc khung chan dung
	emote = TextureRect.new()
	emote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emote.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	emote.offset_left = 222
	emote.offset_right = 222 + 54
	emote.offset_top = -318
	emote.offset_bottom = -318 + 54
	emote.pivot_offset = Vector2(27, 54)
	emote.visible = false
	dialog.add_child(emote)
	dialog.visible = false


func _on_box_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _can_continue:
		buzz(15)
		continue_pressed.emit()


func _on_choice_button(i: int) -> void:
	choice_made.emit(i)


func open_dialog(speaker: String, tex: Texture2D) -> void:
	name_label.text = speaker
	emote.visible = false
	set_portrait(tex)
	hint_label.visible = false
	choice_box.visible = false
	show_continue(true)
	dialog.visible = true
	dialog.modulate.a = 0.0
	box_panel.pivot_offset = Vector2(0.0, box_panel.size.y)
	box_panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel()
	tw.tween_property(dialog, "modulate:a", 1.0, 0.2)
	tw.tween_property(box_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## mood: "happy" / "sad" -> hien bieu tuong nho canh chan dung; con lai thi an.
func show_emote(mood: String) -> void:
	var path := "res://assets/art/emote_%s.png" % mood
	if not ResourceLoader.exists(path):
		emote.visible = false
		return
	emote.texture = load(path)
	emote.visible = true
	emote.modulate.a = 1.0
	emote.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.bind_node(emote)
	tw.tween_property(emote, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(emote, "position:y", emote.position.y - 8, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(emote, "position:y", emote.position.y, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(1.0)
	tw.tween_property(emote, "modulate:a", 0.0, 0.4)


func set_portrait(tex: Texture2D) -> void:
	portrait.texture = tex
	portrait_frame.visible = tex != null


func say(t: String) -> void:
	text_label.text = t
	text_label.visible_ratio = 0.0
	if _typing != null:
		_typing.kill()
	_typing = create_tween()
	var per_char: float = GameState.TEXT_SPEEDS[GameState.text_speed]
	_typing.tween_property(text_label, "visible_ratio", 1.0, clampf(t.length() * per_char, 0.2, 4.0))


## Neu chu dang chay: hien het va tra ve true.
func finish_typing() -> bool:
	if text_label.visible_ratio < 1.0:
		if _typing != null:
			_typing.kill()
		text_label.visible_ratio = 1.0
		return true
	return false


func show_hint(t: String) -> void:
	hint_label.text = t
	hint_label.visible = t != ""


func _style_choice(b: Button, col: Color, h: float) -> void:
	b.custom_minimum_size.y = h
	(b.get_node("Spine") as ColorRect).color = col
	for st in ["normal", "hover", "pressed"]:
		var sb := _toon(PAPER_DARK if st == "pressed" else PAPER, 16, 14, 2.0 if st == "pressed" else 6.0)
		sb.content_margin_left = 38
		b.add_theme_stylebox_override(st, sb)


## items: mang Dictionary {title, genre, stock, featured}
func show_choices(items: Array) -> void:
	for i in choice_buttons.size():
		var b: Button = choice_buttons[i]
		b.visible = i < items.size()
		if i < items.size():
			var it: Dictionary = items[i]
			var extra := " · bày" if it.get("featured", false) else ""
			b.text = "%s\n%s · còn %d%s" % [it["title"], it["genre"], it["stock"], extra]
			_style_choice(b, GENRE_COLORS.get(it["genre"], WOOD), 88)
	_pop_choices()


## Cac lua chon mot dong (vd. cau hoi khi doc vi khach).
func show_options(texts: Array) -> void:
	for i in choice_buttons.size():
		var b: Button = choice_buttons[i]
		b.visible = i < texts.size()
		if i < texts.size():
			b.text = texts[i]
			_style_choice(b, TEAL, 60)
	_pop_choices()


func _pop_choices() -> void:
	choice_box.visible = true
	choice_box.modulate.a = 0.0
	create_tween().tween_property(choice_box, "modulate:a", 1.0, 0.25)
	show_continue(false)


func hide_choices() -> void:
	choice_box.visible = false


func show_continue(on: bool) -> void:
	_can_continue = on
	more_label.visible = on


func close_dialog() -> void:
	dialog.visible = false
	_can_continue = false


# ---------- Bang chuan bi / tong ket / so ----------

func _build_panels() -> void:
	prep_panel = _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	prep_panel.add_child(v)
	prep_title = _label(v, "", 32, ACCENT)
	if font_bold != null:
		prep_title.add_theme_font_override("font", font_bold)
	# hai the: Nhap sach / Sua sang tiem
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	v.add_child(tabs)
	var group := ButtonGroup.new()
	tab_books = _button(tabs, "Nhập sách", Vector2(0, 60), 24)
	tab_upgrades = _button(tabs, "Sửa sang tiệm", Vector2(0, 60), 24)
	for tb in [tab_books, tab_upgrades]:
		tb.toggle_mode = true
		tb.button_group = group
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_books.pressed.connect(_show_tab.bind(false))
	tab_upgrades.pressed.connect(_show_tab.bind(true))
	prep_event = _label(v, "", 18, ACCENT)
	prep_event.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prep_sub = _label(v, "", 18, WOOD)
	prep_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	book_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scroll(scroll)
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	# nguoi ban sach cu (chi hien vao ngay co nguoi ban)
	seller_box = VBoxContainer.new()
	seller_box.add_theme_constant_override("separation", 8)
	seller_box.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_child(seller_box)
	for b in Data.BOOKS + Data.RARE_BOOKS:
		var title: String = b["title"]
		var card := PanelContainer.new()
		var cs := _sb(PAPER_DARK, GENRE_COLORS.get(b["genre"], WOOD), 0, 12, 10)
		cs.border_width_left = 12
		cs.content_margin_left = 20
		card.add_theme_stylebox_override("panel", cs)
		card.mouse_filter = Control.MOUSE_FILTER_PASS  # de ngon tay vuot xuyen qua the -> danh sach cuon duoc
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)  # nut cach xa nhau, do bam nham
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		row.add_child(info)
		var tl := _label(info, title, 23)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label(info, b["genre"] + (" · sách hiếm" if b in Data.RARE_BOOKS else ""), 18, WOOD)
		var count_l := _label(row, "", 22)
		count_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var feat := _button(row, "Bày", Vector2(130, 64), 18)
		feat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		feat.mouse_filter = Control.MOUSE_FILTER_PASS
		feat.button_down.connect(_on_buy_down.bind("f:" + title, scroll))
		feat.pressed.connect(_on_feature_button.bind(title, scroll))
		var buy := _button(row, "+1", Vector2(110, 64), 24)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.mouse_filter = Control.MOUSE_FILTER_PASS
		buy.button_down.connect(_on_buy_down.bind(title, scroll))
		buy.pressed.connect(_on_buy_button.bind(title, scroll))
		stock_rows[title] = [count_l, buy, feat, card]
	_build_upgrade_list(v)
	open_btn = _button(v, "Mở cửa tiệm", Vector2(0, 80), 30)
	open_btn.pressed.connect(func() -> void: open_shop_pressed.emit())

	evening_panel = _panel()
	var e := VBoxContainer.new()
	e.add_theme_constant_override("separation", 16)
	evening_panel.add_child(e)
	evening_label = _label(e, "", 28)
	evening_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evening_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next_btn := _button(e, "Sang ngày mới", Vector2(0, 80), 30)
	next_btn.pressed.connect(func() -> void: new_day_pressed.emit())

	notebook_panel = _panel()
	var nb := VBoxContainer.new()
	nb.add_theme_constant_override("separation", 12)
	notebook_panel.add_child(nb)
	notebook_title = _label(nb, "Sổ của ông", 32, ACCENT)
	if font_bold != null:
		notebook_title.add_theme_font_override("font", font_bold)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 12)
	nb.add_child(nrow)
	var ngroup := ButtonGroup.new()
	for i in 3:
		var tb := _button(nrow, ["Trang sổ", "Sách đã bán", "Danh hiệu"][i], Vector2(0, 56), 22)
		tb.toggle_mode = true
		tb.button_group = ngroup
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed.connect(_fill_notebook.bind(i))
		nb_tabs.append(tb)
	var nscroll := ScrollContainer.new()
	nscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scroll(nscroll)
	nb.add_child(nscroll)
	notebook_list = VBoxContainer.new()
	notebook_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notebook_list.add_theme_constant_override("separation", 8)
	nscroll.add_child(notebook_list)
	var close_btn := _button(nb, "Đóng sổ", Vector2(0, 72), 26)
	close_btn.pressed.connect(close_notebook)


func _on_buy_down(title: String, scroll: ScrollContainer) -> void:
	_press_scroll[title] = scroll.scroll_vertical


func _on_buy_button(title: String, scroll: ScrollContainer) -> void:
	# neu ngon tay vua vuot de cuon danh sach thi khong tinh la bam mua
	if absi(scroll.scroll_vertical - int(_press_scroll.get(title, scroll.scroll_vertical))) > 12:
		return
	buy_pressed.emit(title)


func _build_upgrade_list(v: VBoxContainer) -> void:
	upgrade_scroll = ScrollContainer.new()
	upgrade_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scroll(upgrade_scroll)
	v.add_child(upgrade_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	upgrade_scroll.add_child(list)
	for u in Data.UPGRADES:
		var id: String = u["id"]
		var card := PanelContainer.new()
		var cs := _sb(PAPER_DARK, MOSS if u["kind"] == "clean" else ACCENT, 0, 12, 10)
		cs.border_width_left = 12
		cs.content_margin_left = 20
		card.add_theme_stylebox_override("panel", cs)
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		row.add_child(info)
		var nm := _label(info, u["name"], 23)
		var ds := _label(info, u["desc"], 18, WOOD)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var b := _button(row, "", Vector2(170, 56), 22)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		b.button_down.connect(_on_buy_down.bind(id, upgrade_scroll))
		b.pressed.connect(_on_upgrade_button.bind(id, upgrade_scroll))
		upgrade_rows[id] = [b, nm]
	upgrade_scroll.visible = false


func _on_feature_button(title: String, scroll: ScrollContainer) -> void:
	if absi(scroll.scroll_vertical - int(_press_scroll.get("f:" + title, scroll.scroll_vertical))) > 12:
		return
	feature_pressed.emit(title)


func _on_rare_button(title: String) -> void:
	rare_pressed.emit(title)


## Dung lai khu nguoi ban sach theo hang ngay hom nay.
func _refresh_seller() -> void:
	for ch in seller_box.get_children():
		seller_box.remove_child(ch)
		ch.queue_free()
	if not GameState.seller_today():
		seller_box.visible = false
		return
	seller_box.visible = true
	var offer := GameState.seller_offer()
	# gon: chi mot nut; bam vao moi mo danh sach sach hiem
	var toggle := _button(seller_box, "Chú Ba ve chai ghé tiệm · %s %d cuốn sách hiếm" % ["ẩn" if _seller_open else "xem", offer.size()], Vector2(0, 60), 18)
	toggle.add_theme_stylebox_override("normal", _toon(Color("fff4c2"), 12, 14, 6.0))
	toggle.mouse_filter = Control.MOUSE_FILTER_PASS
	toggle.pressed.connect(_toggle_seller)
	if not _seller_open:
		return
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", _toon(Color("fff4c2"), 12, 14, 4.0))
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	seller_box.add_child(head)
	var hv := VBoxContainer.new()
	head.add_child(hv)
	var h := _label(hv, "Mua một cuốn được 2 bản, từ nay nhập thêm được.", 18, INK)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for b in offer:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		hv.add_child(row)
		var nm := _label(row, "%s · %s" % [b["title"], b["genre"]], 18)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var btn := _button(row, "%d tiền" % Data.RARE_PRICE, Vector2(150, 60), 22)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.disabled = GameState.coins < Data.RARE_PRICE
		btn.pressed.connect(_on_rare_button.bind(b["title"]))


func _toggle_seller() -> void:
	_seller_open = not _seller_open
	_refresh_seller()


func _on_upgrade_button(id: String, scroll: ScrollContainer) -> void:
	if absi(scroll.scroll_vertical - int(_press_scroll.get(id, scroll.scroll_vertical))) > 12:
		return
	upgrade_pressed.emit(id)


func _show_tab(upgrades: bool) -> void:
	book_scroll.visible = not upgrades
	upgrade_scroll.visible = upgrades
	tab_books.button_pressed = not upgrades
	tab_upgrades.button_pressed = upgrades
	if upgrades:
		if GameState.cleaning_done():
			prep_sub.text = "Trang trí cho tiệm. Mỗi món có một tác dụng nhỏ."
		else:
			prep_sub.text = "Tiệm bỏ lâu nên còn bụi. Dọn dẹp xong mới trang trí được."
	else:
		prep_sub.text = "Sách %d tiền một cuốn · Bày tối đa %d cuốn (+3 tiền khi bán)" % [GameState.buy_price(), GameState.MAX_FEATURED]


## Mo bang chuan bi buoi sang (mac dinh o the Nhap sach).
func show_prep() -> void:
	_seller_open = false
	prep_title.text = "%s, ngày %d · %s" % [Data.WEEKDAYS[GameState.weekday()], GameState.day, Data.WEATHER_NAMES[GameState.weather()]]
	var ev := GameState.week_event()
	if GameState.weather() == "rain":
		ev = (ev + " " if ev != "" else "") + "Trời mưa: khách thưa hơn."
	prep_event.text = ev
	prep_event.visible = ev != ""
	_show_tab(false)
	refresh_stock()
	prep_panel.modulate.a = 1.0
	prep_panel.visible = true


func refresh_stock() -> void:
	for t in stock_rows:
		var row: Array = stock_rows[t]
		var unlocked := GameState.is_unlocked(t)
		(row[3] as Control).visible = unlocked
		row[0].text = "Còn %d" % GameState.stock_of(t)
		row[1].disabled = GameState.coins < GameState.buy_price()
		var on: bool = t in GameState.featured
		row[2].text = "Đang bày" if on else "Bày"
		row[2].disabled = not on and GameState.featured.size() >= GameState.MAX_FEATURED
	_refresh_seller()
	for u in Data.UPGRADES:
		var b: Button = upgrade_rows[u["id"]][0]
		match GameState.upgrade_state(u):
			"owned":
				b.text = "Đã xong" if u["kind"] == "clean" else "Đã có"
				b.disabled = true
			"locked":
				b.text = "%d tiền" % int(u["price"])
				b.disabled = true
			"poor":
				b.text = "%d tiền" % int(u["price"])
				b.disabled = true
			_:
				b.text = "%d tiền" % int(u["price"])
				b.disabled = false
	if upgrade_scroll.visible:
		_show_tab(true)  # cap nhat dong huong dan (vd. vua don dep xong)


## An bang chuan bi mot chut de nguoi choi thay tiem vua thay doi.
func peek_shop() -> void:
	var tw := create_tween()
	tw.bind_node(prep_panel)
	tw.tween_property(prep_panel, "modulate:a", 0.0, 0.25)
	tw.tween_interval(1.6)
	tw.tween_property(prep_panel, "modulate:a", 1.0, 0.3)


func show_evening(text: String) -> void:
	evening_label.text = text
	evening_panel.visible = true


func open_notebook() -> void:
	if dialog.visible or title_root != null:
		return
	buzz(20)
	_fill_notebook(0)
	Audio.sfx("page_flip")
	notebook_panel.visible = true


func _clear_notebook() -> void:
	for ch in notebook_list.get_children():
		notebook_list.remove_child(ch)
		ch.queue_free()


## 0 = trang so, 1 = bo suu tap sach, 2 = danh hieu
func _fill_notebook(tab: int) -> void:
	_nb_tab = tab
	for i in nb_tabs.size():
		nb_tabs[i].button_pressed = i == tab
	_clear_notebook()
	if tab == 1:
		_fill_collection()
		return
	if tab == 2:
		_fill_achievements()
		return
	_fill_pages()


func _fill_collection() -> void:
	var all: Array = Data.BOOKS + Data.RARE_BOOKS
	var found := 0
	for b in all:
		var t: String = b["title"]
		var n := int(GameState.sold.get(t, 0))
		var known := GameState.is_unlocked(t)
		if n > 0:
			found += 1
		if not known:
			_label(notebook_list, "• ??? · sách hiếm chưa tìm thấy", 22, Color(INK, 0.4))
		elif n == 0:
			_label(notebook_list, "• %s · %s · chưa bán" % [t, b["genre"]], 22, Color(INK, 0.55))
		else:
			_label(notebook_list, "• %s · %s · đã bán %d" % [t, b["genre"], n], 22)
	notebook_title.text = "Bộ sưu tập · đã bán %d/%d đầu sách" % [found, all.size()]


func _fill_achievements() -> void:
	var got := 0
	for a in Data.ACHIEVEMENTS:
		var ok: bool = a["id"] in GameState.achievements
		if ok:
			got += 1
		_label(notebook_list, a["name"] + ("" if ok else " · chưa đạt"), 26, ACCENT if ok else Color(INK, 0.45))
		_label(notebook_list, "  " + str(a["desc"]), 20, INK if ok else Color(INK, 0.45))
	notebook_title.text = "Danh hiệu · đạt %d/%d" % [got, Data.ACHIEVEMENTS.size()]


func _fill_pages() -> void:
	var total := 0
	for c in Data.CUSTOMERS:
		if not c.has("visits"):
			continue
		var nm: String = c["name"]
		var n_pages: int = c["visits"].size()
		total += n_pages
		_label(notebook_list, nm, 28, ACCENT)
		var opened := 0
		for pg in GameState.pages:
			if pg["name"] == nm:
				opened += 1
				var t := _label(notebook_list, "• " + str(pg["text"]), 22)
				t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for _k in range(n_pages - opened):
			_label(notebook_list, "• …trang chưa mở", 22, Color(INK, 0.4))
	notebook_title.text = "Sổ của ông · đã mở %d/%d trang" % [GameState.pages.size(), total]


func close_notebook() -> void:
	buzz(15)
	notebook_panel.visible = false


func _style_scroll(sc: ScrollContainer) -> void:
	sc.scroll_deadzone = 8  # vuot qua 8 diem anh moi tinh la cuon
	sc.get_v_scroll_bar().custom_minimum_size.x = 18


# ---------- Man hinh chinh, mo dau, tam dung, cai dat, gioi thieu ----------

const VOLUME_TEXT := ["Tắt", "25%", "50%", "75%", "100%"]

const INTRO_PAGES := [
	"Mùa mưa năm 1994.\n\nMột con phố cũ, hàng me già rợp bóng, tiếng chuông xe đạp leng keng mỗi sáng.",
	"“Cháu thương,\n\nKhi cháu đọc lá thư này thì ông đã đi xa rồi. Ông để lại cho cháu tiệm sách nhỏ ở đầu phố, nơi ông đã ngồi suốt bốn mươi năm.”",
	"“Tiệm đóng cửa cũng lâu, bụi đã phủ lên mấy kệ gỗ. Nhưng ông tin khách quen vẫn sẽ quay lại, chỉ chờ có người mở cửa.”",
	"“Ông để lại cuốn sổ ghi chuyện từng người khách. Cháu cứ lắng nghe họ, rồi trao đúng cuốn sách cho đúng người. Mỗi lần như vậy, một trang sổ sẽ mở ra.\n\nThương cháu. Ông.”",
	"Cách chơi\n\n• Buổi sáng: nhập thêm sách lên kệ.\n• Mở cửa: nghe khách kể, chọn cuốn sách hợp với họ.\n• Buổi tối: xem lại một ngày, rồi sang ngày mới.\n• Bấm \"Sổ của ông\" để đọc những trang đã mở.",
]


# Tranh nen cho tung trang (file trong assets/art, khong co duoi .png)
const INTRO_IMAGES := ["intro_pho", "intro_thu", "intro_tiem_bui", "intro_thu", "shop_bg"]
const ENDING_IMAGES := ["ending_tiem", "ending_tiem", "ending_tiem", "ending_tiem", "ending_tiem", "intro_pho"]

const ENDING_PAGES := [
	"Một sáng thứ Bảy, chuông cửa reo sớm hơn mọi ngày.",
	"Chị Mai ôm vào một bó cúc vàng, cắm vào chiếc bình trên quầy.\n\n“Tiệm hoa của mình mở rồi, ngay đầu hẻm. Từ giờ bình này để mình lo nhé.”",
	"Chiều đến, ông Tư kê bàn cờ cạnh cửa sổ, đặt quân Tướng về đúng chỗ của nó.\n\n“Nào, cháu đi trước đi. Ngày xưa ông cháu cũng toàn nhường tôi đi trước.”",
	"Nam chạy vào, tay ôm xấp bản thảo còn thơm mùi mực. Trang đầu tiên ghi:\n\n“Tặng ông chủ tiệm sách đầu phố, người đã bảo tôi: Viết tiếp đi.”",
	"Gần tối, cô Liên ngồi giữa tiệm đọc thơ từ tập bìa xanh. Bé Thỏ ngồi hàng đầu, mẹ bé đứng nép ở cửa.\n\nNgoài hiên, chú Đức vừa vá xe vừa lẩm nhẩm đọc theo.",
	"Cuốn sổ của ông giờ không còn trang nào để trống.\n\nNhưng tiệm sách thì vẫn còn rất nhiều ngày để viết tiếp.",
]

const CREDITS_TEXT := "The Little Bookshop\nTiệm sách nhỏ phố cũ\n\n\nThiết kế, viết truyện và phát triển\nTrung Nguyen\n\n\nNhân vật pixel\ntạo với PixelLab\n\nNhạc nền\n\"Hush Hamlet\", \"Apple Cider\"\ncủa Zane Little Music (CC0)\n\nTiếng động\ntự tạo cho game\n\nPhông chữ\nGNU Unifont (SIL Open Font License)\n\nCông cụ\nGodot Engine (giấy phép MIT)\n\n\nCảm ơn bạn đã ghé tiệm."


func _build_menus() -> void:
	# Bang tam dung
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.custom_minimum_size = Vector2(460, 0)
	pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(pause_panel)
	pause_panel.visible = false
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	pause_panel.add_child(pv)
	var pt := _label(pv, "Tạm dừng", 32, ACCENT)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(pv, "Chơi tiếp", Vector2(0, 72), 26).pressed.connect(close_pause)
	_button(pv, "Sổ của ông", Vector2(0, 72), 26).pressed.connect(_pause_notebook)
	_button(pv, "Cài đặt", Vector2(0, 72), 26).pressed.connect(_pause_settings)
	_button(pv, "Lưu và về màn hình chính", Vector2(0, 72), 26).pressed.connect(_pause_to_menu)

	# Bang cai dat
	settings_panel = _panel()
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 16)
	settings_panel.add_child(sv)
	_label(sv, "Cài đặt", 32, ACCENT)
	_setting_row(sv, "Rung khi chạm", "vibrate")
	_setting_row(sv, "Tốc độ chữ", "text_speed")
	_setting_row(sv, "Nhạc nền", "music")
	_setting_row(sv, "Tiếng động", "sfx")
	_setting_row(sv, "Hiện FPS (số khung hình/giây)", "show_fps")
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(sp)
	_button(sv, "Xong", Vector2(0, 72), 26).pressed.connect(close_settings)

	# Bang gioi thieu (credits) - ten tac gia chi dat o day
	credits_panel = _panel()
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	credits_panel.add_child(cv)
	_label(cv, "Giới thiệu", 32, ACCENT)
	var cscroll := ScrollContainer.new()
	cscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scroll(cscroll)
	cv.add_child(cscroll)
	var ct := _label(cscroll, CREDITS_TEXT, 26)
	ct.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ct.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(cv, "Đóng", Vector2(0, 72), 26).pressed.connect(_close_credits)

	# Hop xac nhan
	confirm_panel = PanelContainer.new()
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.custom_minimum_size = Vector2(620, 0)
	confirm_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	confirm_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(confirm_panel)
	confirm_panel.visible = false


func _pause_notebook() -> void:
	close_pause()
	open_notebook()


func _pause_settings() -> void:
	pause_panel.visible = false
	open_settings(true)


func _pause_to_menu() -> void:
	buzz(30)
	pause_panel.visible = false
	get_tree().paused = false
	main_menu_requested.emit()


func _close_credits() -> void:
	buzz(15)
	credits_panel.visible = false


func _setting_text(key: String) -> String:
	match key:
		"vibrate":
			return "Bật" if GameState.vibrate else "Tắt"
		"text_speed":
			return ["Chậm", "Vừa", "Nhanh"][GameState.text_speed]
		"show_fps":
			return "Bật" if GameState.show_fps else "Tắt"
		"music":
			return VOLUME_TEXT[GameState.music_volume]
		"sfx":
			return VOLUME_TEXT[GameState.sfx_volume]
	return ""


func _setting_row(parent: Node, text: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var l := _label(row, text, 26)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var b := _button(row, _setting_text(key), Vector2(180, 64), 26)
	b.pressed.connect(_on_setting.bind(key, b))


func _on_setting(key: String, b: Button) -> void:
	match key:
		"vibrate":
			GameState.vibrate = not GameState.vibrate
		"text_speed":
			GameState.text_speed = (GameState.text_speed + 1) % 3
		"show_fps":
			GameState.show_fps = not GameState.show_fps
		"music":
			GameState.music_volume = (GameState.music_volume + 1) % VOLUME_TEXT.size()
			Audio.apply_volume()
		"sfx":
			GameState.sfx_volume = (GameState.sfx_volume + 1) % VOLUME_TEXT.size()
			Audio.sfx("coin")  # nghe thu muc am luong moi
	b.text = _setting_text(key)
	GameState.save_settings()
	buzz(15)


func _confirm(text: String, yes_text: String, on_yes: Callable) -> void:
	for ch in confirm_panel.get_children():
		ch.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	confirm_panel.add_child(v)
	var l := _label(v, text, 26)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var no := _button(row, "Thôi", Vector2(0, 72), 26)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_confirm_answer.bind(Callable()))
	var yes := _button(row, yes_text, Vector2(0, 72), 26)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.add_theme_color_override("font_color", ACCENT)
	yes.pressed.connect(_confirm_answer.bind(on_yes))
	confirm_panel.move_to_front()
	confirm_panel.visible = true


func _confirm_answer(on_yes: Callable) -> void:
	buzz(15)
	confirm_panel.visible = false
	if on_yes.is_valid():
		on_yes.call()


func _clear_title_root() -> void:
	if title_root != null:
		title_root.queue_free()
		title_root = null


## Man hinh chinh. save_info = "" neu chua co ban luu.
func show_main_menu(save_info: String) -> void:
	_clear_title_root()
	close_dialog()
	prep_panel.visible = false
	evening_panel.visible = false
	notebook_panel.visible = false
	hud.visible = false
	Audio.play_music("menu")
	title_root = Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_root)
	# lop toi ben trai de chu noi, ben phai van thay tiem
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.08, 0.07, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(shade)
	var side := ColorRect.new()
	side.color = Color(0.1, 0.08, 0.07, 0.5)
	side.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	side.offset_right = 560
	title_root.add_child(side)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	v.offset_left = 70
	v.offset_right = 490
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	title_root.add_child(v)
	var t := _hud_label(v, "The Little\nBookshop", 64)
	t.add_theme_color_override("font_color", Color("f4d03f"))
	var sub := _hud_label(v, "Tiệm sách nhỏ phố cũ", 32)
	sub.add_theme_color_override("font_color", LIGHT)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	v.add_child(gap)

	_save_info = save_info
	if save_info != "":
		var cont := _button(v, "Chơi tiếp", Vector2(0, 64), 26)
		cont.pressed.connect(_on_continue_game)
		var info := _hud_label(v, save_info, 16)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var newb := _button(v, "Ván mới", Vector2(0, 64), 26)
	newb.pressed.connect(_on_new_game_button)
	_button(v, "Cài đặt", Vector2(0, 64), 26).pressed.connect(open_settings.bind(false))
	_button(v, "Giới thiệu", Vector2(0, 64), 26).pressed.connect(_open_credits)
	if OS.get_name() == "Android":  # iOS khong cho app tu thoat
		_button(v, "Thoát", Vector2(0, 64), 26).pressed.connect(get_tree().quit)
	title_root.modulate.a = 0.0
	create_tween().tween_property(title_root, "modulate:a", 1.0, 0.4)


func _on_continue_game() -> void:
	buzz(40)
	_fade_out_title()
	continue_game_pressed.emit()


func _on_new_game_button() -> void:
	buzz(25)
	if _save_info != "":
		_confirm("Bắt đầu ván mới?\nTiến trình đang lưu (%s) sẽ bị xoá." % _save_info, "Xoá và chơi lại", show_intro)
	else:
		show_intro()


func _open_credits() -> void:
	buzz(15)
	credits_panel.move_to_front()
	credits_panel.visible = true


func _fade_out_title() -> void:
	var r := title_root
	title_root = null
	hud.visible = true
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.4)
	tw.tween_callback(r.queue_free)


## Phan mo dau cua Van moi: vai trang chu tren nen tiem toi, cham de qua trang.
func show_intro() -> void:
	Audio.play_music("menu")
	_show_story(INTRO_PAGES, INTRO_IMAGES, "intro")


## Doan ket: hien khi mo het so cua ong, roi chay chu Credits.
func show_ending() -> void:
	Audio.play_music("menu")
	_show_story(ENDING_PAGES, ENDING_IMAGES, "ending")


func _show_story(story: Array, images: Array, mode: String) -> void:
	_story_pages = story
	_story_images = images
	_story_mode = mode
	close_dialog()
	prep_panel.visible = false
	evening_panel.visible = false
	_clear_title_root()
	hud.visible = false
	title_root = Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.gui_input.connect(_on_intro_input)
	root.add_child(title_root)
	var black := ColorRect.new()
	black.color = Color("120d0b")
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_root.add_child(black)
	# nen tiem mo, phong to cham cham
	var bg := TextureRect.new()
	_intro_bg = bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_root.add_child(bg)
	bg.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	var zoom := create_tween()
	zoom.bind_node(bg)
	zoom.tween_property(bg, "scale", Vector2(1.08, 1.08), 60.0)

	# khung chu nam duoi day man hinh, de thay tranh phia tren
	var paper := PanelContainer.new()
	paper.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	paper.offset_left = 60
	paper.offset_right = -60
	paper.offset_top = -250
	paper.offset_bottom = -24
	paper.grow_vertical = Control.GROW_DIRECTION_BEGIN
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_root.add_child(paper)
	var pv := VBoxContainer.new()
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(pv)
	_intro_label = _label(pv, "", 32)
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_label.add_theme_constant_override("line_spacing", 6)
	_intro_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hint := _label(pv, "chạm để tiếp  »", 16, ACCENT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var blink := create_tween().set_loops()
	blink.bind_node(hint)
	blink.tween_property(hint, "modulate:a", 0.4, 0.55)
	blink.tween_property(hint, "modulate:a", 1.0, 0.55)

	var skip := _button(title_root, "Bỏ qua", Vector2(160, 60), 24)
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -180
	skip.offset_right = -20
	skip.offset_top = 16
	skip.offset_bottom = 76
	skip.pressed.connect(_end_intro)

	if mode == "ending":
		skip.text = "Xem Credits"
		skip.offset_left = -240
	_intro_i = 0
	_show_intro_page()


func _show_intro_page() -> void:
	_set_story_image(_story_images[mini(_intro_i, _story_images.size() - 1)])
	_intro_label.text = _story_pages[_intro_i]
	_intro_label.visible_ratio = 0.0
	if _typing != null:
		_typing.kill()
	_typing = create_tween()
	var per_char: float = GameState.TEXT_SPEEDS[GameState.text_speed]
	_typing.tween_property(_intro_label, "visible_ratio", 1.0, clampf(_intro_label.text.length() * per_char, 0.3, 5.0))


## Doi tranh nen cua trang: mo dan sang tranh moi neu khac tranh cu.
func _set_story_image(file: String) -> void:
	var path := "res://assets/art/%s.png" % file
	if not ResourceLoader.exists(path):
		path = "res://assets/art/shop_bg.png"
	var tex: Texture2D = load(path)
	if _intro_bg.texture == tex:
		return
	if _intro_bg.texture == null:
		_intro_bg.texture = tex
		return
	var tw := create_tween()
	tw.bind_node(_intro_bg)
	tw.tween_property(_intro_bg, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: _intro_bg.texture = tex)
	tw.tween_property(_intro_bg, "modulate:a", 1.0, 0.5)


func _on_intro_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	buzz(15)
	if _intro_label.visible_ratio < 1.0:
		if _typing != null:
			_typing.kill()
		_intro_label.visible_ratio = 1.0
		return
	_intro_i += 1
	Audio.sfx("page_flip", 0.7)
	if _intro_i >= _story_pages.size():
		_end_intro()
	else:
		_show_intro_page()


func _end_intro() -> void:
	if title_root == null:
		return
	buzz(40)
	if _story_mode == "ending":
		_roll_credits()
		return
	_fade_out_title()
	new_game_pressed.emit()


## Chu Credits chay tu duoi len tren nen toi; cuoi cung la nut tiep tuc mo tiem.
func _roll_credits() -> void:
	_clear_title_root()
	title_root = Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_root)
	var black := ColorRect.new()
	black.color = Color("120d0b")
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(black)
	var vs := get_viewport().get_visible_rect().size
	var c := _hud_label(title_root, CREDITS_TEXT, 32)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.position = Vector2(0, vs.y)
	c.size = Vector2(vs.x, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := c.get_combined_minimum_size().y
	var roll := create_tween()
	roll.bind_node(c)
	roll.tween_property(c, "position:y", -h, (vs.y + h) / 55.0)  # 55 diem anh moi giay
	roll.tween_callback(_credits_done)
	var skip := _button(title_root, "Bỏ qua", Vector2(160, 60), 24)
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -180
	skip.offset_right = -20
	skip.offset_top = 16
	skip.offset_bottom = 76
	skip.pressed.connect(_credits_done)


func _credits_done() -> void:
	if title_root == null or title_root.has_node("Done"):
		return
	for ch in title_root.get_children():
		if ch is Label or ch is Button:
			ch.queue_free()
	var v := VBoxContainer.new()
	v.name = "Done"
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	title_root.add_child(v)
	var t := _hud_label(v, "Tiệm sách nhỏ vẫn sáng đèn mỗi ngày.", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color("f4d03f"))
	var b := _button(v, "Tiếp tục mở tiệm", Vector2(380, 72), 26)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_finish_ending)
	v.modulate.a = 0.0
	create_tween().tween_property(v, "modulate:a", 1.0, 0.8)


func _finish_ending() -> void:
	buzz(40)
	_fade_out_title()
	ending_finished.emit()


func open_pause() -> void:
	if title_root != null or pause_panel.visible:
		return
	buzz(20)
	pause_panel.move_to_front()
	pause_panel.visible = true
	get_tree().paused = true  # dung khach di lai va dong ho


func close_pause() -> void:
	buzz(15)
	pause_panel.visible = false
	get_tree().paused = false


func open_settings(from_pause: bool) -> void:
	buzz(15)
	_settings_back_to_pause = from_pause
	settings_panel.move_to_front()
	settings_panel.visible = true


func close_settings() -> void:
	buzz(15)
	settings_panel.visible = false
	if _settings_back_to_pause:
		pause_panel.visible = true



# ---------- Huong dan choi lan dau ----------

func _build_tutorial() -> void:
	tut_frame = ReferenceRect.new()
	tut_frame.editor_only = false
	tut_frame.border_color = Color("f4d03f")
	tut_frame.border_width = 6.0
	tut_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_frame.visible = false
	root.add_child(tut_frame)
	tut_box = PanelContainer.new()
	tut_box.add_theme_stylebox_override("panel", _toon(Color("fff4c2"), 12, 16, 6.0))
	tut_box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # khong chan ngon tay
	tut_box.custom_minimum_size = Vector2(420, 0)
	tut_box.visible = false
	root.add_child(tut_box)
	tut_label = _label(tut_box, "", 22)
	tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_label.custom_minimum_size = Vector2(388, 0)


## Hien loi nhac canh mot nut, kem khung vang nhap nhay quanh nut do.
func show_tutorial(text: String, target: Control) -> void:
	_tut_target = target
	tut_label.text = text
	tut_box.size = Vector2.ZERO  # tinh lai chieu cao theo chu
	tut_frame.move_to_front()
	tut_box.move_to_front()
	_place_tutorial()


func hide_tutorial() -> void:
	_tut_target = null
	tut_box.visible = false
	tut_frame.visible = false


func _process(delta: float) -> void:
	if _tut_target != null:
		_tut_t += delta
		_place_tutorial()


func _place_tutorial() -> void:
	var t := _tut_target
	var on := t != null and is_instance_valid(t) and t.is_visible_in_tree() \
		and not pause_panel.visible and not notebook_panel.visible and not settings_panel.visible
	tut_box.visible = on
	tut_frame.visible = on
	if not on:
		return
	var r := t.get_global_rect().grow(8.0)
	tut_frame.position = r.position
	tut_frame.size = r.size
	tut_frame.modulate.a = 0.55 + 0.45 * sin(_tut_t * 5.0)
	var vs := get_viewport().get_visible_rect().size
	var bs := tut_box.get_combined_minimum_size()
	var x := clampf(r.position.x + r.size.x / 2.0 - bs.x / 2.0, 12.0, vs.x - bs.x - 12.0)
	var y := r.position.y - bs.y - 14.0  # uu tien dat phia tren nut
	if y < 80.0:
		y = minf(r.end.y + 14.0, vs.y - bs.y - 12.0)
	tut_box.position = Vector2(x, y)


## Nut dau tien dang hien trong danh sach nhap sach (de chi vao).
func first_book_button(index: int) -> Control:
	for b in Data.BOOKS:
		var row: Array = stock_rows[b["title"]]
		if (row[3] as Control).visible:
			return row[index]
	return null
