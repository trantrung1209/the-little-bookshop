extends RefCounted
## "Khop" cho nhan vat co canh tay roi (thay vi tay ve san trong tung khung hinh).
## Tay duoc code vung theo nhip buoc chan -> mem va deu.
##   arm       : ten file anh canh tay trong assets/art
##   pivot     : diem xoay tren anh canh tay (vai), tinh bang diem anh
##   shoulders : vi tri vai trong tung khung di bo (goc toa do = giua ban chan)
##   idle_frame: khung dung lam tu the dung yen
##   swing     : bien do vung tay (radian, 0.45 ~ 26 do)
##   phase     : 1 hoac -1. Neu thay tay vung cung chieu voi chan (sai), doi dau o day.
##   height    : chieu cao nhan vat tren tranh (diem anh)

const RIGS := {
	"mai": {
		"arm": "mai_arm",
		"pivot": Vector2(22.0, 19.8),
		"shoulders": [Vector2(-15.3, -199.4), Vector2(-14.6, -191.4), Vector2(-13.5, -203.4), Vector2(-14.9, -199.4), Vector2(-15.0, -196.4), Vector2(-15.0, -200.4)],
		"idle_frame": 4,
		"swing": 0.45,
		"phase": 1.0,
		"height": 340.0,
	},
	"ong_tu": {
		"arm": "ong_tu_arm",
		"pivot": Vector2(16.5, 14.8),
		"shoulders": [Vector2(-23.8, -203.2), Vector2(-23.8, -203.8), Vector2(-23.8, -203.8), Vector2(-23.8, -203.8), Vector2(-23.8, -203.8), Vector2(-23.8, -203.8)],
		"idle_frame": 4,
		"swing": 0.45,
		"phase": 1.0,
		"height": 325.0,
	},
	"nam": {
		"arm": "nam_arm",
		"pivot": Vector2(17.5, 15.8),
		"shoulders": [Vector2(-14.3, -201.8), Vector2(-14.3, -203.6), Vector2(-14.3, -201.8), Vector2(-14.3, -203.6)],
		"idle_frame": 1,
		"swing": 0.45,
		"phase": 1.0,
		"height": 330.0,
	},
	"walkin_mother": {
		"arm": "walkin_mother_arm",
		"pivot": Vector2(16.0, 14.4),
		"shoulders": [Vector2(-2.6, -201.2), Vector2(-2.6, -201.8), Vector2(-2.6, -203.7), Vector2(-2.6, -203.1)],
		"idle_frame": 1,
		"swing": 0.45,
		"phase": 1.0,
		"height": 352.0,
	},
	"walkin_young_man": {
		"arm": "walkin_young_man_arm",
		"pivot": Vector2(18.5, 16.7),
		"shoulders": [Vector2(-10.1, -202.4), Vector2(-10.1, -200.1), Vector2(-10.1, -203.5), Vector2(-10.1, -203.0), Vector2(-10.1, -201.2), Vector2(-10.1, -202.4)],
		"idle_frame": 4,
		"swing": 0.45,
		"phase": 1.0,
		"height": 340.0,
	},
	"walkin_husband": {
		"arm": "walkin_husband_arm",
		"pivot": Vector2(18.5, 16.7),
		"shoulders": [Vector2(-7.3, -202.4), Vector2(-7.3, -203.9), Vector2(-7.3, -203.2), Vector2(-7.3, -203.9)],
		"idle_frame": 1,
		"swing": 0.45,
		"phase": 1.0,
		"height": 338.0,
	},
}
