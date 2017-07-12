function configurePstate_SpeedyGrater

global Pstate

Pstate = struct; %clear it

Pstate.type = 'SG';

Pstate.param{1} = {'PreStimDelay'   'float'     0       0                'sec'};
Pstate.param{2} = {'StimDuration '  'float'     1       0                 'sec'};
Pstate.param{3} = {'PostStimDelay'  'float'     0       0                'sec'};

Pstate.param{4} = {'StimSize'       'int'       5       0               'degree'};
Pstate.param{5} = {'Speed'          'int'       1       0                'deg/s'}; 
Pstate.param{6} = {'Orientation'    'int'       90      0                'deg'};  %start location, 0 equal screen center
Pstate.param{7} = {'SFreq'          'float'     0.05    0                ''}; %number of cycles
Pstate.param{8} = {'Orientation'    'int'       90      1                'deg'};
Pstate.param{9} = {'Elevation'      'int'       90      0                'deg'};
Pstate.param{10} = {'Azimuth'       'int'       10      0                'deg'};
Pstate.param{11} = {'contrast'      'float'     1       0                '%'};

Pstate.param{12} = {'TrialInterval' 'int'       0       0                'secs'}; 
                    
                    