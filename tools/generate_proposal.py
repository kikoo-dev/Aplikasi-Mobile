"""
Generator Proposal Aplikasi ProfilKita ITENAS (.docx)

Jalankan: python tools/generate_proposal.py
Output  : Proposal_Aplikasi_ProfilKita_ITENAS.docx
"""

import os

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

ORANGE = RGBColor(0xF2, 0x65, 0x22)
ORANGE_DARK = RGBColor(0xD1, 0x4E, 0x0E)
INK = RGBColor(0x24, 0x1A, 0x12)
INK_SOFT = RGBColor(0x6E, 0x61, 0x57)
GRAY = RGBColor(0x9E, 0x91, 0x89)

FONT = "Calibri"


# ============================================================
# HELPER
# ============================================================
def set_cell_bg(cell, hex_color):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_color)
    tc_pr.append(shd)


def set_cell_borders(cell, color="E0D8D0", size=4):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = OxmlElement("w:tcBorders")
    for edge in ("top", "left", "bottom", "right"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), str(size))
        el.set(qn("w:color"), color)
        borders.append(el)
    tc_pr.append(borders)


def add_para(doc, text="", size=11, bold=False, color=INK, align=None,
             space_before=0, space_after=6, italic=False, line=1.25,
             indent=None):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    pf = p.paragraph_format
    pf.space_before = Pt(space_before)
    pf.space_after = Pt(space_after)
    pf.line_spacing = line
    if indent is not None:
        pf.left_indent = Cm(indent)
    if text:
        run = p.add_run(text)
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.italic = italic
        run.font.color.rgb = color
        run.font.name = FONT
    return p


def add_heading(doc, text, level=1):
    sizes = {1: 15, 2: 12.5, 3: 11.5}
    color = ORANGE_DARK if level == 1 else ORANGE
    p = doc.add_paragraph()
    pf = p.paragraph_format
    pf.space_before = Pt(16 if level == 1 else 12)
    pf.space_after = Pt(7)
    pf.keep_with_next = True
    run = p.add_run(text)
    run.font.size = Pt(sizes.get(level, 11))
    run.font.bold = True
    run.font.color.rgb = color
    run.font.name = FONT
    return p


def add_bullet(doc, text, level=0, bold_prefix=None):
    p = doc.add_paragraph(style="List Bullet")
    pf = p.paragraph_format
    pf.space_before = Pt(0)
    pf.space_after = Pt(3)
    pf.line_spacing = 1.2
    pf.left_indent = Cm(0.75 + level * 0.6)
    if bold_prefix:
        r1 = p.add_run(bold_prefix)
        r1.font.bold = True
        r1.font.size = Pt(11)
        r1.font.color.rgb = INK
        r1.font.name = FONT
        r2 = p.add_run(text)
        r2.font.size = Pt(11)
        r2.font.color.rgb = INK_SOFT
        r2.font.name = FONT
    else:
        r = p.add_run(text)
        r.font.size = Pt(11)
        r.font.color.rgb = INK_SOFT
        r.font.name = FONT
    return p


def add_numbered(doc, text, bold_prefix=None):
    p = doc.add_paragraph(style="List Number")
    pf = p.paragraph_format
    pf.space_after = Pt(3)
    pf.line_spacing = 1.2
    pf.left_indent = Cm(0.75)
    if bold_prefix:
        r1 = p.add_run(bold_prefix)
        r1.font.bold = True
        r1.font.size = Pt(11)
        r1.font.color.rgb = INK
        r1.font.name = FONT
        r2 = p.add_run(text)
        r2.font.size = Pt(11)
        r2.font.color.rgb = INK_SOFT
        r2.font.name = FONT
    else:
        r = p.add_run(text)
        r.font.size = Pt(11)
        r.font.color.rgb = INK_SOFT
        r.font.name = FONT
    return p


def add_table(doc, headers, rows, widths=None, header_bg="F26522"):
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = "Table Grid"

    # Cegah baris tabel terpotong di tengah antar halaman
    for row in table.rows:
        tr_pr = row._tr.get_or_add_trPr()
        cant = OxmlElement("w:cantSplit")
        tr_pr.append(cant)

    # Ulangi baris header di setiap halaman
    hdr_row = table.rows[0]
    tr_pr = hdr_row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)

    hdr = table.rows[0].cells
    for i, h in enumerate(headers):
        hdr[i].text = ""
        set_cell_bg(hdr[i], header_bg)
        set_cell_borders(hdr[i])
        p = hdr[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.space_before = Pt(2)
        r = p.add_run(h)
        r.font.bold = True
        r.font.size = Pt(10)
        r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        r.font.name = FONT

    for ri, row in enumerate(rows):
        cells = table.add_row().cells
        for ci, val in enumerate(row):
            cells[ci].text = ""
            set_cell_borders(cells[ci])
            if ri % 2 == 1:
                set_cell_bg(cells[ci], "FDF7F3")
            p = cells[ci].paragraphs[0]
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.line_spacing = 1.15
            r = p.add_run(str(val))
            r.font.size = Pt(10)
            r.font.color.rgb = INK
            r.font.name = FONT

    if widths:
        for i, w in enumerate(widths):
            for row in table.rows:
                row.cells[i].width = Cm(w)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    return table


def add_callout(doc, title, body):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.rows[0].cells[0]
    set_cell_bg(cell, "FFF1E8")
    set_cell_borders(cell, "FFD9C2", 8)
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(title)
    r.font.bold = True
    r.font.size = Pt(10.5)
    r.font.color.rgb = ORANGE_DARK
    r.font.name = FONT

    p2 = cell.add_paragraph()
    p2.paragraph_format.space_after = Pt(4)
    p2.paragraph_format.line_spacing = 1.25
    r2 = p2.add_run(body)
    r2.font.size = Pt(10)
    r2.font.color.rgb = INK
    r2.font.name = FONT
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_hr(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(10)
    pPr = p._p.get_or_add_pPr()
    pbdr = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), "6")
    bottom.set(qn("w:color"), "E0D8D0")
    pbdr.append(bottom)
    pPr.append(pbdr)


def page_break(doc):
    doc.add_page_break()


# ============================================================
# DOKUMEN
# ============================================================
def main():
    doc = Document()

    # ---------- Setup halaman ----------
    section = doc.sections[0]
    section.page_width = Cm(21.0)
    section.page_height = Cm(29.7)
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(2.8)
    section.right_margin = Cm(2.2)

    style = doc.styles["Normal"]
    style.font.name = FONT
    style.font.size = Pt(11)
    style.font.color.rgb = INK

    # ========================================================
    # HALAMAN JUDUL
    # ========================================================
    add_para(doc, "PROPOSAL PROYEK APLIKASI MOBILE",
             size=12, bold=True, color=GRAY,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=4)
    add_para(doc, "", space_after=30)

    add_para(doc, "ProfilKita",
             size=40, bold=True, color=ORANGE,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "Aplikasi Profil Digital & Jejaring Kampus",
             size=16, bold=True, color=INK,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=10)
    add_para(doc,
             "Platform identitas digital mahasiswa berbasis Flutter dan Supabase\n"
             "untuk Institut Teknologi Nasional Bandung",
             size=11.5, color=INK_SOFT,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=40, line=1.4)

    add_callout(doc, "Ringkasan Singkat",
                "ProfilKita adalah aplikasi mobile yang menyatukan profil pribadi "
                "mahasiswa (biodata, about me, dan tautan sosial media) dengan feed "
                "sosial kampus yang memungkinkan mahasiswa berbagi postingan dan foto, "
                "saling berkomentar, serta berinteraksi — dilengkapi kalkulator sebagai "
                "alat bantu belajar. Seluruh data tersimpan di cloud melalui Supabase "
                "dengan pengamanan Row Level Security.")

    add_para(doc, "", space_after=50)

    add_para(doc, "Disusun oleh:", size=10.5, color=GRAY,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=6)
    add_para(doc, "Keyko Danu Tri Saputra", size=14, bold=True, color=INK,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "NIM: ..........................", size=11, color=INK_SOFT,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "Kelas: ........................", size=11, color=INK_SOFT,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=24)

    add_para(doc, "Mata Kuliah Pemrograman Mobile", size=11.5, bold=True,
             color=INK, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "Program Studi ..........................................",
             size=11, color=INK_SOFT,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "Fakultas Teknologi Industri", size=11, color=INK_SOFT,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "Institut Teknologi Nasional Bandung", size=12, bold=True,
             color=ORANGE_DARK, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=2)
    add_para(doc, "2026", size=11, color=INK_SOFT,
             align=WD_ALIGN_PARAGRAPH.CENTER, space_after=0)

    page_break(doc)

    # ========================================================
    # DAFTAR ISI
    # ========================================================
    add_heading(doc, "DAFTAR ISI", 1)
    add_para(doc, "Dokumen ini disusun dalam delapan bab berikut:",
             size=10.5, color=INK_SOFT, space_after=10)

    toc = [
        ("BAB I", "PENDAHULUAN",
         "Latar belakang, rumusan masalah, tujuan, dan manfaat"),
        ("BAB II", "DESKRIPSI APLIKASI",
         "Gambaran umum, target pengguna, dan fitur utama"),
        ("BAB III", "PERANCANGAN SISTEM",
         "Arsitektur, alur aplikasi, dan perancangan antarmuka"),
        ("BAB IV", "TEKNOLOGI YANG DIGUNAKAN",
         "Stack teknologi dan alasan pemilihan"),
        ("BAB V", "PERANCANGAN BASIS DATA & KEAMANAN",
         "Struktur tabel, Row Level Security, dan storage"),
        ("BAB VI", "IMPLEMENTASI",
         "Realisasi kode, statistik proyek, dan pengujian"),
        ("BAB VII", "RENCANA PENGEMBANGAN",
         "Jadwal pengerjaan dan pengembangan lanjutan"),
        ("BAB VIII", "PENUTUP",
         "Kesimpulan dan penutup"),
    ]
    add_table(doc, ["Bagian", "Judul", "Cakupan Pembahasan"], toc,
              widths=[2.2, 5.2, 7.8])

    add_para(doc, "", space_after=10)
    add_callout(doc, "Catatan Status Proyek",
                "Aplikasi ini sudah dalam tahap implementasi dan berjalan pada "
                "perangkat fisik (ASUS ROG Phone 3, Android 12), terhubung ke backend "
                "Supabase aktif. Proposal ini disusun sebagai dokumen pengajuan "
                "sekaligus laporan capaian sementara.")

    page_break(doc)

    # ========================================================
    # BAB I - PENDAHULUAN
    # ========================================================
    add_heading(doc, "BAB I — PENDAHULUAN", 1)

    add_heading(doc, "1.1 Latar Belakang", 2)
    add_para(doc,
             "Perkembangan teknologi mobile telah mengubah cara mahasiswa membangun "
             "identitas digitalnya. Namun, informasi tentang seorang mahasiswa saat ini "
             "masih tersebar di banyak platform yang tidak saling terhubung: biodata "
             "tersimpan di dokumen pribadi, aktivitas organisasi terdokumentasi di grup "
             "chat, portofolio tersebar di media sosial umum, dan capaian akademik "
             "terpisah di sistem kampus.",
             line=1.35, space_after=8)
    add_para(doc,
             "Kondisi ini menimbulkan beberapa persoalan. Pertama, mahasiswa kesulitan "
             "memperkenalkan diri secara utuh kepada pihak lain seperti dosen pembimbing, "
             "panitia kegiatan, atau mitra kerja sama. Kedua, kegiatan dan capaian "
             "mahasiswa cepat tenggelam dalam arus informasi grup chat sehingga tidak "
             "terdokumentasi dengan baik. Ketiga, tidak ada ruang khusus di tingkat "
             "kampus yang memungkinkan mahasiswa melihat aktivitas satu sama lain di luar "
             "media sosial umum yang bersifat publik luas.",
             line=1.35, space_after=8)
    add_para(doc,
             "Di sisi lain, lingkungan kampus Institut Teknologi Nasional Bandung memiliki "
             "identitas visual yang khas berupa kombinasi warna oranye dan putih. Identitas "
             "ini belum banyak diterapkan pada aplikasi digital internal yang dibuat oleh "
             "mahasiswa sendiri.",
             line=1.35, space_after=8)
    add_para(doc,
             "Berdasarkan uraian tersebut, penulis mengusulkan pengembangan aplikasi mobile "
             "bernama ProfilKita — sebuah aplikasi yang menyatukan profil digital mahasiswa "
             "berbasis identitas kampus dengan fitur jejaring sosial terbatas untuk "
             "lingkungan kampus, dilengkapi alat bantu hitung sebagai fungsi pendukung.",
             line=1.35, space_after=6)

    add_heading(doc, "1.2 Rumusan Masalah", 2)
    add_para(doc, "1. Bagaimana merancang aplikasi mobile yang dapat menyatukan biodata, "
                  "deskripsi diri, dan tautan sosial media mahasiswa dalam satu profil "
                  "digital yang rapi dan mudah dibagikan?",
             size=11, color=INK_SOFT, indent=0.75, space_after=3, line=1.2)
    add_para(doc, "2. Bagaimana menyediakan ruang berbagi aktivitas kampus berupa feed "
                  "postingan dan foto antar mahasiswa, lengkap dengan interaksi suka dan "
                  "komentar?",
             size=11, color=INK_SOFT, indent=0.75, space_after=3, line=1.2)
    add_para(doc, "3. Bagaimana mengimplementasikan backend yang aman sehingga data setiap "
                  "mahasiswa terlindungi dan tidak dapat diubah oleh pengguna lain?",
             size=11, color=INK_SOFT, indent=0.75, space_after=3, line=1.2)
    add_para(doc, "4. Bagaimana menerapkan identitas visual Institut Teknologi Nasional "
                  "Bandung secara konsisten pada seluruh antarmuka aplikasi?",
             size=11, color=INK_SOFT, indent=0.75, space_after=6, line=1.2)

    add_heading(doc, "1.3 Tujuan Proyek", 2)
    add_bullet(doc, "Membangun aplikasi mobile berbasis Flutter untuk platform Android "
                    "yang berfungsi sebagai profil digital mahasiswa.",
               bold_prefix="Tujuan Utama — ")
    add_bullet(doc, "menyediakan satu halaman profil yang memuat biodata lengkap, "
                    "deskripsi diri, foto profil, serta tautan Instagram, Facebook, dan TikTok.",
               bold_prefix="Tujuan Khusus 1 — ")
    add_bullet(doc, "menyediakan feed sosial kampus untuk berbagi postingan teks maupun "
                    "foto, dengan fitur suka, komentar, dan penghapusan postingan milik sendiri.",
               bold_prefix="Tujuan Khusus 2 — ")
    add_bullet(doc, "mengimplementasikan backend Supabase dengan autentikasi, basis data "
                    "relasional, penyimpanan berkas, dan pengamanan Row Level Security.",
               bold_prefix="Tujuan Khusus 3 — ")
    add_bullet(doc, "menerapkan tema oranye–putih beserta logo ITENAS secara konsisten "
                    "pada seluruh layar aplikasi.",
               bold_prefix="Tujuan Khusus 4 — ")
    add_bullet(doc, "menyediakan kalkulator dengan penerapan prioritas operasi matematika "
                    "yang benar serta riwayat perhitungan sebagai alat bantu belajar.",
               bold_prefix="Tujuan Khusus 5 — ")

    add_heading(doc, "1.4 Manfaat Proyek", 2)
    add_para(doc, "Bagi mahasiswa:", size=11, bold=True, color=INK, space_after=3)
    add_bullet(doc, "memiliki identitas digital yang terpusat dan mudah dibagikan")
    add_bullet(doc, "dapat mendokumentasikan kegiatan kampus dalam satu tempat")
    add_bullet(doc, "memperoleh alat bantu hitung yang lebih akurat daripada kalkulator "
                    "bawaan perangkat pada operasi bertingkat")

    add_para(doc, "Bagi institusi:", size=11, bold=True, color=INK,
             space_before=6, space_after=3)
    add_bullet(doc, "memperkuat identitas visual kampus melalui aplikasi buatan mahasiswa")
    add_bullet(doc, "menjadi contoh penerapan teknologi cloud dalam kegiatan akademik")
    add_bullet(doc, "membuka peluang pengembangan serupa untuk kebutuhan internal kampus")

    add_para(doc, "Bagi penulis:", size=11, bold=True, color=INK,
             space_before=6, space_after=3)
    add_bullet(doc, "menerapkan ilmu pemrograman mobile, basis data, dan keamanan aplikasi "
                    "secara terpadu dalam satu proyek nyata")

    page_break(doc)

    # ========================================================
    # BAB II - DESKRIPSI APLIKASI
    # ========================================================
    add_heading(doc, "BAB II — DESKRIPSI APLIKASI", 1)

    add_heading(doc, "2.1 Gambaran Umum", 2)
    add_para(doc,
             "ProfilKita adalah aplikasi mobile untuk platform Android yang dikembangkan "
             "menggunakan framework Flutter. Aplikasi ini berfungsi sebagai identitas "
             "digital mahasiswa yang menggabungkan tiga fungsi utama dalam satu antarmuka: "
             "profil pribadi, jejaring sosial kampus, dan kalkulator.",
             line=1.35, space_after=8)
    add_para(doc,
             "Seluruh data aplikasi disimpan pada layanan cloud Supabase yang mencakup "
             "autentikasi pengguna, basis data PostgreSQL, dan penyimpanan berkas gambar. "
             "Dengan demikian, data pengguna dapat diakses dari perangkat mana pun selama "
             "menggunakan akun yang sama.",
             line=1.35, space_after=8)

    add_heading(doc, "2.2 Target Pengguna", 2)
    add_table(doc,
              ["Segmen", "Karakteristik", "Kebutuhan Utama"],
              [
                  ["Mahasiswa aktif",
                   "Membutuhkan identitas digital untuk kegiatan akademik dan organisasi",
                   "Profil terpusat yang dapat dibagikan"],
                  ["Pengurus organisasi",
                   "Mengelola dokumentasi dan publikasi kegiatan",
                   "Feed untuk berbagi informasi & foto kegiatan"],
                  ["Mahasiswa baru",
                   "Sedang membangun relasi di lingkungan kampus",
                   "Melihat aktivitas dan profil mahasiswa lain"],
                  ["Umum (internal kampus)",
                   "Dosen, staf, atau panitia yang ingin mengenal mahasiswa",
                   "Akses cepat ke biodata dan capaian mahasiswa"],
              ],
              widths=[3.6, 6.0, 5.4])

    add_heading(doc, "2.3 Fitur Utama", 2)
    add_table(doc,
              ["No", "Fitur", "Deskripsi"],
              [
                  ["1", "Splash Screen",
                   "Layar pembuka beranimasi dengan logo ITENAS, sekaligus memeriksa "
                   "sesi login tersimpan sehingga pengguna tidak perlu masuk ulang."],
                  ["2", "Registrasi & Login",
                   "Pendaftaran akun dengan nama lengkap, username, email, dan password. "
                   "Tersedia validasi formulir, indikator kekuatan password, serta fitur "
                   "lupa password."],
                  ["3", "Edit Profil",
                   "Pengisian biodata lengkap (nama, username, telepon, tanggal lahir, "
                   "jenis kelamin, pekerjaan, alamat), unggah foto profil dari kamera atau "
                   "galeri, serta bio singkat dan deskripsi diri."],
                  ["4", "Sosial Media Terhubung",
                   "Menyimpan dan menampilkan tautan Instagram, Facebook, dan TikTok yang "
                   "dapat diketuk untuk langsung membuka aplikasi terkait."],
                  ["5", "Beranda / Feed Kampus",
                   "Umpan vertikal berisi postingan mahasiswa lain, menampilkan foto profil, "
                   "nama, jurusan, waktu unggah, teks, dan foto postingan."],
                  ["6", "Bagikan Postingan",
                   "Membuat postingan baru berisi teks dan/atau foto dari galeri maupun "
                   "kamera, langsung tersimpan ke cloud."],
                  ["7", "Komentar",
                   "Memberi dan membaca komentar pada setiap postingan, dengan penghitung "
                   "jumlah komentar yang diperbarui otomatis."],
                  ["8", "Hapus Postingan",
                   "Pemilik dapat menghapus postingannya sendiri melalui menu, dilengkapi "
                   "dialog konfirmasi. Komentar dan suka terkait ikut terhapus."],
                  ["9", "Kalkulator",
                   "Operasi dasar, persen, dan tanda kurung dengan penerapan prioritas "
                   "operasi matematika yang benar, serta riwayat perhitungan."],
              ],
              widths=[1.1, 4.0, 9.9])

    add_heading(doc, "2.4 Batasan Aplikasi", 2)
    add_para(doc, "Agar ruang lingkup proyek jelas, ditetapkan batasan berikut:",
             size=10.5, color=INK_SOFT, space_after=4)
    add_bullet(doc, "aplikasi dikembangkan khusus untuk platform Android; versi iOS dan web "
                    "belum menjadi fokus utama meskipun struktur kode sudah mendukung")
    add_bullet(doc, "verifikasi email saat pendaftaran dinonaktifkan untuk kebutuhan "
                    "pengembangan dan demonstrasi")
    add_bullet(doc, "feed menampilkan seluruh postingan pengguna tanpa penyaringan, "
                    "pencarian, atau pengelompokan berdasarkan jurusan")
    add_bullet(doc, "fitur edit postingan belum tersedia; pengguna hanya dapat menghapus "
                    "lalu membuat ulang")
    add_bullet(doc, "notifikasi waktu nyata belum diimplementasikan; pengguna memperbarui "
                    "feed secara manual")

    page_break(doc)

    # ========================================================
    # BAB III - PERANCANGAN SISTEM
    # ========================================================
    add_heading(doc, "BAB III — PERANCANGAN SISTEM", 1)

    add_heading(doc, "3.1 Arsitektur Aplikasi", 2)
    add_para(doc,
             "Aplikasi dibangun dengan arsitektur berlapis (layered architecture) yang "
             "memisahkan tanggung jawab setiap bagian kode. Pendekatan ini dipilih agar kode "
             "mudah dipelihara dan diuji.",
             line=1.35, space_after=8)
    add_table(doc,
              ["Lapisan", "Tanggung Jawab", "Komponen"],
              [
                  ["Presentation", "Menampilkan antarmuka dan menerima input pengguna",
                   "Screens, Widgets"],
                  ["State Management", "Menyimpan status aplikasi seperti sesi login dan "
                   "data profil", "AuthController (InheritedNotifier)"],
                  ["Service", "Menjembatani aplikasi dengan sumber data",
                   "SupabaseService, FeedService, DemoService"],
                  ["Data", "Model data dan konversi ke format basis data",
                   "UserProfile, FeedPost, PostComment"],
                  ["Backend", "Autentikasi, basis data, dan penyimpanan berkas",
                   "Supabase (Auth, PostgreSQL, Storage)"],
              ],
              widths=[3.2, 6.2, 5.6])

    add_para(doc, "Prinsip utama yang diterapkan:", size=11, bold=True,
             color=INK, space_before=4, space_after=3)
    add_bullet(doc, "lapisan antarmuka tidak pernah mengakses basis data secara langsung; "
                    "semua akses data melewati lapisan service",
               bold_prefix="Pemisahan tanggung jawab — ")
    add_bullet(doc, "aplikasi dapat berjalan tanpa backend melalui mode demo lokal, "
                    "sehingga tetap dapat didemonstrasikan saat konfigurasi belum tersedia",
               bold_prefix="Ketersediaan — ")
    add_bullet(doc, "komponen antarmuka seperti kartu, avatar, dan tombol dibuat sekali "
                    "lalu digunakan ulang di banyak layar",
               bold_prefix="Reusabilitas — ")

    add_heading(doc, "3.2 Alur Penggunaan Aplikasi", 2)
    add_para(doc, "Alur utama penggunaan aplikasi adalah sebagai berikut:",
             size=10.5, color=INK_SOFT, space_after=6)
    add_table(doc,
              ["Tahap", "Layar", "Aktivitas Pengguna"],
              [
                  ["1", "Splash Screen",
                   "Aplikasi menampilkan logo dan memeriksa sesi login tersimpan"],
                  ["2", "Login / Registrasi",
                   "Pengguna masuk dengan akun yang ada, atau membuat akun baru"],
                  ["3", "Beranda",
                   "Pengguna melihat feed kampus berisi postingan mahasiswa lain"],
                  ["4", "Berinteraksi",
                   "Memberi suka, berkomentar, membagikan postingan, atau menghapus "
                   "postingan sendiri"],
                  ["5", "Edit Profil",
                   "Melengkapi biodata, deskripsi diri, foto, dan tautan sosial media"],
                  ["6", "Profil Saya",
                   "Melihat hasil profil dan membuka tautan sosial media"],
                  ["7", "Kalkulator",
                   "Melakukan perhitungan dengan riwayat hasil"],
              ],
              widths=[1.4, 4.2, 9.6])

    add_heading(doc, "3.3 Perancangan Antarmuka", 2)
    add_para(doc,
             "Perancangan antarmuka mengikuti Design System Material 3 dengan penyesuaian "
             "identitas visual kampus. Beberapa ketentuan desain yang diterapkan:",
             line=1.35, space_after=6)

    add_table(doc,
              ["Aspek Visual", "Ketentuan"],
              [
                  ["Warna utama", "Oranye ITENAS #F26522"],
                  ["Warna turunan", "Oranye muda #FF9A4D, oranye tua #D14E0E, "
                                    "oranye lembut #FFF1E8"],
                  ["Warna latar", "Putih #FFFFFF dan krem #FFFAF6"],
                  ["Warna teks", "Cokelat gelap #241A12 untuk keterbacaan tinggi"],
                  ["Bentuk sudut", "Membulat 16–22 piksel pada kartu dan tombol"],
                  ["Tipografi", "Hierarki tegas dengan bobot tebal pada Judul"],
                  ["Logo", "Perisai dengan inisial ITN dan pita nama ITENAS"],
                  ["Mode gelap", "Mendukung tema gelap mengikuti pengaturan sistem"],
                  ["Responsif", "Tata letak menyesuaikan ukuran layar perangkat"],
              ],
              widths=[5.0, 11.0])

    add_heading(doc, "3.4 Perancangan Navigasi", 2)
    add_para(doc,
             "Navigasi antar layar dirancang sederhana dengan alur linear dan tanpa "
             "kedalaman berlebih. Dari beranda, pengguna dapat mengakses fitur melalui "
             "tombol pintas yang tersedia, sedangkan fitur tambahan seperti kalkulator dan "
             "edit profil tersedia melalui tombol pada bilah atas maupun menu pintas.",
             line=1.35, space_after=6)

    page_break(doc)

    # ========================================================
    # BAB IV - TEKNOLOGI
    # ========================================================
    add_heading(doc, "BAB IV — TEKNOLOGI YANG DIGUNAKAN", 1)

    add_heading(doc, "4.1 Stack Teknologi", 2)
    add_table(doc,
              ["Komponen", "Teknologi", "Versi", "Fungsi"],
              [
                  ["Framework UI", "Flutter", "3.47", "Membangun antarmuka cross-platform"],
                  ["Bahasa", "Dart", "3.13", "Bahasa pemrograman utama"],
                  ["Backend", "Supabase", "—", "Backend as a Service"],
                  ["Autentikasi", "Supabase Auth", "2.18", "Login, registrasi, sesi"],
                  ["Basis data", "PostgreSQL", "13+", "Penyimpanan data relasional"],
                  ["Penyimpanan", "Supabase Storage", "—", "Foto profil & foto postingan"],
                  ["Design System", "Material 3", "—", "Panduan & komponen UI"],
                  ["Penyimpanan lokal", "SharedPreferences", "2.5", "Sesi login di perangkat"],
                  ["Pengambil gambar", "image_picker", "1.2", "Akses kamera & galeri"],
                  ["Pembuka tautan", "url_launcher", "6.3", "Membuka aplikasi sosial media"],
                  ["Format tanggal", "intl", "0.20", "Format tanggal Indonesia"],
              ],
              widths=[3.4, 4.0, 2.0, 6.6])

    add_heading(doc, "4.2 Alasan Pemilihan Teknologi", 2)

    add_para(doc, "Flutter", size=11, bold=True, color=INK, space_after=2)
    add_para(doc,
             "Flutter dipilih karena memungkinkan satu basis kode untuk menghasilkan "
             "aplikasi dengan performa native. Komponen antarmuka yang kaya memudahkan "
             "penerapan desain bertema kampus secara konsisten. Ekosistem paketnya juga "
             "lengkap untuk kebutuhan seperti pengambilan gambar dan autentikasi.",
             size=10.5, color=INK_SOFT, line=1.3, space_after=7)

    add_para(doc, "Supabase", size=11, bold=True, color=INK, space_after=2)
    add_para(doc,
             "Supabase menyediakan autentikasi, basis data PostgreSQL, dan penyimpanan "
             "berkas dalam satu layanan. Hal ini menghilangkan kebutuhan membangun server "
             "terpisah, sehingga penulis dapat memusatkan perhatian pada logika aplikasi "
             "dan keamanan data. Fitur Row Level Security memungkinkan pembatasan akses "
             "data langsung pada tingkat basis data.",
             size=10.5, color=INK_SOFT, line=1.3, space_after=7)

    add_para(doc, "PostgreSQL melalui Supabase", size=11, bold=True, color=INK,
             space_after=2)
    add_para(doc,
             "Basis data relasional dipilih karena hubungan antar entitas cukup jelas — "
             "seorang pengguna memiliki satu profil dan banyak postingan, satu postingan "
             "memiliki banyak komentar dan banyak suka. Fitur seperti foreign key dengan "
             "cascade delete dan trigger sangat membantu menjaga konsistensi data.",
             size=10.5, color=INK_SOFT, line=1.3, space_after=7)

    add_heading(doc, "4.3 Kebutuhan Sistem", 2)
    add_para(doc,
             "Agar aplikasi dapat berjalan dengan baik, ditetapkan kebutuhan sistem "
             "minimum sebagai berikut:",
             size=10.5, color=INK_SOFT, space_after=5)
    add_table(doc,
              ["Kategori", "Kebutuhan Minimum"],
              [
                  ["Perangkat", "Android 7.0 (API 24) ke atas, arsitektur ARM64"],
                  ["Memori", "2 GB RAM"],
                  ["Ruang penyimpanan", "± 60 MB"],
                  ["Jaringan", "Koneksi internet untuk sinkronisasi data cloud"],
                  ["Izin aplikasi", "Akses internet, kamera, dan galeri foto"],
                  ["Lingkungan pengembangan", "Flutter SDK 3.47, Android SDK, Java 17"],
              ],
              widths=[5.0, 11.0])

    add_heading(doc, "4.4 Pertimbangan Arsitektur Klien-Server", 2)
    add_para(doc,
             "Karena seluruh data disimpan di cloud, aplikasi menerapkan pendekatan "
             "klien-server di mana perangkat hanya berperan sebagai penampil dan pengirim "
             "data. Konsekuensinya, aplikasi memerlukan koneksi internet untuk sebagian "
             "besar fungsinya. Untuk mengantisipasi kondisi tanpa koneksi pada saat "
             "demonstrasi, disediakan mode data lokal sebagai cadangan sehingga antarmuka "
             "tetap dapat ditampilkan meskipun backend belum terkonfigurasi.",
             line=1.35, space_after=6)

    page_break(doc)

    # ========================================================
    # BAB V - DATABASE & KEAMANAN
    # ========================================================
    add_heading(doc, "BAB V — PERANCANGAN BASIS DATA & KEAMANAN", 1)

    add_heading(doc, "5.1 Struktur Basis Data", 2)
    add_para(doc,
             "Basis data dirancang dengan lima komponen utama: empat tabel dan satu "
             "penyimpanan berkas. Hubungan antar tabel dirancang agar penghapusan data "
             "induk otomatis menghapus data turunannya.",
             line=1.35, space_after=8)

    add_para(doc, "Tabel profiles — menyimpan data profil pengguna",
             size=10.5, bold=True, color=ORANGE_DARK, space_after=3)
    add_table(doc,
              ["Kolom", "Tipe", "Keterangan"],
              [
                  ["id", "UUID", "Kunci utama, terhubung ke tabel autentikasi"],
                  ["email", "TEXT", "Alamat email pengguna"],
                  ["full_name", "TEXT", "Nama lengkap"],
                  ["username", "TEXT", "Nama pengguna, unik"],
                  ["phone", "TEXT", "Nomor telepon"],
                  ["bio", "TEXT", "Bio singkat"],
                  ["about_me", "TEXT", "Deskripsi diri panjang"],
                  ["address", "TEXT", "Alamat"],
                  ["occupation", "TEXT", "Pekerjaan atau jurusan"],
                  ["birth_date", "DATE", "Tanggal lahir"],
                  ["gender", "TEXT", "Jenis kelamin"],
                  ["avatar_url", "TEXT", "URL foto profil"],
                  ["instagram, facebook, tiktok", "TEXT", "Tautan sosial media"],
                  ["created_at, updated_at", "TIMESTAMPTZ", "Waktu dibuat & diubah"],
              ],
              widths=[5.0, 3.0, 8.0])

    add_para(doc, "Tabel posts — menyimpan postingan feed",
             size=10.5, bold=True, color=ORANGE_DARK, space_before=4, space_after=3)
    add_table(doc,
              ["Kolom", "Tipe", "Keterangan"],
              [
                  ["id", "UUID", "Kunci utama postingan"],
                  ["author_id", "UUID", "Pemilik postingan (foreign key ke profiles)"],
                  ["content", "TEXT", "Isi teks postingan"],
                  ["image_url", "TEXT", "URL foto postingan"],
                  ["like_count", "INTEGER", "Jumlah suka (diperbarui lewat fungsi)"],
                  ["comment_count", "INTEGER", "Jumlah komentar"],
                  ["created_at, updated_at", "TIMESTAMPTZ", "Waktu dibuat & diubah"],
              ],
              widths=[4.4, 3.0, 8.6])

    add_para(doc, "Tabel post_likes — menyimpan suka pengguna",
             size=10.5, bold=True, color=ORANGE_DARK, space_before=4, space_after=3)
    add_table(doc,
              ["Kolom", "Tipe", "Keterangan"],
              [
                  ["id", "UUID", "Kunci utama"],
                  ["post_id", "UUID", "Postingan yang disukai"],
                  ["user_id", "UUID", "Pengguna yang menyukai"],
                  ["(post_id, user_id)", "UNIQUE", "Mencegah suka ganda pada satu postingan"],
              ],
              widths=[4.4, 3.0, 8.6])

    add_para(doc, "Tabel post_comments — menyimpan komentar",
             size=10.5, bold=True, color=ORANGE_DARK, space_before=4, space_after=3)
    add_table(doc,
              ["Kolom", "Tipe", "Keterangan"],
              [
                  ["id", "UUID", "Kunci utama"],
                  ["post_id", "UUID", "Postingan yang dikomentari"],
                  ["author_id", "UUID", "Penulis komentar"],
                  ["content", "TEXT", "Isi komentar"],
                  ["created_at", "TIMESTAMPTZ", "Waktu komentar dibuat"],
              ],
              widths=[4.4, 3.0, 8.6])

    add_para(doc, "Penyimpanan berkas (Storage)",
             size=10.5, bold=True, color=ORANGE_DARK, space_before=4, space_after=3)
    add_table(doc,
              ["Bucket", "Isi", "Hak Akses"],
              [
                  ["avatars", "Foto profil pengguna", "Baca publik, unggah hanya oleh pemilik folder"],
                  ["posts", "Foto postingan feed", "Baca publik, unggah hanya oleh pemilik folder"],
              ],
              widths=[3.4, 5.0, 7.6])

    add_heading(doc, "5.2 Keamanan Data", 2)
    add_para(doc,
             "Keamanan data diterapkan melalui beberapa mekanisme pada tingkat basis data "
             "maupun aplikasi:",
             line=1.35, space_after=6)

    add_bullet(doc, "setiap tabel mengaktifkan Row Level Security sehingga pengguna hanya "
                    "dapat membaca data publik dan mengubah data miliknya sendiri. "
                    "Percobaan mengubah data pengguna lain akan ditolak oleh basis data.",
               bold_prefix="Row Level Security — ")
    add_bullet(doc, "saat pengguna mendaftar, sebuah trigger pada tabel autentikasi "
                    "otomatis membuatkan baris profil baru, sehingga tidak ada profil "
                    "yatim maupun profil ganda.",
               bold_prefix="Trigger pendaftaran — ")
    add_bullet(doc, "diterapkan pada kolom username untuk mencegah duplikasi tanpa "
                    "membedakan huruf besar dan kecil.",
               bold_prefix="Indeks unik — ")
    add_bullet(doc, "penghapusan postingan otomatis menghapus komentar dan suka terkait "
                    "melalui aturan cascade pada foreign key.",
               bold_prefix="Integritas relasional — ")
    add_bullet(doc, "jumlah suka dan komentar diperbarui melalui fungsi basis data "
                    "khusus agar nilai selalu konsisten.",
               bold_prefix="Fungsi penghitung — ")
    add_bullet(doc, "aplikasi hanya menyimpan kunci publik (anon key) pada sisi klien. "
                    "Kunci rahasia yang memiliki hak penuh tidak pernah disertakan dalam "
                    "aplikasi.",
               bold_prefix="Pemisahan kunci akses — ")

    add_heading(doc, "5.3 Penanganan Password", 2)
    add_para(doc,
             "Password pengguna tidak pernah disimpan dalam bentuk teks asli. Supabase "
             "Auth menyimpannya sebagai hash bcrypt yang bersifat satu arah, sehingga "
             "bahkan administrator basis data tidak dapat membaca password pengguna. "
             "Apabila pengguna lupa password, proses pemulihan dilakukan melalui tautan "
             "yang dikirim ke email terdaftar.",
             line=1.35, space_after=6)

    add_heading(doc, "5.4 Alur Penyimpanan Foto", 2)
    add_para(doc,
             "Saat pengguna mengunggah foto, aplikasi memeriksa terlebih dahulu ukuran "
             "berkas dengan batas maksimal lima megabita. Berkas yang lolos pemeriksaan "
             "diunggah ke bucket penyimpanan pada folder bernama sesuai identitas pengguna, "
             "sehingga kebijakan akses dapat membatasi unggahan hanya pada folder miliknya "
             "sendiri. Setelah unggahan berhasil, alamat publik berkas disimpan pada kolom "
             "yang sesuai di basis data, dan alamat itulah yang ditampilkan pada antarmuka.",
             line=1.35, space_after=6)

    # ========================================================
    # BAB VI - IMPLEMENTASI
    # ========================================================
    add_heading(doc, "BAB VI — IMPLEMENTASI", 1)

    add_heading(doc, "6.1 Struktur Kode", 2)
    add_para(doc,
             "Kode program disusun dalam struktur folder yang memisahkan tanggung jawab "
             "setiap bagian sebagai berikut:",
             line=1.35, space_after=6)
    add_table(doc,
              ["Folder", "Isi", "Jumlah Berkas"],
              [
                  ["lib/main.dart & app.dart", "Titik masuk aplikasi, konfigurasi tema", "2"],
                  ["core/", "Konfigurasi, tema, format, dan penyedia state global", "4"],
                  ["models/", "Model data profil, postingan, dan komentar", "4"],
                  ["services/", "Akses Supabase, mode demo, dan pengelola state", "4"],
                  ["screens/splash/", "Layar pembuka", "1"],
                  ["screens/auth/", "Layar login dan registrasi", "2"],
                  ["screens/home/", "Beranda feed dan halaman komentar", "2"],
                  ["screens/profile/", "Profil, edit profil, komponen sosial media", "3"],
                  ["screens/calculator/", "Kalkulator dan pengurai ekspresi matematika", "1"],
                  ["widgets/", "Komponen antarmuka yang dapat digunakan ulang", "5"],
              ],
              widths=[5.2, 8.2, 2.6])

    add_heading(doc, "6.2 Statistik Proyek", 2)
    add_table(doc,
              ["Metrik", "Jumlah"],
              [
                  ["Total berkas kode Dart", "28 berkas"],
                  ["Total baris kode", "± 7.700 baris"],
                  ["Layar aplikasi", "9 layar"],
                  ["Jumlah tabel basis data", "4 tabel"],
                  ["Jumlah bucket penyimpanan", "2 bucket"],
                  ["Paket pihak ketiga", "7 paket"],
                  ["Pemeriksaan kualitas kode (analyzer)", "0 masalah"],
              ],
              widths=[8.0, 8.0])

    add_heading(doc, "6.3 Pengujian yang Dilakukan", 2)
    add_para(doc,
             "Pengujian dilakukan pada tiga tingkat: pengujian otomatis pada basis data, "
             "pengujian antarmuka, serta pengujian langsung pada perangkat fisik. Hasil "
             "pengujian diringkas sebagai berikut:",
             line=1.35, space_after=6)
    add_table(doc,
              ["Area Pengujian", "Cakupan", "Hasil"],
              [
                  ["Autentikasi & Profil",
                   "Registrasi, pembuatan profil otomatis, penyimpanan biodata dan sosial "
                   "media, sesi login", "Lulus"],
                  ["Penyimpanan Berkas",
                   "Unggah foto profil dan foto postingan, akses publik foto", "Lulus"],
                  ["Bagikan & Feed",
                   "Membuat postingan teks maupun foto, menampilkan feed", "Lulus"],
                  ["Komentar",
                   "Menambah komentar, membaca daftar, penghitung otomatis", "Lulus"],
                  ["Hapus Postingan",
                   "Penghapusan oleh pemilik, penolakan terhadap pengguna lain, "
                   "penghapusan komentar dan suka terkait", "Lulus"],
                  ["Keamanan Akses",
                   "Pengguna lain ditolak saat mencoba menghapus data bukan miliknya",
                   "Lulus"],
                  ["Kalkulator",
                   "Prioritas operasi, tanda kurung, persen, riwayat", "Lulus"],
                  ["Kualitas Kode",
                   "Pemeriksaan statis dan pengujian antarmuka otomatis", "Lulus"],
              ],
              widths=[4.4, 9.4, 2.2])

    add_heading(doc, "6.4 Perangkat Pengujian", 2)
    add_para(doc,
             "Aplikasi telah dipasang dan diuji pada perangkat ASUS ROG Phone 3 "
             "(Android 12, arsitektur ARM64). Pengujian mencakup alur lengkap mulai dari "
             "splash screen, registrasi, pengisian profil, unggah foto, membuat postingan, "
             "berkomentar, hingga menghapus postingan.",
             line=1.35, space_after=6)

    add_callout(doc, "Kendala Teknis yang Berhasil Diatasi",
                "Pada tahap pengujian ditemukan bahwa berkas aplikasi versi rilis "
                "mengalami kegagalan saat dibuka akibat proses optimasi kode (R8) yang "
                "merusak tanda tangan metode pada salah satu paket pustaka. Permasalahan "
                "ini diidentifikasi melalui pembacaan log perangkat dan diselesaikan "
                "dengan menonaktifkan proses tersebut, lalu disertai dokumentasi agar "
                "tidak terulang. Kasus ini menunjukkan pentingnya pengujian pada versi "
                "rilis, bukan hanya versi pengembangan.")

    page_break(doc)

    # ========================================================
    # BAB VII - RENCANA
    # ========================================================
    add_heading(doc, "BAB VII — RENCANA PENGEMBANGAN", 1)

    add_heading(doc, "7.1 Tahapan Pengerjaan", 2)
    add_table(doc,
              ["Tahap", "Kegiatan", "Status"],
              [
                  ["1", "Studi kebutuhan dan penetapan ruang lingkup", "Selesai"],
                  ["2", "Perancangan alur aplikasi dan skema basis data", "Selesai"],
                  ["3", "Pembangunan antarmuka dan tema visual", "Selesai"],
                  ["4", "Integrasi autentikasi dan profil pengguna", "Selesai"],
                  ["5", "Pembangunan feed, komentar, dan interaksi sosial", "Selesai"],
                  ["6", "Penyimpanan berkas dan pengamanan akses data", "Selesai"],
                  ["7", "Pengujian pada perangkat fisik dan perbaikan", "Selesai"],
                  ["8", "Penyempurnaan dokumentasi dan laporan akhir", "Berjalan"],
                  ["9", "Penyusunan berkas siap distribusi (signing, ikon)", "Rencana"],
              ],
              widths=[1.4, 12.2, 2.4])

    add_heading(doc, "7.2 Rencana Pengembangan Lanjutan", 2)
    add_para(doc, "Beberapa pengembangan yang direncanakan setelah proyek ini:",
             size=10.5, color=INK_SOFT, space_after=4)
    add_bullet(doc, "notifikasi waktu nyata untuk komentar dan postingan baru menggunakan "
                    "Supabase Realtime")
    add_bullet(doc, "pencarian dan penyaringan postingan berdasarkan jurusan atau kata kunci")
    add_bullet(doc, "fitur edit postingan tanpa harus menghapus dan membuat ulang")
    add_bullet(doc, "penghapusan berkas foto dari penyimpanan ketika postingan dihapus, "
                    "agar tidak menumpuk")
    add_bullet(doc, "halaman profil publik yang dapat diakses melalui tautan langsung")
    add_bullet(doc, "mode luring dengan sinkronisasi otomatis saat koneksi kembali tersedia")
    add_bullet(doc, "pengembangan versi iOS dan web yang optimal")

    add_heading(doc, "7.3 Rencana Distribusi", 2)
    add_para(doc,
             "Untuk keperluan demonstrasi dan penilaian, aplikasi akan didistribusikan "
             "dalam bentuk berkas APK yang dapat dipasang langsung pada perangkat Android. "
             "Berkas APK ditandatangani dengan kunci pengembangan sehingga hanya sesuai "
             "untuk keperluan demonstrasi, bukan publikasi resmi. Apabila aplikasi akan "
             "dipublikasikan melalui Google Play Store, diperlukan pembuatan kunci "
             "penandatanganan resmi terlebih dahulu.",
             line=1.35, space_after=6)

    page_break(doc)

    # ========================================================
    # BAB VIII - PENUTUP
    # ========================================================
    add_heading(doc, "BAB VIII — PENUTUP", 1)

    add_heading(doc, "8.1 Kesimpulan", 2)
    add_para(doc,
             "ProfilKita merupakan aplikasi mobile yang mengintegrasikan profil digital "
             "mahasiswa, jejaring sosial kampus, dan kalkulator dalam satu antarmuka "
             "beridentitas Institut Teknologi Nasional Bandung. Aplikasi dikembangkan "
             "dengan Flutter di sisi klien dan Supabase sebagai backend yang menangani "
             "autentikasi, basis data, serta penyimpanan berkas.",
             line=1.35, space_after=8)
    add_para(doc,
             "Berdasarkan implementasi dan pengujian yang telah dilakukan, seluruh tujuan "
             "utama proyek telah tercapai. Aplikasi berjalan pada perangkat fisik, mampu "
             "menyimpan dan menampilkan data secara terpusat, serta dilengkapi pengamanan "
             "akses sampai pada tingkat basis data. Proyek ini juga memberikan pembelajaran "
             "bahwa pengujian pada versi rilis, penanganan kesalahan yang informatif, dan "
             "pemisahan tanggung jawab antarlapisan kode merupakan bagian penting dari "
             "sebuah aplikasi yang siap digunakan.",
             line=1.35, space_after=8)

    add_heading(doc, "8.2 Harapan", 2)
    add_para(doc,
             "Penulis berharap aplikasi ini dapat bermanfaat sebagai identitas digital "
             "mahasiswa serta menjadi contoh penerapan teknologi cloud dalam kegiatan "
             "akademik. Penulis juga terbuka terhadap masukan, saran, dan arahan dari dosen "
             "pengampu agar aplikasi dapat dikembangkan lebih baik ke depannya.",
             line=1.35, space_after=20)

    add_hr(doc)
    add_para(doc, "Bandung, ........................ 2026",
             size=11, color=INK, align=WD_ALIGN_PARAGRAPH.RIGHT, space_after=30)
    add_para(doc, "Mengetahui,",
             size=11, color=INK_SOFT, align=WD_ALIGN_PARAGRAPH.LEFT, space_after=2)
    add_para(doc, "Dosen Pengampu",
             size=11, color=INK_SOFT, align=WD_ALIGN_PARAGRAPH.LEFT, space_after=40)
    add_para(doc, "..............................................",
             size=11, color=INK, align=WD_ALIGN_PARAGRAPH.LEFT, space_after=2)
    add_para(doc, "NIP. ......................................",
             size=10.5, color=INK_SOFT, align=WD_ALIGN_PARAGRAPH.LEFT, space_after=0)

    # ---------- Simpan ----------
    out = os.path.join(ROOT, "Proposal_Aplikasi_ProfilKita_ITENAS.docx")
    doc.save(out)
    print(f"Berhasil dibuat: {out}")
    print(f"Total paragraf: {len(doc.paragraphs)}")
    print(f"Total tabel: {len(doc.tables)}")


if __name__ == "__main__":
    main()
