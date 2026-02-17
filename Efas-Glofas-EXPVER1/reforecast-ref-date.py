#!/usr/bin/env python3
import sys
import os
import glob
import traceback
from datetime import datetime, timedelta

from eccodes import (
    codes_grib_new_from_file,
    codes_get,
    codes_set,
    codes_write,
    codes_release,
    CodesInternalError,
)

VERBOSE = True

# ----------------------------
# Reference date windows
# ----------------------------
START_2023 = datetime(2023, 2, 27)
END_2023   = datetime(2023, 12, 31)

START_2024 = datetime(2024, 1, 1)
END_2024   = datetime(2024, 11, 21)

# Precompute Mondays (0) and Thursdays (3) for each window
REF_DATES_2023 = {
    (START_2023 + timedelta(days=i)).date()
    for i in range((END_2023 - START_2023).days + 1)
    if (START_2023 + timedelta(days=i)).weekday() in (0, 3)
}

REF_DATES_2024 = {
    (START_2024 + timedelta(days=i)).date()
    for i in range((END_2024 - START_2024).days + 1)
    if (START_2024 + timedelta(days=i)).weekday() in (0, 3)
}


def update_one_file(INPUT, OUTPUT):
    with open(INPUT, "rb") as fin, open(OUTPUT, "wb") as fout:
        while True:
            gid = codes_grib_new_from_file(fin)
            if gid is None:
                break

            try:
                # Read message date from GRIB keys
                month = int(codes_get(gid, "month"))
                year  = int(codes_get(gid, "year"))
                day   = int(codes_get(gid, "day"))
                print('month,year and day done')
             

                msg_date = datetime(year, month, day).date()

                # Set YearOfModelVersion based on which Mon/Thu window the date falls into
                if msg_date in REF_DATES_2023:
                    codes_set(gid, "YearOfModelVersion", 2023)
                elif msg_date in REF_DATES_2024:
                    codes_set(gid, "YearOfModelVersion", 2024)
                # else: leave YearOfModelVersion unchanged

                # Keep these as the message's month/day (as in your original logic)
                codes_set(gid, "MonthOfModelVersion", month)
                codes_set(gid, "DayOfModelVersion", day)

                # Write modified message
                codes_write(gid, fout)

            finally:
                # Always release the handle
                codes_release(gid)


def main():
    # Usage:
    #   python3 update_modelversion_keys.py INPUT.grib2 [OUTPUT.grib2]
    if len(sys.argv) < 2:
        print("Usage: python3 update_modelversion_keys.py INPUT.grib2 [OUTPUT.grib2]")
        return 2

    INPUT = sys.argv[1]

    # Default output: add '-reference' before extension
    if len(sys.argv) >= 3:
        OUTPUT = sys.argv[2]
    else:
        base, ext = os.path.splitext(INPUT)
        OUTPUT = f"{base}-reference{ext}"

    if not os.path.isfile(INPUT):
        print(f"Input file not found: {INPUT}")
        return 2

    print(f"Input : {INPUT}")
    print(f"Output: {OUTPUT}")

    update_one_file(INPUT, OUTPUT)
    return 0
if __name__ == "__main__":
    try:
        sys.exit(main())
    except CodesInternalError as err:
        if VERBOSE:
            traceback.print_exc()
        else:
            sys.stderr.write(str(err) + "\n")
        sys.exit(1)