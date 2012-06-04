#! /usr/bin/env python
#
# Python module to process real-time WQM from an ANMN National Reference Station.


import numpy as np
from IMOSfile.dataUtils import readCSV, timeFromString
import IMOSfile.IMOSnetCDF as inc
from datetime import datetime


### module variables ###################################################

i = np.int32
f = np.float64
formWQM = np.dtype(
    [('Config ID', i),
     ('Trans ID', i),
     ('Record', i),
     ('Header Index', i),
     ('Serial No', i),
     ('Nominal Depth', f),
     ('Time', 'S24'),
     ('Temperature', f),
     ('Pressure', f),
     ('Salinity', f),
     ('Dissolved Oxygen', f),
     ('Chlorophyll', f),
     ('Turbidity', f),
     ('Voltage', f)
     ])



### functions #######################################################

def procWQM(station, start_date=None, end_date=None, csvFile='WQM.csv'):
    """
    Read data from a WQM.csv file (in current directory, unless
    otherwise specified) and convert it to a netCDF file (Wave.nc by
    default).
    """

    # load default netCDF attributes for station
    assert station
    attribFile = '/home/marty/work/code/NRSrealtime/'+station+'_attributes.txt'
     
    # read in WQM file
    data = readCSV(csvFile, formWQM)

    # convert time from string to something more numeric 
    # (using default epoch in netCDF module)
    (time, dtime) = timeFromString(data['Time'], inc.epoch)

    # select time range
    ii = np.arange(len(dtime))
    if end_date:
        ii = np.where(dtime < end_date)[0]
    if start_date:
        ii = np.where(dtime[ii] > start_date)[0]
    if len(ii) < 1:
        print csvFile+': No data in given time range!'
        return
    data = data[ii]
    time = time[ii]
    dtime = dtime[ii]

    # create two files, one for each WQM instrument
    for depth in set(data['Nominal Depth']):
        jj = np.where(data['Nominal Depth'] == depth)[0]
        dd = data[jj]
        tt = time[jj]

        ss = set(dd['Serial No'])
        if len(ss) > 1:
            print 'WARNING: Multiple WQM serial numbers selected for file!'

        # create netCDF file
        file = inc.IMOSnetCDFFile(attribFile=attribFile)
        file.title = 'Real-time WQM data from Maria Island National Reference station'
        file.instrument = 'WET Labs WQM'
        file.instrument_serial_number = ss.pop()
	file.instrument_sample_interval = 1.
	file.instrument_burst_interval = 900.
	file.instrument_burst_duration = 59.
        file.instrument_nominal_depth = depth

        # dimensions
        TIME = file.setDimension('TIME', tt)
        LAT = file.setDimension('LATITUDE', -44.5)   # set from data ???
        LON = file.setDimension('LONGITUDE', 143.777)   # set from data ???
        #DEPTH = ??? should add this using seawater toolbox!

        # variables
        TEMP = file.setVariable('TEMP', dd['Temperature'], ('TIME',))

        PRES_REL = file.setVariable('PRES_REL', dd['Pressure'], ('TIME',))
        # PRES_REL.applied_offset = -10.1352972  ???

        PSAL = file.setVariable('PSAL', dd['Salinity'], ('TIME',))

        DOX1 = file.setVariable('DOX1', dd['Dissolved Oxygen'], ('TIME',))

        CPHL = file.setVariable('CPHL', dd['Chlorophyll'], ('TIME',))
        CPHL.comment = "Artificial chlorophyll data computed from bio-optical sensor raw counts using standard WET Labs calibration."
        # CPHL.comment = "Artificial chlorophyll data computed from bio-optical sensor raw counts measurements. Originally expressed in ug/l, 1l = 0.001m3 was assumed."   same as in delayed-mode file ???

        TURB = file.setVariable('TURB', dd['Turbidity'], ('TIME',))

        # VOLT = file.setVariable('VOLT', dd['Voltage'], ('TIME',)) do we need this???


        # set standard filename
        file.updateAttributes()
        file.standardFileName('TPSOBU', 'NRSMAI-SubSurface-realtime-WQM-%.0f' % depth)

        file.close()





### processing - if run from command line

if __name__=='__main__':
    import sys

    if len(sys.argv)<2: 
        print 'usage:'
        print '  '+sys.argv[0]+' station_code [year [input_file.csv] ]'
        exit()

    station = sys.argv[1]

    if len(sys.argv)>2: 
        year = int(sys.argv[2])
        start_date = datetime(year, 1, 1)
        end_date = datetime(year+1, 1, 1)
    else:
        start_date = None
        end_date = None

    csvFile='WQM.csv'
    if len(sys.argv)>3: csvFile = sys.argv[3]
    
    procWQM(station, start_date, end_date, csvFile)

