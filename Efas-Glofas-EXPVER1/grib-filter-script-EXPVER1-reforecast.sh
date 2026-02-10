#!/bin/bash
module load python3
module load eccodes
INPUT_FOLDER="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-EXPVER1"
RULES_path="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-EXPVER1"
grib_filter_path="/perm/maro/ecc_hydro_cems_c3s/adapted/bin"
PYTHON_SCRIPT="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-EXPVER1/reforecast-ref-date.py"   # <-- change path

echo "---- Step 1: Creating sample files ----"

for file in "$INPUT_FOLDER"/*.grib; do
    base=$(basename "$file" .grib)
    echo "Processing: $file"

    "$grib_filter_path/grib_filter" \
    "$RULES_path/grib_filter_script_EXPVER1_final" \
    "$file" \
    -o "$INPUT_FOLDER/${base}-sample.grib"

done

echo "All sample files created!"
echo "---- Step 2: Running python script only on reforecast sample files ----"

for file in "$INPUT_FOLDER"/*reforecast*sample*.grib; do
    # skip if no match
    [ -e "$file" ] || continue

    echo "Running python script on: $file"
    python3 "$PYTHON_SCRIPT" "$file"
    echo "Done: $file"
    echo "-----------------------------"
done

echo "All processing completed!"
