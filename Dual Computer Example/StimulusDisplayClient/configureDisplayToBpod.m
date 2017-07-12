function configureDisplayToBpod(varargin)
%originally configureDisplay.m, written by Ian Nauhaus, CallawayLab

close all

Priority(0);  %Make sure priority is set to "real-time"  

% priorityLevel=MaxPriority(w);
% Priority(priorityLevel);

configurePstate('PG') %Use grater as the default when opening
configureMstate

configComToBpod(varargin);
initializeDisplay;

