#!/bin/sh
if [ $# -lt 2 ]
  then
	  echo "Uso: $0 <nombre-archivo> \"<titulo con espacios>\""
    exit;
fi

actual_dir=$PWD;


year=$(date +%Y)
month=$(date +%m)
name_month=$(date +%B)
day=$(date +%d)

tag_name="$year-$month-$day-$1"


sed -i "/<ul>/a\        <li><a href=\"posts/$year-$month-$day-$1.html\">$2</a> – $day $name_month $year</li>" index.html

#ls -1 $3 | sed -e "s|^|<img src=\"https://archive.org/download/tag_name/|" | sed -e "s|$|_thumb.jpg\">|" | tee -a "posts/$year-$month-$day-$1.html"

### Carga imagenes de archive.
#for i in $(ls -1 $3/*.jpg); do echo "<a href=\"https://archive.org/download/$4/$i\"><img src=\"https://archive.org/download/$4/${i%.*}_thumb.jpg\"></a>" >> "posts/$year-$month-$day-$1.html" ; done


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
echo "    <p>ESCRIBI EL ARTICULOOOOOOOOOOOOOOOOOOO</p>"  >> "$actual_dir/posts/$tag_name.html"

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


vim "posts/$year-$month-$day-$1.html"
