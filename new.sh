#!/bin/sh
if [ $# -lt 2 ]
  then
	  echo "Uso: $0 <nombre-archivo> \"<titulo con espacios>\" <ruta del directorio de imagenes(opcional)> <tag_name_archive(opcional)> audio \"texto_entero para generar audio\""
    exit;
fi

year=$(date +%Y)
month=$(date +%m)
name_month=$(date +%B)
day=$(date +%d)


# 1. Arreglar el script si el audio dura menos que las imágenes porque genera valor negativo (el audio debe durar lo mismo que el video). NO. Esto se soluciona cambiando el totseconds.
# 2. Subir video automáticamente el audio a YouTube y a Archive.
#
# ia upload $year-$month-$dayaudio file.m4a
# youtube-upload ...
# 3. Crear un artículo automáticamente basado en imágenes.
# 4. Crear un audio con espeak que tenga la misma duración que el video (contá cuántas imágenes tenes y multiplicá por cada segundo cada imágen).
# echo "texto" | espeak-ng -v es -w file.wav
# cp gen.sh /usr/bin && chmod +x /usr/bin/gen.sh
# ls *.jpg | sort | gen.sh > video
# modificá totseconds en /usr/bin/slider
# slider -i video -a audio.wav 
# 5. Enlazá las URLs de archive automáticamente
# 6. Hacer script para juntar videos (no imagenes) con ffmpeg.
# 7. Subtitular audios subilos a youtube y descargalos con yt-dlp.
# 8. Pasar los subtitulos a un llm o a chatgpt para que haga un resumen.
# 9. Generar un archivo de audio con los subtitulos de chatgpt.
# 10. Subir video automáticamente el video a YouTube y a Archive.
# source internetarchive/bin/activate && ia upload $year-$month-$day-$1 /tmp/video_generado.mp4
# source $HOME/youtube-upload/bin/activate && $HOME/youtube-upload/youtube-upload/bin/youtube-upload --title="$1" --default-language="es" --privacy="unlisted" --embeddable=True /tmp/video_generado.mp4
#### Video subido a  Archive.org:
# <video width="640" height="480" controls>
#   <source src="path/to/video.mp4" type="video/mp4">
#   Your browser does not support the video tag.
# </video>
# 
# #### Video subido a YouTube:
# ```html
# <iframe width="560" height="315" src="https://www.youtube.com/embed/dQw4w9WgXcQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>



cp posts/2025-10-hola.html posts/$year-$month-$day-$1.html
sed -i "/<ul>/a\        <li><a href=\"posts/$year-$month-$day-$1.html\">$2</a> – $day $name_month $year</li>" index.html
#ls -1 $3 | sed -e "s|^|<img src=\"https://archive.org/download/tag_name/|" | sed -e "s|$|_thumb.jpg\">|" | tee -a "posts/$year-$month-$day-$1.html"

### Carga imagenes de archive.
for i in $(ls -1 $3/*.jpg); do echo "<a href=\"https://archive.org/download/$4/$i\"><img src=\"https://archive.org/download/$4/${i%.*}_thumb.jpg\"></a>" >> "posts/$year-$month-$day-$1.html" ; done



vim "posts/$year-$month-$day-$1.html"
