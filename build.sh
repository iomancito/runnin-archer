#!/usr/bin/env bash
# Compila la APK de depuración de Android en ./build/RunningArcher.apk
#
# Uso:
#   ./build.sh            # solo compila
#   ./build.sh -i         # compila e instala en el móvil conectado por adb
#
# Rutas de Godot y adb: cambiar con las variables GODOT y ADB si no son las de siempre.
set -euo pipefail

GODOT="${GODOT:-/mnt/ARC100/Godot/Godot_v4.7.1-stable_linux.x86_64}"
ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
DIR="$(cd "$(dirname "$0")" && pwd)"
SALIDA="$DIR/build"
APK="$SALIDA/RunningArcher.apk"
LOG="$SALIDA/export.log"

mkdir -p "$SALIDA"
#Godot no debe importar lo que hay en build/
touch "$SALIDA/.gdignore"

echo "Compilando $APK ..."
if ! "$GODOT" --headless --path "$DIR" --export-debug "Android" "$APK" > "$LOG" 2>&1 || [ ! -f "$APK" ]; then
	echo "Error al exportar. Log completo: $LOG" >&2
	grep -E "ERROR|SCRIPT ERROR" "$LOG" | tail -20 >&2 || true
	exit 1
fi
#errores de scripts: la APK se genera igualmente, pero fallaría en el móvil
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
	echo "Aviso: hay errores de scripts (ver $LOG):" >&2
	grep -E "SCRIPT ERROR|Parse Error" "$LOG" | head -10 >&2
fi
echo "APK: $APK ($(du -h "$APK" | cut -f1))"

if [ "${1:-}" = "-i" ]; then
	echo "Instalando en el móvil ..."
	"$ADB" install -r "$APK" | grep -v "^ess$"
fi
