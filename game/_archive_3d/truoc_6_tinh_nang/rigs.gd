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
##   native    : true = hinh pixel da phong to dung 5 lan, giu nguyen kich thuoc

const RIGS := {
	# Chi Mai ban PIXEL ART: tay da co san trong 8 khung di bo cua PixelLab.
	"mai": {
		"native": true,
	},
	"ong_tu": {
		"native": true,
	},
	"nam": {
		"native": true,
	},
	"walkin_mother": {
		"native": true,
	},
	"walkin_young_man": {
		"native": true,
	},
	"walkin_husband": {
		"native": true,
	},
}
