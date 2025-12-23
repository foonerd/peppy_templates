#!/bin/bash
# Generate gallery README.md for each resolution folder
# Templates are stored as .zip files
# Extracts previews and generates index

REPO_URL="https://github.com/foonerd/peppy_templates"
RAW_URL="https://raw.githubusercontent.com/foonerd/peppy_templates/main"

# Find all resolution folders containing zip files
find_resolution_folders() {
    find template_peppy templates_peppy_spectrum templates_spectrum \
        -name "*.zip" 2>/dev/null | \
        xargs -I {} dirname {} | sort -u
}

# Extract preview from zip
# Handles: subfolder/preview.png, preview.png at root, art.png as fallback
extract_preview() {
    local zip_file="$1"
    local output_dir="$2"
    local template_name=$(basename "$zip_file" .zip)
    
    # Create previews directory
    mkdir -p "$output_dir/previews"
    
    # List all files in zip
    local zip_contents=$(unzip -l "$zip_file" 2>/dev/null)
    
    # Try to find preview file (in order of preference)
    local preview_file=""
    local patterns=("preview.png" "preview.jpg" "preview.jpeg" "art.png" "art.jpg")
    
    for pattern in "${patterns[@]}"; do
        # Match both subfolder/pattern and pattern at root
        preview_file=$(echo "$zip_contents" | grep -oE "[^ ]*${pattern}" | head -1)
        if [[ -n "$preview_file" ]]; then
            break
        fi
    done
    
    if [[ -n "$preview_file" ]]; then
        # Extract preview (suppress all output)
        unzip -jo "$zip_file" "$preview_file" -d "$output_dir/previews/" >/dev/null 2>&1
        
        # Get extension
        local ext="${preview_file##*.}"
        
        # Rename to template name
        local extracted_name=$(basename "$preview_file")
        if [[ -f "$output_dir/previews/$extracted_name" ]]; then
            mv "$output_dir/previews/$extracted_name" "$output_dir/previews/${template_name}.${ext}" 2>/dev/null
            echo "${template_name}.${ext}"
            return
        fi
    fi
    
    # No preview found - use placeholder
    # Find script directory and go up to repo root
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_root="$(dirname "$script_dir")"
    local placeholder="$repo_root/assets/no-preview.svg"
    
    if [[ -f "$placeholder" ]]; then
        cp "$placeholder" "$output_dir/previews/${template_name}.svg"
        echo "${template_name}.svg"
    else
        echo ""
    fi
}

# Extract meter info from zip
# Handles both subfolder/meters.txt and meters.txt at root
get_meter_info() {
    local zip_file="$1"
    local field="$2"
    
    # Extract meters.txt content - try subfolder first, then root
    local meters_content=$(unzip -p "$zip_file" "*/meters.txt" 2>/dev/null)
    if [[ -z "$meters_content" ]]; then
        meters_content=$(unzip -p "$zip_file" "meters.txt" 2>/dev/null)
    fi
    
    case "$field" in
        "name")
            echo "$meters_content" | grep -m1 '^\[' | tr -d '[]'
            ;;
        "type")
            echo "$meters_content" | grep -m1 'meter.type' | cut -d'=' -f2 | tr -d ' '
            ;;
        "extended")
            if echo "$meters_content" | grep -q 'config.extend.*=.*True'; then
                echo "Yes"
            else
                echo "No"
            fi
            ;;
        "spectrum")
            if echo "$meters_content" | grep -q 'spectrum.visible.*=.*True'; then
                echo "Yes"
            else
                echo "No"
            fi
            ;;
        "albumart")
            if echo "$meters_content" | grep -q 'albumart.pos'; then
                echo "Yes"
            else
                echo "No"
            fi
            ;;
    esac
}

# Get resolution from path
get_resolution() {
    local dir="$1"
    local width=$(echo "$dir" | cut -d'/' -f2)
    local height=$(echo "$dir" | cut -d'/' -f3)
    
    # Remove leading zeros
    width=$(echo "$width" | sed 's/^0*//')
    height=$(echo "$height" | sed 's/^0*//')
    
    if [[ -n "$width" && -n "$height" && "$height" =~ ^[0-9]+$ ]]; then
        echo "${width}x${height}"
    else
        echo "unknown"
    fi
}

# Get category display name
get_category_name() {
    local dir="$1"
    local category=$(echo "$dir" | cut -d'/' -f1)
    
    case "$category" in
        "template_peppy")
            echo "VU Meters"
            ;;
        "templates_peppy_spectrum")
            echo "VU Meters with Spectrum"
            ;;
        "templates_spectrum")
            echo "Spectrum Analyzers"
            ;;
        *)
            echo "$category"
            ;;
    esac
}

# Generate gallery README for a resolution folder
generate_gallery() {
    local dir="$1"
    local resolution=$(get_resolution "$dir")
    local category=$(get_category_name "$dir")
    local zip_count=$(ls -1 "$dir"/*.zip 2>/dev/null | wc -l)
    
    if [[ "$zip_count" -eq 0 ]]; then
        return
    fi
    
    echo "Processing: $dir ($zip_count templates)"
    
    # Start README
    cat > "$dir/README.md" << EOF
# ${category} - ${resolution}

${zip_count} template(s) available for ${resolution} resolution.

EOF

    # Process each zip
    for zip_file in "$dir"/*.zip; do
        if [[ ! -f "$zip_file" ]]; then
            continue
        fi
        
        local template_name=$(basename "$zip_file" .zip)
        local preview_file=$(extract_preview "$zip_file" "$dir")
        local meter_name=$(get_meter_info "$zip_file" "name")
        local meter_type=$(get_meter_info "$zip_file" "type")
        local has_extended=$(get_meter_info "$zip_file" "extended")
        local has_spectrum=$(get_meter_info "$zip_file" "spectrum")
        local has_albumart=$(get_meter_info "$zip_file" "albumart")
        
        # Template section
        cat >> "$dir/README.md" << EOF
---

## ${template_name}

EOF

        # Add preview if exists
        if [[ -n "$preview_file" ]]; then
            cat >> "$dir/README.md" << EOF
![${template_name}](previews/${preview_file})

EOF
        fi

        cat >> "$dir/README.md" << EOF
| Property | Value |
|----------|-------|
| Meter Name | ${meter_name:-unknown} |
| Meter Type | ${meter_type:-unknown} |
| Extended Config | ${has_extended:-No} |
| Spectrum | ${has_spectrum:-No} |
| Album Art | ${has_albumart:-No} |

**[Download ${template_name}.zip](${template_name}.zip)**

EOF

    done

    # Footer
    cat >> "$dir/README.md" << EOF
---

## Installation

1. Download the desired template zip
2. Extract to \`/data/INTERNAL/peppy_screensaver/templates/\`
3. Select in plugin settings

---

*Part of [PeppyMeter Templates](${REPO_URL})*
EOF

    echo "Generated: $dir/README.md"
}

# Main
echo "Scanning for templates..."

for res_folder in $(find_resolution_folders); do
    if [[ -d "$res_folder" ]]; then
        generate_gallery "$res_folder"
    fi
done

echo "Done."
