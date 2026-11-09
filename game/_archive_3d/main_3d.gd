extends Node3D
## The Little Bookshop - Sprint 0 prototype
## Mot can phong isometric 3D: xoay/keo/phong to camera, cham chon ke sach,
## mot khach di toi ke roi toi quay, bam "Ban sach" de nhan tien.

const ROOM := 8.0
const SELL_PRICE := 15
const DOOR_POS := Vector3(2.5, 0.0, 3.4)
const COUNTER_FRONT := Vector3(-1.5, 0.0, 1.7)

var coins := 0
var pivot: Node3D
var cam: Camera3D
var target_yaw := 45.0
var walls := []      # moi phan tu: [MeshInstance3D, Vector3 huong mat tuong]
var shelves := []
var selected = null
var customer: Node3D = null
var customer_waiting := false
var title_layer: CanvasLayer = null
# Hoi thoai, cot truyen NPC, so cua ong
var current_visit: Dictionary = {}
var dialog_queue: Array = []
var dialog_mode := ""
var typing_tween: Tween
var continue_btn: Button
var npc_progress := {}
var pages: Array = []
var notebook_panel: PanelContainer
var notebook_title: Label
var notebook_list: VBoxContainer
var _t := 0.0
var _last_cust_pos := Vector3.ZERO

var touches := {}
var drag_dist := 0.0
var pinch_start_dist := 0.0
var pinch_start_size := 12.0

var coins_label: Label
var fps_label: Label
var info_label: Label
const Data = preload("res://scripts/game_data.gd")

var customer_index := 0
var current_customer: Dictionary = {}
var choices := []
var hits := 0
var served := 0

var dialog: PanelContainer
var name_label: Label
var request_label: Label
var hint_label: Label
var choice_box: HBoxContainer
var choice_buttons := []

# Ngay lam viec, ton kho, luu game
enum Phase { PREP, OPEN, EVENING }
const OPEN_MIN := 600.0     # 10:00
const CLOSE_MIN := 1020.0   # 17:00
const MIN_PER_SEC := 2.5    # 1 giay that = 2,5 phut trong game
const BUY_PRICE := 8
const START_COINS := 50
const SAVE_PATH := "user://save.json"
var phase := Phase.PREP
var day := 1
var minutes := 480.0
var stock := {}
var day_coins_start := 0
var day_hits_start := 0
var day_served_start := 0
var day_label: Label
var prep_panel: PanelContainer
var prep_title: Label
var stock_rows := {}
var evening_panel: PanelContainer
var evening_label: Label


func _ready() -> void:
	Engine.max_fps = 60  # game thu gian khong can 120 FPS; giu 60 de do nong may, ton pin
	_build_environment()
	_build_room()
	_build_camera()
	_build_ui()
	_load_game()
	_start_prep()
	_build_title()


# ---------- Dung canh ----------

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _box(size: Vector3, pos: Vector3, c: Color, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2a2320")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffe6c4")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffd9a8")
	sun.light_energy = 1.0
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.55
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)


func _build_room() -> void:
	var h := ROOM / 2.0
	# San gach bong
	_box(Vector3(ROOM, 0.2, ROOM), Vector3(0.0, -0.1, 0.0), Color("8f6a4a"), self)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ROOM, ROOM)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = _tile_texture()
	fm.uv1_scale = Vector3(8.0, 8.0, 1.0)
	fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	fm.roughness = 0.7
	floor_mi.material_override = fm
	floor_mi.position = Vector3(0.0, 0.005, 0.0)
	add_child(floor_mi)
	# Tham do
	_box(Vector3(3.2, 0.03, 2.2), Vector3(0.6, 0.02, 0.2), Color("9c3b2e"), self)
	_box(Vector3(2.8, 0.035, 1.8), Vector3(0.6, 0.022, 0.2), Color("c9643f"), self)

	# Tuong vang, chan tuong go, cua so chop xanh
	_add_wall(Vector3(0.0, 1.5, -h), Vector3(ROOM, 3.0, 0.2), Vector3(0, 0, -1), [Vector3(2.7, 1.75, -h)])
	_add_wall(Vector3(-h, 1.5, 0.0), Vector3(0.2, 3.0, ROOM), Vector3(-1, 0, 0), [Vector3(-h, 1.75, 1.7)])
	_add_wall(Vector3(0.0, 1.5, h), Vector3(ROOM, 3.0, 0.2), Vector3(0, 0, 1), [])
	_add_wall(Vector3(h, 1.5, 0.0), Vector3(0.2, 3.0, ROOM), Vector3(1, 0, 0), [])
	var door := Node3D.new()
	add_child(door)
	_box(Vector3(1.4, 2.4, 0.08), Vector3(DOOR_POS.x, 1.2, h - 0.1), Color("6b4a2f"), door)
	_box(Vector3(1.2, 2.2, 0.1), Vector3(DOOR_POS.x, 1.1, h - 0.12), Color("3e7d7a"), door)
	_no_shadow(door)
	walls.append([door, Vector3(0, 0, 1)])

	_add_shelf(Vector3(-2.3, 0.0, -3.4), 0.0, "Kệ Tiểu thuyết", Color("c0392b"))
	_add_shelf(Vector3(0.6, 0.0, -3.4), 0.0, "Kệ Trinh thám", Color("34495e"))
	_add_shelf(Vector3(-3.4, 0.0, -0.6), 90.0, "Kệ Lịch sử", Color("b9770e"))

	# Quay thu ngan
	_box(Vector3(2.2, 0.95, 0.8), Vector3(-1.5, 0.475, 2.6), Color("7a4a2b"), self)
	_box(Vector3(2.3, 0.08, 0.9), Vector3(-1.5, 0.99, 2.6), Color("5a3520"), self)
	_box(Vector3(2.0, 0.6, 0.03), Vector3(-1.5, 0.5, 2.19), Color("9a6a42"), self)
	_box(Vector3(0.45, 0.3, 0.35), Vector3(-0.9, 1.18, 2.65), Color("c9a227"), self)
	_add_plant(Vector3(-2.35, 1.03, 2.6), 0.6, self)
	# Chong sach duoi san
	_box(Vector3(0.45, 0.12, 0.32), Vector3(-3.3, 0.06, 1.0), Color("2e6f8e"), self)
	_box(Vector3(0.42, 0.1, 0.3), Vector3(-3.28, 0.17, 1.02), Color("c97b3a"), self)
	_box(Vector3(0.4, 0.11, 0.28), Vector3(-3.31, 0.275, 0.99), Color("8e3b46"), self)

	# Goc doc sach: ghe may, ban tron, chau cay lon
	var rattan := Color("c9a26b")
	_box(Vector3(0.9, 0.4, 0.8), Vector3(2.7, 0.2, -2.6), rattan, self)
	_box(Vector3(0.9, 0.7, 0.15), Vector3(2.7, 0.65, -2.95), rattan, self)
	_box(Vector3(0.14, 0.55, 0.8), Vector3(2.25, 0.3, -2.6), rattan, self)
	_box(Vector3(0.14, 0.55, 0.8), Vector3(3.15, 0.3, -2.6), rattan, self)
	_box(Vector3(0.72, 0.12, 0.62), Vector3(2.7, 0.46, -2.55), Color("6c9a6f"), self)
	_cyl(0.25, 0.25, 0.04, Vector3(1.85, 0.55, -2.6), Color("7a4a2b"), self)
	_cyl(0.04, 0.04, 0.55, Vector3(1.85, 0.275, -2.6), Color("5a3520"), self)
	_add_plant(Vector3(3.4, 0.0, -3.4), 1.6, self)
	# Bang phan truoc cua
	_box(Vector3(0.6, 0.9, 0.06), Vector3(3.3, 0.55, 3.0), Color("2d3a33"), self)
	_box(Vector3(0.66, 0.06, 0.08), Vector3(3.3, 1.0, 3.0), Color("8b5a33"), self)
	# Den tha chao xanh
	_add_lamp(Vector3(-0.8, 2.4, -0.8))
	_add_lamp(Vector3(1.6, 2.4, 1.0))


func _add_wall(pos: Vector3, size: Vector3, normal: Vector3, windows: Array) -> void:
	var g := Node3D.new()
	add_child(g)
	_box(size, pos, Color("ead3a0"), g)
	var base_size := size + Vector3(0.04, 0.0, 0.04)
	base_size.y = 0.5
	_box(base_size, Vector3(pos.x, 0.25, pos.z), Color("a8744a"), g)
	for wp in windows:
		_add_window(wp, normal, g)
	_no_shadow(g)
	walls.append([g, normal])


func _no_shadow(node: Node) -> void:
	for ch in node.get_children():
		if ch is GeometryInstance3D:
			(ch as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_no_shadow(ch)


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(c)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _cyl(top_r: float, bot_r: float, h: float, pos: Vector3, c: Color, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(r: float, pos: Vector3, c: Color, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _add_window(wp: Vector3, normal: Vector3, parent: Node) -> void:
	var w := Node3D.new()
	parent.add_child(w)
	w.position = wp - normal * 0.11
	w.rotation.y = atan2(normal.x, normal.z)
	var glass := _box(Vector3(1.0, 1.2, 0.03), Vector3.ZERO, Color("cfeaf5"), w)
	glass.material_override = _glow_mat(Color("cfeaf5"), 0.6)
	var fc := Color("2f5d46")
	_box(Vector3(1.12, 0.08, 0.08), Vector3(0.0, 0.64, 0.0), fc, w)
	_box(Vector3(1.12, 0.08, 0.08), Vector3(0.0, -0.64, 0.0), fc, w)
	_box(Vector3(0.08, 1.36, 0.08), Vector3(-0.56, 0.0, 0.0), fc, w)
	_box(Vector3(0.08, 1.36, 0.08), Vector3(0.56, 0.0, 0.0), fc, w)
	_box(Vector3(0.04, 1.2, 0.05), Vector3.ZERO, fc, w)
	for sx in [-0.86, 0.86]:
		_box(Vector3(0.5, 1.32, 0.05), Vector3(sx, 0.0, -0.02), Color("3e7d5a"), w)
		for k in 5:
			_box(Vector3(0.44, 0.03, 0.06), Vector3(sx, -0.5 + k * 0.25, -0.03), Color("2f6347"), w)


func _add_lamp(pos: Vector3) -> void:
	_box(Vector3(0.03, 3.0 - pos.y, 0.03), Vector3(pos.x, (3.0 + pos.y) / 2.0, pos.z), Color("333333"), self)
	_cyl(0.06, 0.32, 0.26, pos, Color("3e7d5a"), self)
	var bulb := _sphere(0.1, pos + Vector3(0.0, -0.14, 0.0), Color("ffe2a0"), self)
	bulb.material_override = _glow_mat(Color("ffd27a"), 3.0)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0.0, -0.3, 0.0)
	light.light_color = Color("ffc777")
	light.light_energy = 1.4
	light.omni_range = 4.5
	add_child(light)


func _add_plant(pos: Vector3, s: float, parent: Node) -> void:
	_cyl(0.2 * s, 0.15 * s, 0.3 * s, pos + Vector3(0.0, 0.15 * s, 0.0), Color("b8613d"), parent)
	_sphere(0.28 * s, pos + Vector3(0.0, 0.5 * s, 0.0), Color("4f8a4a"), parent)
	_sphere(0.2 * s, pos + Vector3(0.15 * s, 0.68 * s, 0.05 * s), Color("5f9e55"), parent)
	_sphere(0.18 * s, pos + Vector3(-0.12 * s, 0.72 * s, -0.06 * s), Color("3f7a3c"), parent)


func _tile_texture() -> ImageTexture:
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGB8)
	var cream := Color("efe2c6")
	var red := Color("b9583f")
	var teal := Color("3f7f74")
	var grout := Color("cdbb98")
	for y in n:
		for x in n:
			var cx := x - 15.5
			var cy := y - 15.5
			var d := absf(cx) + absf(cy)
			var corner := Vector2(absf(cx), absf(cy)).distance_to(Vector2(15.5, 15.5))
			var col := cream
			if d < 5.0:
				col = red
			elif d >= 8.0 and d < 10.0:
				col = teal
			if corner < 7.0:
				col = red
			if x == 0 or y == 0:
				col = grout
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _make_person(c: Dictionary) -> Node3D:
	var p := Node3D.new()
	var v := Node3D.new()
	v.name = "Visual"
	p.add_child(v)
	var pants := Color("3b3b4a")
	_cyl(0.07, 0.07, 0.5, Vector3(-0.1, 0.25, 0.0), pants, v)
	_cyl(0.07, 0.07, 0.5, Vector3(0.1, 0.25, 0.0), pants, v)
	_cyl(0.2, 0.27, 0.62, Vector3(0.0, 0.78, 0.0), Color(c["color"]), v)
	_sphere(0.27, Vector3(0.0, 1.36, 0.0), Color("f1c9a0"), v)
	var hair := _sphere(0.29, Vector3(0.0, 1.5, -0.08), Color(c.get("hair", "3a2a20")), v)
	hair.scale = Vector3(1.0, 0.75, 1.0)
	_sphere(0.035, Vector3(-0.09, 1.38, 0.25), Color("1d1d1d"), v)
	_sphere(0.035, Vector3(0.09, 1.38, 0.25), Color("1d1d1d"), v)
	if c.get("hat", "") == "non_la":
		_cyl(0.01, 0.45, 0.26, Vector3(0.0, 1.72, 0.0), Color("e8d6a0"), v)
	return p


func _face(node: Node3D, target: Vector3) -> void:
	if not is_instance_valid(node):
		return
	var d := target - node.position
	if d.length() > 0.01:
		node.rotation.y = atan2(d.x, d.z)


func _add_shelf(pos: Vector3, yaw: float, label: String, book_color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = yaw
	add_child(body)
	var wood := Color("8b5a33")
	_box(Vector3(2.0, 2.2, 0.15), Vector3(0.0, 1.1, -0.2), wood, body)
	_box(Vector3(0.1, 2.25, 0.5), Vector3(-1.0, 1.125, 0.0), wood, body)
	_box(Vector3(0.1, 2.25, 0.5), Vector3(1.0, 1.125, 0.0), wood, body)
	for row in 4:
		_box(Vector3(2.0, 0.06, 0.5), Vector3(0.0, 0.1 + row * 0.65, 0.0), wood, body)
	_box(Vector3(2.15, 0.08, 0.58), Vector3(0.0, 2.25, 0.0), Color("6e4527"), body)
	for row in 3:
		var base_y := 0.13 + row * 0.65
		var x := -0.93
		while x < 0.85:
			var bw := minf(randf_range(0.13, 0.22), 0.93 - x)
			if bw < 0.08:
				break
			var bh := randf_range(0.34, 0.48)
			var c := book_color.lightened(randf_range(0.0, 0.35))
			if randf() < 0.5:
				c = book_color.darkened(randf_range(0.0, 0.25))
			if randf() < 0.2:
				c = Color.from_hsv(randf(), 0.45, 0.75)
			_box(Vector3(bw, bh, 0.34), Vector3(x + bw / 2.0, base_y + bh / 2.0, 0.03), c, body)
			x += bw + 0.012
	_add_plant(Vector3(0.6, 2.29, 0.0), 0.35, body)
	var marker := _box(Vector3(2.2, 0.03, 0.9), Vector3(0.0, 0.03, 0.7), Color("f4d03f"), body)
	marker.visible = false
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.2, 0.8)
	col.shape = shape
	col.position = Vector3(0.0, 1.1, 0.1)
	body.add_child(col)
	body.set_meta("label", label)
	body.set_meta("marker", marker)
	body.set_meta("front", pos + Vector3(0.0, 0.0, 1.0).rotated(Vector3.UP, deg_to_rad(yaw)))
	shelves.append(body)


func _build_camera() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	pivot.rotation_degrees.y = target_yaw
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 12.0
	cam.near = 0.1
	cam.far = 100.0
	cam.position = Vector3(0.0, 14.14, 20.0)
	cam.rotation_degrees.x = -35.264
	pivot.add_child(cam)
	cam.current = true


# ---------- Giao dien ----------

func _label(parent: Node, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("fff4e0"))
	l.add_theme_color_override("font_outline_color", Color("2b2420"))
	l.add_theme_constant_override("outline_size", 8)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 96)
	b.add_theme_font_size_override("font_size", 32)
	parent.add_child(b)
	return b


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	top.offset_bottom = 70
	top.add_theme_constant_override("separation", 40)
	layer.add_child(top)
	coins_label = _label(top, "Tiền: 0", 32)
	day_label = _label(top, "Ngày 1 · 08:00", 30)
	info_label = _label(top, "Chạm vào kệ sách để xem", 30)
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fps_label = _label(top, "FPS: 0", 26)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -120
	bottom.offset_bottom = -20
	bottom.add_theme_constant_override("separation", 24)
	layer.add_child(bottom)
	var rotate_btn := _button(bottom, "Xoay phòng")
	rotate_btn.pressed.connect(_on_rotate)
	var book_btn := _button(bottom, "Sổ của ông")
	book_btn.pressed.connect(_on_open_notebook)

	# Khung hoi thoai tu van sach
	dialog = PanelContainer.new()
	dialog.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog.offset_left = 160
	dialog.offset_right = -160
	dialog.offset_top = -400
	dialog.offset_bottom = -130
	dialog.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.14, 0.12, 0.93)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(20)
	dialog.add_theme_stylebox_override("panel", style)
	layer.add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	dialog.add_child(box)
	name_label = _label(box, "", 28)
	name_label.add_theme_color_override("font_color", Color("f4d03f"))
	request_label = _label(box, "", 26)
	request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label = _label(box, "", 22)
	hint_label.add_theme_color_override("font_color", Color("d5c4a1"))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_box = HBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 16)
	box.add_child(choice_box)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 100)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_on_choice.bind(i))
		choice_box.add_child(b)
		choice_buttons.append(b)
	continue_btn = _button(box, "Tiếp »")
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_btn.custom_minimum_size = Vector2(200, 80)
	continue_btn.pressed.connect(_on_continue)
	dialog.visible = false
	_build_panels(layer)


func _on_rotate() -> void:
	_buzz()
	target_yaw += 90.0


# ---------- Moi khung hinh ----------

func _process(delta: float) -> void:
	if title_layer != null:
		target_yaw += delta * 6.0  # man gioi thieu: camera xoay cham quanh tiem
	pivot.rotation_degrees.y = lerpf(pivot.rotation_degrees.y, target_yaw, clampf(delta * 8.0, 0.0, 1.0))
	var back := cam.global_transform.basis.z
	back.y = 0.0
	back = back.normalized()
	for w in walls:
		var normal: Vector3 = w[1]
		w[0].visible = normal.dot(back) < 0.3
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	_t += delta
	if customer != null and is_instance_valid(customer):
		var moved := customer.position.distance_to(_last_cust_pos) > 0.0005
		_last_cust_pos = customer.position
		var vis := customer.get_node_or_null("Visual") as Node3D
		if vis != null:
			vis.position.y = absf(sin(_t * 11.0)) * 0.07 if moved else 0.0
	if phase == Phase.OPEN and not dialog.visible and not notebook_panel.visible:
		minutes = minf(minutes + delta * MIN_PER_SEC, CLOSE_MIN)
	var m := int(minutes)
	day_label.text = "Ngày %d · %02d:%02d" % [day, floori(m / 60.0), m % 60]


# ---------- Cam ung: cham, keo, chum hai ngon ----------

func _unhandled_input(event: InputEvent) -> void:
	if title_layer != null or prep_panel.visible or evening_panel.visible or notebook_panel.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			if touches.size() == 1:
				drag_dist = 0.0
			elif touches.size() == 2:
				pinch_start_dist = _touch_distance()
				pinch_start_size = cam.size
		else:
			if touches.size() == 1 and drag_dist < 12.0:
				_tap(event.position)
			touches.erase(event.index)
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() == 1:
			drag_dist += event.relative.length()
			_pan(event.relative)
		elif touches.size() == 2 and pinch_start_dist > 0.0:
			drag_dist = 999.0
			var d := _touch_distance()
			cam.size = clampf(pinch_start_size * pinch_start_dist / maxf(d, 1.0), 5.0, 20.0)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.size = clampf(cam.size * 0.9, 5.0, 20.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.size = clampf(cam.size * 1.1, 5.0, 20.0)


func _touch_distance() -> float:
	var pts := touches.values()
	if pts.size() < 2:
		return 0.0
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	return a.distance_to(b)


func _pan(rel: Vector2) -> void:
	var k := cam.size / get_viewport().get_visible_rect().size.y
	var right := cam.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var fwd := -cam.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var p := pivot.position - right * rel.x * k + fwd * rel.y * k * 1.7
	p.x = clampf(p.x, -4.0, 4.0)
	p.z = clampf(p.z, -4.0, 4.0)
	pivot.position = p


func _tap(screen_pos: Vector2) -> void:
	if dialog.visible:
		return  # dang tu van, khong chon ke
	var vh := get_viewport().get_visible_rect().size.y
	if screen_pos.y < 80.0 or screen_pos.y > vh - 140.0:
		return  # vung thanh tren / nut bam
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_select(null)
		return
	var col = hit["collider"]
	if col in shelves:
		_select(col)
	else:
		_select(null)


func _select(s) -> void:
	if selected != null:
		selected.get_meta("marker").visible = false
	selected = s
	if selected != null:
		_buzz(15)
		selected.get_meta("marker").visible = true
		info_label.text = selected.get_meta("label")
	else:
		info_label.text = "Chạm vào kệ sách để xem"


# ---------- Khach hang va tu van sach ----------

func _walk_time(a: Vector3, b: Vector3) -> float:
	return a.distance_to(b) / 1.6


func _update_stats() -> void:
	coins_label.text = "Tiền: %d · Trúng ý: %d/%d" % [coins, hits, served]


func _spawn_customer() -> void:
	current_customer = _next_customer()
	customer = _make_person(current_customer)
	add_child(customer)
	customer.position = DOOR_POS

	var shelf: Node3D = shelves.pick_random()
	var shelf_front: Vector3 = shelf.get_meta("front")
	info_label.text = "%s vào tiệm" % current_customer["name"]
	var tw := create_tween()
	tw.tween_callback(_face.bind(customer, shelf_front))
	tw.tween_property(customer, "position", shelf_front, _walk_time(DOOR_POS, shelf_front))
	tw.tween_callback(_face.bind(customer, shelf.position))
	tw.tween_interval(1.5)
	tw.tween_callback(_face.bind(customer, COUNTER_FRONT))
	tw.tween_property(customer, "position", COUNTER_FRONT, _walk_time(shelf_front, COUNTER_FRONT))
	tw.tween_callback(_face.bind(customer, COUNTER_FRONT + Vector3(0.0, 0.0, 1.0)))
	tw.tween_callback(_customer_at_counter)


func _score(book: Dictionary, c: Dictionary) -> int:
	var s := 0
	for t in book["tags"]:
		if t in c["want"]:
			s += 1
		if t in c["avoid"]:
			s -= 2
	return s


func _customer_at_counter() -> void:
	customer_waiting = true
	_select(null)
	info_label.text = "Khách đang nói chuyện ở quầy"
	current_visit = _current_visit(current_customer)
	name_label.text = current_customer["name"]
	hint_label.visible = false
	choice_box.visible = false
	dialog.visible = true
	dialog_mode = "intro"
	dialog_queue = []
	for line in current_visit.get("lines", []):
		dialog_queue.append("“%s”" % line)
	dialog_queue.append("“%s”" % current_visit["request"])
	continue_btn.visible = true
	_next_line()


func _next_customer() -> Dictionary:
	var n: int = Data.CUSTOMERS.size()
	for k in n:
		var c: Dictionary = Data.CUSTOMERS[(customer_index + k) % n]
		if c.has("visits") and int(npc_progress.get(c["name"], 0)) >= c["visits"].size():
			continue  # NPC da xong cot truyen
		customer_index += k + 1
		return c
	customer_index += 1
	return Data.CUSTOMERS[customer_index % n]


func _current_visit(c: Dictionary) -> Dictionary:
	if c.has("visits"):
		var v: Array = c["visits"]
		var k := mini(int(npc_progress.get(c["name"], 0)), v.size() - 1)
		return v[k]
	return c


func _say(text: String) -> void:
	request_label.text = text
	request_label.visible_ratio = 0.0
	if typing_tween != null:
		typing_tween.kill()
	typing_tween = create_tween()
	typing_tween.tween_property(request_label, "visible_ratio", 1.0, clampf(text.length() * 0.025, 0.3, 2.5))


func _next_line() -> void:
	_say(dialog_queue.pop_front())
	if dialog_queue.is_empty() and dialog_mode == "intro":
		_show_choices()


func _on_continue() -> void:
	_buzz(15)
	if request_label.visible_ratio < 1.0:
		if typing_tween != null:
			typing_tween.kill()
		request_label.visible_ratio = 1.0
		return
	if not dialog_queue.is_empty():
		_next_line()
		return
	if dialog_mode == "outro":
		continue_btn.visible = false
		dialog_mode = ""
		_customer_leave()


func _show_choices() -> void:
	var c := current_visit
	var books: Array = []
	for b in Data.BOOKS:
		if int(stock.get(b["title"], 0)) > 0:
			books.append(b)
	if books.is_empty():
		customer_waiting = false
		info_label.text = "Hết sách! Nhớ nhập thêm vào buổi sáng"
		dialog_mode = "outro"
		dialog_queue = ["“Tiệm hết sách rồi à? Hôm khác tôi quay lại vậy.”"]
		return
	continue_btn.visible = false
	var hint: String = current_customer.get("hint", "")
	hint_label.text = hint
	hint_label.visible = hint != ""
	# Luon co 1 cuon hop nhat (trong so sach con) + toi da 2 cuon ngau nhien
	books.shuffle()
	var best: Dictionary = books[0]
	for b in books:
		if _score(b, c) > _score(best, c):
			best = b
	choices = [best]
	for b in books:
		if choices.size() >= 3:
			break
		if b != best:
			choices.append(b)
	choices.shuffle()
	for i in 3:
		choice_buttons[i].visible = i < choices.size()
		if i < choices.size():
			var bk: Dictionary = choices[i]
			choice_buttons[i].text = "%s\n(%s) · còn %d" % [bk["title"], bk["genre"], int(stock[bk["title"]])]
	choice_box.visible = true
	info_label.text = "Chọn sách phù hợp cho khách"


func _on_choice(i: int) -> void:
	if not customer_waiting:
		return
	_buzz(35)
	customer_waiting = false
	var c := current_visit
	var bk: Dictionary = choices[i]
	var sc := _score(bk, c)
	var line := ""
	var reward := 0
	var outro: Array = []
	if sc >= 2:
		line = c["great"]
		reward = 25
		hits += 1
		if current_customer.has("visits"):
			var nm: String = current_customer["name"]
			npc_progress[nm] = int(npc_progress.get(nm, 0)) + 1
			pages.append({"name": nm, "text": c["page"]})
			outro.append("~ Một trang mới trong sổ của ông vừa mở ra.")
	elif sc == 1:
		line = c["ok"]
		reward = 15
	else:
		line = c["miss"]
		reward = 10
	served += 1
	coins += reward
	stock[bk["title"]] = int(stock[bk["title"]]) - 1
	_update_stats()
	hint_label.text = "Bạn đã gợi ý: %s  (+%d tiền)" % [bk["title"], reward]
	hint_label.visible = true
	choice_box.visible = false
	info_label.text = "Khách đã chọn sách"
	dialog_mode = "outro"
	dialog_queue = outro
	_say("“%s”" % line)
	continue_btn.visible = true
	_save_game()


func _customer_leave() -> void:
	var leaving := customer
	_close_dialog()
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(_face.bind(leaving, DOOR_POS))
	tw.tween_property(leaving, "position", DOOR_POS, _walk_time(COUNTER_FRONT, DOOR_POS))
	tw.tween_callback(leaving.queue_free)
	tw.tween_interval(1.5)
	tw.tween_callback(_after_customer_left)


func _after_customer_left() -> void:
	if phase == Phase.OPEN and minutes < CLOSE_MIN:
		_spawn_customer()
	else:
		_start_evening()


func _close_dialog() -> void:
	dialog.visible = false


# ---------- Ngay lam viec: chuan bi, mo cua, buoi toi ----------

func _make_panel(layer: CanvasLayer) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 220
	p.offset_right = -220
	p.offset_top = 90
	p.offset_bottom = -40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.14, 0.12, 0.95)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(24)
	p.add_theme_stylebox_override("panel", style)
	layer.add_child(p)
	p.visible = false
	return p


func _build_panels(layer: CanvasLayer) -> void:
	# Bang Chuan bi: nhap sach
	prep_panel = _make_panel(layer)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	prep_panel.add_child(v)
	prep_title = _label(v, "", 32)
	prep_title.add_theme_color_override("font_color", Color("f4d03f"))
	_label(v, "Nhập thêm sách cho kệ · %d tiền một cuốn" % BUY_PRICE, 22)
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
		var count_l := _label(row, "Còn: 0", 22)
		var buy := Button.new()
		buy.text = "+1"
		buy.custom_minimum_size = Vector2(110, 64)
		buy.add_theme_font_size_override("font_size", 26)
		buy.pressed.connect(_on_buy.bind(title))
		row.add_child(buy)
		stock_rows[title] = [count_l, buy]
	var open_btn := Button.new()
	open_btn.text = "Mở cửa tiệm"
	open_btn.custom_minimum_size = Vector2(0, 90)
	open_btn.add_theme_font_size_override("font_size", 32)
	open_btn.pressed.connect(_on_open_shop)
	v.add_child(open_btn)

	# Bang Buoi toi: tong ket ngay
	evening_panel = _make_panel(layer)
	var e := VBoxContainer.new()
	e.add_theme_constant_override("separation", 16)
	evening_panel.add_child(e)
	evening_label = _label(e, "", 28)
	evening_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evening_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next_btn := Button.new()
	next_btn.text = "Sang ngày mới"
	next_btn.custom_minimum_size = Vector2(0, 90)
	next_btn.add_theme_font_size_override("font_size", 32)
	next_btn.pressed.connect(_on_new_day)
	e.add_child(next_btn)

	# Bang So cua ong
	notebook_panel = _make_panel(layer)
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
	var close_btn := Button.new()
	close_btn.text = "Đóng sổ"
	close_btn.custom_minimum_size = Vector2(0, 80)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.pressed.connect(_on_close_notebook)
	nb.add_child(close_btn)


func _start_prep() -> void:
	phase = Phase.PREP
	minutes = 480.0
	day_coins_start = coins
	day_hits_start = hits
	day_served_start = served
	evening_panel.visible = false
	dialog.visible = false
	prep_panel.visible = true
	info_label.text = "Chuẩn bị mở cửa"
	_refresh_stock_ui()
	_update_stats()


func _refresh_stock_ui() -> void:
	prep_title.text = "Ngày %d · Chuẩn bị (8:00)" % day
	for t in stock_rows:
		stock_rows[t][0].text = "Còn: %d" % int(stock.get(t, 0))
		stock_rows[t][1].disabled = coins < BUY_PRICE


func _on_buy(title: String) -> void:
	_buzz()
	if coins < BUY_PRICE:
		return
	coins -= BUY_PRICE
	stock[title] = int(stock.get(title, 0)) + 1
	_refresh_stock_ui()
	_update_stats()


func _on_open_shop() -> void:
	_buzz(40)
	prep_panel.visible = false
	phase = Phase.OPEN
	minutes = OPEN_MIN
	_save_game()
	_spawn_customer()


func _start_evening() -> void:
	phase = Phase.EVENING
	minutes = CLOSE_MIN
	var served_today := served - day_served_start
	var hits_today := hits - day_hits_start
	var total_stock := 0
	for t in stock:
		total_stock += int(stock[t])
	evening_label.text = "Ngày %d kết thúc\n\nLãi hôm nay: %d tiền\nKhách đã phục vụ: %d\nTư vấn trúng ý: %d/%d\nSách còn trên kệ: %d cuốn\n\nTổng tiền: %d" % [day, coins - day_coins_start, served_today, hits_today, served_today, total_stock, coins]
	info_label.text = "Tiệm đã đóng cửa"
	evening_panel.visible = true
	_save_game()


func _on_new_day() -> void:
	_buzz(40)
	day += 1
	_start_prep()
	_save_game()


# ---------- Luu / tai game ----------

func _save_game() -> void:
	var data := {"version": 2, "day": day, "coins": coins, "hits": hits, "served": served, "stock": stock, "customer_index": customer_index, "npc_progress": npc_progress, "pages": pages}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


func _load_game() -> void:
	coins = START_COINS
	for b in Data.BOOKS:
		stock[b["title"]] = 2
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	day = int(d.get("day", 1))
	coins = int(d.get("coins", START_COINS))
	hits = int(d.get("hits", 0))
	served = int(d.get("served", 0))
	customer_index = int(d.get("customer_index", 0))
	var np = d.get("npc_progress", {})
	if typeof(np) == TYPE_DICTIONARY:
		for k in np:
			npc_progress[k] = int(np[k])
	var pg = d.get("pages", [])
	if typeof(pg) == TYPE_ARRAY:
		pages = pg
	var st = d.get("stock", {})
	if typeof(st) == TYPE_DICTIONARY:
		for t in st:
			if stock.has(t):
				stock[t] = int(st[t])


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if prep_panel != null:
			_save_game()


# ---------- Rung khi cham, man gioi thieu ----------

func _buzz(ms: int = 25) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _build_title() -> void:
	title_layer = CanvasLayer.new()
	title_layer.layer = 10
	add_child(title_layer)
	prep_panel.visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.08, 0.07, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(center)
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
	var text := "Bắt đầu"
	if FileAccess.file_exists(SAVE_PATH):
		text = "Chơi tiếp · Ngày %d" % day
	var start := _button(v, text)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.custom_minimum_size = Vector2(340, 96)
	start.pressed.connect(_on_title_start)


func _on_title_start() -> void:
	_buzz(40)
	var layer := title_layer
	title_layer = null
	target_yaw = roundf((target_yaw - 45.0) / 90.0) * 90.0 + 45.0
	prep_panel.visible = phase == Phase.PREP
	var tw := create_tween()
	for ch in layer.get_children():
		if ch is CanvasItem:
			tw.parallel().tween_property(ch, "modulate:a", 0.0, 0.5)
	tw.tween_callback(layer.queue_free)


# ---------- So cua ong ----------

func _on_open_notebook() -> void:
	if dialog.visible or title_layer != null:
		return
	_buzz(20)
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
		for pg in pages:
			if pg["name"] == nm:
				opened += 1
				var t := _label(notebook_list, "• " + str(pg["text"]), 22)
				t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for _k in range(n_pages - opened):
			var locked := _label(notebook_list, "• …trang chưa mở", 22)
			locked.modulate = Color(1, 1, 1, 0.45)
	notebook_title.text = "Sổ của ông · đã mở %d/%d trang" % [pages.size(), total]
	notebook_panel.visible = true


func _on_close_notebook() -> void:
	_buzz(15)
	notebook_panel.visible = false
