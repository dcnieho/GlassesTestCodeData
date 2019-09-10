#!/bin/bash

SRC="/home/santini/ex/glassesTest/data/pupil-labs/"
DST="/home/santini/ex/glassesTest/processed/pupil-labs/"

python3 pl_preprocessing.py ${SRC}/2018_10_17/000/ ${DST} mn1
python3 pl_preprocessing.py ${SRC}/2018_10_17/001/ ${DST} mn2
python3 pl_preprocessing.py ${SRC}/2018_10_17/002/ ${DST} nh1
python3 pl_preprocessing.py ${SRC}/2018_10_17/003/ ${DST} nh2
python3 pl_preprocessing.py ${SRC}/2018_10_17/004/ ${DST} gl1
python3 pl_preprocessing.py ${SRC}/2018_10_17/005/ ${DST} gl2
python3 pl_preprocessing.py ${SRC}/2018_10_18/000/ ${DST} av1
python3 pl_preprocessing.py ${SRC}/2018_10_18/001/ ${DST} av2
python3 pl_preprocessing.py ${SRC}/2018_10_18/003/ ${DST} pt1
python3 pl_preprocessing.py ${SRC}/2018_10_18/004/ ${DST} pt2
python3 pl_preprocessing.py ${SRC}/2018_10_18/005/ ${DST} aw1
python3 pl_preprocessing.py ${SRC}/2018_10_18/006/ ${DST} aw2
python3 pl_preprocessing.py ${SRC}/2018_10_18/008/ ${DST} gh1
python3 pl_preprocessing.py ${SRC}/2018_10_18/009/ ${DST} gh2
python3 pl_preprocessing.py ${SRC}/2018_10_19/000/ ${DST} wr1
python3 pl_preprocessing.py ${SRC}/2018_10_19/001/ ${DST} wr2
python3 pl_preprocessing.py ${SRC}/2018_10_19/002/ ${DST} km1
python3 pl_preprocessing.py ${SRC}/2018_10_19/003/ ${DST} km2

