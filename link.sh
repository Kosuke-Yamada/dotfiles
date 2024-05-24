#!/bin/sh

DOT_DIRECTORY="$HOME/dotfiles"
BACKUP_DIRECTORY="$HOME/.backup/dotfiles"

cd $(dirname $0)

mkdir -p $BACKUP_DIRECTORY

for f in .??*; do
    if [ "$f" = ".git" ]; then
        continue
    fi

    if [ -e $HOME/$f ] && [ ! -L $HOME/$f ]; then
        mv $HOME/$f $BACKUP_DIRECTORY
    fi
    ln -snfv $DOT_DIRECTORY/$f $HOME/$f
done

rmdir -p $BACKUP_DIRECTORY 2>/dev/null
