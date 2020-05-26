# Data and code for Niehorster, Santini et al., 2020.

This package contains the data presented in [Niehorster, Santini, Hessels, Hooge, Kasneci & Nyström (2020). The impact of slippage on the data quality of head-worn eye trackers. Behavior Research Methods. doi: 10.3758/s13428-019-01307-0](https://doi.org/10.3758/s13428-019-01307-0)

It also contains the code used for preprocessing the recordings of the different eye-tracking setups, and the analysis code that created the figures in the paper.

To recreate the figures, first run `createCache.m`. The various figures are then created by the files `exampleData.m`, `validation.m` and `offsetsAndLoss.m`.
The figure comparing 50Hz and 100Hz tobii data is created by running `G2Sawtooth.m`.

The code and data in this repository are licensed under the Creative Commons Attribution 4.0 (CC BY 4.0) license, unless otherwise stated.




## Data disclaimer, limitations and conditions of release
By downloading this data set, you expressly agree to the following conditions of release and acknowledge the following disclaimers issued by the authors:

### A. Conditions of Release
Data are available by permission of the authors. Use of data in publications, either digital or hardcopy, must be cited as follows: 
- Niehorster, D.C., Santini, T., Hessels, R.S., Hooge, I.T.C, Kasneci, E. & Nyström, M. (2020). The impact of slippage on the data quality of head-worn eye trackers. Behavior Research Methods. doi: 10.3758/s13428-019-01307-0

### B. Disclaimer of Liability
The authors shall not be held liable for any improper or incorrect use or application of the data provided, and assume no responsibility for the use or application of the data or interpretations based on the data, or information derived from interpretation of the data. In no event shall the authors be liable for any direct, indirect or incidental damage, injury, loss, harm, illness or other damage or injury arising from the release, use or application of these data. This disclaimer of liability applies to any direct, indirect, incidental, exemplary, special or consequential damages or injury, even if advised of the possibility of such damage or injury, including but not limited to those caused by any failure of performance, error, omission, defect, delay in operation or transmission, computer virus, alteration, use, application, analysis or interpretation of data.

### C. Disclaimer of Accuracy of Data
No warranty, expressed or implied, is made regarding the accuracy, adequacy, completeness, reliability or usefulness of any data provided. These data are provided "as is." All warranties of any kind, expressed or implied, including but not limited to fitness for a particular use, freedom from computer viruses, the quality, accuracy or completeness of data or information, and that the use of such data or information will not infringe any patent, intellectual property or proprietary rights of any party, are disclaimed. The user expressly acknowledges that the data may contain some nonconformities, omissions, defects, or errors. The authors do not warrant that the data will meet the user’s needs or expectations, or that all nonconformities, omissions, defects, or errors can or will be corrected. The authors are not inviting reliance on these data, and the user should always verify actual data.
