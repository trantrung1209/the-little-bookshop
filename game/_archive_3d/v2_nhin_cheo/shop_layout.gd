extends RefCounted
## Toa do trong anh nen shop_bg.png (1920 x 1080).
## Khop voi tranh nen ve tay ban dau tien (7/11).
## Khi thay tranh khac: chi can chinh cac so o day cho khop voi tranh.

const ART_SIZE := Vector2(1920, 1080)
const DOOR := Vector2(1535, 760)            # khach xuat hien / ra ve (truoc cua go ben phai)
const COUNTER_STAND := Vector2(720, 1000)   # cho khach dung sau quay (chan bi quay che)
const COUNTER_RECT := Rect2(330, 783, 780, 277)  # vi tri anh counter.png (780 x 277)
const WALK_SPEED := 240.0                   # diem anh moi giay (di thong tha)
const DEPTH_FAR_Y := 720.0                  # sat chan tuong
const DEPTH_NEAR_Y := 1000.0                # sat quay
const DEPTH_FAR_SCALE := 0.82               # nho hon khi o xa
const DEPTH_NEAR_SCALE := 1.05              # lon hon khi o gan
const DOOR_STEP := Vector2(1470, 830)       # buoc vao tiem truoc khi re di
const SHELVES := [
	{"label": "Kệ Tiểu thuyết", "rect": Rect2(342, 155, 342, 569), "stand": Vector2(513, 790)},
	{"label": "Kệ Trinh thám", "rect": Rect2(693, 155, 347, 569), "stand": Vector2(866, 790)},
	{"label": "Kệ Lịch sử", "rect": Rect2(1046, 155, 335, 569), "stand": Vector2(1213, 790)},
]
