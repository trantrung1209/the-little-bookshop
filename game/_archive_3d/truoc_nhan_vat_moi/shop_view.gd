extends Node2D
## Hien thi tiem sach 2D nhin ngang: anh nen, ke sach cham duoc, khach di lai tren 1 duong san.
## Hinh lay tu res://assets/art/<ten>.png.
## Nhan vat co hoat hinh di bo neu co du file <id>_walk_0.png ... <id>_walk_5.png
## (va <id>_idle.png khi dung yen). Neu khong co, dung 1 hinh tinh <id>.png + nhun nhe.

const Layout = preload("res://scripts/shop_layout.gd")
const Rigs = preload("res://scripts/rigs.gd")
const Data = preload("res://scripts/game_data.gd")
const DIM := Color(0.8, 0.76, 0.72)  # tiem toi khi chua thay bong den
const ART := "res://assets/art/"
const MAX_WALK_FRAMES := 16  # nhan vat co the co 4, 6, 8... khung di bo

var world: Node2D
var highlights: Array = []
var _walkers := {}
var _t := 0.0
var dust: Sprite2D
var webs: Sprite2D
var decor := {}   # id -> Sprite2D do trang tri da dat
var tint: CanvasModulate   # mau anh sang theo gio trong ngay + thoi tiet
var rain: Node2D
var _drops: Array = []
var _weather := "sun"
const RAIN_AREA := Rect2(1440, 100, 480, 860)   # vung cua kinh nhin ra pho
## (phut trong ngay, mau anh sang)
const DAYLIGHT := [
	[480.0, Color(1.0, 0.97, 0.93)], [600.0, Color(1.0, 1.0, 1.0)], [840.0, Color(1.0, 0.99, 0.96)],
	[960.0, Color(1.0, 0.92, 0.82)], [1020.0, Color(0.93, 0.8, 0.74)], [1080.0, Color(0.8, 0.7, 0.72)],
]


func _ready() -> void:
	world = Node2D.new()
	world.y_sort_enabled = true
	# pixel art: giu canh vuong sac net, khong lam mo
	world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world)
	var bg := Sprite2D.new()
	bg.texture = tex("shop_bg")
	bg.centered = false
	bg.z_index = -10
	world.add_child(bg)
	# lop bui va mang nhen phu len nen (an dan khi don dep)
	dust = _overlay("dirt_dust", -9)
	webs = _overlay("dirt_webs", -8)
	tint = CanvasModulate.new()
	add_child(tint)
	rain = Node2D.new()
	rain.z_index = -7
	rain.visible = false
	rain.draw.connect(_draw_rain)
	world.add_child(rain)
	for i in 70:
		_drops.append(Vector2(RAIN_AREA.position.x + randf() * RAIN_AREA.size.x, RAIN_AREA.position.y + randf() * RAIN_AREA.size.y))
	for s in Layout.SHELVES:
		var r: Rect2 = s["rect"]
		var hl := ReferenceRect.new()
		hl.editor_only = false
		hl.border_color = Color("f4d03f")
		hl.border_width = 8.0
		hl.position = r.position
		hl.size = r.size
		hl.z_index = 5
		hl.visible = false
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(hl)
		highlights.append(hl)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _overlay(file: String, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex_or_null(file)
	s.centered = false
	s.z_index = z
	world.add_child(s)
	return s


## Cap nhat tiem theo cac mon sua sang da mua. just_bought = id vua mua (co hieu ung).
func apply_upgrades(just_bought: String = "") -> void:
	_show_dirt(webs, not GameState.has_upgrade("webs"), just_bought == "webs")
	_show_dirt(dust, not GameState.has_upgrade("dust"), just_bought == "dust")
	var light := Color.WHITE if GameState.has_upgrade("bulb") else DIM
	if just_bought == "bulb":
		create_tween().tween_property(world, "modulate", light, 1.2)
	else:
		world.modulate = light
	for u in Data.UPGRADES:
		if u["kind"] != "decor":
			continue
		var id: String = u["id"]
		var owned := GameState.has_upgrade(id)
		if owned and not decor.has(id):
			var t := tex_or_null(u["sprite"])
			if t == null:
				continue
			var s := Sprite2D.new()
			s.texture = t
			s.centered = false
			s.offset = Vector2(-t.get_width() / 2.0, -float(t.get_height()))  # goc o giua-day hinh
			s.position = u["pos"]
			s.z_index = -5  # sau nhan vat
			world.add_child(s)
			decor[id] = s
			if id == just_bought:
				s.scale = Vector2(0.6, 0.6)
				s.modulate.a = 0.0
				var tw := create_tween().set_parallel()
				tw.tween_property(s, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(s, "modulate:a", 1.0, 0.3)
		elif not owned and decor.has(id):
			decor[id].queue_free()
			decor.erase(id)


## Thoi tiet cua ngay: "sun" / "cloud" / "rain".
func set_weather(w: String) -> void:
	_weather = w
	rain.visible = w == "rain"


## Doi mau anh sang theo gio (phut trong ngay) va thoi tiet.
func set_time(minutes: float) -> void:
	var c: Color = DAYLIGHT[0][1]
	for i in range(DAYLIGHT.size() - 1):
		var a: Array = DAYLIGHT[i]
		var b: Array = DAYLIGHT[i + 1]
		if minutes >= float(a[0]) and minutes <= float(b[0]):
			c = (a[1] as Color).lerp(b[1], (minutes - float(a[0])) / (float(b[0]) - float(a[0])))
			break
		if minutes > float(b[0]):
			c = b[1]
	if _weather == "rain":
		c *= Color(0.82, 0.86, 0.94)
	elif _weather == "cloud":
		c *= Color(0.93, 0.94, 0.97)
	c.a = 1.0
	tint.color = c


func _draw_rain() -> void:
	for d in _drops:
		rain.draw_rect(Rect2(d, Vector2(5, 30)), Color(0.85, 0.9, 1.0, 0.45))


func _move_rain(delta: float) -> void:
	for i in _drops.size():
		var d: Vector2 = _drops[i]
		d += Vector2(-120.0, 1100.0) * delta
		if d.y > RAIN_AREA.end.y or d.x < RAIN_AREA.position.x:
			d = Vector2(RAIN_AREA.position.x + randf() * RAIN_AREA.size.x + 60.0, RAIN_AREA.position.y)
		_drops[i] = d
	rain.queue_redraw()


func _show_dirt(s: Sprite2D, on: bool, animate: bool) -> void:
	if s == null:
		return
	if on:
		s.visible = true
		s.modulate.a = 1.0
	elif animate:
		var tw := create_tween()
		tw.tween_property(s, "modulate:a", 0.0, 1.0)
		tw.tween_callback(s.hide)
	else:
		s.visible = false


func _fit() -> void:
	var vs := get_viewport_rect().size
	var s := vs.y / Layout.ART_SIZE.y
	world.scale = Vector2(s, s)
	world.position = Vector2((vs.x - Layout.ART_SIZE.x * s) / 2.0, 0.0)


func tex(name: String) -> Texture2D:
	var t := tex_or_null(name)
	if t == null:
		return load(ART + "missing.png")
	return t


func tex_or_null(name: String) -> Texture2D:
	var path := ART + name + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return null


func shelf_at(screen_pos: Vector2) -> int:
	var p := world.get_global_transform().affine_inverse() * screen_pos
	for i in Layout.SHELVES.size():
		var r: Rect2 = Layout.SHELVES[i]["rect"]
		if r.has_point(p):
			return i
	return -1


func highlight(index: int) -> void:
	for k in highlights.size():
		highlights[k].visible = k == index


## Tao SpriteFrames tu cac file <id>_walk_N.png; tra ve null neu thieu file.
func _walk_frames(sprite_id: String) -> SpriteFrames:
	if tex_or_null("%s_walk_0" % sprite_id) == null:
		return null
	var sf := SpriteFrames.new()
	sf.add_animation("walk")
	sf.set_animation_speed("walk", Layout.WALK_FPS)
	sf.set_animation_loop("walk", true)
	for i in MAX_WALK_FRAMES:
		var t := tex_or_null("%s_walk_%d" % [sprite_id, i])
		if t == null:
			break
		sf.add_frame("walk", t)
	var idle := tex_or_null("%s_idle" % sprite_id)
	if idle == null:
		idle = sf.get_frame_texture("walk", 0)
	sf.set_animation_speed("default", 1.0)
	sf.add_frame("default", idle)
	return sf


func spawn_person(sprite_id: String) -> Node2D:
	var p := Node2D.new()
	var spr: Node2D
	var h := 1.0
	var sf := _walk_frames(sprite_id)
	if sf != null:
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = sf
		anim.animation = "default"
		h = float(sf.get_frame_texture("default", 0).get_height())
		anim.offset = Vector2(0.0, -h / 2.0)
		_add_arm(anim, sprite_id)
		spr = anim
	else:
		var st := Sprite2D.new()
		var t := tex(sprite_id)
		st.texture = t
		h = float(t.get_height())
		st.offset = Vector2(0.0, -h / 2.0)
		spr = st
	spr.name = "Sprite"
	var target_h := Layout.PERSON_HEIGHT
	var native := false
	if Rigs.RIGS.has(sprite_id):
		target_h = float(Rigs.RIGS[sprite_id].get("height", Layout.PERSON_HEIGHT))
		native = bool(Rigs.RIGS[sprite_id].get("native", false))
	# hinh pixel da phong to dung ty le -> giu nguyen kich thuoc (khong co gian)
	var k := 1.0 if native else target_h / h
	spr.scale = Vector2(k, k)
	spr.set_meta("base_scale", k)
	p.add_child(spr)
	p.position = Layout.DOOR
	p.modulate.a = 0.0
	world.add_child(p)
	_walkers[p] = p.position
	create_tween().tween_property(p, "modulate:a", 1.0, 0.4)
	return p


## Gan canh tay roi (neu nhan vat co trong rigs.gd). Tay ve truoc than.
func _add_arm(anim: AnimatedSprite2D, sprite_id: String) -> void:
	if not Rigs.RIGS.has(sprite_id):
		return
	var rig: Dictionary = Rigs.RIGS[sprite_id]
	if not rig.has("arm"):
		return  # tay da ve san trong khung hinh (vd. nhan vat pixel)
	var t := tex_or_null(rig["arm"])
	if t == null:
		return
	var arm := Sprite2D.new()
	arm.name = "Arm"
	arm.texture = t
	arm.centered = false
	arm.offset = -(rig["pivot"] as Vector2)
	var shoulders: Array = rig["shoulders"]
	arm.position = shoulders[int(rig["idle_frame"])]
	anim.add_child(arm)
	anim.set_meta("rig", rig)


func _update_arm(anim: AnimatedSprite2D, walking: bool) -> void:
	if not anim.has_meta("rig"):
		return
	var arm := anim.get_node_or_null("Arm") as Sprite2D
	if arm == null:
		return
	var rig: Dictionary = anim.get_meta("rig")
	var shoulders: Array = rig["shoulders"]
	if walking:
		var f := anim.frame
		var t := (float(f) + anim.frame_progress) / float(shoulders.size())
		arm.position = shoulders[f % shoulders.size()]
		arm.rotation = float(rig["swing"]) * float(rig["phase"]) * cos(TAU * t)
	else:
		arm.position = shoulders[int(rig["idle_frame"])]
		# dung yen: tay ha xuong tu tu, du dua rat nhe
		arm.rotation = lerpf(arm.rotation, sin(_t * 1.6) * 0.03, 0.12)


## Hinh ve mac dinh quay sang phai; di sang trai thi lat nguoc.
func face(p: Node2D, target: Vector2) -> void:
	if not is_instance_valid(p):
		return
	if absf(target.x - p.position.x) > 2.0:
		_set_facing(p, target.x < p.position.x)


func _set_facing(p: Node2D, left: bool) -> void:
	var spr := p.get_node("Sprite") as Node2D
	var k: float = spr.get_meta("base_scale", 1.0)
	spr.scale.x = -k if left else k


func remove_person(p: Node2D) -> void:
	if not is_instance_valid(p):
		_walkers.erase(p)
		return
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(_free_person.bind(p))


func _free_person(p: Node2D) -> void:
	_walkers.erase(p)
	if is_instance_valid(p):
		p.queue_free()


func _process(delta: float) -> void:
	_t += delta
	if rain.visible:
		_move_rain(delta)
	for p in _walkers.keys():
		if not is_instance_valid(p):
			_walkers.erase(p)
			continue
		var node := p as Node2D
		var moved: bool = node.position.distance_to(_walkers[p]) > 0.05
		_walkers[p] = node.position
		var spr := node.get_node("Sprite") as Node2D
		var k: float = spr.get_meta("base_scale", 1.0)
		var anim := spr as AnimatedSprite2D
		if anim != null:
			if moved:
				if anim.animation != "walk":
					anim.play("walk")
				spr.scale.y = k
				_update_arm(anim, true)
			else:
				if anim.animation != "default":
					anim.play("default")
				# dung yen: tho nhe
				spr.scale.y = k * (1.0 + sin(_t * 2.2) * 0.012)
				_update_arm(anim, false)
		else:
			if moved:
				var ph := _t * 9.0
				spr.position.y = -absf(sin(ph)) * 6.0
				spr.rotation = sin(ph) * 0.04
			else:
				spr.position.y = lerpf(spr.position.y, 0.0, 0.2)
				spr.rotation = lerpf(spr.rotation, 0.0, 0.2)


## Cat phan dau + vai tu hinh toan than (dung khi chua co chan dung rieng).
func sprite_portrait(sprite_id: String) -> Texture2D:
	var t := tex_or_null("%s_idle" % sprite_id)  # uu tien hinh ve moi
	if t == null:
		t = tex_or_null(sprite_id)
	if t == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = t
	var w := float(t.get_width())
	at.region = Rect2(0.0, 0.0, w, w * 1.1)
	return at
