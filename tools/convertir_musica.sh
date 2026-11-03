#!/usr/bin/env bash
# Convierte las canciones (MP3 de Suno) a los OGG de assets/musica/.
# Uso: tools/convertir_musica.sh [carpeta_origen]
#
# - Pistas en bucle: los últimos FUNDIDO segundos se mezclan con los primeros y el archivo empieza
#   en FUNDIDO, así el final enlaza sin corte con el principio al repetirse.
# - Jingles: tal cual, con un fundido corto al final.
# - OGG Vorbis calidad 1 (~80 kbps), 44,1 kHz estéreo: suficiente para el altavoz del móvil.
set -euo pipefail

ORIGEN="${1:-$HOME/Música/running_archer}"
DESTINO="$(dirname "$0")/../assets/musica"
FUNDIDO=2.5
CALIDAD=1

# archivo de origen -> pista del juego (nombres de Musica.PISTAS)
BUCLES=(
	"menu_principal.mp3:menu"
	"menu_mejoras.mp3:tienda"
	"map1.mp3:mapa1"
	"map2.mp3:mapa2"
	"map3.mp3:mapa3"
	"red_dragon.mp3:boss1"
	"black_dragon.mp3:boss2"
	"skeleton_dragon.mp3:boss3"
)
JINGLES=(
	"victoria.mp3:victoria"
	"Game Over.mp3:derrota"
	"victoria_final.mp3:final"
)

mkdir -p "$DESTINO"
for par in "${BUCLES[@]}"; do
	src="$ORIGEN/${par%%:*}"; dst="$DESTINO/${par##*:}.ogg"
	ffmpeg -hide_banner -loglevel error -y -i "$src" -filter_complex \
		"[0:a]asplit[a][b];[a]atrim=start=$FUNDIDO,asetpts=PTS-STARTPTS[cuerpo];[b]atrim=end=$FUNDIDO,asetpts=PTS-STARTPTS[cabeza];[cuerpo][cabeza]acrossfade=d=$FUNDIDO:c1=qsin:c2=qsin" \
		-ar 44100 -ac 2 -c:a libvorbis -q:a $CALIDAD "$dst"
	echo "bucle   $dst"
done
for par in "${JINGLES[@]}"; do
	src="$ORIGEN/${par%%:*}"; dst="$DESTINO/${par##*:}.ogg"
	d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$src")
	ffmpeg -hide_banner -loglevel error -y -i "$src" -af "afade=t=out:st=$(echo "$d - 1" | bc):d=1" \
		-ar 44100 -ac 2 -c:a libvorbis -q:a $CALIDAD "$dst"
	echo "jingle  $dst"
done
du -ch "$DESTINO"/*.ogg | tail -1
