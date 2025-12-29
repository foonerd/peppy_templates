#!/bin/bash
# Generate gallery README.md for each resolution folder
# Templates are stored as .zip files
# Extracts previews and generates index

set -e

REPO_URL="https://github.com/foonerd/peppy_templates"
RAW_URL="https://raw.githubusercontent.com/foonerd/peppy_templates/main"
ASSETS_DIR="assets"
NO_PREVIEW="no-preview.svg"

# Find all resolution folders containing zip files
find_resolution_folders() {
    find template_peppy templates_peppy_spectrum templates_spectrum \
        -name "*.zip" 2>/dev/null | \
        xargs -I {} dirname {} 2>/dev/null | sort -u
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
    local zip_contents=$(unzip -l "$zip_file" 2>/dev/null || true)
    
    # Try to find preview file (in order of preference)
    local preview_file=""
    local patterns=("preview.png" "preview.jpg" "preview.jpeg" "art.png" "art.jpg")
    
    for pattern in "${patterns[@]}"; do
        # Match both subfolder/pattern and pattern at root (case insensitive)
        preview_file=$(echo "$zip_contents" | grep -ioE "[^ ]*${pattern}" | head -1)
        if [[ -n "$preview_file" ]]; then
            break
        fi
    done
    
    if [[ -n "$preview_file" ]]; then
        # Extract preview (suppress all output)
        unzip -jo "$zip_file" "$preview_file" -d "$output_dir/previews/" >/dev/null 2>&1 || true
        
        # Get extension
        local ext="${preview_file##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        
        # Rename to template name
        local extracted_name=$(basename "$preview_file")
        if [[ -f "$output_dir/previews/$extracted_name" ]]; then
            mv "$output_dir/previews/$extracted_name" "$output_dir/previews/${template_name}.${ext}"
            echo "${template_name}.${ext}"
            return
        fi
    fi
    
    # No preview found - use placeholder
    if [[ -f "$ASSETS_DIR/$NO_PREVIEW" ]]; then
        cp "$ASSETS_DIR/$NO_PREVIEW" "$output_dir/previews/${template_name}.svg"
        echo "${template_name}.svg"
    else
        echo ""
    fi
}

# Extract meter info from zip
# CRITICAL: tr -d '\r' strips Windows line endings that break markdown tables
get_meter_info() {
    local zip_file="$1"
    local field="$2"
    
    # Extract meters.txt content and strip Windows line endings
    local meters_content=$(unzip -p "$zip_file" "*/meters.txt" 2>/dev/null | tr -d '\r' || true)
    
    # If not found in subfolder, try root
    if [[ -z "$meters_content" ]]; then
        meters_content=$(unzip -p "$zip_file" "meters.txt" 2>/dev/null | tr -d '\r' || true)
    fi
    
    case "$field" in
        "name")
            echo "$meters_content" | grep -m1 '^\[' | tr -d '[]' | xargs
            ;;
        "type")
            echo "$meters_content" | grep -m1 'meter.type' | cut -d'=' -f2 | tr -d ' ' | xargs
            ;;
        "extended")
            if echo "$meters_content" | grep -qi 'config.extend.*=.*true'; then
                echo "Yes"
            else
                echo "No"
            fi
            ;;
        "spectrum")
            if echo "$meters_content" | grep -qi 'spectrum.*='; then
                local spec_val=$(echo "$meters_content" | grep -i 'spectrum' | grep -v '^#' | head -1 | cut -d'=' -f2 | tr -d ' ')
                if [[ -n "$spec_val" && "$spec_val" != "none" && "$spec_val" != "None" ]]; then
                    echo "Yes"
                else
                    echo "No"
                fi
            else
                echo "No"
            fi
            ;;
        "albumart")
            if echo "$meters_content" | grep -qi 'albumart.pos'; then
                echo "Yes"
            else
                echo "No"
            fi
            ;;
    esac
}

# Generate gallery README for a resolution folder
generate_gallery() {
    local dir="$1"
    local category=$(echo "$dir" | cut -d'/' -f1)
    local resolution=$(basename "$dir")
    
    echo "Processing: $dir"
    
    # Header
    cat > "$dir/README.md" << EOF
# ${resolution} Templates

EOF

    # Add category description
    case "$category" in
        "template_peppy")
            echo "VU Meter templates for PeppyMeter Screensaver." >> "$dir/README.md"
            ;;
        "templates_peppy_spectrum")
            echo "VU Meter with Spectrum overlay templates." >> "$dir/README.md"
            ;;
        "templates_spectrum")
            echo "Spectrum Analyzer templates." >> "$dir/README.md"
            ;;
    esac
    
    echo "" >> "$dir/README.md"
    echo "---" >> "$dir/README.md"
    echo "" >> "$dir/README.md"

    # Process each zip file
    for zip_file in "$dir"/*.zip; do
        [[ -f "$zip_file" ]] || continue
        
        local template_name=$(basename "$zip_file" .zip)
        echo "  - $template_name"
        
        # Extract preview
        local preview_file=$(extract_preview "$zip_file" "$dir")
        
        # Get meter info
        local meter_name=$(get_meter_info "$zip_file" "name")
        local meter_type=$(get_meter_info "$zip_file" "type")
        local has_extended=$(get_meter_info "$zip_file" "extended")
        local has_spectrum=$(get_meter_info "$zip_file" "spectrum")
        local has_albumart=$(get_meter_info "$zip_file" "albumart")
        
        # Template section
        cat >> "$dir/README.md" << EOF
## ${template_name}

EOF

        # Preview image
        if [[ -n "$preview_file" && -f "$dir/previews/$preview_file" ]]; then
            cat >> "$dir/README.md" << EOF
![${template_name}](previews/${preview_file})

EOF
        fi

        # Specs table
        cat >> "$dir/README.md" << EOF
| Property | Value |
|----------|-------|
| Meter Name | ${meter_name:-unknown} |
| Meter Type | ${meter_type:-linear} |
| Extended Config | ${has_extended:-No} |
| Spectrum | ${has_spectrum:-No} |
| Album Art | ${has_albumart:-No} |

[Download ${template_name}.zip](${template_name}.zip)

---

EOF

    done

    # Footer
    cat >> "$dir/README.md" << EOF

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
echo "========================================"
echo "PeppyMeter Template README Generator"
echo "========================================"
echo ""

folders=$(find_resolution_folders)

if [[ -z "$folders" ]]; then
    echo "No template folders found containing .zip files"
    exit 0
fi

echo "Found folders:"
echo "$folders"
echo ""

for res_folder in $folders; do
    if [[ -d "$res_folder" ]]; then
        generate_gallery "$res_folder"
    fi
done

echo ""
echo "Done."
