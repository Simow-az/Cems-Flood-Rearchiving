set -euo pipefail
shopt -s nullglob

IN_DIR="${1:-.}"

GRIB_FILTER_DEFAULT="/perm/maro/ecc_hydro_cems_c3s/adapted/bin/grib_filter"
GRIB_SET_DEFAULT="/perm/maro/ecc_hydro_cems_c3s/adapted/bin/grib_set"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_FILTER="${SCRIPT_DIR}/grib_filter_C3S_V1"


if [[ -x "$GRIB_FILTER_DEFAULT" ]]; then
  GRIB_FILTER="$GRIB_FILTER_DEFAULT"
elif command -v grib_filter >/dev/null 2>&1; then
  GRIB_FILTER="$(command -v grib_filter)"
else
  echo "ERROR: grib_filter not found" >&2
  exit 1
fi

if [[ -x "$GRIB_SET_DEFAULT" ]]; then
  GRIB_SET="$GRIB_SET_DEFAULT"
elif command -v grib_set >/dev/null 2>&1; then
  GRIB_SET="$(command -v grib_set)"
else
  echo "ERROR: grib_set not found" >&2
  exit 1
fi

if [[ ! -f "$BASE_FILTER" ]]; then
  echo "ERROR: base filter file not found: $BASE_FILTER" >&2
  exit 1
fi

echo "Using grib_filter: $GRIB_FILTER"
echo "Using grib_set   : $GRIB_SET"
echo "Using rules file : $BASE_FILTER"
echo "grib_filter -V:"
"$GRIB_FILTER" -V || true
echo "----------------------------------------"

choose_model_keys() {
  local fname="$1"
  case "$fname" in
    *pcr_globwb* ) echo "backgroundProcess=153,generatingProcessIdentifier=40"  ;;
    *ecland*     ) echo "backgroundProcess=151,generatingProcessIdentifier=40"  ;;
    *mhm*        ) echo "backgroundProcess=152,generatingProcessIdentifier=40"  ;;
    *glofas*     ) echo "backgroundProcess=147,generatingProcessIdentifier=120" ;;
    *            ) echo "" ;;
  esac
}

mapfile -d '' FILES < <(find "$IN_DIR" -maxdepth 1 -type f \
  \( -iname '*.grib2' -o -iname '*.grb2' -o -iname '*.grib' -o -iname '*.grb' \) \
  ! -iname '*-sample.*' \
  -print0)

echo "Found ${#FILES[@]} GRIB files in: $IN_DIR"

created=0
failed=0
skipped_exists=0
skipped_unknown_model=0

for f in "${FILES[@]}"; do
  name="$(basename -- "$f")"
  dir="$(dirname -- "$f")"
  base="${name%.*}"
  ext="${name##*.}"

  out1="${dir}/${base}-sample.${ext}"
  out2="${dir}/${base}-sample-sample.${ext}"

  if [[ -e "$out2" ]]; then
    echo "Skip (exists): $(basename -- "$out2")"
    ((skipped_exists++)) || true
    continue
  fi

  model_keys="$(choose_model_keys "$name")"
  #if [[ -z "$model_keys" ]]; then
   # echo "Skip (unknown model): $name"
   # ((skipped_unknown_model++)) || true
    #continue
  #fi

  echo "Processing: $name"
  echo "  Base filter output : $(basename -- "$out1")"
  echo "  Final output       : $(basename -- "$out2")"
  echo "  Model keys         : $model_keys"

  # --- Step 1: base filter ---
  rm -f -- "$out1"
  echo "  Running: $GRIB_FILTER -o \"$out1\" \"$BASE_FILTER\" \"$f\""
  if ! "$GRIB_FILTER" -o "$out1" "$BASE_FILTER" "$f" 2>&1; then
    echo "ERROR: grib_filter failed for: $name" >&2
    echo "  Tip: run manually to see details:" >&2
    echo "    $GRIB_FILTER -o \"$out1\" \"$BASE_FILTER\" \"$f\"" >&2
    ((failed++)) || true
    echo "----------------------------------------"
    continue
  fi

  if [[ ! -s "$out1" ]]; then
    echo "ERROR: grib_filter produced an empty output: $out1" >&2
    ((failed++)) || true
    echo "----------------------------------------"
    continue
  fi

  # --- Step 2: model keys ---
  rm -f -- "$out2"
  echo "  Running: $GRIB_SET -s \"$model_keys\" \"$out1\" \"$out2\""
  if ! "$GRIB_SET" -s "$model_keys" "$out1" "$out2" 2>&1; then
    echo "ERROR: grib_set failed for: $name" >&2
    ((failed++)) || true
    echo "----------------------------------------"
    continue
  fi

  ((created++)) || true
  echo "OK: created $(basename -- "$out2")"
  echo "----------------------------------------"
done

echo "Done."
echo "Summary: created=${created}, skipped_exists=${skipped_exists}, skipped_unknown_model=${skipped_unknown_model}, failed=${failed}"
