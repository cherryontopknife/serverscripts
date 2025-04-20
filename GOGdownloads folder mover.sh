#!/bin/bash

# Your downloads dir should contain folders downloaded from gog-games.to with the unzipped archive inside the folder. This AI written script renames all the folders and files within those folders to a cleaner format. Some folders will still have a suffix of "game." Games with a period (.) in their name may also cause issues, because the script replaces periods with spaces. GameVault has a much easier time identifying games with these renamed folders.

# Example of downloads dir folder/ file format:
# /your/download/dir/here/game-beyond.the.ice.palace.2-(80938)/game-beyond.the.ice.palace.2-(80938).rar
# using this script results in:
# /your/games/installer/folder/here/beyond the ice palace 2/beyond the ice palace 2.rar

# Function to rename subfolders and files in the given directory.
# @param $1: The directory to process.
rename_folders_and_files() {
    local dir="$1"
    local backup_dir="$dir/backup_$(date +%Y%m%d_%H%M%S)"

    # Check if the provided argument is a directory.
    if [[ ! -d "$dir" ]]; then
        echo "Error: '$dir' is not a valid directory."
        return 1
    fi

    # Create a backup directory
    mkdir -p "$backup_dir"

    # Loop through all entries in the given directory.
    for entry in "$dir"/*; do
        if [[ -d "$entry" ]]; then
            local base_name=$(basename "$entry")
            local new_folder_name="${base_name#game-}"
            new_folder_name="${new_folder_name%%-(*)}"

            # Backup the original folder
            cp -r "$entry" "$backup_dir"

            # Check for name conflict before renaming
            if [[ "$base_name" != "$new_folder_name" && ! -d "$dir/$new_folder_name" ]]; then
                mv "$entry" "$dir/$new_folder_name"
                echo "Renamed folder: '$entry' to '$dir/$new_folder_name'"
            fi

            # Rename files within the renamed subfolder.
            for file in "$dir/$new_folder_name"/*; do
                if [[ -f "$file" ]]; then
                    local file_base_name=$(basename "$file")
                    local file_extension="${file_base_name##*.}"
                    local new_file_name="${new_folder_name}.$file_extension"

                    # Backup the original file
                    cp "$file" "$backup_dir"

                    # Check for name conflict before renaming
                    if [[ "$file_base_name" != "$new_file_name" && ! -f "$dir/$new_folder_name/$new_file_name" ]]; then
                        mv "$file" "$dir/$new_folder_name/$new_file_name"
                        echo "Renamed file: '$file' to '$dir/$new_folder_name/$new_file_name'"
                    fi
                fi
            done
        fi
    done

    echo "All operations completed. Backup created at: $backup_dir"
}

rename_subfolders_and_files() {
    local root_dir="$1"

    # Check if directory exists
    if [ ! -d "$root_dir" ]; then
        echo "Error: Directory '$root_dir' does not exist."
        return 1
    fi

    # Process each subdirectory
    find "$root_dir" -mindepth 1 -maxdepth 1 -type d | while read -r subdir; do
        # Get the original subdirectory name
        original_subdir_name=$(basename "$subdir")
        
        # Replace periods with spaces in the subdirectory name
        new_subdir_name="${original_subdir_name//./ }"
        
        # Only proceed if the name actually changed
        if [ "$original_subdir_name" != "$new_subdir_name" ]; then
            # Construct new path
            new_subdir_path="$(dirname "$subdir")/$new_subdir_name"
            
            # Rename the subdirectory
            echo "Renaming directory: '$subdir' to '$new_subdir_path'"
            mv -- "$subdir" "$new_subdir_path"
            
            # Process files in the renamed subdirectory
            find "$new_subdir_path" -maxdepth 1 -type f | while read -r file; do
                # Get the original filename without extension
                original_filename=$(basename "$file")
                extension="${original_filename##*.}"
                original_basename="${original_filename%.*}"
                
                # Replace periods with spaces in the filename (without extension)
                new_basename="${original_basename//./ }"
                new_filename="$new_basename.$extension"
                
                # Only proceed if the name actually changed
                if [ "$original_filename" != "$new_filename" ]; then
                    # Construct new file path
                    new_file_path="$(dirname "$file")/$new_filename"
                    
                    # Rename the file
                    echo "Renaming file: '$file' to '$new_file_path'"
                    mv -- "$file" "$new_file_path"
                fi
            done
        fi
    done

    echo "Operation completed successfully."
}

# Example usage:
# rename_subfolders_and_files "/path/to/games"


rename_folders_and_files /your/download/dir/here
rename_subfolders_and_files /your/download/dir/here

echo "done renaming. moving folders now"

mkdir /your/backup/dest/dir/here/gogbackups/
mv /your/download/dir/here/backup* /your/backup/dest/dir/here/gogbackups

# Define the source and destination directories
SOURCE_DIR="/your/downloads/dir/here"
DEST_DIR="/your/games/installer/folder/here/"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory $SOURCE_DIR does not exist."
  exit 1
fi

# Check if the destination directory exists
if [ ! -d "$DEST_DIR" ]; then
  echo "Destination directory $DEST_DIR does not exist."
  exit 1
fi

# Iterate over each item in the source directory
for item in "$SOURCE_DIR"/*; do
  # Extract the base name of the item
  base_name=$(basename "$item")
  echo "checking if $base_name already exists in gog games folder"
  # Check if the item exists in the destination directory
  if [ -e "$DEST_DIR/$base_name" ]; then
    # If it exists, remove it
    echo "$base_name already exists, deleting existing folder"
    rm -rf "$DEST_DIR/$base_name"
  else
    echo "$base_name does not already exist"
  fi

  # Move the item to the destination directory
  echo "moving $base_name folder from download folder to gog games folder"
  mv "$item" "$DEST_DIR"
done

echo "Contents of $SOURCE_DIR have been moved to $DEST_DIR, overwriting existing folders."