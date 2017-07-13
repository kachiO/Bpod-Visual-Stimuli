function playDualGrater
t = tic;
global BpodSystem
screenPTR = BpodSystem.PluginObjects.StimulusDisplay.screenPTR;

%unload textures and locations for drawing on screen
locationStimL =BpodSystem.PluginObjects.StimulusDisplay.Textures.locationStimL;
locationStimR = BpodSystem.PluginObjects.StimulusDisplay.Textures.locationStimR;
srcRect = BpodSystem.PluginObjects.StimulusDisplay.Textures.StimSize;

gratingtexL = BpodSystem.PluginObjects.StimulusDisplay.Textures.StimL;
gratingtexR = BpodSystem.PluginObjects.StimulusDisplay.Textures.StimR;

syncTexture = BpodSystem.PluginObjects.StimulusDisplay.Textures.Sync;
syncLoc = BpodSystem.PluginObjects.StimulusDisplay.Textures.SyncLocation;
syncRect = BpodSystem.PluginObjects.StimulusDisplay.Textures.SyncSize;

freqL = BpodSystem.PluginObjects.StimulusDisplay.Textures.CyclesPerPixelL;
freqR = BpodSystem.PluginObjects.StimulusDisplay.Textures.CyclesPerPixelR;

oriAngle = BpodSystem.PluginObjects.StimulusDisplay.Parameters.Orientation;

cyclespersecondL = BpodSystem.PluginObjects.StimulusDisplay.Parameters.TFreqs(1);
cyclespersecondR = BpodSystem.PluginObjects.StimulusDisplay.Parameters.TFreqs(2);

rotateMode = kPsychUseTextureMatrixForRotation;

movieDurationSecs = BpodSystem.PluginObjects.StimulusDisplay.Parameters.StimDuration; % Run the movie animation for a fixed period.

% Amplitude of the grating in units of absolute display intensity range: A
% setting of 0.5 means that the grating will extend over a range from -0.5
% up to 0.5, i.e., it will cover a total range of 1.0 == 100% of the total
% displayable range. As we select a background color and offset for the
% grating of 0.5 (== 50% nominal intensity == a nice neutral gray), this
% will extend the sinewaves values from 0 = total black in the minima of
% the sine wave up to 1 = maximum white in the maxima. Amplitudes of more
% than 0.5 don't make sense, as parts of the grating would lie outside the
% displayable range for your computers displays:
amplitude = 0.5;

% Retrieve video redraw interval for later control of our animation timing:
ifi = Screen('GetFlipInterval', screenPTR);

% Phase is the phase shift in degrees (0-360 etc.)applied to the sine grating:
phaseL = 0;
phaseR = 0;
% Compute increment of phase shift per redraw:
phaseincrement1 = (cyclespersecondL * 360) * ifi;
phaseincrement2 = (cyclespersecondR * 360) * ifi;

% Use realtime priority for better timing precision:
% Priority(1);
priorityLevel=MaxPriority(screenPTR);
Priority(priorityLevel);

Screen('Flip', screenPTR);
Screen('FillRect', screenPTR, 128);

vbl = Screen('Flip', screenPTR);
vblendtime = vbl + movieDurationSecs;
numFrames = round(movieDurationSecs * 1/ifi); %number of frames to draw, 

% Animation loop:
% while vbl < vblendtime
for f = 1:numFrames
    % Increment phase by 1 degree:
    phaseL = phaseL + phaseincrement1;
    phaseR = phaseR + phaseincrement2;

    % Draw the grating, with given rotation 'angle',
    % sine grating 'phase' shift and amplitude, rotating via set
    % 'rotateMode'. Note that we pad the last argument with a 4th
    % component, which is 0. This is required, as this argument must be a
    % vector with a number of components that is an integral multiple of 4,
    % i.e. in our case it must have 4 components:
    Screen('DrawTexture', screenPTR, gratingtexL, srcRect, locationStimL, oriAngle, [], [], [], [], rotateMode, [phaseL, freqL, amplitude, 0]);
    Screen('DrawTexture', screenPTR, gratingtexR, srcRect, locationStimR, oriAngle, [], [], [], [], rotateMode, [phaseR, freqR, amplitude, 0]);
    Screen('DrawTexture', screenPTR, syncTexture(1),syncRect,syncLoc);

    % Show it at next retrace:
    vbl = Screen('Flip', screenPTR, vbl + 0.5 * ifi);
end
Screen('DrawingFinished',screenPTR);

Screen('Flip', screenPTR);
Screen('FillRect', screenPTR, 128);

Screen('Flip', screenPTR);
Screen('DrawTexture', screenPTR, syncTexture(2),syncRect,syncLoc);
Screen('Flip', screenPTR);
    
% ManualOverride(4,1)
%BpodSystem.HardwareState.BNCInputs(ChannelCode) = 0;

Priority(0);
toc(t)

