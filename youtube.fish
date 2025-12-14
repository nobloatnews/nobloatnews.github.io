echo "Generamos thumbnail para youtube"
echo "Ingresa titulo sin espacios:"
read titulo
echo "Ingresa pequeña descripción con saltos de linea para el thumbnail de youtube (sino sale de la imagen)"
read short_description
echo "Gerando thumbnail..."
thumbnailg $short_description /tmp/$titulo.png
echo "Ingresa ubicación completa de archivo de audio m4a de la clase"
read archivo_audio_path
echo "Creando un video a partir del audio..."
ffmpeg -i /tmp/$titulo.png -i $archivo_audio_path -c:v libx264 -tune stillimage -c:a copy /tmp/$titulo.mp4

source $HOME/youtube-upload/bin/activate.fish 
$HOME/youtube-upload/youtube-upload/bin/youtube-upload \
  --title="$titulo" \
  --description="$short_description" \
  #--category="Science" \
  --recording-date="2011-03-10T15:32:17.0Z" \
  --default-language="es" \
  --default-audio-language="es" \
  #--client-secrets="my_client_secrets.json" \
  #--credentials-file="my_credentials.json" \
  #--playlist="My favorite music" \
  --privacy="unlisted" \
  --embeddable=True \
  /tmp/$titulo.mp4
