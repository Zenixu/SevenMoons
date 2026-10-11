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


## Kotak tombol. `kind`: "normal" | "accent" | "honest" | "danger".
## `honest` sengaja hanya berbingkai (tanpa isi) — pembeda NON-WARNA untuk
## pilihan "jujur" yang lebih redup (MECHANICS_SPEC §2 & §10).
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
