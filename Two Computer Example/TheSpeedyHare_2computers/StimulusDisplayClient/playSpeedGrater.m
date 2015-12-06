function playSpeedGrater

global StimulusDisplay
%% grab variables from StimulusDisplay
srcRect = StimulusDisplay.Stimulus.SizeRect;
numFrames = StimulusDisplay.Stimulus.NumFrames;
gratingTex = StimulusDisplay.Stimulus.Texture;

syncTexture = StimulusDisplay.SyncSquare.Texture;
syncLoc = StimulusDisplay.SyncSquare.Location;
syncRect = StimulusDisplay.SyncSquare.SizeRect;

screenPTR = StimulusDisplay.screenPTR;
screenNumber = StimulusDisplay.screenNum;

frameRate=Screen('FrameRate',screenNumber);

if frameRate == 0
    frameRate=60;
end

parameters = getParamStruct;
movieDurationSecs = parameters.StimulusDuration; % Run the movie animation for a fixed period.

% Convert movieDuration in seconds to duration in frames to draw:
movieDurationFrames=round(movieDurationSecs * frameRate);
movieFrameIndices1=(mod(0:(movieDurationFrames-1), numFrames) + 1);

% Use realtime priority for better timing precision:
priorityLevel=MaxPriority(screenPTR);
Priority(priorityLevel);

Screen('Flip', screenPTR);

% Animation loop:
for i=1:movieDurationFrames
    % Draw image:
    Screen('DrawTexture', screenPTR, gratingTex(movieFrameIndices1(i)),srcRect,StimLocation);
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
    
Priority(0);


