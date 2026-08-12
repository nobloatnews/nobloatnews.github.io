#!/bin/bash
# ---------------------------------------------------------------------------
# subtitular_audios.sh
#
# Automatiza la parte manual de: subir audios .m4a a YouTube (como video con
# una imagen fija), esperar a que YouTube genere los subtítulos automáticos,
# bajarlos con yt-dlp, limpiarlos y concatenarlos EN ORDEN en un solo archivo
# "subtitulos.txt" dentro de la carpeta del post.
#
# Lo que NO hace (a propósito): no genera el resumen con ChatGPT. Eso lo
# seguís haciendo vos: pegás "subtitulos.txt" en ChatGPT/Grok/NotebookLM,
# guardás el resumen como "script" en la misma carpeta, y ahí sí corrés
# new.sh normalmente.
#
# Se puede cortar con Ctrl+C en cualquier momento (por ejemplo mientras
# espera los subtítulos) y volver a correr el script más tarde: retoma
# donde quedó gracias al archivo de estado .youtube_subs_state.tsv
# ---------------------------------------------------------------------------
set -uo pipefail   # OJO: sin -e a propósito, acá manejamos los errores a mano

intervalo_minutos=5   # cada cuánto reintenta bajar subtítulos pendientes
umbral_silencio_db="-30dB"   # qué tan fuerte tiene que sonar para no considerarse silencio
duracion_min_silencio="0.5"  # segundos mínimos de silencio para contarlo como tal
recorte_maximo_seg="15"      # tope de seguridad: si "detecta" más que esto, no recorta nada

for cmd in ffmpeg yt-dlp fzf thumbnailg; do
  command -v "$cmd" >/dev/null || { echo "Falta $cmd"; exit 1; }
done
[ -x "$HOME/youtube-upload/youtube-upload/bin/youtube-upload" ] || { echo "No encuentro youtube-upload en \$HOME/youtube-upload"; exit 1; }

base_dir="$HOME/samba"   # misma carpeta base que new.sh
[ -d "$base_dir" ] || { echo "No existe $base_dir"; exit 1; }

img_dir=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | fzf --prompt="Carpeta del post> ") || true
[ -n "${img_dir:-}" ] || { echo "No se eligió carpeta. Abortando."; exit 1; }

nombre_archivo=$(basename "$img_dir" | iconv -t ascii//TRANSLIT 2>/dev/null | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

state_file="$img_dir/.youtube_subs_state.tsv"
cache_dir="$img_dir/.subs_cache"
mkdir -p "$cache_dir"
[ -f "$state_file" ] || : > "$state_file"

# ---------------------------------------------------------------------------
# 1) Elegir y subir audios nuevos (los que ya están en el estado se excluyen)
# ---------------------------------------------------------------------------
ya_registrados() { cut -f2 "$state_file" 2>/dev/null; }

detectar_inicio_audio() {
  # Devuelve en segundos dónde empieza a haber sonido real (silencedetect de ffmpeg).
  # Si no encuentra silencio inicial, o si lo que detecta es sospechosamente largo,
  # devuelve 0 (no recortar) en vez de arriesgarse a comerse audio real.
  local archivo="$1"
  local analisis inicio
  analisis=$(ffmpeg -i "$archivo" -af "silencedetect=noise=${umbral_silencio_db}:d=${duracion_min_silencio}" -f null - 2>&1) || true
  inicio=$(printf '%s\n' "$analisis" | grep -oE 'silence_end: [0-9.]+' | head -1 | awk '{print $2}')
  if [ -z "$inicio" ]; then
    echo "0"
    return
  fi
  awk -v i="$inicio" -v tope="$recorte_maximo_seg" 'BEGIN {
    r = i - 0.3            # colchón para no comerse la primera sílaba
    if (r < 0) r = 0
    if (r > tope) r = 0    # tope de seguridad ante una detección rara
    printf "%.2f", r
  }'
}

mapfile -t candidatos < <(find "$img_dir" -maxdepth 1 -type f \( -iname '*.m4a' -o -iname '*.mp3' -o -iname '*.wav' \) -printf '%f\n' 2>/dev/null | sort)

# sacar de la lista los que ya están registrados (subidos en una corrida anterior)
if [ -f "$state_file" ] && [ -s "$state_file" ]; then
  mapfile -t ya < <(ya_registrados)
  restantes=()
  for c in "${candidatos[@]}"; do
    encontrado=0
    for r in "${ya[@]}"; do [ "$c" = "$r" ] && encontrado=1 && break; done
    [ "$encontrado" -eq 0 ] && restantes+=("$c")
  done
  candidatos=("${restantes[@]}")
fi

if [ -s "$state_file" ]; then
  ultimo_orden=$(cut -f1 "$state_file" | sort -n | tail -1)
  siguiente_orden=$((ultimo_orden + 1))
else
  siguiente_orden=1
fi

if [ "${#candidatos[@]}" -gt 0 ]; then
  echo "Subo automáticamente ${#candidatos[@]} audio(s) sin procesar, en orden alfabético: ${candidatos[*]}"
  for elegido in "${candidatos[@]}"; do
    audio_path="$img_dir/$elegido"
    slug_video="${nombre_archivo}-audio-${siguiente_orden}"
    titulo_legible="$nombre_archivo audio $siguiente_orden"

    echo "-> Generando thumbnail y video para '$elegido'..."
    rm -f "/tmp/${slug_video}.png" "/tmp/${slug_video}.mp4"   # no arrastrar sobras de una corrida anterior

    thumb_err=$(cd /tmp && thumbnailg "$titulo_legible" "/tmp/${slug_video}.png" 2>&1 >/dev/null) || true
    if [ ! -s "/tmp/${slug_video}.png" ]; then
      echo "   No se pudo generar el thumbnail para '$elegido', lo salteo. Error:"
      echo "$thumb_err" | sed 's/^/   /'
      continue
    fi

    echo "-> Analizando silencio inicial de '$elegido'..."
    inicio_recorte=$(detectar_inicio_audio "$audio_path")
    if awk -v i="$inicio_recorte" 'BEGIN{exit !(i>0)}'; then
      echo "   Recorto los primeros ${inicio_recorte}s de silencio antes de subir."
    fi

    ffmpeg_err=$(ffmpeg -y -i "/tmp/${slug_video}.png" -ss "$inicio_recorte" -i "$audio_path" -c:v libx264 -tune stillimage -c:a copy "/tmp/${slug_video}.mp4" 2>&1 >/dev/null) || true
    if [ ! -s "/tmp/${slug_video}.mp4" ]; then
      echo "   No se pudo generar el video para '$elegido', lo salteo. Error:"
      echo "$ffmpeg_err" | sed 's/^/   /'
      continue
    fi

    echo "-> Subiendo '$elegido' a YouTube..."
    source "$HOME/youtube-upload/bin/activate"
    salida_upload=$("$HOME/youtube-upload/youtube-upload/bin/youtube-upload" \
      --title="$titulo_legible" \
      --description="Audio $siguiente_orden de $nombre_archivo - generado automáticamente para subtítulos." \
      --default-language="es" \
      --default-audio-language="es" \
      --privacy="unlisted" \
      --embeddable=True \
      "/tmp/${slug_video}.mp4" 2>&1)
    estado_upload=$?
    deactivate 2>/dev/null || true

    video_id=$(printf '%s\n' "$salida_upload" | grep -oE 'watch\?v=[A-Za-z0-9_-]+' | tail -1 | sed 's/^watch?v=//')

    if [ "$estado_upload" -ne 0 ] || [ -z "$video_id" ]; then
      echo "   No pude subir '$elegido' (código de salida $estado_upload), lo dejo para reintentar a mano después. Salida:"
      printf '%s\n' "$salida_upload" | tail -8 | sed 's/^/   /'
      continue
    fi

    printf '%s\t%s\t%s\t%s\n' "$siguiente_orden" "$elegido" "$video_id" "PENDIENTE" >> "$state_file"
    echo "   Subido y confirmado (código $estado_upload) como $video_id."
    siguiente_orden=$((siguiente_orden + 1))
  done
else
  echo "No hay audios nuevos sin procesar en $img_dir."
fi

# ---------------------------------------------------------------------------
# 2) Esperar y bajar subtítulos de todo lo PENDIENTE (de esta corrida o de antes)
# ---------------------------------------------------------------------------
intentar_bajar_pendientes() {
  quedan_pendientes=0
  tmp_state="$state_file.tmp"
  : > "$tmp_state"
  while IFS=$'\t' read -r orden archivo video_id estado; do
    [ -z "${orden:-}" ] && continue
    if [ "$estado" = "PENDIENTE" ]; then
      salida="/tmp/subs_${video_id}"
      yt-dlp --ignore-config --write-auto-sub --no-write-subs --sub-lang es --sub-format "srt" \
        --skip-download "https://www.youtube.com/watch?v=$video_id" -o "$salida" >/dev/null 2>&1 || true

      srt_encontrado=$(find /tmp -maxdepth 1 -name "subs_${video_id}.es.srt" -size +0c 2>/dev/null | head -1)
      if [ -n "$srt_encontrado" ]; then
        sed -E '/^[0-9]+$|^$/d; /^[0-9]{2}:/d' "$srt_encontrado" > "$cache_dir/${video_id}.txt"
        rm -f "$srt_encontrado"
        estado="LISTO"
        echo "   Listo: $archivo ($video_id)"
      else
        quedan_pendientes=1
      fi
    fi
    printf '%s\t%s\t%s\t%s\n' "$orden" "$archivo" "$video_id" "$estado" >> "$tmp_state"
  done < "$state_file"
  mv "$tmp_state" "$state_file"
}

if grep -q "PENDIENTE" "$state_file" 2>/dev/null; then
  echo "Esperando subtítulos de YouTube (reintento cada $intervalo_minutos min, Ctrl+C para pausar y retomar después)..."
  while true; do
    intentar_bajar_pendientes
    if [ "$quedan_pendientes" -eq 0 ]; then
      break
    fi
    echo "   Todavía faltan algunos. Reintento en $intervalo_minutos minutos..."
    sleep "$((intervalo_minutos * 60))"
  done
fi

# ---------------------------------------------------------------------------
# 3) Armar subtitulos.txt en el orden elegido
# ---------------------------------------------------------------------------
if [ -s "$state_file" ]; then
  salida_txt="$img_dir/subtitulos.txt"
  : > "$salida_txt"
  sort -n -t $'\t' -k1 "$state_file" | while IFS=$'\t' read -r orden archivo video_id estado; do
    [ "$estado" = "LISTO" ] || continue
    cat "$cache_dir/${video_id}.txt" >> "$salida_txt"
    echo "" >> "$salida_txt"
  done
  echo "-----------------------------------------"
  echo "Listo: $salida_txt"
  echo "Pegalo en ChatGPT/Grok/NotebookLM, guardá el resumen como:"
  echo "  $img_dir/script"
  echo "y después corré new.sh como siempre."
  echo "-----------------------------------------"

  if command -v falkon >/dev/null; then
    falkon "$salida_txt" >/dev/null 2>&1 &
    disown
  else
    echo "(No encontré 'falkon' instalado, no pude abrirlo automáticamente.)"
  fi
else
  echo "No hay nada procesado todavía."
fi
