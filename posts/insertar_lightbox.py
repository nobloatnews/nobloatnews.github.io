#!/usr/bin/env python3
"""
Inserta automaticamente <script src=".../lightbox.js" defer></script>
en TODOS los .html de tu sitio, justo antes de </body>, reutilizando
el mismo prefijo relativo ("../", "./", etc.) que cada pagina ya usa
para linkear su style.css. Si una pagina ya tiene el script, la salta.

Uso:
    python3 insertar_lightbox.py /ruta/a/tu/sitio

No modifica lightbox.js ni style.css: eso lo copias vos una sola vez
a la raiz del sitio (junto a style.css).
"""
import re
import sys
from pathlib import Path


def prefijo_relativo(html: str) -> str:
    m = re.search(r'href="([^"]*?)style\.css"', html)
    if m:
        href = m.group(1)
        return href[: -len("style.css")] if href.endswith("style.css") else ""
    return ""  # si no encuentra style.css, asume el mismo directorio


def procesar_archivo(path: Path):
    html = path.read_text(encoding="utf-8")
    if "lightbox.js" in html:
        print(f"  (ya tiene lightbox) {path}")
        return
    prefijo = prefijo_relativo(html)
    tag = f'  <script src="{prefijo}lightbox.js" defer></script>\n'
    nuevo_html, n = re.subn(r"</body>", tag + "</body>", html, count=1)
    if n == 0:
        print(f"  [!] no se encontro </body> en {path}")
        return
    path.write_text(nuevo_html, encoding="utf-8")
    print(f"  OK {path}")


def main():
    if len(sys.argv) != 2:
        print("Uso: python3 insertar_lightbox.py /ruta/a/tu/sitio")
        sys.exit(1)
    raiz = Path(sys.argv[1])
    archivos = list(raiz.rglob("*.html"))
    print(f"Encontrados {len(archivos)} archivos .html\n")
    for f in archivos:
        procesar_archivo(f)


if __name__ == "__main__":
    main()
