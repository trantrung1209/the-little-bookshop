extends RefCounted
## Toa do trong anh nen shop_bg.png (1920 x 1080) - phong cach nhin ngang (8/11).
## Tat ca nhan vat di tren MOT duong san duy nhat (FLOOR_Y), chi qua trai / qua phai.
## Khi thay tranh khac: chi can chinh cac so o day cho khop voi tranh.

const ART_SIZE := Vector2(1920, 1080)
const FLOOR_Y := 905.0                      # duong chan nhan vat (hang gach phia tren)
const DOOR := Vector2(1715, FLOOR_Y)        # cua sat ben phai: khach vao / ra
const COUNTER_STAND := Vector2(545, FLOOR_Y)  # dung canh quay thu ngan ben trai
const PERSON_HEIGHT := 340.0                # chieu cao nhan vat tren tranh
const WALK_SPEED := 150.0                   # diem anh moi giay - khop voi buoc chan
const WALK_FPS := 8.0                       # so khung hinh di bo moi giay
const SHELVES := [
	{"label": "Kệ Tiểu thuyết", "rect": Rect2(472, 310, 348, 544), "stand": Vector2(646, FLOOR_Y)},
	{"label": "Kệ Trinh thám", "rect": Rect2(823, 310, 346, 544), "stand": Vector2(996, FLOOR_Y)},
	{"label": "Kệ Lịch sử", "rect": Rect2(1176, 310, 345, 544), "stand": Vector2(1348, FLOOR_Y)},
]
