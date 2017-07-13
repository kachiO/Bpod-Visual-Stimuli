function PsychToolboxDisplayServer(command, varargin)
%% PsychtoolboxDisplayServer
% Equivalent to PsychtoolboxSoundServer, but for communicating with
% Psychooltoolbox visual display. 

global BpodSystem

switch lower(command)
    
    case 'init' %initialize gray screen and sync squares
        % This script calls Psychtoolbox commands available only in OpenGL-based
        % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
        % only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
        % an error message if someone tries to execute this script on a computer without
        % an OpenGL Psychtoolbox
        AssertOpenGL;
        
        screenNumber=max(Screen('Screens')); %assumes two connected screens. plays visual stimulus to second screen. 
        
        screenRes = Screen('Resolution',screenNumber);
        [screenPTR, screenRect] = Screen('OpenWindow',screenNumber,128);
        
%         Screen(screenPTR,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        white=WhiteIndex(screenNumber);
        black=BlackIndex(screenNumber);
        
        % Round gray to integral number, to avoid roundoff artifacts with some
        % graphics cards:
        gray=round((white+black)/2);
        
        % This makes sure that on floating point framebuffers we still get a
        % well defined gray. It isn't strictly neccessary in this demo:
        if gray == white
            gray=white / 2;
        end

        monitorParameters; %loads monitor parameters
        pixpercmX = screenRes.width/BpodSystem.PluginObjects.StimulusDisplay.MonitorScreenXcm;
        pixpercmY = screenRes.height/BpodSystem.PluginObjects.StimulusDisplay.MonitorScreenYcm;
        
        syncWX = round(pixpercmX*BpodSystem.PluginObjects.StimulusDisplay.SyncSize);
        syncWY = round(pixpercmY*BpodSystem.PluginObjects.StimulusDisplay.SyncSize);
                
        %SyncLoc = [0 screenRes.height-syncWY syncWX-1 screenRes.height-1]';
        SyncLoc = [0 0 syncWX-1 syncWY-1]';
        SyncPiece = [0 0 syncWX-1 syncWY-1]';
        
        %Set the screen
        Screen(screenPTR, 'FillRect', 128)
        Screen(screenPTR, 'Flip');
        
        syncTexture(1) = Screen(screenPTR, 'MakeTexture', white*ones(syncWY,syncWX)); % "low"
        syncTexture(2) = Screen(screenPTR, 'MakeTexture', black*ones(syncWY,syncWX)); % "low"
        
        Screen('DrawTexture', screenPTR, syncTexture(2),SyncPiece,SyncLoc);
        Screen(screenPTR, 'Flip');
        
        BpodSystem.PluginObjects.StimulusDisplay.Textures.Sync = syncTexture;
        BpodSystem.PluginObjects.StimulusDisplay.Textures.SyncLocation = SyncLoc;
        BpodSystem.PluginObjects.StimulusDisplay.Textures.SyncSize = SyncPiece; 
               
        BpodSystem.PluginObjects.StimulusDisplay.screenNumber = screenNumber;
        BpodSystem.PluginObjects.StimulusDisplay.screenPTR = screenPTR;
        BpodSystem.PluginObjects.StimulusDisplay.screenRect =screenRect;
        BpodSystem.PluginObjects.StimulusDisplay.refresh_rate = 1/Screen('GetFlipInterval', screenPTR);
        
    case 'make' %send instructions/parameters for creating the visual stimulus to be displayed
        stimID = varargin{1};
        parameterStruct = varargin{2};
        makeStimulus(stimID,parameterStruct);
        BpodSystem.PluginObjects.StimulusDisplay.Parameters = parameterStruct;
        
    case 'play' %play visual stimulus
        stimID = varargin{1};
        playStimulus(stimID);
        
    case 'stop' %stop the  visual stimulus
        Screen(BpodSystem.PluginObjects.StimulusDisplay.screenPTR, 'FillRect', 128)
        Screen(BpodSystem.PluginObjects.StimulusDisplay.screenPTR, 'Flip');
        
    case 'stopall'
        Screen('CloseAll');
        
end

%% axuilary functions:

function makeStimulus(stimID,parameters)
% runs scripts that will create desired stimulus

switch stimID
    
%     case 'CB'
%         %checkboard stimulus will be used as noise
%         makeCheckerboard(parameters)
        
    case 'DG'
        %dual grating stimulus
        makeDualGrater(parameters)
        
end

function playStimulus(stimID)
% runs scripts that will play desired stimulus
% add case for each visual stimulus type
switch stimID
    case 1
        %dual grating stimulus
        playDualGrater
                
end



