#!/usr/bin/python

import os
import sys
import numpy as np
import csv

import matplotlib.pyplot as plt

x = []
y = []

with open( os.path.join(sys.argv[1], 'transformations.tsv'), 'r' ) as f:
    reader = csv.DictReader(f, delimiter='\t')
    for entry in reader:
        gt = entry['gt'].split(',')
        x.append(gt[0])
        y.append(gt[1])

plt.plot(x, label='x')
plt.plot(y, label='y')
plt.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)
plt.show()
