#!/bin/bash

TARGETS="av1 av2 aw1 aw2 gh1 gh2 gl1 gl2 km1 km2 mn1 mn2 nh1 nh2 pt1 pt2 wr1 wr2"
for i in $TARGETS
do
	./viewer.py /home/santini/ex/glassesTest/processed/${1}/${i}/
done
