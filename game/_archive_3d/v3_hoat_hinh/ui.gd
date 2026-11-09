extends CanvasLayer
## Giao dien phong cach "tranh hoat hinh": vien nau dam day, bong do cung, mau am - khop voi tranh ve.
## Hop thoai co chan dung + bang ten, the sach de chon,
## bang chuan bi / tong ket / so cua ong, man gioi thieu. Bao cho main.gd qua signal.

signal choice_made(index: int)
signal continue_pressed
signal buy_pressed(title: String)
signal open_shop_pressed
signal new_day_pressed
signal title_start_pressed

const Data = preload("res://scripts/game_data.gd")
const FONT_PATH := "res://assets/fonts/Lora-Variable.ttf"

const PAPER := Color("fbf1da")
const PAPER_DARK := Color("efdcb8")
const TEAL := Color("4f8f8c")
const OUTLINE := 5
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
var name_label: Label
var text_label: Label
var hint_label: Label
var more_label: Label
var choice_box: VBoxContainer
var choice_buttons: Array = []
var prep_panel: PanelContainer
var prep_title: Label
var stock_rows := {}
var evening_panel: PanelContainer
var evening_label: Label
var notebook_panel: PanelContainer
var notebook_title: Label
var notebook_list: VBoxContainer
var title_root: Control = null
var _typing: Tween
var _can_continue := false
var font_body: Font = null
var font_bold: Font = null


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	_build_hud()
	_build_dialog()
	_build_panels()


func buzz(ms: int = 25) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func busy() -> bool:
	return title_root != null or dialog.visible or prep_panel.visible or evening_panel.visible or notebook_panel.visible


# ---------- Giao dien chung (theme) ----------

func _sb(bg: Color, border: Color, bw: int, radius: int, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


## Khung kieu tranh hoat hinh: vien dam + bong do cung lech xuong duoi.
func _toon(bg: Color, radius: int, margin: float, drop: float = 7.0, border: Color = INK) -> StyleBoxFlat:
	var s := _sb(bg, border, OUTLINE, radius, margin)
	s.anti_aliasing = true
	if drop > 0.0:
		s.shadow_color = Color(INK, 0.85)
		s.shadow_size = 1
		s.shadow_offset = Vector2(drop * 0.6, drop)
	return s


func _font(weight: int) -> Font:
	if not ResourceLoader.exists(FONT_PATH):
		return null
	var fv := FontVariation.new()
	fv.base_font = load(FONT_PATH)
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight}
	return fv


func _make_theme() -> Theme:
	var th := Theme.new()
	font_body = _font(500)
	font_bold = _font(700)
	if font_body != null:
		th.default_font = font_body
	th.default_font_size = 24
	th.set_stylebox("normal", "Button", _toon(PAPER, 16, 14, 6.0))
	th.set_stylebox("hover", "Button", _toon(Color("fff8e8"), 16, 14, 6.0))
	th.set_stylebox("pressed", "Button", _toon(PAPER_DARK, 16, 14, 2.0))
	th.set_stylebox("disabled", "Button", _toon(Color(0.88, 0.84, 0.76), 16, 14, 0.0, Color(INK, 0.4)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		th.set_color(c, "Button", INK)
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.38, 0.32, 0.7))
	th.set_stylebox("panel", "PanelContainer", _toon(PAPER, 24, 26, 9.0))
	th.set_color("font_color", "Label", INK)
	return th


func _label(parent: Node, text: String, font_size: int, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## Chu sang co vien toi, dung khi chu nam thang tren tranh.
func _hud_label(parent: Node, text: String, font_size: int) -> Label:
	var l := _label(parent, text, font_size, LIGHT)
	l.add_theme_color_override("font_outline_color", Color("2b2420"))
	l.add_theme_constant_override("outline_size", 8)
	return l


func _button(parent: Node, text: String, min_size: Vector2 = Vector2(240, 80), font_size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 200
	p.offset_right = -200
	p.offset_top = 90
	p.offset_bottom = -30
	root.add_child(p)
	p.visible = false
	return p


# ---------- Thanh tren ----------

func _build_hud() -> void:
	var pill := PanelContainer.new()
	var ps := _toon(Color(INK, 0.88), 18, 10, 0.0, Color(PAPER, 0.9))
	ps.set_border_width_all(3)
	ps.content_margin_left = 20
	ps.content_margin_right = 20
	pill.add_theme_stylebox_override("panel", ps)
	pill.position = Vector2(20, 14)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	coins_label = _label(row, "", 26, LIGHT)
	day_label = _label(row, "", 26, Color("f4d03f"))

	info_label = _hud_label(root, "", 26)
	info_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	info_label.offset_left = -300
	info_label.offset_right = 300
	info_label.offset_top = 22
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var book_btn := _button(root, "Sổ của ông", Vector2(200, 64), 24)
	book_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	book_btn.offset_left = -220
	book_btn.offset_right = -20
	book_btn.offset_top = 12
	book_btn.offset_bottom = 76
	book_btn.pressed.connect(open_notebook)

	fps_label = _label(root, "", 16, Color(1, 1, 1, 0.55))
	fps_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fps_label.offset_left = 8
	fps_label.offset_top = -24


func update_hud(stats: String, time_text: String) -> void:
	coins_label.text = stats
	day_label.text = time_text
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func set_info(t: String) -> void:
	info_label.text = t


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
	for i in 3:
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
	plate.rotation_degrees = -3.0  # nghieng nhe nhu nhan dan tay
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
	portrait_frame.rotation_degrees = 2.0
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(portrait_frame)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_frame.add_child(portrait)
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


func set_portrait(tex: Texture2D) -> void:
	portrait.texture = tex
	portrait_frame.visible = tex != null


func say(t: String) -> void:
	text_label.text = t
	text_label.visible_ratio = 0.0
	if _typing != null:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(text_label, "visible_ratio", 1.0, clampf(t.length() * 0.025, 0.3, 2.5))


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


## items: mang Dictionary {title, genre, stock}
func show_choices(items: Array) -> void:
	for i in 3:
		var b: Button = choice_buttons[i]
		b.visible = i < items.size()
		if i < items.size():
			var it: Dictionary = items[i]
			b.text = "%s\n%s · còn %d cuốn" % [it["title"], it["genre"], it["stock"]]
			var col: Color = GENRE_COLORS.get(it["genre"], WOOD)
			(b.get_node("Spine") as ColorRect).color = col
			for st in ["normal", "hover", "pressed"]:
				var sb := _toon(PAPER_DARK if st == "pressed" else PAPER, 16, 14, 2.0 if st == "pressed" else 6.0)
				sb.content_margin_left = 38
				b.add_theme_stylebox_override(st, sb)
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
	_label(v, "Nhập thêm sách cho kệ · %d tiền một cuốn" % GameState.BUY_PRICE, 21, WOOD)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for b in Data.BOOKS:
		var title: String = b["title"]
		var card := PanelContainer.new()
		var cs := _sb(PAPER_DARK, GENRE_COLORS.get(b["genre"], WOOD), 0, 12, 10)
		cs.border_width_left = 12
		cs.content_margin_left = 20
		card.add_theme_stylebox_override("panel", cs)
		list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		row.add_child(info)
		_label(info, title, 23)
		_label(info, b["genre"], 18, WOOD)
		var count_l := _label(row, "", 22)
		count_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var buy := _button(row, "+1", Vector2(96, 56), 24)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.pressed.connect(_on_buy_button.bind(title))
		stock_rows[title] = [count_l, buy]
	var open_btn := _button(v, "Mở cửa tiệm", Vector2(0, 80), 30)
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
	var nscroll := ScrollContainer.new()
	nscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nb.add_child(nscroll)
	notebook_list = VBoxContainer.new()
	notebook_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notebook_list.add_theme_constant_override("separation", 8)
	nscroll.add_child(notebook_list)
	var close_btn := _button(nb, "Đóng sổ", Vector2(0, 72), 26)
	close_btn.pressed.connect(close_notebook)


func _on_buy_button(title: String) -> void:
	buy_pressed.emit(title)


func show_prep() -> void:
	prep_title.text = "Ngày %d · Chuẩn bị (8:00)" % GameState.day
	refresh_stock()
	prep_panel.visible = true


func refresh_stock() -> void:
	for t in stock_rows:
		stock_rows[t][0].text = "Còn %d" % GameState.stock_of(t)
		stock_rows[t][1].disabled = GameState.coins < GameState.BUY_PRICE


func show_evening(text: String) -> void:
	evening_label.text = text
	evening_panel.visible = true


func open_notebook() -> void:
	if dialog.visible or title_root != null:
		return
	buzz(20)
	for ch in notebook_list.get_children():
		notebook_list.remove_child(ch)
		ch.queue_free()
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
	notebook_panel.visible = true


func close_notebook() -> void:
	buzz(15)
	notebook_panel.visible = false


# ---------- Man gioi thieu ----------

func show_title(button_text: String) -> void:
	prep_panel.visible = false
	title_root = Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_root)
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.08, 0.07, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)
	var icon := TextureRect.new()
	icon.texture = load("res://icon.svg")
	icon.custom_minimum_size = Vector2(180, 180)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(icon)
	var t := _hud_label(v, "The Little Bookshop", 64)
	if font_bold != null:
		t.add_theme_font_override("font", font_bold)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color("f4d03f"))
	var start := _button(v, button_text, Vector2(340, 84), 28)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_on_title_button)


func _on_title_button() -> void:
	buzz(40)
	var r := title_root
	title_root = null
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.5)
	tw.tween_callback(r.queue_free)
	title_start_pressed.emit()
