#!/bin/bash
# Claude
set -euo pipefail

rm -rf $HOME/.cache/slider

# Script para generar videos con imágenes sincronizadas a párrafos de texto
# Uso: ./gen_auto.sh archivo_entrada.txt [archivo_salida.mp4]

if [ $# -lt 1 ]; then
    echo "Uso: $0 <archivo_de_entrada.txt> [archivo_salida.mp4]"
    echo ""
    echo "Formato del archivo:"
    echo "imagen1.jpg"
    echo "Texto del primer párrafo que se leerá con espeak."
    echo ""
    echo "imagen2.jpg"
    echo "Texto del segundo párrafo."
    echo ""
    exit 1
fi

INPUT_FILE="$1"
BASENAME=$(basename "$INPUT_FILE" .txt)
OUTPUT_VIDEO="${2:-${BASENAME}_final.mp4}"

# Directorio temporal único
TEMP_DIR="/tmp/gen_auto_$$"
WORK_DIR="$TEMP_DIR/work"

OUTPUT_TIMECODES="timecodes.txt"
OUTPUT_AUDIO="audio.wav"
OUTPUT_SRT="subtitles.srt"
TEMP_VIDEO="temp_video.mp4"

mkdir -p "$WORK_DIR"

echo "=== Procesando archivo: $INPUT_FILE ==="

# Guardar directorio actual
ORIGINAL_DIR=$(pwd)

# Arrays para guardar datos
declare -a images
declare -a texts
declare -a durations
declare -a audio_files

# Leer el archivo y separar imágenes de textos
current_image=""
current_text=""

while IFS= read -r line || [ -n "$line" ]; do
    # Línea vacía = separador
    if [ -z "$line" ]; then
        if [ -n "$current_image" ] && [ -n "$current_text" ]; then
            images+=("$current_image")
            texts+=("$current_text")
            current_image=""
            current_text=""
        fi
        continue
    fi
    
    # Si no hay imagen actual, esta línea es la imagen
    if [ -z "$current_image" ]; then
        current_image="$line"
    else
        # Agregar al texto (con espacio si ya hay texto)
        if [ -n "$current_text" ]; then
            current_text="$current_text $line"
        else
            current_text="$line"
        fi
    fi
done < "$INPUT_FILE"

# Agregar el último par si existe
if [ -n "$current_image" ] && [ -n "$current_text" ]; then
    images+=("$current_image")
    texts+=("$current_text")
fi

echo "=== Encontradas ${#images[@]} imágenes con sus párrafos ==="

# Verificar que todas las imágenes existen y copiarlas al directorio de trabajo
echo "=== Copiando imágenes al directorio de trabajo ==="
declare -a local_images

for i in "${!images[@]}"; do
    img="${images[$i]}"
    
    # Convertir ruta relativa a absoluta si es necesario
    if [[ "$img" != /* ]]; then
        img="$ORIGINAL_DIR/$img"
    fi
    
    if [ ! -f "$img" ]; then
        echo "ERROR: La imagen '$img' no existe!"
        exit 1
    fi
    
    # Copiar imagen al directorio de trabajo con nombre simple
    local_name="img_$(printf "%03d" $i).jpg"
    cp "$img" "$WORK_DIR/$local_name"
    local_images+=("$local_name")
    echo "  Copiada: $(basename "$img") -> $local_name"
done

# Cambiar al directorio de trabajo
cd "$WORK_DIR"

# Generar audios individuales y calcular duraciones exactas
echo "=== Generando audios individuales con espeak-ng ==="

current_time=0
srt_counter=1

# Inicializar archivo SRT
> "$OUTPUT_SRT"

# Crear lista de archivos de audio para concatenar
audio_list="audio_list.txt"
> "$audio_list"

for i in "${!texts[@]}"; do
    text="${texts[$i]}"
    
    # Crear audio para este párrafo
    audio_file="audio_$(printf "%03d" $i).wav"
    echo "$text" | espeak-ng -v es -w "$audio_file"
    
    audio_files+=("$audio_file")
    echo "file '$audio_file'" >> "$audio_list"
    
    # Obtener duración EXACTA en segundos con precisión decimal
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_file")
    
    # Convertir a enteros para los cálculos de tiempo (redondeando hacia arriba)
    duration_int=$(printf "%.0f" "$(echo "$duration + 0.5" | bc)")
    
    durations+=("$duration_int")
    
    # Calcular tiempo final
    end_time=$((current_time + duration_int))
    
    # Formatear tiempos para SRT
    start_srt=$(printf "%02d:%02d:%02d,000" $((current_time/3600)) $(((current_time/60)%60)) $((current_time%60)))
    end_srt=$(printf "%02d:%02d:%02d,000" $((end_time/3600)) $(((end_time/60)%60)) $((end_time%60)))
    
    # Agregar entrada al SRT
    echo "$srt_counter" >> "$OUTPUT_SRT"
    echo "$start_srt --> $end_srt" >> "$OUTPUT_SRT"
    echo "$text" >> "$OUTPUT_SRT"
    echo "" >> "$OUTPUT_SRT"
    
    srt_counter=$((srt_counter + 1))
    current_time=$end_time
    
    echo "  Párrafo ${i}: ${duration_int}s (exacto: ${duration}s)"
done

echo "=== Concatenando audios ==="
# Concatenar todos los audios en uno solo usando el método concat demuxer
ffmpeg -y -f concat -safe 0 -i "$audio_list" -c copy "$OUTPUT_AUDIO"

echo "=== Generando archivo de timecodes para slider ==="

# Generar archivo de timecodes con rutas locales
> "$OUTPUT_TIMECODES"
current_time=0

for i in "${!local_images[@]}"; do
    timestamp=$(printf "%02d:%02d:%02d" $((current_time/3600)) $(((current_time/60)%60)) $((current_time%60)))
    echo -e "$timestamp\t${local_images[$i]}" >> "$OUTPUT_TIMECODES"
    current_time=$((current_time + durations[$i]))
done

echo "=== Generando video con slider ==="
slider -i "$OUTPUT_TIMECODES" -a "$OUTPUT_AUDIO" -o "$TEMP_VIDEO"

echo "=== Quemando subtítulos ==="
ffmpeg -y -i "$TEMP_VIDEO" -vf "subtitles=$OUTPUT_SRT:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF&,OutlineColour=&H000000&,Outline=2,Shadow=1,MarginV=20'" -c:a copy "$ORIGINAL_DIR/$OUTPUT_VIDEO"

# Limpiar
cd "$ORIGINAL_DIR"
rm -rf "$TEMP_DIR"

echo ""
echo "=== ¡Video generado exitosamente! ==="
echo "Archivo: $OUTPUT_VIDEO"
echo ""
