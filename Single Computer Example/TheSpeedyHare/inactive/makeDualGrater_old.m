function makeDualGrater(parameters)

% Screen('Preference', 'SkipSyncTests', 0);

global BpodSystem

screenNumber = BpodSystem.PluginObjects.StimulusDisplay.screenNumber;
screenPTR = BpodSystem.PluginObjects.StimulusDisplay.screenPTR;
screenRect = BpodSystem.PluginObjects.StimulusDisplay.screenRect;

%load parameters
gratingsizeDeg = parameters.StimSize; %in degrees, need to be converted into pixels
speedL = parameters.Speeds(1);%degrees/s
speedR = parameters.Speeds(2);%degrees/s
sFreqL = parameters.SFreqs(1);%cycles/degree
sFreqR = parameters.SFreqs(2);%cycles/degree
contrastL = parameters.StimContrasts(1);
contrastR = parameters.StimContrasts(2);

orientationAngle = parameters.Orientation; %degrees
elevationDeg = parameters.Elevation;%degrees
azimuthDeg = parameters.Azimuth;%degrees

% Find the color values which correspond to white and black: Usually
% black is always 0 and white 255, but this rule is not true if one of
% the high precision framebuffer modes is enabled via the
% PsychImaging() commmand, so we query the true values via the
% functions WhiteIndex and BlackIndex:
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

% Contrast 'inc'rement range for given white and gray values:
inc=white-gray;

% priorityLevel=MaxPriority(screenPTR); %#ok<NASGU>

Screen('BlendFunction', screenPTR, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% Create a special texture drawing shader for masked texture drawing:
glsl = MakeTextureDrawShader(screenPTR, 'SeparateAlphaChannel');

TFreqL = speedL * sFreqL;
TFreqR = speedR * sFreqR;

monitorParameters; %get monitor parameters

screenDistance = BpodSystem.PluginObjects.StimulusDisplay.ScreenDistance; %in cm, needs to be converted to pixels
screenRes = Screen('Resolution',screenNumber);
pixelspercmX = screenRes.width/BpodSystem.PluginObjects.StimulusDisplay.MonitorScreenXcm;
pixelspercmY = screenRes.height/BpodSystem.PluginObjects.StimulusDisplay.MonitorScreenYcm;
screendistancepxls = (screenDistance*pixelspercmX);

gratingsize = round(tan(gratingsizeDeg * pi/180)*(screendistancepxls)); %convert to pixels
texsize = ceil(gratingsize/2);
% This is the visible size of the grating. It is twice the half-width
% of the texture plus one pixel to make sure it has an odd number of
% pixels and is therefore symmetric around the center of the texture:
visiblesize=2*texsize+1;

cycPerPixelL = (sFreqL * gratingsizeDeg) / gratingsize; %cycles/pixel
cycPerPixelR = (sFreqR * gratingsizeDeg) / gratingsize; %cycles/pixel

elevationPxls = round(tand(abs(elevationDeg)) *(screenDistance*pixelspercmY));
azimuthPxls = round(tand(abs(azimuthDeg)) *(screenDistance*pixelspercmX));

%define destination of stimuli
srcRect=[0 0 visiblesize visiblesize];
dstRect = CenterRect(srcRect,screenRect);
[xcenter,ycenter] = RectCenter(screenRect); %get the center coordinates
newXL = xcenter - azimuthPxls; %to the left of center is negative
newYL = ycenter - elevationPxls;%top left corner of monitor is 0,0. pixel positions increase downward (y direction), and to the right (x-direction)
locationStimL = CenterRectOnPoint(dstRect,newXL,newYL);

newXR = xcenter + azimuthPxls; %to the right of center is positive
newYL = ycenter - elevationPxls; 
locationStimR = CenterRectOnPoint(dstRect,newXR,newYL);

% If MacOSX does not know the frame rate the 'FrameRate' will return 0.
% That usually means we run on a flat panel with 60 Hz fixed refresh
% rate:
frameRate=Screen('FrameRate',screenNumber);

if frameRate == 0
    frameRate=60;
end

% Compute each frame of the movie and convert the those frames, stored in
% MATLAB matices, into Psychtoolbox OpenGL textures using 'MakeTexture';
numFramesL = floor(frameRate/TFreqL); %temporal period, i.e. number of frames in one cycle of the drifting grating
LgratingTex = nan(1,numFramesL);

[x,y]=meshgrid(-texsize:texsize,-texsize:texsize);
circle = white * (x.^2 + y.^2 <= (texsize)^2);%  Create circular aperture for the alpha-channel

for i=1:numFramesL
    phase=(i/numFramesL)*2*pi;
    % grating # 1
    angle = orientationAngle*pi/180; % in radians
    f = cycPerPixelL*2*pi; % cycles/pixel
    a = cos(angle)*f;
    b = sin(angle)*f;
    gratingL = sin(a*x+b*y+phase);
    Lgrater(:,:,1) = (gray+(contrastL*inc*gratingL));
    
    % Set 2nd channel (the alpha channel) of 'grating' to the aperture
    % defined in 'circle':
    Lgrater(:,:,2) = 0;
    Lgrater(1:2*texsize+1, 1:2*texsize+1, 2) = circle;

    LgratingTex(i)=Screen('MakeTexture', screenPTR, Lgrater,[], [], [], [], glsl);
end

numFramesR = floor(frameRate/TFreqR); %temporal period, i.e. number of frames in one cycle of the drifting grating
RgratingTex = nan(1,numFramesR);

for i = 1:numFramesR
    phase=(i/numFramesR)*2*pi;

    %grating #2
    angle=orientationAngle*pi/180; % in radians
    f=cycPerPixelR*2*pi; % cycles/pixel
    a=cos(angle)*f;
    b=sin(angle)*f;
    gratingR=sin(a*x+b*y+phase);
    Rgrater(:,:,1) = (gray + (contrastR .* inc*gratingR));
    
    %  Create circular aperture for the alpha-channel:
    circle = white * (x.^2 + y.^2 <= (texsize)^2);
    
    % Set 2nd channel (the alpha channel) of 'grating' to the aperture
    % defined in 'circle':
    Rgrater(:,:,2) = 0;
    Rgrater(1:2*texsize+1, 1:2*texsize+1, 2) = circle;
    
    RgratingTex(i)=Screen('MakeTexture', screenPTR, Rgrater,[], [], [], [], glsl);
    
end
BpodSystem.PluginObjects.StimulusDisplay.frameRate = frameRate;

BpodSystem.PluginObjects.StimulusDisplay.Textures.StimSize = srcRect;
BpodSystem.PluginObjects.StimulusDisplay.Textures.StimL = LgratingTex;
BpodSystem.PluginObjects.StimulusDisplay.Textures.StimR = RgratingTex;
BpodSystem.PluginObjects.StimulusDisplay.Textures.locationStimL = locationStimL;
BpodSystem.PluginObjects.StimulusDisplay.Textures.locationStimR = locationStimR;
BpodSystem.PluginObjects.StimulusDisplay.Textures.NumFramesStimL = numFramesL;
BpodSystem.PluginObjects.StimulusDisplay.Textures.NumFramesStimR = numFramesR;
disp('done making gratings')
% Priority(0);


