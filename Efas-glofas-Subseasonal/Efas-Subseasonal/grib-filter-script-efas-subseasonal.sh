#!/bin/bash
INPUT_FOLDER="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-Hydro-Branch/Efas-glofas-Subseasonal/Efas-Subseasonal/Orig-Files"
RULES_path="/perm/ecm3644/CEMS-FLOOD-DATA-SAMPLES/Samples-Hydro-Branch/Efas-glofas-Subseasonal/Efas-Subseasonal"
grib_filter_path="/perm/maro/ecc_hydro_cems_c3s/adapted/bin"

for file in "$INPUT_FOLDER"/*.grib; do
    base=$(basename "$file" .grib)
    echo "Processing: $file"
    "$grib_filter_path/"grib_filter "$RULES_path/filter_rules-Efas-Subseasonal-Forcings" "$file" -o "$INPUT_FOLDER/${base}-sample.grib"
    echo "$INPUT_FOLDER/${base}-sample.grib"
done

echo "All files processed!"


