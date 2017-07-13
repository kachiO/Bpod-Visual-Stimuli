% This is a local file for specifying static rig-dependent measurements such as the
% size of the monitor and distance of the subject from the screen. 
% In principle these parameters can be added directly to the protocol parameter GUI.

global BpodSystem

%monitor dimensions
BpodSystem.PluginObjects.StimulusDisplay.MonitorScreenXcm = 44.5; %cm, width of the screen
BpodSystem.PluginObjects.StimulusDisplay.MonitorScreenYcm = 24.9; %cm, height of the screen
BpodSystem.PluginObjects.StimulusDisplay.ScreenDistance = 11; %cm, distance of the subject to the monitor

% specify the size of the sync patches for checking stimulus timing
BpodSystem.PluginObjects.StimulusDisplay.SyncSize = 0.5; %cm; %square 
