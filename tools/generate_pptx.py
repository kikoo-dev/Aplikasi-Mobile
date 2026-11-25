"""
Generator presentasi PowerPoint untuk project "ProfilKita ITENAS".

Menghasilkan file: Presentasi_ProfilKita_ITENAS.pptx

Jalankan:  python tools/generate_pptx.py
"""

import os

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

# ============================================================
# PALET WARNA (tema Orange - Putih ITENAS)
# ============================================================
ORANGE = RGBColor(0xF2, 0x65, 0x22)
ORANGE_DARK = RGBColor(0xD1, 0x4E, 0x0E)
ORANGE_LIGHT = RGBColor(0xFF, 0x9A, 0x4D)
ORANGE_SOFT = RGBColor(0xFF, 0xF1, 0xE8)
ORANGE_SOFT2 = RGBColor(0xFF, 0xE3, 0xD2)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
INK = RGBColor(0x24, 0x1A, 0x12)
INK_SOFT = RGBColor(0x6E, 0x61, 0x57)
INK_MUTED = RGBColor(0x9E, 0x91, 0x89)
LINE = RGBColor(0xF0, 0xE7, 0xE0)
CREAM = RGBColor(0xFF, 0xFA, 0xF6)
GREEN = RGBColor(0x1F, 0xA9, 0x7A)

SCREENS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screens_ready")
SCREENS_NEW = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           "screens_new_ready")

FONT = "Segoe UI"
FONT_BOLD = "Segoe UI Semibold"

W, H = Inches(13.333), Inches(7.5)


# ============================================================
# HELPER
# ============================================================
def new_deck():
    prs = Presentation()
    prs.slide_width = W
    prs.slide_height = H
    return prs


def blank(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def rect(slide, x, y, w, h, fill=None, line=None, radius=None,
         shape=MSO_SHAPE.RECTANGLE, line_w=1.0):
    shp = slide.shapes.add_shape(shape, x, y, w, h)
    if fill is None:
        shp.fill.background()
    else:
        shp.fill.solid()
        shp.fill.fore_color.rgb = fill
    if line is None:
        shp.line.fill.background()
    else:
        shp.line.color.rgb = line
        shp.line.width = Pt(line_w)
    shp.shadow.inherit = False
    if radius is not None and shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        try:
            shp.adjustments[0] = radius
        except Exception:
            pass
    if shp.has_text_frame:
        shp.text_frame.word_wrap = True
    return shp


def rrect(slide, x, y, w, h, fill=None, line=None, radius=0.08, line_w=1.0):
    return rect(slide, x, y, w, h, fill, line, radius,
                MSO_SHAPE.ROUNDED_RECTANGLE, line_w)


def text(slide, x, y, w, h, content, size=18, color=INK, bold=False,
         align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP, spacing=1.0,
         font=FONT, italic=False, space_after=0):
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = 0
    tf.margin_right = 0
    tf.margin_top = 0
    tf.margin_bottom = 0
    tf.vertical_anchor = anchor

    lines = content.split("\n")
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        p.line_spacing = spacing
        p.space_after = Pt(space_after)
        run = p.add_run()
        run.text = line
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.italic = italic
        run.font.name = FONT_BOLD if bold else font
        run.font.color.rgb = color
    return box


def bullets(slide, x, y, w, h, items, size=15, color=INK,
            bullet_color=ORANGE, gap=10, spacing=1.35):
    """items: list of (judul, deskripsi) atau str."""
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = 0
    tf.margin_top = 0
    tf.margin_right = 0
    tf.margin_bottom = 0

    for i, item in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.line_spacing = spacing
        p.space_after = Pt(gap)
        p.alignment = PP_ALIGN.LEFT

        if isinstance(item, tuple):
            head, desc = item
            r1 = p.add_run()
            r1.text = "•  "
            r1.font.size = Pt(size)
            r1.font.bold = True
            r1.font.name = FONT
            r1.font.color.rgb = bullet_color

            r2 = p.add_run()
            r2.text = head
            r2.font.size = Pt(size)
            r2.font.bold = True
            r2.font.name = FONT_BOLD
            r2.font.color.rgb = color

            if desc:
                r3 = p.add_run()
                r3.text = " — " + desc
                r3.font.size = Pt(size)
                r3.font.name = FONT
                r3.font.color.rgb = INK_SOFT
        else:
            r1 = p.add_run()
            r1.text = "•  "
            r1.font.size = Pt(size)
            r1.font.bold = True
            r1.font.color.rgb = bullet_color
            r1.font.name = FONT

            r2 = p.add_run()
            r2.text = item
            r2.font.size = Pt(size)
            r2.font.name = FONT
            r2.font.color.rgb = color
    return box


def gradient_bg(slide, c1=ORANGE_LIGHT, c2=ORANGE_DARK, angle=45):
    """Background gradient penuh (via gradient fill)."""
    bg = rect(slide, 0, 0, W, H, fill=c1)
    bg.fill.gradient()
    stops = bg.fill.gradient_stops
    stops[0].color.rgb = c1
    stops[0].position = 0.0
    stops[1].color.rgb = c2
    stops[1].position = 1.0
    bg.fill.gradient_angle = angle
    return bg


def deco_circle(slide, x, y, d, alpha_color=WHITE, transparency=88):
    c = rect(slide, x, y, d, d, fill=alpha_color, shape=MSO_SHAPE.OVAL)
    # transparansi via XML
    from pptx.oxml.ns import qn
    solidFill = c.fill._xPr.find(qn('a:solidFill'))
    if solidFill is not None:
        clr = solidFill.find(qn('a:srgbClr'))
        if clr is not None:
            alpha = clr.makeelement(qn('a:alpha'),
                                    {'val': str(int((100 - transparency) * 1000))})
            clr.append(alpha)
    return c


def page_number(slide, num, total):
    text(slide, W - Inches(1.3), H - Inches(0.5), Inches(1.0), Inches(0.3),
         f"{num} / {total}", size=10, color=INK_MUTED, align=PP_ALIGN.RIGHT)


def footer_line(slide, label="ProfilKita — Institut Teknologi Nasional Bandung"):
    rect(slide, Inches(0.9), H - Inches(0.62), Inches(11.5), Emu(9525), fill=LINE)
    text(slide, Inches(0.9), H - Inches(0.5), Inches(8), Inches(0.3),
         label, size=9.5, color=INK_MUTED)


def section_header(slide, kicker, title, subtitle=None):
    """Header standar untuk slide konten."""
    rect(slide, Inches(0.9), Inches(0.62), Inches(0.075), Inches(0.52), fill=ORANGE)
    text(slide, Inches(1.12), Inches(0.55), Inches(9), Inches(0.3),
         kicker.upper(), size=10.5, color=ORANGE, bold=True)
    text(slide, Inches(1.12), Inches(0.82), Inches(10.5), Inches(0.5),
         title, size=27, color=INK, bold=True)
    if subtitle:
        text(slide, Inches(1.12), Inches(1.36), Inches(10.8), Inches(0.4),
             subtitle, size=12.5, color=INK_MUTED)
    return Inches(1.85) if subtitle else Inches(1.55)


def icon_card(slide, x, y, w, h, icon_text, title, desc,
              fill=WHITE, border=LINE, icon_bg=ORANGE_SOFT,
              icon_color=ORANGE, title_size=13.5, desc_size=10.5):
    card = rrect(slide, x, y, w, h, fill=fill, line=border, radius=0.10)
    badge = rrect(slide, x + Inches(0.22), y + Inches(0.22),
                  Inches(0.42), Inches(0.42), fill=icon_bg, radius=0.30)
    text(slide, x + Inches(0.22), y + Inches(0.26), Inches(0.42), Inches(0.36),
         icon_text, size=15, align=PP_ALIGN.CENTER, color=icon_color)
    text(slide, x + Inches(0.22), y + Inches(0.76), w - Inches(0.44), Inches(0.3),
         title, size=title_size, bold=True, color=INK)
    text(slide, x + Inches(0.22), y + Inches(1.10), w - Inches(0.44), h - Inches(1.2),
         desc, size=desc_size, color=INK_SOFT, spacing=1.25)
    return card


# ============================================================
# SLIDE 1 — COVER
# ============================================================
def slide_cover(prs):
    s = blank(prs)
    gradient_bg(s, ORANGE_LIGHT, ORANGE_DARK, 45)

    deco_circle(s, Inches(9.4), Inches(-1.8), Inches(5.4), WHITE, 92)
    deco_circle(s, Inches(11.0), Inches(4.6), Inches(3.4), WHITE, 94)
    deco_circle(s, Inches(-1.3), Inches(5.2), Inches(3.0), WHITE, 95)

    # Logo ITENAS
    logo = rrect(s, Inches(0.9), Inches(1.15), Inches(1.05), Inches(1.05),
                 fill=WHITE, radius=0.22)
    shield = rect(s, Inches(1.16), Inches(1.36), Inches(0.53), Inches(0.5),
                  fill=ORANGE, shape=MSO_SHAPE.ROUND_2_SAME_RECTANGLE)
    text(s, Inches(1.16), Inches(1.46), Inches(0.53), Inches(0.3),
         "ITN", size=11, bold=True, color=WHITE, align=PP_ALIGN.CENTER)

    text(s, Inches(0.9), Inches(2.55), Inches(10), Inches(0.35),
         "INSTITUT TEKNOLOGI NASIONAL BANDUNG", size=12, bold=True,
         color=WHITE)
    text(s, Inches(0.9), Inches(2.95), Inches(10.5), Inches(1.5),
         "ProfilKita", size=64, bold=True, color=WHITE)
    text(s, Inches(0.9), Inches(4.05), Inches(9.5), Inches(0.5),
         "Aplikasi Mobile Profil, Jejaring Kampus & Kalkulator", size=22,
         color=RGBColor(0xFF, 0xE8, 0xD8))
    rect(s, Inches(0.92), Inches(4.72), Inches(1.5), Inches(0.045), fill=WHITE)
    text(s, Inches(0.9), Inches(4.95), Inches(8.5), Inches(0.9),
         "Dibangun dengan Flutter  •  Backend Supabase  •  Tema Orange–Putih ITENAS",
         size=13, color=RGBColor(0xFF, 0xF0, 0xE4), spacing=1.4)

    # Pill badges
    badges = ["Flutter", "Supabase", "PostgreSQL", "Storage", "Android"]
    bx = Inches(0.9)
    for b in badges:
        bw = Inches(0.28 + 0.105 * len(b))
        pill = rrect(s, bx, Inches(5.85), bw, Inches(0.36),
                     fill=None, line=WHITE, radius=0.5, line_w=1.2)
        text(s, bx, Inches(5.92), bw, Inches(0.25), b, size=10.5,
             color=WHITE, align=PP_ALIGN.CENTER)
        bx += bw + Inches(0.14)

    text(s, Inches(0.9), Inches(6.7), Inches(6), Inches(0.3),
         "Tugas Mata Kuliah Pemrograman Mobile", size=10.5,
         color=RGBColor(0xFF, 0xDD, 0xC8))
    return s


# ============================================================
# SLIDE 2 — AGENDA
# ============================================================
def slide_agenda(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Agenda", "Apa yang akan dibahas",
                       "Ringkasan materi presentasi pengenalan project")

    items = [
        ("01", "Latar Belakang", "Masalah & alasan project dibuat"),
        ("02", "Tujuan Project", "Manfaat dan target pengguna"),
        ("03", "Fitur Utama", "8 fitur: auth, profil, feed, kalkulator"),
        ("04", "Arsitektur & Teknologi", "Flutter, Supabase, struktur kode"),
        ("05", "Desain & Tema", "Identitas visual ITENAS orange–putih"),
        ("06", "Database & Keamanan", "5 tabel, RLS, storage, RPC"),
        ("07", "Demo Aplikasi", "Alur pemakaian + screenshot asli"),
        ("08", "Fitur Feed", "Bagikan, komentar, hapus postingan"),
        ("09", "Keunggulan", "Nilai lebih aplikasi"),
        ("10", "Penutup", "Kesimpulan & pengembangan lanjutan"),
    ]

    col_w = Inches(5.55)
    row_h = Inches(0.76)
    start_y = Inches(1.90)

    for i, (no, title, desc) in enumerate(items):
        col = i % 2
        row = i // 2
        x = Inches(0.9) + col * (col_w + Inches(0.55))
        yy = start_y + row * (row_h + Inches(0.16))

        rrect(s, x, yy, col_w, row_h, fill=WHITE, line=LINE, radius=0.14)
        rrect(s, x + Inches(0.15), yy + Inches(0.15), Inches(0.46),
              Inches(0.46), fill=ORANGE_SOFT, radius=0.28)
        text(s, x + Inches(0.15), yy + Inches(0.245), Inches(0.46), Inches(0.28),
             no, size=11.5, bold=True, color=ORANGE, align=PP_ALIGN.CENTER)
        text(s, x + Inches(0.74), yy + Inches(0.14), col_w - Inches(0.9),
             Inches(0.28), title, size=12.5, bold=True, color=INK)
        text(s, x + Inches(0.74), yy + Inches(0.42), col_w - Inches(0.9),
             Inches(0.26), desc, size=9.8, color=INK_MUTED)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 3 — LATAR BELAKANG
# ============================================================
def slide_background(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Latar Belakang", "Mengapa ProfilKita?",
                       "Kebutuhan mahasiswa akan identitas digital dan alat bantu belajar")

    # Kiri: masalah
    text(s, Inches(0.9), y, Inches(5.6), Inches(0.3),
         "Permasalahan", size=13, bold=True, color=ORANGE)
    bullets(s, Inches(0.9), y + Inches(0.38), Inches(5.6), Inches(3.6), [
        ("Data profil terpisah-pisah", "biodata, sosial media, dan portofolio "
         "tersebar di banyak platform"),
        ("Sulit memperkenalkan diri", "tidak ada satu halaman profil yang rapi "
         "dan bisa dibagikan"),
        ("Aktivitas kampus tidak terdokumentasi", "kegiatan, foto, dan capaian "
         "mahasiswa cepat tenggelam"),
        ("Butuh alat hitung cepat", "kalkulator bawaan HP terbatas untuk "
         "operasi bertingkat"),
    ], size=12.5, gap=13)

    # Kanan: solusi card
    card_x = Inches(6.95)
    rrect(s, card_x, y, Inches(5.45), Inches(4.05), fill=WHITE, line=LINE,
          radius=0.07)
    rect(s, card_x, y, Inches(5.45), Inches(0.075), fill=ORANGE)
    text(s, card_x + Inches(0.35), y + Inches(0.32), Inches(4.8), Inches(0.3),
         "Solusi: ProfilKita", size=15, bold=True, color=INK)
    text(s, card_x + Inches(0.35), y + Inches(0.70), Inches(4.8), Inches(0.5),
         "Satu aplikasi mobile yang menyatukan identitas digital mahasiswa "
         "dengan alat bantu sehari-hari.",
         size=11.5, color=INK_SOFT, spacing=1.3)

    features = [
        ("Profil terpusat", "biodata, about me, 3 sosial media"),
        ("Jejaring kampus", "feed foto & postingan seperti LinkedIn"),
        ("Kalkulator pintar", "prioritas operasi, riwayat hitungan"),
        ("Identitas kampus", "tema visual resmi ITENAS"),
    ]
    fy = y + Inches(1.62)
    for i, (t, d) in enumerate(features):
        yy = fy + i * Inches(0.58)
        rect(s, card_x + Inches(0.35), yy + Inches(0.06), Inches(0.30),
             Inches(0.30), fill=ORANGE_SOFT, shape=MSO_SHAPE.OVAL)
        text(s, card_x + Inches(0.35), yy + Inches(0.105), Inches(0.30),
             Inches(0.22), "✓", size=10, bold=True, color=ORANGE,
             align=PP_ALIGN.CENTER)
        text(s, card_x + Inches(0.78), yy + Inches(0.02), Inches(4.3),
             Inches(0.26), t, size=11.5, bold=True, color=INK)
        text(s, card_x + Inches(0.78), yy + Inches(0.26), Inches(4.3),
             Inches(0.26), d, size=9.5, color=INK_MUTED)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 4 — TUJUAN
# ============================================================
def slide_goals(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Tujuan Project", "Apa yang ingin dicapai",
                       "Sasaran fungsional dan teknis dari aplikasi")

    cards = [
        ("◎", "Identitas Digital", "Menyediakan satu halaman profil lengkap "
         "berisi biodata, about me, dan tautan sosial media."),
        ("◈", "Jejaring Sosial", "Menghadirkan feed kampus untuk berbagi "
         "postingan dan foto antar mahasiswa."),
        ("∑", "Alat Bantu Hitung", "Kalkulator dengan prioritas operasi "
         "matematika yang benar dan riwayat perhitungan."),
        ("◐", "Branding Kampus", "Menerapkan identitas visual ITENAS "
         "melalui tema orange–putih yang konsisten."),
        ("☁", "Backend Nyata", "Mengimplementasikan autentikasi, database, "
         "dan storage menggunakan Supabase."),
        ("✎", "Pengalaman Nyaman", "UI modern Material 3, dark mode, animasi "
         "halus, dan validasi input di semua form."),
    ]

    cw = Inches(3.75)
    ch = Inches(2.15)
    gx = Inches(0.36)
    gy = Inches(0.30)
    for i, (ic, t, d) in enumerate(cards):
        col = i % 3
        row = i // 3
        x = Inches(0.9) + col * (cw + gx)
        yy = y + Inches(0.05) + row * (ch + gy)
        icon_card(s, x, yy, cw, ch, ic, t, d)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 5 — FITUR UTAMA (GRID)
# ============================================================
def slide_features(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Fitur Utama", "Delapan fitur inti aplikasi",
                       "Dari splash screen hingga interaksi sosial di feed")

    feats = [
        ("1", "Splash Screen", "Animasi logo ITENAS, pengecekan sesi otomatis, "
         "auto-login jika sudah pernah masuk."),
        ("2", "Login & Register", "Autentikasi email + password, validasi form, "
         "indikator kekuatan password, lupa password."),
        ("3", "Edit Profil", "Upload foto (kamera/galeri), biodata lengkap, "
         "about me, Instagram, Facebook, TikTok."),
        ("4", "Beranda / Feed", "Feed vertikal gaya LinkedIn: postingan teks & "
         "foto dari seluruh mahasiswa, tersimpan di Supabase."),
        ("5", "Bagikan Postingan", "Buat postingan baru dengan teks dan/atau "
         "foto. Upload langsung ke Supabase Storage."),
        ("6", "Komentar", "Beri komentar pada postingan, daftar komentar realtime, "
         "counter otomatis, dilindungi RLS."),
        ("7", "Hapus Postingan", "Pemilik dapat menghapus postingannya sendiri "
         "dengan konfirmasi. Komentar & like ikut terhapus."),
        ("8", "Kalkulator", "Prioritas operasi (kali/bagi dulu), kurung, persen, "
         "riwayat. Hasil muncul hanya setelah tanda sama dengan."),
    ]

    cw = Inches(2.82)
    ch = Inches(2.05)
    gx = Inches(0.24)
    gy = Inches(0.26)
    for i, (no, t, d) in enumerate(feats):
        col = i % 4
        row = i // 4
        x = Inches(0.9) + col * (cw + gx)
        yy = y + Inches(0.05) + row * (ch + gy)

        rrect(s, x, yy, cw, ch, fill=WHITE, line=LINE, radius=0.10)
        rrect(s, x + Inches(0.18), yy + Inches(0.18), Inches(0.38),
              Inches(0.38), fill=ORANGE, radius=0.30)
        text(s, x + Inches(0.18), yy + Inches(0.235), Inches(0.38), Inches(0.28),
             no, size=12.5, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        text(s, x + Inches(0.18), yy + Inches(0.66), cw - Inches(0.36),
             Inches(0.3), t, size=11.5, bold=True, color=INK)
        text(s, x + Inches(0.18), yy + Inches(0.96), cw - Inches(0.36),
             ch - Inches(1.05), d, size=9.2, color=INK_SOFT, spacing=1.22)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 6 — ARSITEKTUR TEKNOLOGI
# ============================================================
def slide_stack(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Teknologi", "Stack & Arsitektur",
                       "Flutter di sisi klien, Supabase sebagai backend")

    stack = [
        ("Flutter 3.47", "Framework UI cross-platform (Dart 3.13)"),
        ("Supabase Auth", "Autentikasi email & password, sesi otomatis"),
        ("Supabase Postgres", "Database relasional untuk profil & feed"),
        ("Supabase Storage", "Penyimpanan foto profil & foto postingan"),
        ("Material 3", "Design system, dark mode, animasi"),
        ("SharedPreferences", "Mode demo lokal tanpa backend"),
    ]

    # kiri
    text(s, Inches(0.9), y, Inches(5.5), Inches(0.3), "Komponen",
         size=13, bold=True, color=ORANGE)
    ly = y + Inches(0.4)
    for i, (t, d) in enumerate(stack):
        yy = ly + i * Inches(0.62)
        rrect(s, Inches(0.9), yy, Inches(5.5), Inches(0.52), fill=WHITE,
              line=LINE, radius=0.22)
        text(s, Inches(1.12), yy + Inches(0.07), Inches(2.2), Inches(0.24),
             t, size=11, bold=True, color=INK)
        text(s, Inches(3.25), yy + Inches(0.09), Inches(3.0), Inches(0.24),
             d, size=9.5, color=INK_MUTED)

    # kanan: diagram alur
    text(s, Inches(6.9), y, Inches(5.5), Inches(0.3), "Alur Data",
         size=13, bold=True, color=ORANGE)

    boxes = [
        ("UI Layer", "Screens & Widgets", ORANGE_SOFT, ORANGE),
        ("State", "AuthController + InheritedNotifier", WHITE, LINE),
        ("Service", "SupabaseService / DemoService", WHITE, LINE),
        ("Backend", "Supabase (Auth • DB • Storage)", ORANGE, ORANGE),
    ]
    by = y + Inches(0.42)
    for i, (t, d, fill, border) in enumerate(boxes):
        yy = by + i * Inches(0.90)
        is_dark = fill == ORANGE
        rrect(s, Inches(7.35), yy, Inches(4.55), Inches(0.62), fill=fill,
              line=border, radius=0.14)
        text(s, Inches(7.35), yy + Inches(0.08), Inches(4.55), Inches(0.25),
             t, size=11.5, bold=True,
             color=WHITE if is_dark else INK, align=PP_ALIGN.CENTER)
        text(s, Inches(7.35), yy + Inches(0.33), Inches(4.55), Inches(0.22),
             d, size=9,
             color=RGBColor(0xFF, 0xE8, 0xD8) if is_dark else INK_MUTED,
             align=PP_ALIGN.CENTER)
        if i < len(boxes) - 1:
            text(s, Inches(9.5), yy + Inches(0.62), Inches(0.4), Inches(0.26),
                 "↓", size=13, color=ORANGE, align=PP_ALIGN.CENTER)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 7 — STRUKTUR PROYEK
# ============================================================
def slide_structure(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Struktur Kode", "Organisasi Folder",
                       "Pemisahan jelas antara model, service, dan tampilan")

    tree = [
        ("lib/", "root aplikasi", True),
        ("├─ main.dart", "entry point + init Supabase", False),
        ("├─ app.dart", "MaterialApp, tema, controller", False),
        ("├─ core/", "env, tema, scope, format", True),
        ("├─ models/", "UserProfile, FeedPost, AppUser", True),
        ("├─ services/", "Supabase, Demo, Feed, AuthController", True),
        ("├─ screens/", "splash, auth, home, profile, calculator", True),
        ("└─ widgets/", "komponen reusable (kartu, avatar, logo)", True),
    ]

    rrect(s, Inches(0.9), y, Inches(6.4), Inches(4.2), fill=WHITE, line=LINE,
          radius=0.06)
    rect(s, Inches(0.9), y, Inches(6.4), Inches(0.44), fill=ORANGE)
    text(s, Inches(1.1), y + Inches(0.11), Inches(5), Inches(0.26),
         "Struktur Folder", size=11, bold=True, color=WHITE)

    ty = y + Inches(0.62)
    for i, (path, desc, is_dir) in enumerate(tree):
        yy = ty + i * Inches(0.44)
        text(s, Inches(1.15), yy, Inches(2.5), Inches(0.24), path, size=10.5,
             bold=is_dir, color=INK if is_dir else INK_SOFT,
             font="Consolas")
        text(s, Inches(3.75), yy + Inches(0.02), Inches(3.4), Inches(0.24),
             desc, size=9, color=INK_MUTED)

    # kanan: poin arsitektur
    points = [
        ("Pemisahan lapisan", "UI tidak mengakses database langsung, "
         "selalu lewat service."),
        ("Dua mode data", "Supabase untuk produksi, mode demo lokal agar "
         "aplikasi tetap bisa dijalankan."),
        ("State sederhana", "InheritedNotifier bawaan Flutter — tanpa "
         "dependency state management tambahan."),
        ("Reusable widget", "Kartu, avatar, tombol, dan logo dipakai "
         "lintas halaman."),
    ]
    text(s, Inches(7.7), y, Inches(4.7), Inches(0.3), "Prinsip Desain Kode",
         size=13, bold=True, color=ORANGE)
    bullets(s, Inches(7.7), y + Inches(0.42), Inches(4.7), Inches(3.8),
            points, size=11.5, gap=14, spacing=1.3)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 8 — DESAIN & TEMA
# ============================================================
def slide_design(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Desain", "Identitas Visual ITENAS",
                       "Tema orange–putih yang konsisten di seluruh layar")

    # Palet
    text(s, Inches(0.9), y, Inches(6), Inches(0.3), "Palet Warna",
         size=13, bold=True, color=ORANGE)

    palette = [
        (ORANGE, "Primary", "#F26522"),
        (ORANGE_LIGHT, "Light", "#FF9A4D"),
        (ORANGE_DARK, "Dark", "#D14E0E"),
        (ORANGE_SOFT, "Soft", "#FFF1E8"),
        (INK, "Ink", "#241A12"),
        (WHITE, "Surface", "#FFFFFF"),
    ]
    px = Inches(0.9)
    for i, (c, name, hexv) in enumerate(palette):
        col = i % 3
        row = i // 3
        x = px + col * Inches(1.95)
        yy = y + Inches(0.42) + row * Inches(1.28)
        sw = rrect(s, x, yy, Inches(1.7), Inches(0.72), fill=c,
                   line=LINE, radius=0.16)
        text(s, x, yy + Inches(0.82), Inches(1.7), Inches(0.22), name,
             size=10.5, bold=True, color=INK)
        text(s, x, yy + Inches(1.02), Inches(1.7), Inches(0.22), hexv,
             size=9, color=INK_MUTED)

    # Prinsip desain
    text(s, Inches(7.2), y, Inches(5.2), Inches(0.3), "Prinsip Desain",
         size=13, bold=True, color=ORANGE)
    bullets(s, Inches(7.2), y + Inches(0.42), Inches(5.2), Inches(3.9), [
        ("Konsisten", "sudut membulat 16–22px, gradient orange pada aksi utama"),
        ("Jelas", "hierarki tipografi tegas, kontras tinggi untuk keterbacaan"),
        ("Hidup", "animasi splash, transisi halus, haptic feedback"),
        ("Aksesibel", "mendukung dark mode otomatis mengikuti sistem"),
        ("Beridentitas", "logo ITENAS hadir di splash, login, header, footer"),
    ], size=11.5, gap=13, spacing=1.3)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 9 — DATABASE & KEAMANAN
# ============================================================
def slide_database(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Database", "Skema Supabase & Keamanan",
                       "Lima tabel utama dengan Row Level Security")

    tables = [
        ("profiles", "id, email, full_name, username, phone, bio, about_me, "
         "address, occupation, birth_date, gender, avatar_url, instagram, "
         "facebook, tiktok"),
        ("posts", "id, author_id, content, image_url, like_count, "
         "comment_count, created_at, updated_at"),
        ("post_likes", "id, post_id, user_id (unik per pasangan)"),
        ("post_comments", "id, post_id, author_id, content, created_at"),
        ("storage", "bucket 'avatars' & 'posts' — public read, upload hanya "
         "oleh pemilik folder"),
    ]

    ty = y + Inches(0.02)
    for i, (name, cols) in enumerate(tables):
        yy = ty + i * Inches(0.84)
        rrect(s, Inches(0.9), yy, Inches(6.55), Inches(0.74), fill=WHITE,
              line=LINE, radius=0.14)
        rrect(s, Inches(1.06), yy + Inches(0.13), Inches(0.48), Inches(0.48),
              fill=ORANGE_SOFT, radius=0.24)
        text(s, Inches(1.06), yy + Inches(0.235), Inches(0.48), Inches(0.24),
             "▤", size=12, color=ORANGE, align=PP_ALIGN.CENTER)
        text(s, Inches(1.70), yy + Inches(0.09), Inches(2.0), Inches(0.22),
             name, size=10.5, bold=True, color=INK, font="Consolas")
        text(s, Inches(1.70), yy + Inches(0.31), Inches(5.5), Inches(0.40),
             cols, size=7.8, color=INK_MUTED, spacing=1.10)

    # Keamanan + RPC
    text(s, Inches(7.8), y, Inches(4.6), Inches(0.3), "Keamanan & Integritas",
         size=13, bold=True, color=ORANGE)
    bullets(s, Inches(7.8), y + Inches(0.42), Inches(4.6), Inches(4.0), [
        ("Row Level Security", "aktif di 4 tabel — pengguna hanya bisa "
         "mengubah datanya sendiri"),
        ("Trigger handle_new_user", "profil otomatis dibuat saat register"),
        ("Unique index username", "mencegah username ganda "
         "(case-insensitive)"),
        ("RPC counter", "increment/decrement like & komentar agar angka "
         "konsisten"),
        ("Cascade delete", "hapus postingan ikut menghapus komentar & like"),
        ("Anon key saja di klien", "service_role key tidak pernah "
         "dipasang di aplikasi"),
    ], size=10.2, gap=11, spacing=1.28)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 10 — ALUR APLIKASI
# ============================================================
def slide_flow(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Alur Aplikasi", "Perjalanan Pengguna",
                       "Dari membuka aplikasi sampai menggunakan kalkulator")

    steps = [
        ("Splash", "logo & cek sesi", "1"),
        ("Login /\nRegister", "buat akun atau masuk", "2"),
        ("Beranda\nFeed", "lihat postingan kampus", "3"),
        ("Edit\nProfil", "biodata & sosial media", "4"),
        ("Profil\nSaya", "lihat hasil profil", "5"),
        ("Kalkulator", "hitung dengan riwayat", "6"),
    ]

    n = len(steps)
    cw = Inches(1.78)
    gap = Inches(0.20)
    total_w = n * cw + (n - 1) * gap
    start_x = (W - total_w) / 2
    cy = y + Inches(0.75)

    for i, (title, desc, no) in enumerate(steps):
        x = start_x + i * (cw + gap)
        rrect(s, x, cy, cw, Inches(1.85), fill=WHITE, line=LINE, radius=0.12)
        rrect(s, x, cy, cw, Inches(0.09), fill=ORANGE, radius=0.4)
        rrect(s, x + cw / 2 - Inches(0.24), cy + Inches(0.30), Inches(0.48),
              Inches(0.48), fill=ORANGE_SOFT, radius=0.5)
        text(s, x + cw / 2 - Inches(0.24), cy + Inches(0.40), Inches(0.48),
             Inches(0.26), no, size=13, bold=True, color=ORANGE,
             align=PP_ALIGN.CENTER)
        text(s, x + Inches(0.1), cy + Inches(0.90), cw - Inches(0.2),
             Inches(0.55), title, size=11.5, bold=True, color=INK,
             align=PP_ALIGN.CENTER, spacing=1.1)
        text(s, x + Inches(0.1), cy + Inches(1.44), cw - Inches(0.2),
             Inches(0.35), desc, size=8.5, color=INK_MUTED,
             align=PP_ALIGN.CENTER)

        if i < n - 1:
            text(s, x + cw - Inches(0.02), cy + Inches(0.82), Inches(0.24),
                 Inches(0.3), "›", size=17, color=ORANGE,
                 align=PP_ALIGN.CENTER)

    # Catatan bawah
    rrect(s, Inches(0.9), y + Inches(3.0), Inches(11.5), Inches(0.95),
          fill=ORANGE_SOFT, radius=0.14)
    text(s, Inches(1.2), y + Inches(3.18), Inches(11.0), Inches(0.6),
         "Sesi login tersimpan otomatis — jika pengguna sudah pernah masuk, "
         "splash akan langsung mengarahkan ke beranda tanpa login ulang.",
         size=11.5, color=ORANGE_DARK, spacing=1.3)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 11 — DEMO / TANGKAPAN LAYAR
# ============================================================
def slide_demo(prs, num, total):
    """Slide demo: menampilkan screenshot asli aplikasi bila tersedia."""
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Demo", "Tampilan Aplikasi",
                       "Tangkapan layar langsung dari perangkat ASUS ROG Phone 3")

    screens = [
        ("Splash", "01-splash.png", SCREENS),
        ("Login", "02-login.png", SCREENS),
        ("Register", "03-register.png", SCREENS),
        ("Beranda Feed", "04-beranda.png", SCREENS),
        ("Komentar", "fitur-02-komentar.png", SCREENS_NEW),
        ("Hapus Postingan", "fitur-04-konfirmasi.png", SCREENS_NEW),
        ("Profil Saya", "09-profil.png", SCREENS),
        ("Kalkulator", "08-kalkulator-hasil.png", SCREENS),
    ]

    # Layout 8 layar dalam satu baris
    n = len(screens)
    gap = Inches(0.12)
    phone_w = Inches(1.40)
    total_w = n * phone_w + (n - 1) * gap
    start_x = (W - total_w) / 2

    phone_h = phone_w * (19.5 / 9)
    top_y = y + Inches(0.05)

    for i, (title, fname, base) in enumerate(screens):
        x = start_x + i * (phone_w + gap)

        # Bingkai HP
        rrect(s, x, top_y, phone_w, phone_h, fill=RGBColor(0x1A, 0x14, 0x10),
              line=None, radius=0.07)
        inset = Inches(0.035)
        rrect(s, x + inset, top_y + inset, phone_w - 2 * inset,
              phone_h - 2 * inset, fill=WHITE, radius=0.055)

        img_path = os.path.join(base, fname)
        if os.path.exists(img_path):
            s.shapes.add_picture(
                img_path,
                x + inset, top_y + inset,
                width=phone_w - 2 * inset,
                height=phone_h - 2 * inset,
            )

        # Label
        text(s, x - Inches(0.04), top_y + phone_h + Inches(0.06),
             phone_w + Inches(0.08), Inches(0.34), title, size=8,
             bold=True, color=INK, align=PP_ALIGN.CENTER)

    text(s, Inches(0.9), H - Inches(1.02), Inches(11.5), Inches(0.28),
         "Aplikasi diuji pada ASUS ROG Phone 3 (Android 12) — terhubung ke "
         "Supabase (Auth, Database, Storage).", size=9.5, color=INK_MUTED,
         align=PP_ALIGN.CENTER)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 12 — KEUNGGULAN
# ============================================================
def slide_feed_features(prs, num, total):
    """Slide khusus: alur interaksi feed (bagikan, komentar, hapus)."""
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Fitur Feed", "Interaksi Jejaring Kampus",
                       "Bagikan, komentari, dan hapus postingan — semua tersimpan di Supabase")

    # ---------- Kiri: langkah-langkah ----------
    steps = [
        ("1", "Bagikan", "Tulis teks dan/atau pilih foto dari galeri atau "
         "kamera, lalu tekan Bagikan."),
        ("2", "Komentari", "Buka postingan, tulis komentar. Counter otomatis "
         "diperbarui lewat RPC."),
        ("3", "Hapus", "Menu titik tiga pada postingan sendiri menampilkan "
         "opsi Hapus dengan konfirmasi."),
    ]
    sy = y + Inches(0.10)
    for i, (no, title, desc) in enumerate(steps):
        yy = sy + i * Inches(1.28)
        rrect(s, Inches(0.9), yy, Inches(4.35), Inches(1.12), fill=WHITE,
              line=LINE, radius=0.14)
        rrect(s, Inches(1.08), yy + Inches(0.20), Inches(0.48), Inches(0.48),
              fill=ORANGE, radius=0.30)
        text(s, Inches(1.08), yy + Inches(0.29), Inches(0.48), Inches(0.28),
             no, size=14, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        text(s, Inches(1.72), yy + Inches(0.16), Inches(3.3), Inches(0.26),
             title, size=12.5, bold=True, color=INK)
        text(s, Inches(1.72), yy + Inches(0.46), Inches(3.3), Inches(0.58),
             desc, size=9.8, color=INK_SOFT, spacing=1.25)

    # ---------- Catatan keamanan ----------
    rrect(s, Inches(0.9), y + Inches(3.95), Inches(4.35), Inches(0.95),
          fill=ORANGE_SOFT, radius=0.14)
    text(s, Inches(1.15), y + Inches(4.10), Inches(3.9), Inches(0.7),
         "Keamanan: RLS memastikan pengguna hanya bisa menghapus "
         "postingannya sendiri. Komentar & like ikut terhapus (cascade).",
         size=9.2, color=ORANGE_DARK, spacing=1.3)

    # ---------- Kanan: screenshot ----------
    shots = [
        ("Menu Hapus", "fitur-03-menu-hapus.png"),
        ("Konfirmasi", "fitur-04-konfirmasi.png"),
        ("Komentar", "fitur-02-komentar.png"),
    ]
    n = len(shots)
    gap = Inches(0.20)
    phone_w = Inches(1.72)
    total_w = n * phone_w + (n - 1) * gap
    start_x = Inches(5.55)
    phone_h = phone_w * (19.5 / 9)
    top_y = y + Inches(0.15)

    for i, (title, fname) in enumerate(shots):
        x = start_x + i * (phone_w + gap)
        rrect(s, x, top_y, phone_w, phone_h, fill=RGBColor(0x1A, 0x14, 0x10),
              line=None, radius=0.07)
        inset = Inches(0.04)
        rrect(s, x + inset, top_y + inset, phone_w - 2 * inset,
              phone_h - 2 * inset, fill=WHITE, radius=0.055)

        img_path = os.path.join(SCREENS_NEW, fname)
        if os.path.exists(img_path):
            s.shapes.add_picture(
                img_path,
                x + inset, top_y + inset,
                width=phone_w - 2 * inset,
                height=phone_h - 2 * inset,
            )
        text(s, x - Inches(0.04), top_y + phone_h + Inches(0.07),
             phone_w + Inches(0.08), Inches(0.24), title, size=9,
             bold=True, color=INK, align=PP_ALIGN.CENTER)

    footer_line(s)
    page_number(s, num, total)
    return s


def slide_advantage(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Keunggulan", "Yang Membedakan",
                       "Nilai lebih dibanding aplikasi profil biasa")

    items = [
        ("Terintegrasi", "Profil, feed sosial, komentar, dan kalkulator dalam "
         "satu aplikasi — tidak perlu pindah-pindah app."),
        ("Beridentitas kampus", "Tema orange-putih dan logo ITENAS "
         "diterapkan konsisten di seluruh antarmuka."),
        ("Siap produksi", "Autentikasi nyata, database relasional, storage, "
         "RLS, dan cascade delete — bukan sekadar UI."),
        ("Interaksi lengkap", "Posting teks & foto, like, komentar, hapus "
         "postingan sendiri — semua tersimpan di cloud."),
        ("Kalkulator akurat", "Menerapkan urutan operasi matematika yang "
         "benar, bukan evaluasi kiri-ke-kanan."),
        ("Ringan & rapi", "Tanpa dependency state management berat, "
         "struktur folder jelas dan mudah dikembangkan."),
    ]

    cw = Inches(5.6)
    ch = Inches(1.22)
    for i, (t, d) in enumerate(items):
        col = i % 2
        row = i // 2
        x = Inches(0.9) + col * (cw + Inches(0.30))
        yy = y + Inches(0.05) + row * (ch + Inches(0.22))
        rrect(s, x, yy, cw, ch, fill=WHITE, line=LINE, radius=0.14)
        rect(s, x, yy, Inches(0.075), ch, fill=ORANGE)
        text(s, x + Inches(0.30), yy + Inches(0.18), cw - Inches(0.5),
             Inches(0.26), t, size=12.5, bold=True, color=INK)
        text(s, x + Inches(0.30), yy + Inches(0.50), cw - Inches(0.5),
             Inches(0.6), d, size=10, color=INK_SOFT, spacing=1.25)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 13 — KESIMPULAN
# ============================================================
def slide_conclusion(prs, num, total):
    s = blank(prs)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = CREAM
    y = section_header(s, "Penutup", "Kesimpulan",
                       "Rangkuman hasil pengerjaan project")

    rrect(s, Inches(0.9), y, Inches(11.5), Inches(1.35), fill=ORANGE_SOFT,
          radius=0.10)
    rect(s, Inches(0.9), y, Inches(0.075), Inches(1.35), fill=ORANGE)
    text(s, Inches(1.25), y + Inches(0.20), Inches(10.8), Inches(0.95),
         "ProfilKita berhasil mengimplementasikan aplikasi mobile Flutter "
         "yang menyatukan profil pengguna, jejaring sosial kampus, dan "
         "kalkulator dalam satu antarmuka bertema ITENAS, dengan Supabase "
         "sebagai backend.",
         size=12.5, color=INK, spacing=1.45)

    # Kiri: sudah selesai
    text(s, Inches(0.9), y + Inches(1.65), Inches(5.5), Inches(0.3),
         "Sudah Tercapai", size=13, bold=True, color=ORANGE)
    bullets(s, Inches(0.9), y + Inches(2.05), Inches(5.5), Inches(2.4), [
        "Splash, login, register berfungsi",
        "CRUD profil + upload foto",
        "Feed postingan teks & foto",
        "Komentar + counter otomatis",
        "Hapus postingan (RLS + cascade)",
        "Kalkulator dengan prioritas operasi",
        "Tema orange-putih ITENAS",
        "Skema database + storage siap pakai",
    ], size=10.5, gap=7)

    # Kanan: pengembangan lanjutan
    text(s, Inches(6.95), y + Inches(1.65), Inches(5.4), Inches(0.3),
         "Pengembangan Lanjutan", size=13, bold=True, color=ORANGE)
    bullets(s, Inches(6.95), y + Inches(2.05), Inches(5.4), Inches(2.4), [
        "Notifikasi realtime (Supabase Realtime)",
        "Pencarian & filter jurusan",
        "Edit postingan setelah dibagikan",
        "Hapus file storage saat post dihapus",
        "Halaman profil publik via deep link",
        "Mode offline dengan sinkronisasi",
    ], size=10.5, gap=7, bullet_color=INK_MUTED)

    footer_line(s)
    page_number(s, num, total)
    return s


# ============================================================
# SLIDE 14 — TERIMA KASIH
# ============================================================
def slide_thanks(prs):
    s = blank(prs)
    gradient_bg(s, ORANGE_LIGHT, ORANGE_DARK, 45)
    deco_circle(s, Inches(9.8), Inches(-1.5), Inches(4.8), WHITE, 92)
    deco_circle(s, Inches(-1.2), Inches(5.0), Inches(3.2), WHITE, 95)

    text(s, Inches(0.9), Inches(2.20), Inches(11), Inches(1.05),
         "TERIMA KASIH", size=52, bold=True, color=WHITE)
    rect(s, Inches(0.92), Inches(3.35), Inches(1.5), Inches(0.045), fill=WHITE)
    text(s, Inches(0.9), Inches(3.62), Inches(10), Inches(0.9),
         "Institut Teknologi Nasional Bandung", size=20,
         color=RGBColor(0xFF, 0xE8, 0xD8))
    text(s, Inches(0.9), Inches(4.35), Inches(10), Inches(1.0),
         "Tanya jawab & masukan sangat kami harapkan\n"
         "untuk pengembangan aplikasi selanjutnya.",
         size=13, color=RGBColor(0xFF, 0xF0, 0xE4), spacing=1.5)

    rrect(s, Inches(0.9), Inches(5.75), Inches(2.6), Inches(0.42),
          fill=None, line=WHITE, radius=0.5, line_w=1.2)
    text(s, Inches(0.9), Inches(5.84), Inches(2.6), Inches(0.26),
         "Flutter  •  Supabase", size=10.5, color=WHITE,
         align=PP_ALIGN.CENTER)
    return s


# ============================================================
# BUILD
# ============================================================
def main():
    prs = new_deck()

    total = 15
    slide_cover(prs)
    slide_agenda(prs, 2, total)
    slide_background(prs, 3, total)
    slide_goals(prs, 4, total)
    slide_features(prs, 5, total)
    slide_stack(prs, 6, total)
    slide_structure(prs, 7, total)
    slide_design(prs, 8, total)
    slide_database(prs, 9, total)
    slide_flow(prs, 10, total)
    slide_demo(prs, 11, total)
    slide_feed_features(prs, 12, total)
    slide_advantage(prs, 13, total)
    slide_conclusion(prs, 14, total)
    slide_thanks(prs)

    out = "Presentasi_ProfilKita_ITENAS.pptx"
    prs.save(out)
    print(f"Berhasil dibuat: {out}")
    print(f"Total slide: {len(prs.slides)}")


if __name__ == "__main__":
    main()
