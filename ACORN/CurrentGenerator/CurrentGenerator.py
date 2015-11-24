#!/usr/bin/python

import os, sys
import urllib2
import numpy as np
from datetime import datetime, timedelta
from netCDF4 import Dataset
import logging
import argparse

import ACORNConstants
import ACORNUtils

import WERA
import CODAR

root = logging.getLogger()
root.setLevel(logging.DEBUG)

def currentFromFile(inputFile, destDir):
    if ACORNUtils.isRadial(inputFile):
        return WERA.currentFromRadials(inputFile, destDir)
    elif ACORNUtils.isVector(inputFile):
        return CODAR.currentFromVectors(inputFile, destDir)
    else:
        logging.error("Not a vector or radial file: '%s'" % inputFile)
        exit(1)

if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--source", help="source file to operate on (radial/vector file)", required=True)
    parser.add_argument("-d", "--dir", help="output directrory (must exist)", required=True)
    parser.add_argument("-D", "--delete", help="delete source file after operation", action='store_true')
    parser.add_argument("-q", "--quiet", help="reduce verbosity (errors only)", action='store_true')
    args = parser.parse_args()

    if args.quiet:
        root.setLevel(logging.ERROR)

    if not currentFromFile(args.source, args.dir):
        exit(1)
    else:
        exit(0)

    if args.delete and os.path.isfile(args.source):
        os.unlink(args.source)