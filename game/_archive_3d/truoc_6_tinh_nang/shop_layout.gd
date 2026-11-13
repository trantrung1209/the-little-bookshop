extends RefCounted
## Toa do trong anh nen shop_bg.png (1920 x 1080) - phong cach PIXEL ART nhin ngang (9/11).
## Nen goc 384 x 216 diem anh, phong to dung 5 lan -> moi "o pixel" = 5 diem tren tranh.
## Tat ca nhan vat di tren MOT duong san duy nhat (FLOOR_Y), chi qua trai / qua phai.

const ART_SIZE := Vector2(1920, 1080)
const PIXEL_SCALE := 5                      # 1 o pixel = 5 diem anh tren tranh
const FLOOR_Y := 949.0                      # duong chan nhan vat (mep tren hang gach bong)
const DOOR := Vector2(1600, FLOOR_Y)        # cua kinh + cua sat ben phai
const COUNTER_STAND := Vector2(585, FLOOR_Y)  # dung canh quay thu ngan ben trai
const PERSON_HEIGHT := 300.0                # chieu cao nhan vat (hinh cu, chua pixel)
const WALK_SPEED := 150.0                   # diem anh moi giay - khop voi buoc chan
const WALK_FPS := 10.0                      # so khung hinh di bo moi giay
const SHELVES := [
	{"label": "Kệ Tiểu thuyết", "rect": Rect2(474, 296, 314, 625), "stand": Vector2(631, FLOOR_Y)},
	{"label": "Kệ Trinh thám", "rect": Rect2(793, 296, 319, 625), "stand": Vector2(952, FLOOR_Y)},
	{"label": "Kệ Lịch sử", "rect": Rect2(1120, 296, 303, 625), "stand": Vector2(1271, FLOOR_Y)},
]
