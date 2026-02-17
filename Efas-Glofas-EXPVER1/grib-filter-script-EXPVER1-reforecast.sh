#!/bin/bash
shopt -s nullglob

#module load python3
#module load eccodes

INPUT_FOLDER="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-Hydro-Branch/Efas-Glofas-EXPVER1"
RULES_path="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-Hydro-Branch/Efas-Glofas-EXPVER1"
grib_filter_path="/perm/maro/ecc_hydro_cems_c3s/adapted/bin"
PYTHON_SCRIPT="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-Hydro-Branch/Efas-Glofas-EXPVER1/reforecast-ref-date.py"

echo "---- Step 1: Creating sample files ----"

for file in "$INPUT_FOLDER"/*.grib; do
    base=$(basename "$file" .grib)

    # Skip files that are already samples
    if [[ "$base" == *-sample ]]; then
        echo "Skip (already filtered input): $file"
        continue
    fi

    OUT="$INPUT_FOLDER/${base}-sample.grib"
    LOG="$INPUT_FOLDER/${base}.log"

    # Skip if output already exists
    if [[ -e "$OUT" ]]; then
        echo "Skip (output exists): $OUT"
        continue
    fi

    echo "Processing: $file"

    "$grib_filter_path/grib_filter" \
      "$RULES_path/grib_filter_script_EXPVER1_final" \
      "$file" \
      -o "$OUT" \
      -v > "$LOG" 2>&1

    status=$?

    if [[ $status -ne 0 ]]; then
        echo "ERROR processing: $file"
        echo "See log: $LOG"
        continue
    fi

    echo "Created: $OUT"
done




echo "All sample files created!"
echo "---- Step 2: Running python script only on reforecast sample files (excluding seasonal) ----"

shopt -s nullglob
shopt -s nocasematch

for file in "$INPUT_FOLDER"/*-sample.grib; do
    name=$(basename "$file")

    # Skip seasonal
    [[ "$name" == *seasonal* ]] && { echo "Skip (seasonal): $name"; continue; }

    # Keep ONLY reforecast sample files
    [[ "$name" != *reforecast* ]] && { echo "Skip (not reforecast): $name"; continue; }

    echo "Running python script on: $file"
    python3 "$PYTHON_SCRIPT" "$file"
    echo "Done: $file"
    echo "-----------------------------"
done

shopt -u nocasematch


echo "All processing completed!"
