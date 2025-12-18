#!/bin/bash
set -euo pipefail

echo "se necesita el comando ia (internet archive)".

for cmd in ffmpeg ffprobe yt-dlp espeak-ng slider gen.sh; do
  # ia (internet archive) debe estar dentro de venv python
  command -v "$cmd" >/dev/null || { echo "Falta $cmd"; exit 1; }
done

# Si pusiste texto no subas el archivo de audio

# 1 o 0 sirve para solo generar el video sin subirlo
prueba=0

actual_dir=$PWD;

if [ $# -lt 3 ];
  then
          echo "Consejo: si tenes un audio, concatená el audio con una imagen y subilo a YouTube descarga los subtitulos y pasalos a ChatGPT pedile un resumen y luego agregalo como texto entero para generar el audio, eso se hace con el script youtube.fish";
	  echo "Si queres que el archivo de audio sea por defecto no uses el 5to parametro."
          echo "Con los siguientes comandos:"
          echo "yt-dlp --ignore-config --write-subs --write-auto-sub --sub-lang es --sub-format \"srt\" --skip-download https://www.youtube.com/watch?v=VIDEO_ID"
          echo "sed -E '/^[0-9]+$|^$/d; /^[0-9]{2}:/d' video.en.srt > subtitles.txt"
	  echo "Uso: $0 <nombre-archivo> \"<titulo con espacios>\" <ruta del directorio de imagenes (opcional)> <ruta entera del directorio de audio.m4a(opcional)> \"subir_audio(opcional): si pones 1 sube el audio\" \"texto entero para generar audio(opcional)\" "
	  echo "Si pones el texto al final, el video se creará con espeak generado con el texto y va a ignorar el archivo de audio."
    exit;
fi

[ $# -ge 3 ] && [ ! -d "$3" ] && echo "Directorio de imágenes inválido" && exit 1
[ $# -ge 4 ] && [ ! -f "$4" ] && echo "Audio no existe" && exit 1



year=$(date +%Y)
month=$(date +%m)
name_month=$(date +%B)
day=$(date +%d)


tag_name="$year-$month-$day-$1"

 # 1. Arreglar el script si el audio dura menos que las imágenes porque genera valor negativo (el audio debe durar lo mismo que el video) ----->> NO. Esto se soluciona cambiando el totseconds. X
# El slidier requiere ese ligero cambio sino te genera valores negativos. X
# 2. Subir video automáticamente el audio a YouTube y a Archive. No se puede subir audios a youtube tendras que concatenarlos con una imágen. X
# ia upload $year-$month-$dayaudio file.m4a X
# youtube-upload ... X
# 3. Crear un artículo automáticamente basado en imágenes. X
# 4. Crear un audio con espeak que tenga la misma duración que el video (contá cuántas imágenes tenes y multiplicá por cada segundo cada imágen). (No hace falta). X
# echo "texto" | espeak-ng -v es -w file.wav X
# cp gen.sh /usr/bin && chmod +x /usr/bin/gen.sh X
# ls *.jpg | sort | gen.sh > video X
# modificá totseconds en /usr/bin/slider X
# slider -i video -a audio.wav X
# 5. Enlazá las URLs de archive automáticamente X
# 6. Hacer script para juntar videos (no imagenes) con ffmpeg. X
# 7. Subtitular audios subilos a youtube y descargalos con yt-dlp.
# 8. Pasar los subtitulos a un llm o a chatgpt para que haga un resumen.
# 9. Generar un archivo de audio con los subtitulos de chatgpt.
# 10. Subir video automáticamente el video a YouTube y a Archive. X
# source internetarchive/bin/activate && ia upload $year-$month-$day-$1 /tmp/video_generado.mp4 X
# source $HOME/youtube-upload/bin/activate && $HOME/youtube-upload/youtube-upload/bin/youtube-upload --title="$1" --default-language="es" --privacy="unlisted" --embeddable=True /tmp/video_generado.mp4 X
#### Video subido a  Archive.org:
# <video width="640" height="480" controls>
#   <source src="path/to/video.mp4" type="video/mp4">
#   Your browser does not support the video tag.
# </video>
# 
# #### Video subido a YouTube:
# ```html
# <iframe width="560" height="315" src="https://www.youtube.com/embed/dQw4w9WgXcQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

echo "<!DOCTYPE html>" > "$actual_dir/posts/$tag_name.html"
echo "<html lang=\"es\">" >> "$actual_dir/posts/$tag_name.html"
echo "<head>" >> "$actual_dir/posts/$tag_name.html"
echo "  <meta charset=\"utf-8\">" >> "$actual_dir/posts/$tag_name.html"
echo "  <title>$2</title>" >> "$actual_dir/posts/$tag_name.html"
echo "  <link rel=\"stylesheet\" href=\"../style.css\">" >> "$actual_dir/posts/$tag_name.html"
echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" >> "$actual_dir/posts/$tag_name.html"
echo "</head>" >> "$actual_dir/posts/$tag_name.html"
echo "<body>" >> "$actual_dir/posts/$tag_name.html"
echo "  <center>" >> "$actual_dir/posts/$tag_name.html"
echo "  <header><a href=\"../index.html\">← Inicio</a></header>" >> "$actual_dir/posts/$tag_name.html"
echo "  <hr>" >> "$actual_dir/posts/$tag_name.html"
echo "  <article>" >> "$actual_dir/posts/$tag_name.html"
echo "    <h1>$2</h1>" >> "$actual_dir/posts/$tag_name.html"
echo "    <p>Artículo publicado por: Andrés Imlauer.</p>" >> "$actual_dir/posts/$tag_name.html"
echo "    <time datetime=\"$year-$month-$day\">$name_month $day, $year</time>" >> "$actual_dir/posts/$tag_name.html"









#cp posts/2025-10-hola.html posts/$tag_name.html
sed -i "/<ul>/a\        <li><a href=\"posts/$tag_name.html\">$2</a> – $day $name_month $year</li>" index.html
#ls -1 $3 | sed -e "s|^|<img src=\"https://archive.org/download/tag_name/|" | sed -e "s|$|_thumb.jpg\">|" | tee -a "posts/$year-$month-$day-$1.html"


## Si pusiste texto como audio. Si queres que el archivo de audio sea por defecto no uses el 6to parametro.
(($# == 6)) && echo "Generando archivo de audio a partir del texto..." && echo "$6" | espeak-ng -v es -w "/tmp/$tag_name.wav"

echo "Listo."

#### GENERAMOS EL VIDEO, si el audio es mas largo que las imagenes tendras que cambiarlo.
#longitud_audio=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $4)
#cantidad_imagenes=$((ls -1 $3 | wc -l))

echo "Generando video..."

# Si es igual a 6 el video será con el audio-texto generado por espeak.
(($# == 6)) && ls $3/*.jpg | sort | gen.sh > "/tmp/$tag_name" && cd /tmp && slider -i "$tag_name" -a "$tag_name.wav" -o "/tmp/$tag_name.mp4"

# Si es igual a 5 o 4 el video debería ser sin el audio-texto generado por espeak pero con el archivo de audio.
(($# == 5)) && ls $3/*.jpg | sort | gen.sh > "/tmp/$tag_name" && cd /tmp && slider -i "$tag_name" -a "$4" -o "/tmp/$tag_name.mp4"
(($# == 4)) && ls $3/*.jpg | sort | gen.sh > "/tmp/$tag_name" && cd /tmp && slider -i "$tag_name" -a "$4" -o "/tmp/$tag_name.mp4"

# Si es igual a 3 el video debería ser solo imagenes sin audios.
(($# == 3)) && ls $3/*.jpg | sort | gen.sh > "/tmp/$tag_name" && cd /tmp && slider -i "$tag_name" -o "/tmp/$tag_name.mp4"

echo "Listo."

((prueba == 1)) && echo "Modo prueba. No subire el video." && exit;

cd $actual_dir;

(($# > 2)) && echo "Subimos video a YouTube" && source $HOME/youtube-upload/bin/activate && youtube_id=$($HOME/youtube-upload/youtube-upload/bin/youtube-upload --title="$2" --privacy="unlisted" --embeddable=True "/tmp/$tag_name.mp4" | tail -1) && echo "Cargo video de YouTube en el html generado (iframe tag)." && echo "<h3><a href=\"https://www.youtube.com/embed/$youtube_id\">¡¡CLICK PARA VER VIDEO DE LAS FOTOS EN YOUTUBE (con explicación)!!</a></h3>" >> "posts/$tag_name.html"

(($# > 2)) && echo "Subimos video a Archive.org" && source $HOME/internetarchive/bin/activate && ia upload "$tag_name-video" "/tmp/$tag_name.mp4" && echo "Cargo video de Archive en el html generado (video tag)." && echo "<h3><a href=\"https://archive.org/download/$tag_name-video/$tag_name.mp4\">¡¡CLICK PARA VER VIDEO DE LAS FOTOS EN ARCHIVE (con explicación)!!</a></h3>" >> "posts/$tag_name.html"; 


# Si pusiste el 5to argumento como 1 entonces subimos el pseudoaudio
(($# > 4)) && (($5 == 1)) && echo "Subimos el audio a Archive." && source $HOME/internetarchive/bin/activate && ia upload "$year-$month-$day-$1audio" $4 && echo "<h3><a href=\"https://archive.org/download/$year-$month-$day-$1audio/$4\">¡¡¡Escuchar el Audio del suceso!!!.</a></h3>" >> "posts/$tag_name.html" ; 


echo "OJO: No se puede subir audio a YouTube lo concatenaré con una imagen."

(($# > 4)) && (($5 == 1)) && echo "Subimos el audio a YouTube." && echo "Generamos thumbnail para youtube" && thumbnailg "$2" "/tmp/$tag_name.png" && echo "Creando un video a partir del audio..." && ffmpeg -i "/tmp/$tag_name.png" -i $4 -c:v libx264 -tune stillimage -c:a copy /tmp/$tag_name.mp4 && source $HOME/youtube-upload/bin/activate && youtube_id=$($HOME/youtube-upload/youtube-upload/bin/youtube-upload --title="$2" --privacy="unlisted" --embeddable=True "/tmp/$tag_name.mp4" | tail -1) && echo "Cargo video del audio de YOUTUBE en el html generado (a tag)." && echo "<h3><a href="\"https://www.youtube.com/embed/$youtube_id">¡¡CLICK PARA ESCUCHAR EL AUDIO EN YOUTUBE!!</a></h3>" >> "posts/$tag_name.html"


echo "Cargo imagenes de archive en el html generado."
echo "<hr>" >> "posts/$tag_name.html"

# Descomenta todo esto para subir imagenes una por una a archive e insertarlas en el html.

#echo "Subo imagenes a Archive"
#(($# > 2)) && cd $3 && source $HOME/internetarchive/bin/activate && ia upload "$tag_name-images" *

#cd $actual_dir;
#cantidad_imagenes=$(ls -1 $3 | wc -l)

#(($# > 2)) && ((cantidad_imagenes >= 10)) && echo "<h3><a href=\"https://archive.org/details/$tag_name-images/\">¡¡¡VER LAS $cantidad_imagenes DE FOTOS EN ARCHIVE!!!!</a></h3>" >> "$actual_dir/posts/$tag_name.html" ; 


#(($# > 2)) && cd $3 && for i in *.jpg; do echo "<a href=\"https://archive.org/download/$tag_name-images/$i\"><img src=\"https://archive.org/download/$tag_name-images/${i%.*}_thumb.jpg\"></a>" >> "$actual_dir/posts/$tag_name.html" ; done



cd $actual_dir;

echo "<hr>" >> "posts/$tag_name.html"
echo "<h3>Resumen</h3>" >> "posts/$tag_name.html"
echo "$6" >> "posts/$tag_name.html"

echo "  </article>" >> "posts/$tag_name.html"
echo "  <hr>" >> "posts/$tag_name.html"
echo "  <a href="../index.html">← Inicio</a>" >> "posts/$tag_name.html"
echo "  </center>" >> "posts/$tag_name.html"
echo "</body>" >> "posts/$tag_name.html"
echo "</html>" >> "posts/$tag_name.html"


git add . && git commit -m "posts/$year-$month-$day-$1.html" && git push
