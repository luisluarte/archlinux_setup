#!/bin/bash

dotfiles_dir="$HOME/Documents/repos/archlinux_setup"
backup_dir="$HOME/.dotfile_backups/$(date +%f-%t)"

declare -a files_to_link=(
    "dotfiles/config=$HOME/.config/i3/config"
    "dotfiles/alacritty.toml=$HOME/.config/alacritty/alacritty.toml"
    "dotfiles/.bashrc=$HOME/.bashrc"
    "dotfiles/picom.conf=$HOME/.config/picom.conf"
    )

mkdir -p "$backup_dir"

for item in "${files_to_link[@]}"; do
    repo_path="${item%=*}"
    system_path="${item#*=}"
    
    # --- data validation ---
    # check for empty paths which cause errors
    if [ -z "$repo_path" ] || [ -z "$system_path" ]; then
        echo "warning: skipping invalid entry: '$item'"
        continue # skip to the next item in the loop
    fi

    src_file=$(realpath -m "$dotfiles_dir/$repo_path")

    if [ -e "$src_file" ]; then
        # corrected the typo in "$system_path" here
        if [ -e "$system_path" ] || [ -l "$system_path" ]; then
            backup_target_dir=$(dirname "$backup_dir/${system_path#$HOME/}")
            mkdir -p "$backup_target_dir"
            
            echo "backing up: $system_path"
            mv "$system_path" "$backup_target_dir/"
        fi
        
        mkdir -p "$(dirname "$system_path")"
        
        echo "linking: $system_path -> $src_file"
        ln -s "$src_file" "$system_path"
    else
        echo "warning: $src_file not found. skipping."
    fi
done

echo "symlinking complete."
