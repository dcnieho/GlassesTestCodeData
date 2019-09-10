#!/bin/bash

SRC="/home/santini/ex/glassesTest/processed/"
PARTICIPANTS="av1 av2 aw1 aw2 gh1 gh2 gl1 gl2 km1 km2 mn1 mn2 nh1 nh2 pt1 pt2 wr1 wr2"
DEVICES="eyerec pupil-labs tobii smi grip"
for PARTICIPANT in $PARTICIPANTS
do
	for DEVICE in $DEVICES 
	do
		TARGET=${SRC}/${DEVICE}/${PARTICIPANT}
		echo Detecting markers for $TARGET
		./detect.py $TARGET
	done
done

./detect.py ${SRC}/tobii/mn_demo
./detect.py ${SRC}/tobii/mn_demo2
./detect.py ${SRC}/smi/mn_demo
