#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
    cat <<USAGE
usage: install.sh [link]          link every tracked dotfile into \$HOME
       install.sh adopt FILE...   move FILE into the repo, then link it back

'link' is the default. Both are safe to re-run.
USAGE
}

# Files in the repo root that are repo infrastructure, not dotfiles to link.
is_not_a_dotfile() {
    case "$1" in
        .|..|.git|.gitignore|install.sh|LICENSE|README.md|*.terminfo) return 0 ;;
        *) return 1 ;;
    esac
}

link_one() {
    local FILE=$1
    local SRC="$DOTFILES_DIR/$FILE"
    local DEST="$HOME/$FILE"

    # Already pointing where we want it.
    if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
        echo "ok       $FILE"
        return
    fi

    # Anything else in the way gets moved aside, never deleted. Hard links from
    # the pre-symlink version of this script land here, and their contents may
    # have drifted from the repo -- keep them so the drift can be diffed.
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        local BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$DEST" "$BACKUP"
        echo "backup   $FILE -> $(basename "$BACKUP")"
    fi

    ln -s "$SRC" "$DEST"
    echo "link     $FILE"
}

cmd_link() {
    local FILE
    for FILE in $(cd "$DOTFILES_DIR" && find . -maxdepth 1 | sed 's/^\.\///g')
    do
        is_not_a_dotfile "$FILE" && continue
        link_one "$FILE"
    done

    for FILE in $(cd "$DOTFILES_DIR" && find . -maxdepth 1 -name '*.terminfo' | sed 's/^\.\///g')
    do
        echo "tic      $FILE"
        tic -x "$DOTFILES_DIR/$FILE"
    done
}

cmd_adopt() {
    if [ "$#" -eq 0 ]; then
        echo "adopt: nothing to adopt" >&2
        usage >&2
        exit 1
    fi

    local ARG FILE SRC DEST
    local ADOPTED=()
    for ARG in "$@"
    do
        FILE=$(basename "$ARG")
        SRC="$DOTFILES_DIR/$FILE"
        DEST="$HOME/$FILE"

        # Only $HOME's top level; install.sh's linking is `find -maxdepth 1`, so
        # anything nested could be moved in but never linked back.
        if [ "$ARG" != "$DEST" ] && [ "$ARG" != "$FILE" ] && [ "$ARG" != "~/$FILE" ]; then
            echo "adopt: $ARG is not a top-level file in \$HOME" >&2
            exit 1
        fi

        if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC" ]; then
            echo "ok       $FILE (already adopted)"
            ADOPTED+=("$FILE")
            continue
        fi

        if [ ! -e "$DEST" ]; then
            echo "adopt: $DEST does not exist" >&2
            exit 1
        fi

        # Refuse rather than clobber: the repo copy may be the one worth keeping,
        # and only you can say which.
        if [ -e "$SRC" ]; then
            echo "adopt: $FILE is already in the repo; compare them first:" >&2
            echo "       diff $SRC $DEST" >&2
            exit 1
        fi

        mv "$DEST" "$SRC"
        echo "adopt    $FILE"
        link_one "$FILE"
        ADOPTED+=("$FILE")
    done

    # Names as they exist in the repo, not the $HOME paths that were passed in.
    echo
    echo "Now commit it:"
    echo "  git -C $DOTFILES_DIR add ${ADOPTED[*]} && git -C $DOTFILES_DIR commit"
}

case "${1:-link}" in
    link)           cmd_link ;;
    adopt)          shift; cmd_adopt "$@" ;;
    -h|--help|help) usage ;;
    *)              echo "install.sh: unknown command '$1'" >&2; usage >&2; exit 1 ;;
esac
