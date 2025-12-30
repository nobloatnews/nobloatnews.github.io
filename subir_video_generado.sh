#!/bin/bash
set -euo pipefail

echo "se necesita el comando ia (internet archive)".

for cmd in ffmpeg ffprobe yt-dlp espeak-ng slider ; do
  # ia (internet archive) debe estar dentro de venv python
  command -v "$cmd" >/dev/null || { echo "Falta $cmd"; exit 1; }
done


# Si pusiste texto no subas el archivo de audio

# 1 sirve para solo generar el video sin subirlo
prueba=0

actual_dir=$PWD;

if [ $# -lt 3 ];
  then
          echo "Consejo: si tenes un audio, concatená el audio con una imagen y subilo a YouTube descarga los subtitulos y pasalos a ChatGPT pedile un resumen y luego agregalo como texto entero para generar el audio, eso se hace con el script youtube.fish";
	  echo "Si queres que el archivo de audio sea por defecto no uses el 5to parametro."
          echo "Con los siguientes comandos:"
          echo "yt-dlp --ignore-config --write-subs --write-auto-sub --sub-lang es --sub-format \"srt\" --skip-download https://www.youtube.com/watch?v=VIDEO_ID"
          echo "sed -E '/^[0-9]+$|^$/d; /^[0-9]{2}:/d' video.en.srt > subtitles.txt"
	  echo "Uso: $0 <nombre-archivo> \"<titulo con espacios>\" <ruta del video generado con el script>" "<ruta carpeta de imagenes> <ruta archivo texto del script>"
	  echo "Si pones el texto al final, el video se creará con espeak generado con el texto y va a ignorar el archivo de audio."
    exit;
fi

[ $# -lt 5 ] && echo "Faltan argumentos. Bye" && exit 1

[ $# -ge 3 ] && [ ! -f "$3" ] && echo "Video no existe" && exit 1
[ $# -ge 4 ] && [ ! -d "$4" ] && echo "La ruta no existe" && exit 1
[ $# -ge 5 ] && [ ! -f "$5" ] && echo "El archivo no existe" && exit 1


filename="${3##*/}"
echo $filename

year=$(date +%Y)
month=$(date +%m)
name_month=$(date +%B)
day=$(date +%d)


tag_name="$year-$month-$day-$1"

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


sed -i "/<ul>/a\        <li><a href=\"posts/$tag_name.html\">$2</a> – $day $name_month $year</li>" index.html
#ls -1 $3 | sed -e "s|^|<img src=\"https://archive.org/download/tag_name/|" | sed -e "s|$|_thumb.jpg\">|" | tee -a "posts/$year-$month-$day-$1.html"


((prueba == 1)) && echo "Modo prueba. No subire el video." && exit;

cd $actual_dir;

#echo "Subimos video a YouTube" && source $HOME/youtube-upload/bin/activate && youtube_id=$($HOME/youtube-upload/youtube-upload/bin/youtube-upload --title="$2" --privacy="unlisted" --embeddable=True "$3" | tail -1) && echo "Cargo video de YouTube en el html generado (iframe tag)." && echo "<h3><a href=\"https://www.youtube.com/embed/$youtube_id\">¡¡CLICK PARA VER VIDEO DE LAS FOTOS EN YOUTUBE (con explicación)!!</a></h3>" >> "posts/$tag_name.html"


echo "Subimos video a Archive.org" && source $HOME/internetarchive/bin/activate && ia upload "$tag_name-video" "$3" && echo "Cargo video de Archive en el html generado (video tag)." && echo "<h3><a href=\"https://archive.org/download/$tag_name-video/$filename\">¡¡CLICK PARA VER VIDEO DE LAS FOTOS EN ARCHIVE (con explicación)!!</a></h3>" >> "posts/$tag_name.html"; 


cd $actual_dir;

echo "<hr>" >> "posts/$tag_name.html"
echo "<h3>Resumen</h3>" >> "posts/$tag_name.html"
echo "<p>"  >> "posts/$tag_name.html"
cat "$5" >> "posts/$tag_name.html"
echo "</p>" >> "posts/$tag_name.html"


echo "Cargo imagenes de archive en el html generado."
echo "<hr>" >> "posts/$tag_name.html"

# Descomenta todo esto para subir imagenes una por una a archive e insertarlas en el html.

echo "Subo imagenes a Archive"
(($# == 4)) && cd $4 && source $HOME/internetarchive/bin/activate && ia upload "$tag_name-images" *

cd $actual_dir;
cantidad_imagenes=$(ls -1 $4 | wc -l)

(($# == 4)) && ((cantidad_imagenes >= 20)) && echo "<h3><a href=\"https://archive.org/details/$tag_name-images/\">¡¡¡VER LAS $cantidad_imagenes DE FOTOS EN ARCHIVE!!!!</a></h3>" >> "$actual_dir/posts/$tag_name.html" ; 


(($# == 4)) && cd $4 && for i in *.jpg; do echo "<a href=\"https://archive.org/download/$tag_name-images/$i\"><img src=\"https://archive.org/download/$tag_name-images/${i%.*}_thumb.jpg\"></a>" >> "$actual_dir/posts/$tag_name.html" ; done


cd $actual_dir;



echo "  </article>" >> "posts/$tag_name.html"
echo "  <hr>" >> "posts/$tag_name.html"
echo "  <a href="../index.html">← Inicio</a>" >> "posts/$tag_name.html"
echo "  </center>" >> "posts/$tag_name.html"
echo "</body>" >> "posts/$tag_name.html"
echo "</html>" >> "posts/$tag_name.html"

git add . && git commit -m $tag_name && git push
