#!/bin/bash

SRC="/media/data/ex/glassesTest/processed/"
PARTICIPANTS="av1 av2 aw1 aw2 gh1 gh2 gl1 gl2 km1 km2 mn1 mn2 nh1 nh2 pt1 pt2 wr1 wr2"
DEVICES="eyerec pupil-labs tobii smi grip"
for PARTICIPANT in $PARTICIPANTS
do
	for DEVICE in $DEVICES 
	do
		TARGET=${SRC}/${DEVICE}/${PARTICIPANT}
		echo Reporting for $TARGET
		./report.py $TARGET
	done
done
