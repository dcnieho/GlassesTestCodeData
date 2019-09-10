#!/bin/bash

SRC="/home/santini/ex/glassesTest/data/EyeRecToo/"
DST="/home/santini/ex/glassesTest/processed/grip/"
TARGETS="av1 av2 aw1 aw2 gh1 gh2 gl1 gl2 km1 km2 mn1 mn2 nh1 nh2 pt1 pt2 wr1 wr2"
for i in $TARGETS
do
	python3 er_preprocessing.py ${SRC}/${i}/1/ ${DST} $i
done
