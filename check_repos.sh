#!/bin/bash

# Si no se pasa una ruta como argumento, se usa el directorio actual
TARGET_DIR="${1:-.}"

echo "Buscando repositorios Git en: $(realpath "$TARGET_DIR")"

find "$TARGET_DIR" -name ".git" -type d -prune -exec dirname {} \; | while read -r repo; do
    echo ""
    echo "========================================"
    echo "📂 Repositorio: $repo"
    echo "========================================"
    
    cd "$repo" || continue
    
    # 1. Comprobar si hay cambios locales sin confirmar
    if [ -n "$(git status --porcelain)" ]; then
        echo "  [Estado]: ⚠️  Tiene cambios sin confirmar o archivos sin trackear."
    else
        echo "  [Estado]: ✔️  Directorio de trabajo limpio."
    fi
    
    # 2. Comprobar sincronización con el remoto
    # Intentamos hacer fetch (silencioso, por si no hay internet o falla)
    if git fetch --quiet 2>/dev/null; then
        LOCAL=$(git rev-parse @ 2>/dev/null)
        REMOTE=$(git rev-parse "@{u}" 2>/dev/null)
        BASE=$(git merge-base @ "@{u}" 2>/dev/null)

        if [ -z "$REMOTE" ]; then
            echo "  [Remoto]: ℹ️  No tiene rama remota configurada (upstream)."
        elif [ "$LOCAL" = "$REMOTE" ]; then
            echo "  [Remoto]: ✔️  Sincronizado (al día)."
        elif [ "$LOCAL" = "$BASE" ]; then
            echo "  [Remoto]: ⬇️  Desactualizado (necesitas hacer 'git pull')."
        elif [ "$REMOTE" = "$BASE" ]; then
            echo "  [Remoto]: ⬆️  Con commits locales sin subir (necesitas hacer 'git push')."
        else
            echo "  [Remoto]: 🔀 Divergido (ramas separadas, requiere merge/rebase)."
        fi
    else
        echo "  [Remoto]: ❌ No se pudo conectar al servidor remoto (revisa tu red)."
    fi

    cd - > /dev/null
done

echo ""
echo "✨ ¡Revisión completada!"
