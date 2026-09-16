#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

FILES_TO_LINK=$(cd "$DOTFILES_DIR" && find . -maxdepth 1 | sed 's/^\.\///g' | grep -Ev "^\\.$|^\\.\\.$|^\\.git$|^\\.gitignore$|^install\\.sh$|.+\\.terminfo|^LICENSE$|^README.md$")

for FILE in $FILES_TO_LINK
do
    SRC="$DOTFILES_DIR/$FILE"
    DEST="$HOME/$FILE"

    # Already pointing where we want it.
    if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
        echo "ok       $FILE"
        continue
    fi

    # Anything else in the way gets moved aside, never deleted. Hard links from
    # the pre-symlink version of this script land here, and their contents may
    # have drifted from the repo -- keep them so the drift can be diffed.
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$DEST" "$BACKUP"
        echo "backup   $FILE -> $(basename "$BACKUP")"
    fi

    ln -s "$SRC" "$DEST"
    echo "link     $FILE"
done

TERMINFO_FILES=$(cd "$DOTFILES_DIR" && find . -maxdepth 1 | grep -E ".+\\.terminfo")

for FILE in $TERMINFO_FILES
do
    echo "tic      $FILE"
    tic -x "$DOTFILES_DIR/$FILE"
done
