#! /usr/bin/env python
#
# Read data from an NRS Suspended Matter data file (Excel) and store
# store it in the report database.

from psycopg2 import connect
import argparse
from IMOSfile.IMOSbgc import harvestBGC,fStr,fFloat,fInt


# List of columns in spreadsheet and how they should be transferred
# into database
#           name in Excel         name in db          format
column = [['Time',               'sample_time',       '%s'  ],
          ['Station Code',       'site_code',         fStr  ],
          ['Latitude',           'sample_lat',        fFloat],
          ['Longitude',          'sample_lon',        fFloat],
          ['Depth',              'sample_depth',      fFloat],
          ['Sample QC Flag',     'sample_qc',         fInt  ],
          ['Sample QC comment',  'sample_comment',    fStr  ],
          ['Time QC comment',    'time_comment',      fStr  ],
          ['Location QC comment','location_comment',  fStr  ]]

# get filename from command line
parser = argparse.ArgumentParser() 
parser.add_argument('file', help='IMOS PHYPIG.xls file')
args = parser.parse_args()

# connect to database
host = 'dbdev.emii.org.au'
db = 'report_db'
user = 'report'
table = 'anmn.nrs_phypig'
conn = connect(host=host, user=user, database=db)
if not conn:
    print 'Failed to connect to database!'
    exit()
print 'Connected to %s database on %s' % (db, host)

# do the harvest
harvestBGC(args.file, column, conn, table)

# close db connection
conn.close()
