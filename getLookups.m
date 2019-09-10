function [lookup,taskLookup] = getLookups
lookup = {
    % name, confidence limit, pretty name, sampling fs, expected fs
    'eyerec'   , 0.66, 'EyeRecToo' , 58 , 60
    'grip'     , 0.66, 'Grip'      , 58 , 60
    'pupillabs', 0.6 , 'Pupil-labs', 118, 120
    'smi'      , 0   , 'SMI'       , 60 , 60
    'tobii'    , 0   , 'Tobii'     , 50 , 50
    };

taskLookup = {
    'baseline' ,'None'
    'vowels'   ,'Vowels'
    'eyebrows' ,'Eyebrows'
    'mov_hor'  ,'Horizontal'
    'mov_ver'  ,'Vertical'
    'mov_depth','Depth'
    };