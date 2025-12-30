#!/bin/bash
# Consolidate companion template pairs into combined zips
# Finds matching templates in template_peppy and templates_spectrum
# Creates combined zip in templates_peppy_spectrum
# Removes original separate zips

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE - No changes will be made ==="
    echo ""
fi

# Extract template prefix by stripping known suffixes
get_template_prefix() {
    local name="$1"
    echo "$name" | sed -E 's/_(meter|spectr|spectrum|vu)$//'
}

# Find companion pairs
find_companion_pairs() {
    echo "Scanning for companion pairs..."
    echo ""
    
    # Get all meter templates
    for meter_zip in template_peppy/*/*/*.zip; do
        [[ -f "$meter_zip" ]] || continue
        
        local meter_name=$(basename "$meter_zip" .zip)
        local meter_dir=$(dirname "$meter_zip")
        local res_path=$(echo "$meter_dir" | grep -oE '[0-9]+/[0-9]+')
        local prefix=$(get_template_prefix "$meter_name")
        
        # Look for matching spectrum
        local spectrum_dir="templates_spectrum/${res_path}"
        [[ -d "$spectrum_dir" ]] || continue
        
        for spectrum_zip in "$spectrum_dir"/*.zip; do
            [[ -f "$spectrum_zip" ]] || continue
            
            local spectrum_name=$(basename "$spectrum_zip" .zip)
            local spectrum_prefix=$(get_template_prefix "$spectrum_name")
            
            if [[ "$prefix" == "$spectrum_prefix" ]]; then
                echo "PAIR FOUND:"
                echo "  Meter:    $meter_zip"
                echo "  Spectrum: $spectrum_zip"
                echo "  Prefix:   $prefix"
                echo ""
                
                if [[ "$DRY_RUN" == false ]]; then
                    consolidate_pair "$meter_zip" "$spectrum_zip" "$prefix" "$res_path"
                fi
            fi
        done
    done
}

# Consolidate a pair into combined zip
consolidate_pair() {
    local meter_zip="$1"
    local spectrum_zip="$2"
    local prefix="$3"
    local res_path="$4"
    
    local work_dir=$(mktemp -d)
    local combined_name="${prefix}"
    local combined_dir="${work_dir}/${combined_name}"
    local output_dir="templates_peppy_spectrum/${res_path}"
    local output_zip="${output_dir}/${combined_name}.zip"
    
    echo "Consolidating: $prefix"
    echo "  Work dir: $work_dir"
    
    # Create combined structure
    mkdir -p "${combined_dir}/templates"
    mkdir -p "${combined_dir}/templates_spectrum"
    
    # Extract meter zip
    echo "  Extracting meter..."
    unzip -q "$meter_zip" -d "${work_dir}/meter_temp"
    
    # Find the extracted folder (may have different name)
    local meter_folder=$(find "${work_dir}/meter_temp" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -z "$meter_folder" ]]; then
        echo "  ERROR: No folder found in meter zip"
        rm -rf "$work_dir"
        return 1
    fi
    
    # Move meter contents to templates subfolder
    local meter_folder_name=$(basename "$meter_folder")
    mv "$meter_folder" "${combined_dir}/templates/${meter_folder_name}"
    
    # Extract spectrum zip
    echo "  Extracting spectrum..."
    unzip -q "$spectrum_zip" -d "${work_dir}/spectrum_temp"
    
    # Find the extracted folder
    local spectrum_folder=$(find "${work_dir}/spectrum_temp" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -z "$spectrum_folder" ]]; then
        echo "  ERROR: No folder found in spectrum zip"
        rm -rf "$work_dir"
        return 1
    fi
    
    # Move spectrum contents to templates_spectrum subfolder
    local spectrum_folder_name=$(basename "$spectrum_folder")
    mv "$spectrum_folder" "${combined_dir}/templates_spectrum/${spectrum_folder_name}"
    
    # Find preview from either source (prefer meter)
    echo "  Looking for preview..."
    local preview_found=false
    for src_dir in "${combined_dir}/templates/${meter_folder_name}" "${combined_dir}/templates_spectrum/${spectrum_folder_name}"; do
        for preview in "$src_dir"/preview.{png,jpg,jpeg} "$src_dir"/art.{png,jpg}; do
            if [[ -f "$preview" ]]; then
                cp "$preview" "${combined_dir}/$(basename "$preview")"
                preview_found=true
                echo "  Found preview: $(basename "$preview")"
                break 2
            fi
        done
    done
    
    if [[ "$preview_found" == false ]]; then
        echo "  WARNING: No preview found"
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Create combined zip
    echo "  Creating combined zip..."
    (cd "$work_dir" && zip -rq "${combined_name}.zip" "${combined_name}")
    mv "${work_dir}/${combined_name}.zip" "$output_zip"
    
    echo "  Created: $output_zip"
    
    # Verify zip contents
    echo "  Contents:"
    unzip -l "$output_zip" | grep -E "templates/|templates_spectrum/|preview" | head -10
    
    # Remove original zips
    echo "  Removing originals..."
    rm "$meter_zip"
    rm "$spectrum_zip"
    
    # Remove preview folders if empty/orphaned
    local meter_preview_dir="$(dirname "$meter_zip")/previews"
    local spectrum_preview_dir="$(dirname "$spectrum_zip")/previews"
    
    # Clean up work directory
    rm -rf "$work_dir"
    
    echo "  DONE: $prefix"
    echo ""
}

# Main
echo "========================================"
echo "Companion Template Consolidator"
echo "========================================"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo "Scanning for pairs (no changes will be made)..."
else
    echo "This will:"
    echo "  1. Find matching pairs in template_peppy and templates_spectrum"
    echo "  2. Create combined zips in templates_peppy_spectrum"
    echo "  3. DELETE the original separate zips"
    echo ""
    read -p "Continue? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""
find_companion_pairs

echo "========================================"
echo "Consolidation complete."
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/generate-readmes.sh to update READMEs"
echo "  2. Review changes with: git status"
echo "  3. Commit and push"
echo "========================================"
