#!/bin/bash
set -euo pipefail

# Función para convertir milisegundos a formato SRT (HH:MM:SS,mmm)
ms_to_srt_time() {
    local ms=$1
    local hours=$((ms / 3600000))
    ms=$((ms % 3600000))
    local minutes=$((ms / 60000))
    ms=$((ms % 60000))
    local seconds=$((ms / 1000))
    local milliseconds=$((ms % 1000))
    printf "%02d:%02d:%02d,%03d" $hours $minutes $seconds $milliseconds
}

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Uso: $0 <archivo_entrada.txt> <archivo_salida.srt> [duracion_fija_ms]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 texto.txt subs.srt          # Usa tiempos de los breaks + habla estimada"
    echo "  $0 texto.txt subs.srt 5000     # Cada subtítulo dura exactamente 5 segundos"
    exit 1
fi

input_file="$1"
output_file="$2"
fixed_duration=${3:-0}

if [ ! -f "$input_file" ]; then
    echo "Error: El archivo $input_file no existe"
    exit 1
fi

# Limpiar archivo de salida
> "$output_file"

current_time=0
counter=1

# Leer el archivo línea por línea
while IFS= read -r line || [ -n "$line" ]; do
    # Remover el tag de break para obtener solo el texto
    text=$(echo "$line" | sed -E "s/<break time=['\"]?[0-9]+ms['\"]?\/>//g" | xargs)
    
    # Ignorar líneas vacías
    if [ -z "$text" ]; then
        continue
    fi
    
    # Si se especificó duración fija, usar esa
    if [ $fixed_duration -gt 0 ]; then
        duration=$fixed_duration
    else
        # Extraer el tiempo del break si existe
        if [[ "$line" =~ \<break\ time=\'([0-9]+)ms\'/\> ]] || [[ "$line" =~ \<break\ time=\"([0-9]+)ms\"/\> ]]; then
            break_duration="${BASH_REMATCH[1]}"
        else
            break_duration=1000
        fi
        
        # Calcular duración del habla (60ms por carácter)
        speech_duration=$((${#text} * 60))
        
        # Duración total = habla + pausa
        duration=$((speech_duration + break_duration))
    fi
    
    # Calcular tiempos
    start_time=$(ms_to_srt_time $current_time)
    end_time=$(ms_to_srt_time $((current_time + duration)))
    
    # Escribir en formato SRT
    echo "$counter" >> "$output_file"
    echo "$start_time --> $end_time" >> "$output_file"
    echo "$text" >> "$output_file"
    echo "" >> "$output_file"
    
    # Debug info
    if [ $fixed_duration -gt 0 ]; then
        echo "Línea $counter: duración fija ${duration}ms" >&2
    else
        echo "Línea $counter: ${#text} chars → ${duration}ms total" >&2
    fi
    
    # Actualizar tiempo y contador
    current_time=$((current_time + duration))
    counter=$((counter + 1))
    
done < "$input_file"

echo "" >&2
echo "Archivo SRT generado: $output_file" >&2
echo "Duración total: $(ms_to_srt_time $current_time)" >&2
