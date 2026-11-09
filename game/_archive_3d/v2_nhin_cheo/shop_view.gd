extends Node2D
## Hien thi tiem sach 2D: anh nen, quay, ke sach cham duoc, khach di lai.
## Hinh lay tu res://assets/art/<ten>.png. Thay anh ve that cung ten file la xong.

const Layout = preload("res://scripts/shop_layout.gd")
const ART := "res://assets/art/"

var world: Node2D
var highlights: Array = []
var _walkers := {}
var _t := 0.0


func _ready() -> void:
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	var bg := Sprite2D.new()
	bg.texture = tex("shop_bg")
	bg.centered = false
	bg.z_index = -10
	world.add_child(bg)
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
	var counter := Sprite2D.new()
	var ct := tex("counter")
	counter.texture = ct
	counter.offset = Vector2(0.0, -ct.get_height() / 2.0)
	counter.position = Vector2(Layout.COUNTER_RECT.get_center().x, Layout.COUNTER_RECT.end.y)
	world.add_child(counter)
	get_viewport().size_changed.connect(_fit)
	_fit()


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


func spawn_person(sprite_id: String) -> Node2D:
	var p := Node2D.new()
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	var t := tex(sprite_id)
	spr.texture = t
	spr.offset = Vector2(0.0, -t.get_height() / 2.0)
	p.add_child(spr)
	p.position = Layout.DOOR
	p.modulate.a = 0.0
	world.add_child(p)
	_walkers[p] = p.position
	_apply_depth(p)
	create_tween().tween_property(p, "modulate:a", 1.0, 0.4)
	return p


## Cang xa (gan tuong) cang nho, cang gan quay cang lon -> co chieu sau.
func _apply_depth(p: Node2D) -> void:
	var k := clampf((p.position.y - Layout.DEPTH_FAR_Y) / (Layout.DEPTH_NEAR_Y - Layout.DEPTH_FAR_Y), 0.0, 1.0)
	var sc := lerpf(Layout.DEPTH_FAR_SCALE, Layout.DEPTH_NEAR_SCALE, k)
	p.scale = Vector2(sc, sc)


func face(p: Node2D, target: Vector2) -> void:
	if not is_instance_valid(p):
		return
	var spr := p.get_node("Sprite") as Sprite2D
	if absf(target.x - p.position.x) > 2.0:
		spr.flip_h = target.x < p.position.x  # hinh ve mac dinh quay sang phai


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
	for p in _walkers.keys():
		if not is_instance_valid(p):
			_walkers.erase(p)
			continue
		var node := p as Node2D
		var moved: bool = node.position.distance_to(_walkers[p]) > 0.1
		_walkers[p] = node.position
		_apply_depth(node)
		var spr := node.get_node("Sprite") as Sprite2D
		if moved:
			# buoc chan: nhun nhe + lac lu trai phai, nhu nhan vat game cozy
			var ph := _t * 9.0
			spr.position.y = -absf(sin(ph)) * 6.0
			spr.rotation = sin(ph) * 0.04
		else:
			spr.position.y = lerpf(spr.position.y, 0.0, 0.2)
			spr.rotation = lerpf(spr.rotation, 0.0, 0.2)


## Cat phan dau + vai tu hinh toan than (dung khi chua co chan dung rieng).
func sprite_portrait(sprite_id: String) -> Texture2D:
	var t := tex_or_null(sprite_id)
	if t == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = t
	var w := float(t.get_width())
	at.region = Rect2(0.0, 0.0, w, w * 1.1)
	return at
