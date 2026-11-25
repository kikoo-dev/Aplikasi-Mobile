"""Konversi proposal DOCX ke PDF memakai Microsoft Word (COM).

Jalankan: python tools/export_proposal_pdf.py
"""
import os

import win32com.client

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOCX = os.path.join(ROOT, "Proposal_Aplikasi_ProfilKita_ITENAS.docx")
PDF = os.path.join(ROOT, "Proposal_Aplikasi_ProfilKita_ITENAS.pdf")


def main():
    if not os.path.exists(DOCX):
        print("File DOCX tidak ditemukan:", DOCX)
        return

    word = win32com.client.Dispatch("Word.Application")
    word.Visible = False
    try:
        doc = word.Documents.Open(DOCX, ReadOnly=False)
        # 17 = wdExportFormatPDF
        doc.ExportAsFixedFormat(PDF, 17)
        pages = doc.ComputeStatistics(2)  # 2 = wdStatisticPages
        words = doc.ComputeStatistics(0)  # 0 = wdStatisticWords
        doc.Close(SaveChanges=False)
        print(f"PDF dibuat: {PDF}")
        print(f"Halaman   : {pages}")
        print(f"Kata      : {words}")
        print(f"Ukuran    : {os.path.getsize(PDF)//1024} KB")
    finally:
        word.Quit()


if __name__ == "__main__":
    main()
