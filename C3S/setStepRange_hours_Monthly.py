#!/usr/bin/env python3

import traceback
import sys

from eccodes import *
from calendar import monthrange
from glob import glob

VERBOSE = 1  # verbose error reporting
offset=0

def example(I,O):
    INPUT=I
    OUTPUT=O

    fin = open(INPUT, 'rb')
    fout = open(OUTPUT, 'wb')

    count=0
    startStep=offset
    endStep=offset

    while 1:
        gid = codes_grib_new_from_file(fin)

        if gid is None:
            break

        month = codes_get(gid,'month')
       	year = codes_get(gid,'year')

        if count > 0:
            startStep = startStep + monthrange(year,month+(count-1))[1]*24
        else:
            startStep=offset
        endStep = endStep + monthrange(year,month+count)[1]*24

        codes_set(gid, 'startStep' , startStep )
        codes_set(gid, 'endStep' , endStep)
        codes_set(gid, 'dayOfEndOfOverallTimeInterval' , monthrange(year,month+count)[1])
        codes_set(gid, 'monthOfEndOfOverallTimeInterval', month+count)
        codes_set(gid, 'indicatorOfUnitForTimeRange', 1)
        codes_set(gid, 'lengthOfTimeRange', endStep-startStep )
       	codes_set(gid, 'indicatorOfUnitForTimeIncrement', 1)
       	codes_set(gid, 'timeIncrement', endStep-startStep )
        count += 1
        codes_write(gid, fout)
        codes_release(gid)

    fin.close()
    fout.close()

def main():
    try:
        filelist=glob(pathname='*monthly-sample-sample.grib2')
        for INPUT in filelist:
            OUTPUT = INPUT.replace('.grib2','_MODIFIED.grib2')
            print(INPUT,OUTPUT)
            example(INPUT,OUTPUT)
    except CodesInternalError as err:
        if VERBOSE:
            traceback.print_exc(file=sys.stderr)
        else:
            sys.stderr.write(err.msg + '\n')
 
        return 1
 
 
if __name__ == "__main__":
    sys.exit(main())
