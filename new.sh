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
vim "posts/$year-$month-$day-$1.html"
