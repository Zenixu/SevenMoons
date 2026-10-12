## UITheme — Palet & helper aksesibilitas UI (Bab 1)
##
## Menyatukan warna, padding, dan radius panel agar seluruh UI/HUD konsisten pada
## resolusi 640x360, dan menerapkan aksesibilitas secara rekursif ke seluruh
## subtree Control:
##   - "Ukuran Huruf"     -> SettingsManager.font_size_multiplier
##   - "Kontras Tinggi"   -> SettingsManager.high_contrast
##
## Aturan: warna TIDAK boleh menjadi satu-satunya pembawa informasi
## (MECHANICS_SPEC §10). Kontras tinggi menambah bingkai/bentuk, bukan hanya warna.
##
## Ukuran dasar tiap huruf disimpan sekali di metadata node (`__ui_base_*`) agar
## penerapan berulang tidak menumpuk (idempoten).
class_name UITheme
extends RefCounted

# --- Palet seragam (indigo dingin, tidak menyilaukan) ---
const BG_PANEL: Color        = Color(0.070, 0.080, 0.110, 0.94)
const BG_PANEL_SOLID: Color  = Color(0.058, 0.068, 0.098, 0.98)
const BG_BACKDROP: Color     = Color(0.020, 0.022, 0.035, 0.78)
const BG_HUD: Color          = Color(0.045, 0.055, 0.080, 0.62)
const BORDER: Color          = Color(0.340, 0.400, 0.520, 0.72)
const BORDER_SOFT: Color     = Color(0.280, 0.330, 0.430, 0.55)
const TEXT: Color            = Color(0.900, 0.920, 0.960, 1.0)
const TEXT_DIM: Color        = Color(0.700, 0.750, 0.850, 0.92)
const TEXT_TITLE: Color      = Color(0.800, 0.880, 1.000, 1.0)
const ACCENT: Color          = Color(0.560, 0.690, 0.930, 1.0)
const ACCENT_SOFT: Color     = Color(0.240, 0.320, 0.470, 1.0)
const WARN: Color            = Color(0.950, 0.760, 0.760, 1.0)

const RADIUS_PANEL: int  = 6
const RADIUS_BUTTON: int = 5
const PAD_X: int = 14
const PAD_Y: int = 12

# --- Kontras tinggi ---
const HC_BG: Color     = Color(0.0, 0.0, 0.0, 1.0)
const HC_TEXT: Color   = Color(1.0, 1.0, 1.0, 1.0)
const HC_BORDER: Color = Color(1.0, 1.0, 1.0, 1.0)
const HC_ACCENT: Color = Color(0.60, 0.85, 1.0, 1.0)

# --- Pilihan "diam" (tombol bertuliskan "...") --------------------------------
# Affordance NON-TEKS: bentuk PIL transparan + ikon "bisu" (pengeras suara
# dicoret) + warna redup. Teks naskah ("...") TIDAK diubah sedikit pun — ini
# murni pembeda visual agar pemain tidak menyangka tombolnya rusak/bug
# (lihat docs/review/VERIFIKASI_KUNCI_TITIK.md).
const SILENCE_TEXT: Color   = Color(0.680, 0.740, 0.860, 0.95)
const SILENCE_BORDER: Color = Color(0.460, 0.520, 0.660, 0.95)
const SILENCE_BG: Color     = Color(0.100, 0.115, 0.155, 0.55)
const SILENCE_ICON_SIZE: int = 16

const _FONT_KEYS: Array[String] = ["font_size", "normal_font_size"]

# ---------------------------------------------------------------------------
# Akses ke SettingsManager (aman dari konteks statis / uji tanpa autoload)
# ---------------------------------------------------------------------------
static func _settings() -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("SettingsManager")
	return null


static func multiplier() -> float:
	var sm: Node = _settings()
	if sm == null:
		return 1.0
	return clampf(float(sm.get("font_size_multiplier")), 0.5, 2.5)


static func high_contrast() -> bool:
	var sm: Node = _settings()
	if sm == null:
		return false
	return bool(sm.get("high_contrast"))


## True bila teks tampil hanya berisi titik-titik (opsi naskah "diam", mis. "...").
## Dipakai untuk memberi affordance visual TANPA mengubah teks naskah.
static func is_silence_text(text: String) -> bool:
	var t: String = text.strip_edges()
	if t.is_empty():
		return false
	for i in t.length():
		var ch: String = t[i]
		if ch != "." and ch != "…" and ch != "·":
			return false
	return true


## Ikon "bisu" (pengeras suara dicoret), digambar vektor — bukan huruf/emoji,
## jadi tidak bergantung pada font. Dipakai sebagai affordance opsi "diam".
class SilenceIcon:
	extends Control

	var glyph_color: Color = Color(0.68, 0.74, 0.86, 0.95)

	func _init(color: Color) -> void:
		glyph_color = color
		custom_minimum_size = Vector2(16, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		if s <= 0.0:
			return
		var lw: float = maxf(1.0, s / 8.0)
		# Badan pengeras suara (kotak kecil).
		var bx: float = s * 0.10
		var by: float = s * 0.36
		var bw: float = s * 0.22
		var bh: float = s * 0.28
		draw_rect(Rect2(bx, by, bw, bh), glyph_color)
		# Corong (segitiga).
		var horn := PackedVector2Array([
			Vector2(bx + bw, by),
			Vector2(s * 0.60, s * 0.16),
			Vector2(s * 0.60, s * 0.84),
			Vector2(bx + bw, by + bh),
		])
		draw_colored_polygon(horn, glyph_color)
		# Garis coret (mute).
		draw_line(Vector2(s * 0.16, s * 0.84), Vector2(s * 0.84, s * 0.16),
			glyph_color, lw * 1.5, true)


## Buat ikon "bisu" berukuran `px` (biasanya ikut skala huruf).
static func make_silence_icon(px: int = SILENCE_ICON_SIZE, color: Color = SILENCE_TEXT) -> Control:
	var ic := SilenceIcon.new(color)
	ic.name = "SilenceIcon"
	ic.custom_minimum_size = Vector2(px, px)
	return ic


# ---------------------------------------------------------------------------
# Gaya (StyleBox) bersama
# ---------------------------------------------------------------------------
## Kotak panel standar (menu, dialog, kotak pikiran).
static func panel_style(solid: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_PANEL_SOLID if solid else BG_PANEL
	sb.border_color = BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(RADIUS_PANEL)
	return sb


## Kotak HUD kecil (jam, "LOOP 2/7", petunjuk) — latar redup agar teks terbaca
## di atas latar terang, tanpa menyilaukan.
static func hud_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_HUD
	sb.border_color = BORDER_SOFT
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb


## Kotak tombol. `kind`: "normal" | "accent" | "honest" | "danger" | "silence".
## `honest` sengaja hanya berbingkai (tanpa isi) — pembeda NON-WARNA untuk
## pilihan "jujur" yang lebih redup (MECHANICS_SPEC §2 & §10).
## `silence` (opsi naskah "...") = bentuk PIL (radius penuh) + bingkai tipis
## + latar transparan redup: pembeda BENTUK NON-WARNA yang jelas berbeda dari
## tombol jawaban lain, sehingga tak tampak seperti tombol rusak.
static func button_style(kind: String = "normal") -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(RADIUS_BUTTON)
	sb.set_border_width_all(1)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	match kind:
		"accent":
			sb.bg_color = ACCENT_SOFT
			sb.border_color = ACCENT
		"honest":
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = BORDER
		"danger":
			sb.bg_color = Color(0.28, 0.10, 0.12, 0.95)
			sb.border_color = WARN
		"silence":
			# Pil (radius penuh) + bingkai tipis + latar transparan redup.
			sb.set_corner_radius_all(16)
			sb.corner_detail = 6
			sb.bg_color = SILENCE_BG
			sb.border_color = SILENCE_BORDER
			sb.draw_center = true
		_:
			sb.bg_color = BG_PANEL_SOLID
			sb.border_color = BORDER
	return sb


static func button_style_hc(kind: String = "normal") -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(RADIUS_BUTTON)
	sb.bg_color = HC_BG if kind != "accent" else Color(0.0, 0.18, 0.34, 1.0)
	sb.border_color = HC_BORDER
	sb.set_border_width_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


# ---------------------------------------------------------------------------
# Ukuran huruf dasar (idempoten)
# ---------------------------------------------------------------------------
## Set ukuran huruf DASAR (belum di-scale) untuk sebuah Control, lalu langsung
## terapkan pengali "Ukuran Huruf" saat ini. Menyimpan dasar di metadata
## `__ui_base_<key>` sehingga pemanggilan `apply()` berulang (mis. saat
## `settings_changed`) TIDAK menumpuk (tidak men-scale dua kali).
##
## WAJIB dipakai oleh UI yang membuat node secara runtime (tombol pilihan, gelembung
## chat, prompt interaksi) — kalau tidak, `apply()` akan menganggap ukuran yang
## sudah di-scale sebagai "dasar" lalu menggandakannya.
static func set_base_font_size(c: Control, base: int, key: String = "font_size") -> void:
	if c == null:
		return
	var b: int = maxi(1, base)
	c.set_meta("__ui_base_" + key, b)
	c.add_theme_font_size_override(key, maxi(1, int(round(float(b) * multiplier()))))


# ---------------------------------------------------------------------------
# Terapkan aksesibilitas ke seluruh subtree
# ---------------------------------------------------------------------------
## Panggil dari `_ready()` tiap UI/HUD. Idempoten: aman dipanggil berkali-kali.
static func apply(root: Node) -> void:
	if root == null:
		return
	_walk(root, multiplier(), high_contrast())


## Hubungkan `SettingsManager.settings_changed` -> `apply(root)`.
## Panggil sekali di `_ready()`. Memakai weakref + auto-disconnect saat node
## keluar dari tree, sehingga tak ada error "capture freed" / koneksi menggantung.
static func bind(root: Node) -> void:
	apply(root)
	var sm: Node = _settings()
	if sm == null or root == null:
		return
	var wr: WeakRef = weakref(root)
	var cb := func() -> void:
		var r: Object = wr.get_ref()
		if r != null and is_instance_valid(r):
			apply(r as Node)
	sm.connect("settings_changed", cb)
	root.tree_exiting.connect(func() -> void:
		if is_instance_valid(sm) and sm.is_connected("settings_changed", cb):
			sm.disconnect("settings_changed", cb)
	)


static func _walk(node: Node, mult: float, hc: bool) -> void:
	if node is Control:
		_apply_node(node as Control, mult, hc)
	for child in node.get_children():
		_walk(child, mult, hc)


static func _apply_node(c: Control, mult: float, hc: bool) -> void:
	# 1) Skala ukuran huruf (simpan dasar sekali).
	for key in _FONT_KEYS:
		if c.has_theme_font_size_override(key):
			var mkey: String = "__ui_base_" + key
			if not c.has_meta(mkey):
				c.set_meta(mkey, c.get_theme_font_size(key))
			var base: int = int(c.get_meta(mkey))
			c.add_theme_font_size_override(key, maxi(1, int(round(float(base) * mult))))

	# 2) Kontras tinggi: warna huruf putih penuh.
	if hc:
		if c is RichTextLabel:
			c.add_theme_color_override("default_color", HC_TEXT)
		elif c is Label or c is Button or c is CheckBox or c is LineEdit:
			c.add_theme_color_override("font_color", HC_TEXT)
			c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))

	# 3) Kontras tinggi: kotak panel yang ditandai `ui_hc` -> hitam + bingkai putih.
	if hc and c.has_meta("ui_hc") and bool(c.get_meta("ui_hc")):
		if c is PanelContainer or c is Panel:
			var sb := StyleBoxFlat.new()
			sb.bg_color = HC_BG
			sb.border_color = HC_BORDER
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(RADIUS_PANEL)
			c.add_theme_stylebox_override("panel", sb)

	# 4) Tombol: gaya konsisten (dan kontras tinggi bila aktif).
	if c is Button:
		_style_button(c as Button, hc)


static func _style_button(btn: Button, hc: bool) -> void:
	var kind: String = str(btn.get_meta("ui_kind", "normal"))
	if hc:
		var sb := button_style_hc(kind)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		var focus := sb.duplicate() as StyleBoxFlat
		focus.border_color = HC_ACCENT
		focus.set_border_width_all(2)
		btn.add_theme_stylebox_override("focus", focus)
	else:
		# Hanya pasang gaya non-kontras untuk tombol yang ditandai `ui_kind`.
		if btn.has_meta("ui_kind"):
			var sb := button_style(kind)
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_stylebox_override("hover", button_style("accent") if kind == "normal" else sb)
			btn.add_theme_stylebox_override("pressed", sb)
