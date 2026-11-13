extends RefCounted
## Du lieu noi dung: sach tu bia, khach vang lai, NPC co cot truyen.
## Sua noi dung o day, khong can dung vao main.gd.
##
## Moi sach co 3 "the chu de". Moi luot khach co "want" (muon) va "avoid" (tranh).
## Diem = so the trung want - 2 x so the trung avoid.
## >= 2: trung y  |  1: tam duoc  |  <= 0: chua hop
##
## NPC co "visits": moi phan tu la mot lan ghe tiem. Tu van TRUNG Y thi
## mo 1 trang so ("page") va lan sau NPC ke tiep chuyen. Chua trung y thi
## lan sau NPC quay lai voi cung yeu cau.

const BOOKS := [
	{"title": "Mùa Thu Cuối Cùng", "genre": "Tiểu thuyết", "tags": ["hồi ức", "tình yêu", "bi kịch"]},
	{"title": "Ngôi Nhà Có Cửa Sổ Xanh", "genre": "Tiểu thuyết", "tags": ["chữa lành", "gia đình", "hy vọng"]},
	{"title": "Bức Thư Không Người Gửi", "genre": "Trinh thám", "tags": ["bí ẩn", "hồi ức", "cô đơn"]},
	{"title": "Vụ Án Ở Ga Cuối", "genre": "Trinh thám", "tags": ["bí ẩn", "phiêu lưu", "kinh dị"]},
	{"title": "Biên Niên Thị Trấn Cũ", "genre": "Lịch sử", "tags": ["lịch sử", "hồi ức", "gia đình"]},
	{"title": "Những Con Tàu Vượt Biển", "genre": "Lịch sử", "tags": ["lịch sử", "phiêu lưu", "can đảm"]},
	{"title": "Chú Gấu Không Chịu Ngủ", "genre": "Thiếu nhi", "tags": ["thiếu nhi", "gia đình", "hài hước"]},
	{"title": "Hẹn Em Dưới Mưa", "genre": "Tiểu thuyết", "tags": ["tình yêu", "hy vọng", "hài hước"]},
	{"title": "Một Mình Lên Núi", "genre": "Tiểu thuyết", "tags": ["can đảm", "chữa lành", "phiêu lưu"]},
	{"title": "Cười Lên Nào, Ông Bảy", "genre": "Tiểu thuyết", "tags": ["hài hước", "hy vọng", "gia đình"]},
	{"title": "Hạt Giống Trên Ban Công", "genre": "Tiểu thuyết", "tags": ["can đảm", "hy vọng", "chữa lành"]},
	{"title": "Hai Ông Già Và Bàn Cờ", "genre": "Tiểu thuyết", "tags": ["tình bạn", "hồi ức", "hài hước"]},
	{"title": "Thư Gửi Mùa Hạ", "genre": "Tiểu thuyết", "tags": ["tình bạn", "tình yêu", "hồi ức"]},
	{"title": "Khu Vườn Của Bà", "genre": "Thiếu nhi", "tags": ["thiếu nhi", "chữa lành", "gia đình"]},
]

const CUSTOMERS := [
	{
		"name": "Chị Mai",
		"sprite": "mai",
		"color": "e67e22",
		"hair": "2b1d16",
		"hint": "Sổ của ông: Mai thích chuyện đời thường, sợ những cái kết buồn.",
		"visits": [
			{
				"lines": ["Chào bạn... tiệm mở cửa lại rồi à?", "Mình là Mai, làm văn phòng ở gần đây."],
				"request": "Dạo này mình thấy mọi thứ thật khó khăn. Có cuốn nào giúp mình nhẹ lòng hơn không?",
				"want": ["chữa lành", "hy vọng"],
				"avoid": ["bi kịch"],
				"great": "Đúng thứ mình cần... Tối nay mình đọc liền.",
				"ok": "Cũng hay đấy, chắc mình sẽ thử xem.",
				"miss": "Ừm... chắc để khi khác mình đọc vậy.",
				"page": "Ông ghi: Bé Mai hay ghé sau giờ học, ngồi đọc ké ở góc ghế mây. Con bé mơ mở một tiệm hoa.",
			},
			{
				"lines": ["Lại là mình đây!", "Cuốn hôm trước làm mình khóc, nhưng là khóc nhẹ nhõm."],
				"request": "Giờ mình muốn đọc gì đó vui vui, để cười một trận.",
				"want": ["hài hước", "hy vọng"],
				"avoid": ["bi kịch", "kinh dị"],
				"great": "Haha, mới đọc trang đầu đã buồn cười rồi. Cảm ơn bạn!",
				"ok": "Chắc cũng vui, để mình xem.",
				"miss": "Cuốn này... không vui lắm nhỉ.",
				"page": "Ông ghi: Mai bảo lớn lên sẽ mở tiệm hoa cạnh tiệm sách, 'để ông có hoa cắm bàn'. Ông đặt sẵn một chiếc bình trống trên quầy.",
			},
			{
				"lines": ["Bạn ơi, mình quyết định rồi.", "Mình sẽ nghỉ việc văn phòng... và mở một tiệm hoa nhỏ."],
				"request": "Có cuốn nào cho người sắp làm một việc can đảm không?",
				"want": ["can đảm", "hy vọng"],
				"avoid": ["bi kịch"],
				"great": "Cảm ơn bạn. Mai mốt tiệm hoa mở, chiếc bình trên quầy này để mình lo nhé.",
				"ok": "Chắc nó sẽ giúp mình phần nào.",
				"miss": "Hừm, chưa phải cuốn mình cần. Để lần sau.",
				"page": "Ông ghi: Nếu một ngày Mai quay lại, hãy chỉ cho con bé chiếc bình trên quầy. Ông vẫn giữ nó.",
			},
		],
	},
	{
		"name": "Một người mẹ",
		"sprite": "walkin_mother",
		"color": "16a085",
		"hat": "non_la",
		"hair": "1f1a17",
		"hint": "",
		"request": "Tôi tìm sách để đọc cùng con gái bảy tuổi trước giờ ngủ.",
		"want": ["thiếu nhi", "gia đình"],
		"avoid": ["kinh dị", "bi kịch"],
		"great": "Con bé chắc chắn sẽ thích! Tối nay hai mẹ con đọc liền.",
		"ok": "Được đấy, chắc bé nghe được.",
		"miss": "Cuốn này... hơi không hợp với bé nhà tôi.",
	},
	{
		"name": "Ông Tư",
		"sprite": "ong_tu",
		"color": "7f8c8d",
		"hair": "d9d4cc",
		"hint": "Sổ của ông: ông Tư – bạn đánh cờ của ông. Mê sử, hay kể chuyện ngày xưa.",
		"visits": [
			{
				"lines": ["Cháu là cháu nội ông chủ cũ đấy à? Giống ông lắm.", "Tôi là Tư. Ngày trước chiều nào tôi cũng sang đánh cờ với ông cháu."],
				"request": "Tôi muốn đọc lại thứ gì gợi nhớ những ngày thị trấn này còn đông vui.",
				"want": ["hồi ức", "lịch sử"],
				"avoid": [],
				"great": "Ha, ngày xưa ông cháu cũng giới thiệu tôi cuốn kiểu này. Cảm ơn cháu.",
				"ok": "Không tệ. Tôi sẽ đọc thử.",
				"miss": "Hừm, không phải thứ tôi tìm, nhưng thôi cứ lấy.",
				"page": "Ông ghi: Tư thua cờ thì mua sách, thắng cờ cũng mua sách. Lão bảo đó là 'thuế bàn cờ'.",
			},
			{
				"lines": ["Hôm qua tôi dọn nhà, tìm thấy bàn cờ cũ.", "Thiếu mất đúng một quân Tướng. Lạ thật."],
				"request": "Có cuốn nào ly kỳ một chút, đọc cho đỡ nhớ bạn già không cháu?",
				"want": ["bí ẩn", "hồi ức"],
				"avoid": ["kinh dị"],
				"great": "Đúng kiểu tôi thích. Đọc xong tôi kể cháu nghe.",
				"ok": "Ừ, để tôi đọc xem.",
				"miss": "Cuốn này không hợp với ông già này lắm.",
				"page": "Ông ghi: Hôm nay Tư thua, giận bỏ về. Ông cất quân Tướng của lão vào ngăn kéo quầy – để lão phải quay lại.",
			},
			{
				"lines": ["Cháu này... ông cháu có để lại gì trong ngăn kéo quầy không?", "À, thôi. Chắc tôi nhớ nhầm."],
				"request": "Cho tôi một cuốn về những người bạn lâu năm.",
				"want": ["tình bạn", "hồi ức"],
				"avoid": [],
				"great": "...Quân Tướng đây rồi! Lão già giữ nó suốt mười năm. Cảm ơn cháu.",
				"ok": "Cũng được. Cảm ơn cháu.",
				"miss": "Thôi, để hôm khác tôi tìm.",
				"page": "Trang mới: Đã trả quân Tướng cho ông Tư. Ông hứa chiều thứ Bảy sang dạy cháu đánh cờ.",
			},
		],
	},
	{
		"name": "Cô Liên",
		"sprite": "co_lien",
		"hint": "Sổ của ông: cô Liên – cô giáo dạy văn trường đầu phố, mê thơ, thích chuyện có hậu.",
		"visits": [
			{
				"lines": ["Chào cháu. Cô là Liên, ngày trước dạy văn ở trường cấp hai đầu phố.", "Lâu lắm rồi cô mới bước vào tiệm này."],
				"request": "Cháu tìm giúp cô một cuốn đọc cho thư thái, kiểu chuyện ngày xưa ấy.",
				"want": ["hồi ức", "chữa lành"],
				"avoid": ["kinh dị"],
				"great": "Đúng giọng văn cô thích. Như được về lại lớp học cũ.",
				"ok": "Cũng được, để cô đọc thử.",
				"miss": "Cuốn này... không hợp với bà già này lắm.",
				"page": "Ông ghi: Cô Liên năm nào cũng mua sách tặng học trò nghèo. Có năm hết tiền, cô bán lại cho ông tập thơ chép tay bìa xanh của mình.",
			},
			{
				"lines": ["Cô có chuyện này muốn hỏi.", "Hồi trước cô có bán cho ông cháu một tập thơ chép tay, bìa xanh. Cô tiếc mãi."],
				"request": "Trong lúc chờ, cháu tìm cho cô cuốn nào về gia đình, đọc cho ấm lòng.",
				"want": ["gia đình", "hy vọng"],
				"avoid": ["bi kịch"],
				"great": "Ấm lòng thật. Cảm ơn cháu.",
				"ok": "Ừ, cô cảm ơn.",
				"miss": "Buồn quá cháu ạ, thôi để hôm khác.",
				"page": "Ông ghi: Tập thơ bìa xanh của cô Liên, ông không bán cho ai. Cất dưới đáy kệ lịch sử, chờ ngày cô quay lại.",
			},
			{
				"lines": ["Cháu ơi... cô nghe nói dưới đáy kệ lịch sử có một tập thơ bìa xanh?", "Ông cháu giữ nó suốt bao năm..."],
				"request": "Hôm nay cô muốn một cuốn về tình bạn, về những người giữ lời hứa.",
				"want": ["tình bạn", "hồi ức"],
				"avoid": [],
				"great": "Tập thơ của cô đây rồi... Ông cháu giữ lời thật. Cô sẽ đọc lại cho lũ học trò cũ nghe.",
				"ok": "Cảm ơn cháu, cô đọc thử.",
				"miss": "Thôi, để lần sau cô tìm.",
				"page": "Trang mới: Đã trả tập thơ bìa xanh cho cô Liên. Cô hứa mỗi tháng ghé đọc thơ cho trẻ con trong phố.",
			},
		],
	},
	{
		"name": "Một chàng trai",
		"sprite": "walkin_young_man",
		"color": "2980b9",
		"hint": "",
		"request": "Tuần sau tôi đi xa một mình lần đầu. Thật ra... hơi sợ.",
		"want": ["can đảm", "phiêu lưu"],
		"avoid": ["kinh dị"],
		"great": "Đọc xong chắc tôi bớt run hẳn. Cảm ơn nhé!",
		"ok": "Chắc sẽ giúp được chút ít.",
		"miss": "Ừ... cảm ơn, nhưng chắc không hợp lắm.",
	},
	{
		"name": "Nam",
		"sprite": "nam",
		"color": "8e44ad",
		"hair": "5a3a22",
		"hint": "Sổ của ông: Nam – cậu sinh viên mê truyện bí ẩn, mơ làm nhà văn.",
		"visits": [
			{
				"lines": ["Chào chủ tiệm! Em là Nam, sinh viên năm hai.", "Em đang viết truyện, mà bí quá."],
				"request": "Có cuốn nào thật ly kỳ cho em lấy cảm hứng không ạ?",
				"want": ["bí ẩn", "phiêu lưu"],
				"avoid": [],
				"great": "Trời ơi, đọc vài trang đầu là có ý tưởng liền! Em cảm ơn!",
				"ok": "Cũng được ạ, để em đọc xem.",
				"miss": "Hơi... nhẹ nhàng quá so với em ạ.",
				"page": "Ông ghi: Có cậu bé hay ngồi bệt dưới kệ trinh thám, viết vào vở. Ông giả vờ không thấy cậu đọc chùa.",
			},
			{
				"lines": ["Em viết xong chương một rồi!", "Mà... em sợ đưa ai đọc. Lỡ dở thì sao."],
				"request": "Có cuốn nào về người dám làm điều mình sợ không ạ?",
				"want": ["can đảm", "phiêu lưu"],
				"avoid": ["kinh dị"],
				"great": "Được rồi, em sẽ đưa chương một cho bạn em đọc. Hồi hộp quá!",
				"ok": "Chắc em sẽ đọc thử.",
				"miss": "Chưa đúng cái em cần lắm ạ.",
				"page": "Ông ghi: Cậu bé ấy để quên cuốn vở. Ông đọc trộm một trang – viết hay lắm. Ông kẹp vào đó mẩu giấy: 'Viết tiếp đi.'",
			},
			{
				"lines": ["Chủ tiệm biết không, hồi nhỏ em để quên vở ở đây...", "Trong vở có mẩu giấy ghi 'Viết tiếp đi'. Nhờ nó mà em viết đến giờ."],
				"request": "Em muốn đọc một cuốn thật ấm áp, để viết cái kết cho truyện của mình.",
				"want": ["hy vọng", "gia đình"],
				"avoid": ["bi kịch"],
				"great": "Em sẽ đề tặng truyện đầu tay cho ông chủ tiệm cũ.",
				"ok": "Cảm ơn chủ tiệm, em đọc thử.",
				"miss": "Cái kết của em chắc không buồn vậy đâu ạ.",
				"page": "Trang mới: Nam chính là cậu bé dưới kệ trinh thám năm nào. Mẩu giấy của ông vẫn nằm trong vở cậu.",
			},
		],
	},
	{
		"name": "Bé Thỏ",
		"sprite": "be_tho",
		"hint": "Sổ của ông: Hằng – con bé nhà bán xôi đầu ngõ, mê truyện tranh, sợ tối.",
		"visits": [
			{
				"lines": ["Con chào ạ! Con là Thỏ, con bảy tuổi rồi.", "Mẹ con bán xôi ngoài đầu ngõ, mẹ cho con vào xem sách."],
				"request": "Ở đây có sách nào vui vui, có con vật không ạ?",
				"want": ["thiếu nhi", "hài hước"],
				"avoid": ["kinh dị", "bi kịch"],
				"great": "Hihi, buồn cười quá! Con cảm ơn ạ!",
				"ok": "Dạ... con xem thử.",
				"miss": "Sách này... không có hình con vật ạ.",
				"page": "Ông ghi: Cái Hằng nhà bán xôi đầu ngõ hay sang xin xem truyện tranh. Con bé sợ tối, ông để đèn bàn sáng cho nó đọc.",
			},
			{
				"lines": ["Tối qua mất điện, con sợ lắm.", "Mẹ phải đọc truyện cho con nghe con mới ngủ được."],
				"request": "Có truyện nào về bạn nhỏ dũng cảm không ạ? Con muốn hết sợ tối.",
				"want": ["can đảm", "thiếu nhi"],
				"avoid": ["kinh dị"],
				"great": "Bạn nhỏ trong truyện không sợ tối! Con cũng sẽ không sợ nữa!",
				"ok": "Dạ, con cảm ơn.",
				"miss": "Truyện này... con hơi sợ ạ.",
				"page": "Ông ghi: Hằng lớn rồi, hết sợ tối. Nó bảo nhờ cuốn truyện ông tặng năm nó lên bảy. Ông vẫn giữ một cuốn giống hệt trong ngăn kéo.",
			},
			{
				"lines": ["Mẹ con kể hồi bé mẹ cũng được ông chủ tiệm tặng sách.", "Mẹ con tên là Hằng đấy ạ!"],
				"request": "Con muốn một cuốn thật vui, để tối đọc cùng mẹ ạ.",
				"want": ["gia đình", "hài hước"],
				"avoid": ["bi kịch"],
				"great": "Con sẽ chạy ra khoe mẹ ngay! Con cảm ơn ạ!",
				"ok": "Dạ, con cảm ơn.",
				"miss": "Mẹ con chắc không thích cuốn này đâu ạ.",
				"page": "Trang mới: Bé Thỏ là con của Hằng. Mẹ con bé nhận ra chiếc ngăn kéo ông vẫn để cuốn truyện ngày xưa, và đã khóc.",
			},
		],
	},
	{
		"name": "Một ông chồng",
		"sprite": "walkin_husband",
		"color": "c0392b",
		"hint": "",
		"request": "Vợ tôi thích chuyện tình, nhưng ghét nhất là kết buồn.",
		"want": ["tình yêu", "hy vọng"],
		"avoid": ["bi kịch"],
		"great": "Tuyệt! Lần này chắc chắn bà ấy vui.",
		"ok": "Hy vọng bà ấy thích.",
		"miss": "Kết buồn thì tôi tiêu mất...",
	},
	{
		"name": "Chú Đức",
		"sprite": "chu_duc",
		"hint": "Sổ của ông: Đức – thợ sửa xe đầu hẻm, ít nói, ngại chữ nghĩa.",
		"visits": [
			{
				"lines": ["...Chào. Tôi là Đức, sửa xe đạp ở đầu hẻm.", "Tôi ít đọc sách lắm. Chữ nghĩa với tôi khó."],
				"request": "Có cuốn nào dễ đọc, vui vui không? Đọc cho đỡ buồn ngủ lúc vắng khách.",
				"want": ["hài hước", "phiêu lưu"],
				"avoid": ["lịch sử", "bi kịch"],
				"great": "Ha, đọc được! Cuốn này dễ hiểu thật.",
				"ok": "Để tôi thử...",
				"miss": "Chữ nhiều quá, tôi chịu.",
				"page": "Ông ghi: Thằng Đức hồi nhỏ hay đứng nép ngoài cửa nhìn vào kệ sách. Hỏi thì nó bảo nó không biết đọc.",
			},
			{
				"lines": ["Tôi đọc xong rồi đấy. Mất ba tuần, nhưng xong.", "Thằng con tôi bảo bố giỏi."],
				"request": "Giờ tôi muốn đọc chuyện về người dám làm việc khó. Đọc cho có động lực.",
				"want": ["can đảm", "hy vọng"],
				"avoid": ["kinh dị"],
				"great": "Cuốn này hay. Tôi sẽ đọc to cho thằng con nghe.",
				"ok": "Ừ, để tôi đọc dần.",
				"miss": "Cuốn này... không hợp với tôi lắm.",
				"page": "Ông ghi: Tối nào Đức cũng ra ngồi bậc tiệm. Ông dạy nó đánh vần, đổi lại nó sửa xe đạp không lấy tiền.",
			},
			{
				"lines": ["Ông chủ tiệm cũ là người dạy tôi đọc chữ đấy.", "Giờ tôi muốn đọc cho đàng hoàng một cuốn sách dày."],
				"request": "Cho tôi một cuốn về chuyện xưa, chuyện có thật. Dày cũng được.",
				"want": ["lịch sử", "hồi ức"],
				"avoid": [],
				"great": "Dày thật... nhưng giờ tôi đọc được rồi. Cảm ơn ông. Cảm ơn tiệm.",
				"ok": "Được, tôi sẽ đọc.",
				"miss": "Chưa phải cuốn tôi muốn.",
				"page": "Trang mới: Chú Đức đã đọc xong cuốn sách dày đầu tiên. Chú treo tấm bảng ở tiệm xe: 'Ai muốn học chữ, cứ hỏi.'",
			},
		],
	},
]

## Sua sang tiem. kind "clean" = don dep (phai xong het 3 viec don dep moi trang tri duoc).
## Tac dung: "charm" = suc hut (khach toi nhanh hon), "tip" = them tien moi luot tu van,
## "close" = gio dong cua (tinh bang phut: 1080 = 18:00).
## "pos" = diem giua-day cua hinh trong khong gian anh nen 1920x1080.
const UPGRADES := [
	{"id": "webs", "kind": "clean", "name": "Quét mạng nhện", "desc": "Khách bớt ngại bước vào.", "price": 15, "charm": 1},
	{"id": "dust", "kind": "clean", "name": "Lau bụi kệ sách", "desc": "Sách sạch sẽ, khách tới đông hơn.", "price": 25, "charm": 1},
	{"id": "bulb", "kind": "clean", "name": "Thay bóng đèn, lau kính", "desc": "Tiệm sáng sủa, khách tới đông hơn.", "price": 35, "charm": 1},
	{"id": "sign", "kind": "decor", "name": "Bảng phấn trước cửa", "desc": "Người qua đường ghé vào nhiều hơn.", "price": 60, "charm": 1, "sprite": "decor_sign", "pos": Vector2(1530, 958)},
	{"id": "plant", "kind": "decor", "name": "Chậu trầu bà", "desc": "Góc tiệm xanh mát, khách tới nhanh hơn.", "price": 80, "charm": 1, "sprite": "decor_plant", "pos": Vector2(445, 958)},
	{"id": "mat", "kind": "decor", "name": "Chiếu cói trước kệ", "desc": "Khách nán lại lâu hơn: +2 tiền mỗi lượt.", "price": 100, "tip": 2, "sprite": "decor_mat", "pos": Vector2(945, 1050)},
	{"id": "radio", "kind": "decor", "name": "Đài cát-sét", "desc": "Nhạc xưa làm khách vui: +3 tiền mỗi lượt.", "price": 120, "tip": 3, "sprite": "decor_radio", "pos": Vector2(578, 708)},
	{"id": "lanterns", "kind": "decor", "name": "Dây đèn lồng", "desc": "Tiệm mở cửa tới 18:00.", "price": 150, "close": 1080, "sprite": "decor_lanterns", "pos": Vector2(1690, 250)},
]

## Sach hiem: chi co khi mua tu nguoi ban sach cu (chu Ba ve chai).
const RARE_BOOKS := [
	{"title": "Gánh Hàng Rong Phố Cũ", "genre": "Tiểu thuyết", "tags": ["hồi ức", "gia đình", "hy vọng"]},
	{"title": "Bóng Đèn Dầu", "genre": "Tiểu thuyết", "tags": ["hồi ức", "cô đơn", "chữa lành"]},
	{"title": "Mật Mã Trên Tờ Lịch", "genre": "Trinh thám", "tags": ["bí ẩn", "lịch sử", "phiêu lưu"]},
	{"title": "Tiếng Gõ Cửa Lúc Nửa Đêm", "genre": "Trinh thám", "tags": ["kinh dị", "bí ẩn", "cô đơn"]},
	{"title": "Bến Cảng Năm Ấy", "genre": "Lịch sử", "tags": ["lịch sử", "can đảm", "hồi ức"]},
	{"title": "Phố Nghề Xưa", "genre": "Lịch sử", "tags": ["lịch sử", "gia đình", "tình bạn"]},
	{"title": "Con Diều Giấy Màu Đỏ", "genre": "Thiếu nhi", "tags": ["thiếu nhi", "tình bạn", "hy vọng"]},
	{"title": "Cậu Bé Bán Kem", "genre": "Thiếu nhi", "tags": ["thiếu nhi", "hài hước", "can đảm"]},
	{"title": "Thư Tình Không Gửi", "genre": "Tiểu thuyết", "tags": ["tình yêu", "bi kịch", "hồi ức"]},
	{"title": "Đôi Bạn Trên Chuyến Tàu Đêm", "genre": "Tiểu thuyết", "tags": ["tình bạn", "phiêu lưu", "hài hước"]},
]
const RARE_PRICE := 20      # gia mot cuon sach hiem (duoc 2 cuon, mo khoa de nhap tiep)

## Doc vi khach: cach khach noi ve tung chu de khi duoc hoi.
const TAG_LIKE := {
	"hồi ức": "gợi nhớ chuyện ngày xưa", "tình yêu": "có chút chuyện tình", "bi kịch": "day dứt, đọc xong còn nghĩ mãi",
	"chữa lành": "đọc xong thấy nhẹ lòng", "gia đình": "về người thân trong nhà", "hy vọng": "có cái kết tươi sáng",
	"bí ẩn": "có bí mật cần khám phá", "cô đơn": "về những người lặng lẽ một mình", "phiêu lưu": "được đi đây đi đó",
	"kinh dị": "rùng rợn một chút", "lịch sử": "về chuyện xưa có thật", "can đảm": "về người dám làm điều khó",
	"thiếu nhi": "dành cho trẻ con", "hài hước": "đọc là bật cười", "tình bạn": "về những người bạn",
}
const TAG_AVOID := {
	"hồi ức": "toàn chuyện cũ buồn buồn", "tình yêu": "yêu đương sướt mướt", "bi kịch": "kết buồn",
	"chữa lành": "triết lý nhẹ nhàng", "gia đình": "chuyện gia đình", "hy vọng": "quá màu hồng",
	"bí ẩn": "đánh đố khó hiểu", "cô đơn": "u ám cô đơn", "phiêu lưu": "đi xa mạo hiểm",
	"kinh dị": "ma quỷ rùng rợn", "lịch sử": "khô khan sách sử", "can đảm": "gồng mình quá sức",
	"thiếu nhi": "con nít quá", "hài hước": "cợt nhả", "tình bạn": "chuyện bạn bè",
}

## Lich tuan: ngay 1 la Thu Hai.
const WEEKDAYS := ["Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật"]
const WEEKDAYS_SHORT := ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
const WEEK_EVENTS := {
	2: "Ngày giao sách: nhập sách chỉ 6 tiền một cuốn.",
	5: "Cuối tuần: khách ghé đông hơn.",
	6: "Chợ sách cũ: chú Ba ve chai ghé tiệm bán sách hiếm.",
}
const WEATHER_NAMES := {"sun": "Nắng", "cloud": "Nhiều mây", "rain": "Mưa"}

## Danh hieu (thu thap). Moi danh hieu dat duoc thuong 10 tien.
const ACHIEVEMENTS := [
	{"id": "first", "name": "Mở hàng", "desc": "Bán cuốn sách đầu tiên."},
	{"id": "hits10", "name": "Người hiểu khách", "desc": "Tư vấn trúng ý 10 lần."},
	{"id": "sold30", "name": "Tiệm đắt hàng", "desc": "Bán 30 cuốn sách."},
	{"id": "genres", "name": "Đủ mọi thể loại", "desc": "Bán được cả 4 thể loại sách."},
	{"id": "mystery10", "name": "Mê trinh thám", "desc": "Bán 10 cuốn trinh thám."},
	{"id": "noask5", "name": "Mắt tinh", "desc": "Đoán trúng ý 5 lần mà không cần hỏi."},
	{"id": "rare5", "name": "Nhà sưu tầm", "desc": "Sưu tầm 5 cuốn sách hiếm."},
	{"id": "clean", "name": "Sạch như mới", "desc": "Dọn dẹp xong tiệm."},
	{"id": "decor", "name": "Tiệm khang trang", "desc": "Mua đủ đồ trang trí."},
	{"id": "week", "name": "Tròn một tuần", "desc": "Mở tiệm đủ 7 ngày."},
	{"id": "pages", "name": "Đọc hết sổ của ông", "desc": "Mở hết các trang sổ."},
]
const ACHIEVEMENT_REWARD := 10
