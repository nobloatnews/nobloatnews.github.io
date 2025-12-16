#!/bin/sh
if [ $# -lt 2 ]
  then
	  echo "Uso: $0 <nombre-archivo> \"<titulo con espacios>\""
    exit;
fi

year=$(date +%Y)
month=$(date +%m)
name_month=$(date +%B)
day=$(date +%d)


cp posts/2025-10-hola.html posts/$year-$month-$day-$1.html
sed -i "/<ul>/a\        <li><a href=\"posts/$year-$month-$day-$1.html\">$2</a> – $day $name_month $year</li>" index.html

#ls -1 $3 | sed -e "s|^|<img src=\"https://archive.org/download/tag_name/|" | sed -e "s|$|_thumb.jpg\">|" | tee -a "posts/$year-$month-$day-$1.html"

### Carga imagenes de archive.
#for i in $(ls -1 $3/*.jpg); do echo "<a href=\"https://archive.org/download/$4/$i\"><img src=\"https://archive.org/download/$4/${i%.*}_thumb.jpg\"></a>" >> "posts/$year-$month-$day-$1.html" ; done



vim "posts/$year-$month-$day-$1.html"
