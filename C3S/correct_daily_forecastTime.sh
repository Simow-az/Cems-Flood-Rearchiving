#!/bin/bash

cat << EOF > daily.filt
if (count == 1){
 set lengthOfTimeRange = 24;
} else {
 set lengthOfTimeRange = 24;
 transient fcstt = forecastTime ;
 transient fcstt24 = fcstt + 24 ;
 set forecastTime = fcstt24 ;
}
write;
EOF

for FILE in *daily-sample-sample.grib2 ; do
 echo $FILE
  #echo "set lengthOfTimeRange=24; write;" | ../../bin/grib_filter - $FILE -o ${FILE/.grib2/_MODIFIED.grib2}
  /perm/maro/ecc_hydro_cems_c3s/adapted/bin/grib_filter daily.filt $FILE -o ${FILE/.grib2/_MODIFIED.grib2}
done
python3 setStepRange_hours.py
