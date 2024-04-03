#!/usr/bin/env python3

"""
This scripts reads a list of points from stdin (each point on separate line,
either `x, y` or `y` with x auto-incremented) and displays a pyplot graph.
"""

import matplotlib.pyplot as plt
import sys
import re
import getopt

marker = '.'
opts, args = getopt.getopt(sys.argv[1:], 'lp')
for o, a in opts:
    if o == '-p':
        marker = ''
    if o == '-l':
        marker += '-'


x = []
y = []

i = 0
for line in sys.stdin:
  vals = [float(n.strip()) for n in line.strip().split(",")]
  if len(vals) == 1:
    x.append(i)
    y.append(vals[0])
  else:
    x.append(vals[0])
    y.append(vals[1])
  i += 1

plt.plot(x, y, marker)
plt.minorticks_on()
plt.grid(which='both', color='#eee')
plt.show()
