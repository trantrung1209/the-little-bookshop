extends CanvasLayer
## Toan bo giao dien: thanh tren, hop thoai co chan dung, bang chuan bi,
## tong ket ngay, so cua ong, man gioi thieu. Bao cho main.gd qua signal.

signal choice_made(index: int)
signal continue_pressed
signal buy_pressed(title: String)
signal open_shop_pressed
signal new_day_pressed
signal title_start_pressed

const Data = preload("res://scripts/game_data.gd")

var coins_label: Label
var day_label: Label
var info_label: Label
var fps_label: Label
var dialog: PanelContainer
var portrait: TextureRect
var name_label: Label
var text_label: Label
var hint_label: Label
var choice_box: HBoxContainer
var choice_buttons: Array = []
var continue_btn: Button
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


func _ready() -> void:
	_build_hud()
	_build_dialog()
	_build_panels()


func buzz(ms: int = 25) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func busy() -> bool:
	return title_root != null or dialog.visible or prep_panel.visible or evening_panel.visible or notebook_panel.visible


# ---------- Khoi dung chung ----------

func _label(parent: Node, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("fff4e0"))
	l.add_theme_color_override("font_outline_color", Color("2b2420"))
	l.add_theme_constant_override("outline_size", 8)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, min_size: Vector2 = Vector2(240, 96), font_size: int = 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b


func _style(alpha: float) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.17, 0.14, 0.12, alpha)
	st.set_corner_radius_all(16)
	st.set_content_margin_all(22)
	return st


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 220
	p.offset_right = -220
	p.offset_top = 90
	p.offset_bottom = -40
	p.add_theme_stylebox_override("panel", _style(0.95))
	add_child(p)
	p.visible = false
	return p


# ---------- Thanh tren / duoi ----------

func _build_hud() -> void:
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	top.offset_bottom = 70
	top.add_theme_constant_override("separation", 40)
	add_child(top)
	coins_label = _label(top, "", 32)
	day_label = _label(top, "", 30)
	info_label = _label(top, "", 28)
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fps_label = _label(top, "", 22)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -100
	bottom.offset_bottom = -16
	add_child(bottom)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	var book_btn := _button(bottom, "Sổ của ông", Vector2(240, 84))
	book_btn.pressed.connect(open_notebook)


func update_hud(stats: String, time_text: String) -> void:
	coins_label.text = stats
	day_label.text = time_text
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func set_info(t: String) -> void:
	info_label.text = t


# ---------- Hop thoai ----------

func _build_dialog() -> void:
	dialog = PanelContainer.new()
	dialog.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog.offset_left = 60
	dialog.offset_right = -60
	dialog.offset_top = -400
	dialog.offset_bottom = -110
	dialog.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog.add_theme_stylebox_override("panel", _style(0.93))
	add_child(dialog)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	dialog.add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(220, 220)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	row.add_child(box)
	name_label = _label(box, "", 28)
	name_label.add_theme_color_override("font_color", Color("f4d03f"))
	text_label = _label(box, "", 26)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label = _label(box, "", 22)
	hint_label.add_theme_color_override("font_color", Color("d5c4a1"))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_box = HBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 16)
	box.add_child(choice_box)
	for i in 3:
		var b := _button(choice_box, "", Vector2(0, 100), 22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_choice_button.bind(i))
		choice_buttons.append(b)
	continue_btn = _button(box, "Tiếp »", Vector2(200, 80), 28)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_btn.pressed.connect(_on_continue_button)
	dialog.visible = false


func _on_choice_button(i: int) -> void:
	choice_made.emit(i)


func _on_continue_button() -> void:
	buzz(15)
	continue_pressed.emit()


func open_dialog(speaker: String, tex: Texture2D) -> void:
	name_label.text = speaker
	set_portrait(tex)
	hint_label.visible = false
	choice_box.visible = false
	continue_btn.visible = true
	dialog.visible = true


func set_portrait(tex: Texture2D) -> void:
	portrait.texture = tex
	portrait.visible = tex != null


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


func show_choices(labels: Array) -> void:
	for i in 3:
		choice_buttons[i].visible = i < labels.size()
		if i < labels.size():
			choice_buttons[i].text = labels[i]
	choice_box.visible = true
	continue_btn.visible = false


func hide_choices() -> void:
	choice_box.visible = false


func show_continue(on: bool) -> void:
	continue_btn.visible = on


func close_dialog() -> void:
	dialog.visible = false


# ---------- Bang chuan bi / tong ket / so ----------

func _build_panels() -> void:
	prep_panel = _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	prep_panel.add_child(v)
	prep_title = _label(v, "", 32)
	prep_title.add_theme_color_override("font_color", Color("f4d03f"))
	_label(v, "Nhập thêm sách cho kệ · %d tiền một cuốn" % GameState.BUY_PRICE, 22)
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
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		list.add_child(row)
		var name_l := _label(row, "%s (%s)" % [title, b["genre"]], 22)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var count_l := _label(row, "", 22)
		var buy := _button(row, "+1", Vector2(110, 64), 26)
		buy.pressed.connect(_on_buy_button.bind(title))
		stock_rows[title] = [count_l, buy]
	var open_btn := _button(v, "Mở cửa tiệm", Vector2(0, 90), 32)
	open_btn.pressed.connect(func() -> void: open_shop_pressed.emit())

	evening_panel = _panel()
	var e := VBoxContainer.new()
	e.add_theme_constant_override("separation", 16)
	evening_panel.add_child(e)
	evening_label = _label(e, "", 28)
	evening_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evening_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next_btn := _button(e, "Sang ngày mới", Vector2(0, 90), 32)
	next_btn.pressed.connect(func() -> void: new_day_pressed.emit())

	notebook_panel = _panel()
	var nb := VBoxContainer.new()
	nb.add_theme_constant_override("separation", 12)
	notebook_panel.add_child(nb)
	notebook_title = _label(nb, "Sổ của ông", 32)
	notebook_title.add_theme_color_override("font_color", Color("f4d03f"))
	var nscroll := ScrollContainer.new()
	nscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nb.add_child(nscroll)
	notebook_list = VBoxContainer.new()
	notebook_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notebook_list.add_theme_constant_override("separation", 8)
	nscroll.add_child(notebook_list)
	var close_btn := _button(nb, "Đóng sổ", Vector2(0, 80), 28)
	close_btn.pressed.connect(close_notebook)


func _on_buy_button(title: String) -> void:
	buy_pressed.emit(title)


func show_prep() -> void:
	prep_title.text = "Ngày %d · Chuẩn bị (8:00)" % GameState.day
	refresh_stock()
	prep_panel.visible = true


func refresh_stock() -> void:
	for t in stock_rows:
		stock_rows[t][0].text = "Còn: %d" % GameState.stock_of(t)
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
		var head := _label(notebook_list, nm, 28)
		head.add_theme_color_override("font_color", Color("f4d03f"))
		var opened := 0
		for pg in GameState.pages:
			if pg["name"] == nm:
				opened += 1
				var t := _label(notebook_list, "• " + str(pg["text"]), 22)
				t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for _k in range(n_pages - opened):
			var locked := _label(notebook_list, "• …trang chưa mở", 22)
			locked.modulate = Color(1, 1, 1, 0.45)
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
	add_child(title_root)
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.08, 0.07, 0.6)
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
	icon.custom_minimum_size = Vector2(200, 200)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(icon)
	var t := _label(v, "The Little Bookshop", 64)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color("f4d03f"))
	var start := _button(v, button_text, Vector2(340, 96), 30)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_on_title_button)


func _on_title_button() -> void:
	buzz(40)
	var root := title_root
	title_root = null
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.5)
	tw.tween_callback(root.queue_free)
	title_start_pressed.emit()
