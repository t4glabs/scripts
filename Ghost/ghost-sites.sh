#!/bin/bash

# === Configuration ===
BASE_WWW_DIR="/var/www"
EXCLUDE_DIRS=("html" "cgi-bin")
# === End of Configuration ===

print_separator() {
  printf '%.0s-' {1..60}
  printf '\n'
}

item_in_array() {
  local item="$1"
  shift
  local arr=("$@")
  for i in "${arr[@]}"; do
    [[ "$i" == "$item" ]] && return 0
  done
  return 1
}

echo "================================================"
echo "  Ghost Version & Info Checker"
echo "================================================"
echo

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root"
   echo "       Use: sudo $0"
   exit 1
fi

found_ghost_instance=false

for dir_path in "${BASE_WWW_DIR}"/*/; do
    potential_user=$(basename "${dir_path%/}")
    dir_path="${dir_path%/}"  # Remove trailing slash

    # Skip excluded directories
    if item_in_array "$potential_user" "${EXCLUDE_DIRS[@]}"; then
        continue  # Silent skip for excluded directories
    fi

    # Validate Linux user
    if ! id "$potential_user" &>/dev/null; then
        echo "Warning: Directory '$potential_user' has no matching user. Skipping."
        continue
    fi

    # Check Ghost installation
    ghost_install_dir="${BASE_WWW_DIR}/${potential_user}"
    if [[ ! -d "${ghost_install_dir}/content" ]]; then
        continue  # Silent skip for directories without Ghost content
    fi

    print_separator
    echo "Processing User/Site: $potential_user"
    echo "Directory: $ghost_install_dir"
    echo

    # Get Ghost information
    ghost_output=$(sudo -H -u "$potential_user" bash -c "cd \"$ghost_install_dir\" && ghost version 2>/dev/null && ghost config get url 2>/dev/null")
    
    if [[ -z "$ghost_output" ]]; then
        echo "  No valid Ghost installation found"
        continue
    fi

    found_ghost_instance=true

    # Parse information
    cli_version=$(awk '/Ghost-CLI version:/ {print $NF}' <<< "$ghost_output")
    ghost_version=$(awk '/Ghost version:/ {print $3}' <<< "$ghost_output")
    ghost_url=$(grep -E '^https?://' <<< "$ghost_output" | tail -n1)

    echo "  Site URL: ${ghost_url:-N/A}"
    echo "  Ghost-CLI Version: ${cli_version:-N/A}"
    echo "  Ghost Version: ${ghost_version:-N/A}"
done

print_separator
[[ "$found_ghost_instance" = true ]] && echo "All checks complete." || echo "No Ghost instances found."
echo "================================================"
