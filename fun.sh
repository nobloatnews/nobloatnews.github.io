# Este script crea un video con imágenes pero las imágenes están coordinadas
# con el texto.
#!/bin/bash
set -euo pipefail

rm -rf $HOME/.cache/slider

if [ $# -lt 1 ]; then
    echo "Uso: $0 <archivo_de_entrada.txt> [archivo_salida.mp4]"
    echo ""
    echo "Formato del archivo:"
    echo "imagen1.jpg"
    echo "Texto del primer párrafo que se leerá con espeak."
    echo ""
    echo "imagen2.jpg"
    echo "Texto del segundo párrafo."
    exit 1
fi

INPUT_FILE="$1"
BASENAME=$(basename "$INPUT_FILE" .txt)
OUTPUT_VIDEO="${2:-${BASENAME}_final.mp4}"

TEMP_DIR="/tmp/gen_auto_$$"
WORK_DIR="$TEMP_DIR/work"

mkdir -p "$WORK_DIR"

echo "=== Procesando archivo: $INPUT_FILE ==="

ORIGINAL_DIR=$(pwd)

declare -a images
declare -a texts

current_image=""
current_text=""

while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$line" ]; then
        if [ -n "$current_image" ] && [ -n "$current_text" ]; then
            images+=("$current_image")
            texts+=("$current_text")
            current_image=""
            current_text=""
        fi
        continue
    fi
    
    if [ -z "$current_image" ]; then
        current_image="$line"
    else
        if [ -n "$current_text" ]; then
            current_text="$current_text $line"
        else
            current_text="$line"
        fi
    fi
done < "$INPUT_FILE"

if [ -n "$current_image" ] && [ -n "$current_text" ]; then
    images+=("$current_image")
    texts+=("$current_text")
fi

echo "=== Encontradas ${#images[@]} imágenes ==="

cd "$WORK_DIR"

# ====================================
# PASO 1: Generar audios individuales
# ====================================
echo "=== Generando audios individuales ==="
declare -a audio_files
declare -a durations

for i in "${!texts[@]}"; do
    audio_file="audio_$(printf "%03d" $i).wav"
    echo "${texts[$i]}" | espeak-ng -v es -w "$audio_file"
    audio_files+=("$audio_file")
    
    # Obtener duración EXACTA con decimales
    duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$audio_file")
    durations+=("$duration")
    
    echo "  Audio $i: ${duration}s"
done

# ====================================
# PASO 2: Concatenar audios
# ====================================
echo "=== Concatenando audios ==="
concat_list="concat_list.txt"
> "$concat_list"

for audio in "${audio_files[@]}"; do
    echo "file '$audio'" >> "$concat_list"
done

ffmpeg -y -f concat -safe 0 -i "$concat_list" -c copy "audio_full.wav"

# ====================================
# PASO 3: Generar timecodes y SRT
# ====================================
echo "=== Generando timecodes y subtítulos ==="

timecodes_file="timecodes.txt"
srt_file="subtitles.srt"

> "$timecodes_file"
> "$srt_file"

current_time=0
srt_counter=1

for i in "${!images[@]}"; do
    img="${images[$i]}"
    
    # Convertir a ruta absoluta
    if [[ "$img" != /* ]]; then
        img="$ORIGINAL_DIR/$img"
    fi
    
    if [ ! -f "$img" ]; then
        echo "ERROR: Imagen no existe: $img"
        exit 1
    fi
    
    # Calcular timestamp
    hours=$(awk "BEGIN {printf \"%02d\", int($current_time/3600)}")
    minutes=$(awk "BEGIN {printf \"%02d\", int(($current_time%3600)/60)}")
    seconds=$(awk "BEGIN {printf \"%02d\", int($current_time%60)}")
    
    timestamp="$hours:$minutes:$seconds"
    
    # Escribir timecode
    echo -e "$timestamp\t$img" >> "$timecodes_file"
    
    # Calcular tiempo final para SRT
    end_time=$(awk "BEGIN {print $current_time + ${durations[$i]}}")
    
    # Formatear para SRT (con milisegundos)
    start_ms=$(awk "BEGIN {printf \"%02d:%02d:%06.3f\", int($current_time/3600), int(($current_time%3600)/60), $current_time%60}" | tr '.' ',')
    end_ms=$(awk "BEGIN {printf \"%02d:%02d:%06.3f\", int($end_time/3600), int(($end_time%3600)/60), $end_time%60}" | tr '.' ',')
    
    # Escribir entrada SRT
    echo "$srt_counter" >> "$srt_file"
    echo "$start_ms --> $end_ms" >> "$srt_file"
    echo "${texts[$i]}" >> "$srt_file"
    echo "" >> "$srt_file"
    
    srt_counter=$((srt_counter + 1))
    current_time=$end_time
done

# ====================================
# PASO 4: Generar video con slider
# ====================================
echo "=== Generando video con slider ==="
slider -i "$timecodes_file" -a "audio_full.wav" -o "temp_video.mp4"

# ====================================
# PASO 5: Quemar subtítulos
# ====================================
echo "=== Añadiendo subtítulos ==="
ffmpeg -y -i "temp_video.mp4" \
    -vf "subtitles=$srt_file:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF&,OutlineColour=&H000000&,Outline=2,Shadow=1,MarginV=20'" \
    -c:a copy "$ORIGINAL_DIR/$OUTPUT_VIDEO"

cd "$ORIGINAL_DIR"
rm -rf "$TEMP_DIR"

echo ""
echo "=== ¡Completado! ==="
echo "Video: $OUTPUT_VIDEO"
echo ""
