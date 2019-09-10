#!/bin/bash

SRC="/home/santini/ex/glassesTest/data/smi/"
DST="/home/santini/ex/glassesTest/processed/smi/"

python smi_preprocessing.py ${SRC}av1-[0c63c705-2d7d-483d-8e3b-fdfa3c082c4f] ${DST} av1
python smi_preprocessing.py ${SRC}av2-[5ae125be-c223-4fba-bce2-0b59a110f155] ${DST} av2
python smi_preprocessing.py ${SRC}aw1-[78a8d588-d9f7-4067-83fe-dcae81384456] ${DST} aw1
python smi_preprocessing.py ${SRC}aw2-[02f04ec4-23ac-4cc0-987d-3b9cbf5b0aba] ${DST} aw2
python smi_preprocessing.py ${SRC}gh1-[6fed561e-bf1d-4c0a-992f-ace49446675d] ${DST} gh1
python smi_preprocessing.py ${SRC}gh2-[510d3cf6-5fbb-400d-aec3-70e960ff6f5a] ${DST} gh2
python smi_preprocessing.py ${SRC}gl1-[9e10f080-4b5d-44d1-be3e-bbf00745ec8e] ${DST} gl1
python smi_preprocessing.py ${SRC}gl2-[8d88e47a-d084-4616-bd4b-4d3b042a9908] ${DST} gl2
python smi_preprocessing.py ${SRC}km1-[58b0043f-643e-4dcf-a51b-03e62b856ec5] ${DST} km1
python smi_preprocessing.py ${SRC}km2-[a3e95b45-29ea-43a0-917f-55e4d975c8ff] ${DST} km2
python smi_preprocessing.py ${SRC}mn1-[57aaf9b2-153b-4f66-8a56-e65443d1c19c] ${DST} mn1
python smi_preprocessing.py ${SRC}mn2-[bb5427e2-08ae-4f82-bbd2-82fe9628c14e] ${DST} mn2
python smi_preprocessing.py ${SRC}nh1-[7f73b2fb-1beb-4651-b4b8-c2b10d62416a] ${DST} nh1
python smi_preprocessing.py ${SRC}nh2-[6963b034-ad37-4005-8495-9cfd923abd21] ${DST} nh2
python smi_preprocessing.py ${SRC}pt1-[4ad484b1-9a6c-4daa-ae3e-3ba565e59ed5] ${DST} pt1
python smi_preprocessing.py ${SRC}pt2-[e9f76f2d-7ff9-438d-8bdf-598c0fd24e7b] ${DST} pt2
python smi_preprocessing.py ${SRC}wr1-[d625c7cf-c93a-45c2-acea-772b9aaba348] ${DST} wr1
python smi_preprocessing.py ${SRC}wr2-[d5dd7deb-0803-45fb-b236-020221e1fd64] ${DST} wr2
python smi_preprocessing.py ${SRC}mn_demo-[0d16c6c7-eeca-4eb7-85f0-7acbe329d8cd] ${DST} mn_demo

