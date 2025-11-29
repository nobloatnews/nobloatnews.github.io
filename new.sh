#!/bin/sh
if [ $# -eq 0 ]
  then
    echo "Poné el mensaje del commit como primer argumento"
    exit;
fi

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)


cp posts/2025-10-marinera_pescado.html posts/$year-$month-$day-$1.html
echo "Publicación creada"
ls -ltr posts/ | tail -5
