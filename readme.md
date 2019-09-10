# Data and code for Niehorster, Santini et al., 2019.

This package contains the data presented in Niehorster, Santini, Hessels, Hooge, Kasneci & Nyström (in press). The impact of slippage on the data quality of head-worn eye trackers. Behavior Research Methods.

It also contains the code used for preprocessing the recordings of the different eye-tracking setups, and the analysis code that created the figures in the paper.

To recreate the figures, first run `createCache.m`. The various figures are then created by the files `exampleData.m`, `validation.m` and `offsetsAndLoss.m`.
The figure comparing 50Hz and 100Hz tobii data is created by running `G2Sawtooth.m`.

The code and data in this repository are licensed under the Creative Commons Attribution 4.0 (CC BY 4.0) license, unless otherwise stated.
