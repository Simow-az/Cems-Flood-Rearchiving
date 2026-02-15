for f in *.grib*; do
  base=$(basename "$f")

  case "$base" in
    et_*)     new="avg_etr_${base#et_}" ;;
    mrro_*)   new="avg_rorwe_${base#mrro_}" ;;
    q_*)      new="avg_dis_${base#q_}" ;;
    rzswi_*)  new="avg_swir_${base#rzswi_}" ;;
    swe_*)    new="avg_sd_${base#swe_}" ;;
    *)        continue ;;
  esac

  echo "Renaming: $base -> $new"
  mv "$f" "$new"
done

