function playDualGrater

global BpodSystem
screenPTR = BpodSystem.StimulusDisplay.screenPTR;
frameRate = BpodSystem.StimulusDisplay.frameRate;
ChannelCode =1;
BpodSystem.HardwareState.BNCInputs(ChannelCode) = 1;

%unload textures and locations for drawing on screen
locationStim1 =BpodSystem.StimulusDisplay.Textures.locationStimL;
locationStim2 = BpodSystem.StimulusDisplay.Textures.locationStimR;
srcRect = BpodSystem.StimulusDisplay.Textures.StimSize;

gratingtex1 = BpodSystem.StimulusDisplay.Textures.StimL;
gratingtex2 = BpodSystem.StimulusDisplay.Textures.StimR;

syncTexture = BpodSystem.StimulusDisplay.Textures.Sync;
syncLoc = BpodSystem.StimulusDisplay.Textures.SyncLocation;
syncRect = BpodSystem.StimulusDisplay.Textures.SyncSize;

movieDurationSecs = BpodSystem.StimulusDisplay.Parameters.StimulusDuration; % Run the movie animation for a fixed period.

numFrames1 = BpodSystem.StimulusDisplay.Textures.NumFramesStimL;
numFrames2 = BpodSystem.StimulusDisplay.Textures.NumFramesStimR;

% Convert movieDuration in seconds to duration in frames to draw:
movieDurationFrames=round(movieDurationSecs * frameRate);
movieFrameIndices1=(mod(0:(movieDurationFrames-1), numFrames1) + 1);
movieFrameIndices2=(mod(0:(movieDurationFrames-1), numFrames2) + 1);

% Use realtime priority for better timing precision:
priorityLevel=MaxPriority(screenPTR);
Priority(priorityLevel);

Screen('Flip', screenPTR);

% Animation loop:
for i=1:movieDurationFrames
    % Draw image:
    Screen('DrawTexture', screenPTR, gratingtex1(movieFrameIndices1(i)),srcRect,locationStim1);
    Screen('DrawTexture', screenPTR, gratingtex2(movieFrameIndices2(i)),srcRect,locationStim2);
    Screen('DrawTexture', screenPTR, syncTexture(1+mod(i,2)),syncRect,syncLoc);
    
    % Show it at next display vertical retrace. Please check DriftDemo2
    % and later, as well as DriftWaitDemo for much better approaches to
    % guarantee a robust and constant animation display timing! This is
    % very basic and not best practice!
    Screen('Flip', screenPTR);
end

Screen('Flip', screenPTR);
Screen('DrawTexture', screenPTR, syncTexture(2),syncRect,syncLoc);
Screen('Flip', screenPTR);
    
% ManualOverride(4,1)
%BpodSystem.HardwareState.BNCInputs(ChannelCode) = 0;

Priority(0);


