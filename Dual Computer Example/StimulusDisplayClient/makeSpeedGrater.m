function makeSpeedGrater

global   Mstate StimulusDisplay
screenPTR = StimulusDisplay.screenPTR;
screenNumber = StimulusDisplay.screenNum;
screenRect = StimulusDisplay.screenRect;

%% load parameters
parameters = getParamStruct;
gratingsizeDeg = parameters.StimSize; %in degrees, need to be converted into pixels
speed = parameters.Speed;%degrees/s
spatialFreq = parameters.SFreq;%cycles/degree
orientationAngle= parameters.Orientation; %degrees
elevationDeg = parameters.Elevation;%degrees
azimuthDeg = parameters.Azimuth;%degrees

%%
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

priorityLevel=MaxPriority(screenPTR); %#ok<NASGU>

Screen('BlendFunction', screenPTR, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% Create a special texture drawing shader for masked texture drawing:
glsl = MakeTextureDrawShader(screenPTR, 'SeparateAlphaChannel');
%%

screenDistance = Mstate.ScreenDistance; %in cm, needs to be converted to pixels
screenRes = Screen('Resolution',screenNumber);
pixelspercmX = screenRes.width/Mstate.MonitorScreenXcm;
pixelspercmY = screenRes.height/Mstate.MonitorScreenYcm;
screendistancepxls = (screenDistance*pixelspercmX);

gratingsize = round(tan(gratingsizeDeg * pi/180)*(screendistancepxls)); %convert to pixels
texsize = ceil(gratingsize/2);
% This is the visible size of the grating. It is twice the half-width
% of the texture plus one pixel to make sure it has an odd number of
% pixels and is therefore symmetric around the center of the texture:
visiblesize=2*texsize+1;

cycPerPixel = (spatialFreq * gratingsizeDeg) / gratingsize; %cycles/pixel
elevationPxls = round(tand(abs(elevationDeg)) *(screenDistance*pixelspercmY));
azimuthPxls = round(tand(abs(azimuthDeg)) *(screenDistance*pixelspercmX));

%define destination of stimuli
srcRect=[0 0 visiblesize visiblesize];
dstRect = CenterRect(srcRect,screenRect);
[xcenter,ycenter] = RectCenter(screenRect); %get the center coordinates
newX = xcenter - azimuthPxls; %to the left of center is negative
newY = ycenter - elevationPxls;%top left corner of monitor is 0,0. pixel positions increase downward (y direction), and to the right (x-direction)
StimLocation = CenterRectOnPoint(dstRect,newX,newY);

% If MacOSX does not know the frame rate the 'FrameRate' will return 0.
% That usually means we run on a flat panel with 60 Hz fixed refresh
% rate:
frameRate=Screen('FrameRate',screenNumber);

if frameRate == 0
    frameRate=60;
end

% Compute each frame of the movie and convert the those frames, stored in
% MATLAB matices, into Psychtoolbox OpenGL textures using 'MakeTexture';
TFreq = speed * spatialFreq;
numFrames = floor(frameRate/TFreq); %temporal period, i.e. number of frames in one cycle of the drifting grating
gratingTex = nan(1,numFrames);

[x,y]=meshgrid(-texsize:texsize,-texsize:texsize);
circle = white * (x.^2 + y.^2 <= (texsize)^2);%  Create circular aperture for the alpha-channel

for i=1:numFrames
    phase=(i/numFrames)*2*pi;
    % grating # 1
    angle=orientationAngle*pi/180; % in radians
    f=cycPerPixel*2*pi; % cycles/pixel
    a=cos(angle)*f;
    b=sin(angle)*f;
    graterEq=sin(a*x+b*y+phase);
    grater(:,:,1) = gray+inc*graterEq;
    
    % Set 2nd channel (the alpha channel) of 'grating' to the aperture
    % defined in 'circle':
    grater(:,:,2) = 0;
    grater(1:2*texsize+1, 1:2*texsize+1, 2) = circle;

    gratingTex(i)=Screen('MakeTexture', screenPTR, grater,[], [], [], [], glsl);
    
end


disp('done making stimulus')

StimulusDisplay.screenNumber = screenNumber;
StimulusDisplay.screenPTR = screenPTR;
StimulusDisplay.screenRect = screenRect;
StimulusDisplay.frameRate = frameRate;

StimulusDisplay.Stimulus.SizeRect = srcRect;
StimulusDisplay.Stimulus.Location = StimLocation;
StimulusDisplay.Stimulus.Texture = gratingTex;
StimulusDisplay.Stimulus.NumFrames = numFrames;

