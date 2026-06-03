#!/usr/bin/env bash
set -euo pipefail

# Parámetros
ROOT_DIR="${1:-.}"                       # directorio raíz (por defecto: directorio actual)
BLACKLIST_FILE="${2:-.gitignore}"        # por defecto: ./blacklist.txt en el directorio de ejecución
BLACKLIST_TYPE="${3:-glob}"              # "glob" (por defecto) o "regex"

# Normalizar ROOT_DIR a ruta sin barra final
ROOT_DIR="${ROOT_DIR%/}"

# Cargar blacklist en array
blacklist=()
if [[ -f "$BLACKLIST_FILE" ]]; then
  while IFS= read -r line; do
    # omitir líneas vacías y comentarios que empiezan con #
    [[ -z "$line" || "${line##\#}" != "$line" ]] && continue
    blacklist+=("$line")
  done < "$BLACKLIST_FILE"
fi

# Función para comprobar si una ruta relativa coincide con la blacklist
# Recibe: ruta_relativa
is_blacklisted() {
  local rel="$1"
  if [[ "${#blacklist[@]}" -eq 0 ]]; then
    return 1
  fi

  if [[ "$BLACKLIST_TYPE" == "glob" ]]; then
    for pat in "${blacklist[@]}"; do
      [[ -z "$pat" ]] && continue

      if [[ "$rel" == $pat || "$(basename "$rel")" == $pat ]]; then
        return 0
      fi

      if [[ "$pat" == ./* || "$pat" == /* ]]; then
        p="${pat#./}"
        if [[ "$rel" == $p || "$rel" == $p/* ]]; then
          return 0
        fi
      fi
    done
    return 1
  else
    for pat in "${blacklist[@]}"; do
      [[ -z "$pat" ]] && continue
      if [[ "$rel" =~ $pat ]]; then
        return 0
      fi
    done
    return 1
  fi
}

# Función para imprimir separador con el nombre del archivo
print_section_header() {
  local rel="$1"
  # Ancho del separador basado en la longitud del nombre (mínimo 20)
  local name_line=" $rel "
  local name_len=${#name_line}
  local width=$(( name_len > 20 ? name_len : 20 ))
  local border
  border=$(printf '%*s' "$width" '' | tr ' ' '=')
  printf '%s\n' "$border"
  printf '%s\n' "$name_line"
  printf '%s\n' "$border"
}

# Recorrer con find y procesar archivos (archivos regulares)
find "$ROOT_DIR" -type f -print0 | while IFS= read -r -d '' file; do
  # calcular ruta relativa respecto a ROOT_DIR
  rel="${file#"$ROOT_DIR"/}"
  [[ "$rel" == "$file" ]] && rel="$(basename "$file")"

  # comprobar blacklist completa
  if is_blacklisted "$rel"; then
    continue
  fi

  # comprobar cada componente de la ruta (para bloquear directorios)
  skip=0
  IFS='/' read -ra parts <<< "$rel"
  prefix=""
  for p in "${parts[@]}"; do
    prefix="${prefix:+$prefix/}$p"
    if is_blacklisted "$prefix"; then
      skip=1
      break
    fi
  done
  [[ $skip -eq 1 ]] && continue

  # Imprimir cabecera de sección (separadores) y luego contenido
  print_section_header "$rel"
  # Mostrar contenido (si es binario, evitar romper la salida; usar cat -- anyway)
  cat -- "$file" || true
  printf '\n'
done
