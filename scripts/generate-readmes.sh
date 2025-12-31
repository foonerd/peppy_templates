#!/bin/bash
# Generate gallery README.md for each resolution folder
# Templates are stored as .zip files
# Extracts previews and generates index

set -e

REPO_URL="https://github.com/foonerd/peppy_templates"
RAW_URL="https://raw.githubusercontent.com/foonerd/peppy_templates/main"
ASSETS_DIR="assets"
NO_PREVIEW="no-preview.svg"

# ========================================
# Normalization Functions
# ========================================

# Clean a name - replace spaces and special chars
clean_name() {
    echo "$1" | \
        sed 's/ /_/g' | \
        sed 's/&/and/g' | \
        sed 's/+/_/g' | \
        sed 's/__*/_/g' | \
        sed 's/_$//' | \
        sed 's/^_//'
}

# Check if name contains invalid characters
name_needs_cleaning() {
    local name="$1"
    # Returns 0 (true) if name has spaces, &, or +
    [[ "$name" =~ [\ \&\+] ]]
}

# Normalize a single zip file
# - Renames zip if filename has invalid chars
# - Repackages if internal folders have invalid chars
# - NEVER touches files inside (preserves config references)
normalize_zip() {
    local zip_file="$1"
    local zip_dir=$(dirname "$zip_file")
    local zip_name=$(basename "$zip_file")
    local base_name="${zip_name%.zip}"
    local changed=false
    
    # Check if zip filename needs cleaning
    if name_needs_cleaning "$base_name"; then
        local new_base=$(clean_name "$base_name")
        local new_zip="${zip_dir}/${new_base}.zip"
        echo "  Rename zip: $zip_name -> ${new_base}.zip"
        mv "$zip_file" "$new_zip"
        zip_file="$new_zip"
        zip_name="${new_base}.zip"
        base_name="$new_base"
        changed=true
    fi
    
    # Check if internal folders need cleaning
    local folder_list=$(unzip -l "$zip_file" 2>/dev/null | awk '{print $4}' | grep '/$' | sort -u)
    local needs_repack=false
    
    while IFS= read -r folder; do
        [[ -z "$folder" ]] && continue
        if name_needs_cleaning "$folder"; then
            needs_repack=true
            break
        fi
    done <<< "$folder_list"
    
    if [[ "$needs_repack" == true ]]; then
        echo "  Repackaging: $zip_name (fixing folder names)"
        
        local work_dir=$(mktemp -d)
        
        # Extract
        unzip -q "$zip_file" -d "$work_dir"
        
        # Rename folders only (deepest first) - NOT files
        find "$work_dir" -depth -type d | while read -r dir; do
            local dir_base=$(basename "$dir")
            local dir_parent=$(dirname "$dir")
            local dir_cleaned=$(clean_name "$dir_base")
            
            if [[ "$dir_base" != "$dir_cleaned" ]]; then
                echo "    Folder: $dir_base -> $dir_cleaned"
                mv "$dir" "$dir_parent/$dir_cleaned"
            fi
        done
        
        # Get root folder name
        local root_folder=$(ls "$work_dir")
        
        # Create new zip
        (cd "$work_dir" && zip -rq "../repack.zip" "$root_folder")
        
        # Replace original
        mv "$work_dir/../repack.zip" "$zip_file"
        
        # Cleanup
        rm -rf "$work_dir"
        
        changed=true
    fi
    
    if [[ "$changed" == true ]]; then
        return 0
    else
        return 1
    fi
}

# Normalize all templates in repository
# Scans all zips and fixes naming issues
normalize_templates() {
    echo "========================================"
    echo "Normalizing Templates"
    echo "========================================"
    
    local any_changes=false
    
    for zip_file in $(find template_peppy templates_peppy_spectrum templates_spectrum -name "*.zip" 2>/dev/null | sort); do
        if normalize_zip "$zip_file"; then
            any_changes=true
        fi
    done
    
    if [[ "$any_changes" == false ]]; then
        echo "  All templates OK - no normalization needed"
    fi
    
    echo ""
}

# Extract template prefix by stripping known suffixes
get_template_prefix() {
    local name="$1"
    # Strip known suffixes: _meter, _spectr, _spectrum, _vu
    echo "$name" | sed -E 's/_(meter|spectr|spectrum|vu)$//'
}

# Find companion templates across categories
# Only matches between template_peppy and templates_spectrum
# templates_peppy_spectrum is self-contained, no companions
find_companions() {
    local current_zip="$1"
    local current_name=$(basename "$current_zip" .zip)
    local current_dir=$(dirname "$current_zip")
    local current_category=$(echo "$current_dir" | cut -d'/' -f1)
    
    # templates_peppy_spectrum is self-contained - no companions
    [[ "$current_category" == "templates_peppy_spectrum" ]] && return
    
    # Get prefix
    local prefix=$(get_template_prefix "$current_name")
    
    # Extract resolution from path (e.g., 1920/1080)
    local res_path=$(echo "$current_dir" | grep -oE '[0-9]+/[0-9]+')
    
    # Only search the other simple category
    local companions=""
    local search_category=""
    
    if [[ "$current_category" == "template_peppy" ]]; then
        search_category="templates_spectrum"
    elif [[ "$current_category" == "templates_spectrum" ]]; then
        search_category="template_peppy"
    else
        return
    fi
    
    # Look for matching zips in same resolution
    local search_dir="${search_category}/${res_path}"
    [[ -d "$search_dir" ]] || return
    
    for zip in "$search_dir"/*.zip; do
        [[ -f "$zip" ]] || continue
        local zip_name=$(basename "$zip" .zip)
        local zip_prefix=$(get_template_prefix "$zip_name")
        
        if [[ "$zip_prefix" == "$prefix" ]]; then
            companions="${companions}${search_category}|${zip_name}\n"
        fi
    done
    
    echo -e "$companions" | grep -v '^$' || true
}

# Find all resolution folders containing zip files
find_resolution_folders() {
    find template_peppy templates_peppy_spectrum templates_spectrum \
        -name "*.zip" 2>/dev/null | \
        xargs -I {} dirname {} 2>/dev/null | sort -u
}

# Extract preview from zip
# Handles: subfolder/preview.png, preview.png at root, art.png as fallback
# Also handles combined zips with nested structure
extract_preview() {
    local zip_file="$1"
    local output_dir="$2"
    local template_name=$(basename "$zip_file" .zip)
    
    # Create previews directory
    mkdir -p "$output_dir/previews"
    
    # List all files in zip
    local zip_contents=$(unzip -l "$zip_file" 2>/dev/null || true)
    
    # Try to find preview file (in order of preference)
    # For combined zips, preview should be at top level: name/preview.png
    local preview_file=""
    local patterns=("preview.png" "preview.jpg" "preview.jpeg" "art.png" "art.jpg")
    
    for pattern in "${patterns[@]}"; do
        # Match both subfolder/pattern and pattern at root (case insensitive)
        # Prioritize shorter paths (top-level preview over nested)
        preview_file=$(echo "$zip_contents" | grep -ioE "[^ ]*${pattern}" | sort | head -1)
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
# Supports both meters.txt (VU meters) and spectrum.txt (spectrum analyzers)
# Handles packs with multiple templates
# Handles combined zips (templates_peppy_spectrum) with nested structure
get_meter_info() {
    local zip_file="$1"
    local field="$2"
    
    # Try meters.txt first, then spectrum.txt
    local config_content=""
    local config_type="meter"
    
    # Try meters.txt in various locations
    # Standard: subfolder/meters.txt
    config_content=$(unzip -p "$zip_file" "*/meters.txt" 2>/dev/null | tr -d '\r' || true)
    
    # Combined structure: */templates/*/meters.txt
    if [[ -z "$config_content" ]]; then
        config_content=$(unzip -p "$zip_file" "*/templates/*/meters.txt" 2>/dev/null | tr -d '\r' || true)
    fi
    
    # Root: meters.txt
    if [[ -z "$config_content" ]]; then
        config_content=$(unzip -p "$zip_file" "meters.txt" 2>/dev/null | tr -d '\r' || true)
    fi
    
    # Try spectrum.txt in various locations
    if [[ -z "$config_content" ]]; then
        config_content=$(unzip -p "$zip_file" "*/spectrum.txt" 2>/dev/null | tr -d '\r' || true)
        config_type="spectrum"
    fi
    
    # Combined structure: */templates_spectrum/*/spectrum.txt
    if [[ -z "$config_content" ]]; then
        config_content=$(unzip -p "$zip_file" "*/templates_spectrum/*/spectrum.txt" 2>/dev/null | tr -d '\r' || true)
        config_type="spectrum"
    fi
    
    # Root: spectrum.txt
    if [[ -z "$config_content" ]]; then
        config_content=$(unzip -p "$zip_file" "spectrum.txt" 2>/dev/null | tr -d '\r' || true)
        config_type="spectrum"
    fi
    
    case "$field" in
        "name")
            # Get ALL section names for packs
            local count=$(echo "$config_content" | grep -c '^\[' || echo 0)
            
            if [[ "$count" -gt 1 ]]; then
                # Pack with multiple templates - list all with bullets
                echo "$config_content" | grep '^\[' | tr -d '[]' | sed 's/^/- /'
            elif [[ "$count" -eq 1 ]]; then
                # Single template
                echo "$config_content" | grep '^\[' | tr -d '[]' | xargs
            else
                echo ""
            fi
            ;;
        "count")
            # Return number of templates in pack
            echo "$config_content" | grep -c '^\[' || echo 0
            ;;
        "type")
            if [[ "$config_type" == "spectrum" ]]; then
                echo "spectrum"
            else
                echo "$config_content" | grep -m1 'meter.type' | cut -d'=' -f2 | tr -d ' ' | xargs
            fi
            ;;
        "extended")
            if echo "$config_content" | grep -qi 'config.extend.*=.*true'; then
                echo "Yes"
            else
                echo "No"
            fi
            ;;
        "spectrum")
            if [[ "$config_type" == "spectrum" ]]; then
                echo "Yes"
            elif echo "$config_content" | grep -qi 'spectrum.*='; then
                local spec_val=$(echo "$config_content" | grep -i 'spectrum' | grep -v '^#' | head -1 | cut -d'=' -f2 | tr -d ' ')
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
            if echo "$config_content" | grep -qi 'albumart.pos'; then
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
            echo "Combined VU Meter + Spectrum templates (self-contained with both parts)." >> "$dir/README.md"
            ;;
        "templates_spectrum")
            echo "Spectrum Analyzer templates." >> "$dir/README.md"
            ;;
    esac
    
    echo "" >> "$dir/README.md"
    echo "---" >> "$dir/README.md"
    echo "" >> "$dir/README.md"

    # Process each zip file (sorted alphabetically)
    local res_path=$(echo "$dir" | grep -oE '[0-9]+/[0-9]+')
    
    for zip_file in $(ls -1 "$dir"/*.zip 2>/dev/null | sort); do
        [[ -f "$zip_file" ]] || continue
        
        local template_name=$(basename "$zip_file" .zip)
        echo "  - $template_name"
        
        # Extract preview
        local preview_file=$(extract_preview "$zip_file" "$dir")
        
        # Get meter info
        local meter_name=$(get_meter_info "$zip_file" "name")
        local meter_count=$(get_meter_info "$zip_file" "count")
        local meter_type=$(get_meter_info "$zip_file" "type")
        local has_extended=$(get_meter_info "$zip_file" "extended")
        local has_spectrum=$(get_meter_info "$zip_file" "spectrum")
        local has_albumart=$(get_meter_info "$zip_file" "albumart")
        
        # Determine if this is a pack
        local is_pack="No"
        if [[ "$meter_count" -gt 1 ]]; then
            is_pack="Yes (${meter_count} templates)"
        fi
        
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

        # Specs table - different format for packs vs single
        if [[ "$meter_count" -gt 1 ]]; then
            # Pack format - list meters separately
            cat >> "$dir/README.md" << EOF
| Property | Value |
|----------|-------|
| Template Pack | ${is_pack} |
| Meter Type | ${meter_type:-linear} |
| Extended Config | ${has_extended:-No} |
| Spectrum | ${has_spectrum:-No} |
| Album Art | ${has_albumart:-No} |

**Included Meters:**

${meter_name}

EOF
        else
            # Single template format
            cat >> "$dir/README.md" << EOF
| Property | Value |
|----------|-------|
| Meter Name | ${meter_name:-unknown} |
| Meter Type | ${meter_type:-linear} |
| Extended Config | ${has_extended:-No} |
| Spectrum | ${has_spectrum:-No} |
| Album Art | ${has_albumart:-No} |

EOF
        fi

        # Get install info for this template
        local this_install_info=""
        local this_label=""
        case "$category" in
            "template_peppy")
                this_install_info="Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates/\`"
                this_label="VU Meter"
                ;;
            "templates_peppy_spectrum")
                this_install_info="BOTH_PARTS"
                this_label="VU Meter + Spectrum (combined)"
                ;;
            "templates_spectrum")
                this_install_info="Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates_spectrum/\`"
                this_label="Spectrum"
                ;;
        esac

        # Check for companion templates
        local companions=$(find_companions "$zip_file")
        
        if [[ -n "$companions" ]]; then
            # Has companions - show as Complete Set
            cat >> "$dir/README.md" << EOF
> **Important:** This template is part of a set. Both parts must be installed for the meters to work correctly.

**Complete Set (both required):**

- ${this_label}: [${template_name}.zip](${template_name}.zip)
  - Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates/\`
EOF
            echo "$companions" | while IFS='|' read -r comp_category comp_name; do
                [[ -z "$comp_category" ]] && continue
                local comp_label=""
                local comp_install=""
                case "$comp_category" in
                    "template_peppy")
                        comp_label="VU Meter"
                        comp_install="Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates/\`"
                        ;;
                    "templates_spectrum")
                        comp_label="Spectrum"
                        comp_install="Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates_spectrum/\`"
                        ;;
                esac
                local comp_path="${comp_category}/${res_path}/${comp_name}.zip"
                echo "- ${comp_label}: [${comp_name}.zip](../../../${comp_path})" >> "$dir/README.md"
                echo "  - ${comp_install}" >> "$dir/README.md"
            done
            echo "" >> "$dir/README.md"
        elif [[ "$this_install_info" == "BOTH_PARTS" ]]; then
            # Combined template - show both install steps
            cat >> "$dir/README.md" << EOF
**Download:** [${template_name}.zip](${template_name}.zip)

**Install (both required):**
1. Extract the zip file
2. Copy \`templates/\` contents to \`/data/INTERNAL/peppy_screensaver/templates/\`
3. Copy \`templates_spectrum/\` contents to \`/data/INTERNAL/peppy_screensaver/templates_spectrum/\`

EOF
        else
            # No companions - single download
            cat >> "$dir/README.md" << EOF
**Download:** [${template_name}.zip](${template_name}.zip)

**Install:** ${this_install_info}

EOF
        fi

        cat >> "$dir/README.md" << EOF
---

EOF

    done

    # Footer
    cat >> "$dir/README.md" << EOF

## Installation

1. Download the desired template zip(s)
2. Extract each to the path shown next to its download link
3. Select in plugin settings

---

*Part of [PeppyMeter Templates](${REPO_URL})*
EOF

    echo "Generated: $dir/README.md"
}

# Generate master catalog with all templates grouped by resolution
generate_catalog() {
    echo ""
    echo "========================================"
    echo "Generating Master Catalog"
    echo "========================================"
    
    mkdir -p catalog
    
    # Collect all resolutions and their templates
    declare -A resolution_templates
    declare -A resolution_categories
    
    for zip_file in $(find template_peppy templates_peppy_spectrum templates_spectrum -name "*.zip" 2>/dev/null); do
        local dir=$(dirname "$zip_file")
        local category=$(echo "$dir" | cut -d'/' -f1)
        local res=$(echo "$dir" | grep -oE '[0-9]+/[0-9]+' | tr '/' 'x')
        
        [[ -z "$res" ]] && continue
        
        # Track templates per resolution
        resolution_templates[$res]="${resolution_templates[$res]}${zip_file}\n"
        
        # Track categories per resolution
        case "$category" in
            "template_peppy")
                resolution_categories[$res]="${resolution_categories[$res]}VU,"
                ;;
            "templates_spectrum")
                resolution_categories[$res]="${resolution_categories[$res]}Spectrum,"
                ;;
            "templates_peppy_spectrum")
                resolution_categories[$res]="${resolution_categories[$res]}Combined,"
                ;;
        esac
    done
    
    # Generate index README
    cat > catalog/README.md << 'EOF'
# PeppyMeter Template Catalog

Browse templates by screen resolution.

## Available Resolutions

| Resolution | Templates | Types |
|------------|-----------|-------|
EOF

    # Sort resolutions and add to index
    for res in $(echo "${!resolution_templates[@]}" | tr ' ' '\n' | sort); do
        local count=$(echo -e "${resolution_templates[$res]}" | grep -c '.zip' || echo 0)
        local cats=$(echo "${resolution_categories[$res]}" | tr ',' '\n' | sort -u | grep -v '^$' | tr '\n' ', ' | sed 's/, $//')
        echo "| [${res}](${res}.md) | ${count} | ${cats} |" >> catalog/README.md
    done
    
    # Add installation instructions
    cat >> catalog/README.md << 'EOF'

---

## Installation Instructions

All paths are relative to `/data/INTERNAL/peppy_screensaver/`

### VU Meter Only (from template_peppy)

1. Download the zip file
2. Extract the zip file
3. Copy the extracted folder to `templates/`

**Example:**
```
Download: 800x480_retro_wood.zip
Extract:  800x480_retro_wood/
Copy to:  /data/INTERNAL/peppy_screensaver/templates/800x480_retro_wood/
```

### Spectrum Only (from templates_spectrum)

1. Download the zip file
2. Extract the zip file
3. Copy the extracted folder to `templates_spectrum/`

**Example:**
```
Download: 800x480_retro_wood.zip
Extract:  800x480_retro_wood/
Copy to:  /data/INTERNAL/peppy_screensaver/templates_spectrum/800x480_retro_wood/
```

### Combined VU + Spectrum (from templates_peppy_spectrum)

1. Download the zip file
2. Extract the zip file
3. Open the extracted folder - you will see `templates/` and `templates_spectrum/` subfolders
4. Copy the contents of `templates/` to `templates/`
5. Copy the contents of `templates_spectrum/` to `templates_spectrum/`

**Example:**
```
Download: 800x480_retro_wood.zip
Extract:  800x480_retro_wood/
Inside:   800x480_retro_wood/templates/800x480_retro_wood/
          800x480_retro_wood/templates_spectrum/800x480_retro_wood/

Copy to:  /data/INTERNAL/peppy_screensaver/templates/800x480_retro_wood/
          /data/INTERNAL/peppy_screensaver/templates_spectrum/800x480_retro_wood/
```

---

*Auto-generated by [PeppyMeter Templates](https://github.com/foonerd/peppy_templates)*
EOF

    echo "Generated: catalog/README.md"
    
    # Generate per-resolution catalog files
    for res in $(echo "${!resolution_templates[@]}" | tr ' ' '\n' | sort); do
        generate_resolution_catalog "$res" "${resolution_templates[$res]}"
    done
}

# Generate catalog page for a single resolution
generate_resolution_catalog() {
    local res="$1"
    local templates="$2"
    
    echo "  Generating catalog/${res}.md"
    
    cat > "catalog/${res}.md" << EOF
# ${res} Templates

All templates available for ${res} resolution.

---

EOF

    # Process each template (sorted alphabetically)
    echo -e "$templates" | grep '.zip' | sort | while read -r zip_file; do
        [[ -z "$zip_file" ]] && continue
        [[ ! -f "$zip_file" ]] && continue
        
        local template_name=$(basename "$zip_file" .zip)
        local dir=$(dirname "$zip_file")
        local category=$(echo "$dir" | cut -d'/' -f1)
        local res_path=$(echo "$dir" | grep -oE '[0-9]+/[0-9]+')
        
        # Determine type badge and install instructions
        local type_badge=""
        local install_info=""
        case "$category" in
            "template_peppy")
                type_badge="VU Meter"
                install_info="Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates/\`"
                ;;
            "templates_spectrum")
                type_badge="Spectrum"
                install_info="Extract and copy folder to \`/data/INTERNAL/peppy_screensaver/templates_spectrum/\`"
                ;;
            "templates_peppy_spectrum")
                type_badge="Combined"
                install_info="BOTH_PARTS"
                ;;
        esac
        
        # Get meter info
        local meter_name=$(get_meter_info "$zip_file" "name")
        local meter_count=$(get_meter_info "$zip_file" "count")
        local meter_type=$(get_meter_info "$zip_file" "type")
        
        # Check if preview exists in category folder
        local preview_path=""
        for ext in png jpg jpeg svg; do
            if [[ -f "${dir}/previews/${template_name}.${ext}" ]]; then
                preview_path="../${dir}/previews/${template_name}.${ext}"
                break
            fi
        done
        
        # Template entry
        cat >> "catalog/${res}.md" << EOF
## ${template_name}

**Type:** ${type_badge}

EOF

        # Add preview if exists
        if [[ -n "$preview_path" ]]; then
            echo "![${template_name}](${preview_path})" >> "catalog/${res}.md"
            echo "" >> "catalog/${res}.md"
        fi
        
        # Show meter names for packs
        if [[ "$meter_count" -gt 1 ]]; then
            cat >> "catalog/${res}.md" << EOF
**Included Meters (${meter_count}):**

${meter_name}

EOF
        elif [[ -n "$meter_name" ]]; then
            echo "**Meter:** ${meter_name}" >> "catalog/${res}.md"
            echo "" >> "catalog/${res}.md"
        fi
        
        # Download and install info
        cat >> "catalog/${res}.md" << EOF
**Download:** [${template_name}.zip](../${zip_file})

EOF

        # Show install instructions based on type
        if [[ "$install_info" == "BOTH_PARTS" ]]; then
            cat >> "catalog/${res}.md" << EOF
**Install (both required):**
1. Extract the zip file
2. Copy \`templates/${template_name}/\` to \`/data/INTERNAL/peppy_screensaver/templates/\`
3. Copy \`templates_spectrum/${template_name}/\` to \`/data/INTERNAL/peppy_screensaver/templates_spectrum/\`

EOF
        else
            cat >> "catalog/${res}.md" << EOF
**Install:** ${install_info}

EOF
        fi

        echo "---" >> "catalog/${res}.md"
        echo "" >> "catalog/${res}.md"

    done
    
    echo "Generated: catalog/${res}.md"
}

# Main

# First normalize any templates with invalid names
normalize_templates

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

# Generate catalog
generate_catalog
