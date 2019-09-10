this folder contains the post-processing scripts used to create the data in the data folder. 
This was performed in two steps, as described in the paper.

- The scripts in `1_to_common_format` are used to map a system's data to a common format
- The scripts in `2_to_reference` then take this gaze data (w.r.t. the scene camera) and map it to the reference plane

We do not provide the input to these scripts here, but hope it offers a good starting point for anyone looking to repeat our tests.