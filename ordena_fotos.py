#!/usr/bin/env python3
"""Lista las fotos .jpg de una carpeta ORDENADAS POR FECHA.

Orden de preferencia para la fecha:
  1) EXIF DateTimeOriginal (fecha real de la foto)
  2) La del nombre del archivo (IMG_AAAAMMDD_HHMMSS, IMG-AAAAMMDD-WAnnnn)
  3) La fecha de modificacion del archivo

Uso:  ordena_fotos.py /ruta/carpeta   ->  imprime una foto por linea (ruta completa)
"""
import os
import re
import sys
from datetime import datetime

try:
    from PIL import Image
    from PIL.ExifTags import TAGS
except ImportError:
    Image = None
    TAGS = {}


def fecha_exif(ruta):
    if Image is None:
        return None
    try:
        with Image.open(ruta) as im:
            exif = im._getexif()
    except Exception:
        return None
    if not exif:
        return None
    for tag in (36867, 36868, 306):  # DateTimeOriginal, DateTimeDigitized, DateTime
        if tag in exif:
            val = exif.get(tag)
            if isinstance(val, str):
                m = re.match(r"(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})", val)
                if m:
                    return datetime(*map(int, m.groups()))
    return None


def fecha_nombre(ruta):
    base = os.path.basename(ruta)
    m = re.search(r"(\d{8})(?:_(\d{6}))?", base)
    if not m:
        return None
    dia, hora = m.group(1), m.group(2) or "000000"
    try:
        return datetime(int(dia[0:4]), int(dia[4:6]), int(dia[6:8]),
                        int(hora[0:2]), int(hora[2:4]), int(hora[4:6]))
    except ValueError:
        return None


def clave(ruta):
    f = fecha_exif(ruta) or fecha_nombre(ruta)
    if f is None:
        return (1, os.stat(ruta).st_mtime, ruta)
    return (0, f.timestamp(), ruta)


def main():
    carpeta = sys.argv[1]
    fotos = []
    for raiz, _dirs, archivos in os.walk(carpeta):
        for a in archivos:
            if a.lower().endswith(".jpg") and not a.lower().endswith("_thumb.jpg"):
                fotos.append(os.path.join(raiz, a))
    for f in sorted(fotos, key=clave):
        print(f)


if __name__ == "__main__":
    main()
