function configureMstate

global Mstate

Mstate.anim = 'xx0';
Mstate.unit = '000';
Mstate.expt = '000';

Mstate.hemi = 'right';
Mstate.screenDist = 22;

Mstate.monitor = 'LIN';  %This should match the default at the master. Otherwise, they will differ, but only at startup

%'updateMonitor.m' happens in 'screenconfig.m' at startup

Mstate.running = 0;

Mstate.syncSize = 4;  %cm
