function makeDualGrater(parameters)

% Screen('Preference', 'SkipSyncTests', 0);

global BpodSystem

screenNumber = BpodSystem.StimulusDisplay.screenNumber;
screenPTR = BpodSystem.StimulusDisplay.screenPTR;
screenRect = BpodSystem.StimulusDisplay.screenRect;

%load parameters
gratingsizeDeg = parameters.StimSize; %in degrees, need to be converted into pixels
[speedL,speedR] = assignLeftRightParams(parameters.Speeds);%degrees/s
[spatialFreqL,spatialFreqR] = assignLeftRightParams(parameters.SpatialFreq);%cycles/degree
[orientationAngleL,orientationAngleR]= assignLeftRightParams(parameters.Orientation); %degrees
[elevationDegL,elevationDegR] = assignLeftRightParams(parameters.Elevation);%degrees
[azimuthDegL,azimuthDegR] = assignLeftRightParams(parameters.Azimuth);%degrees

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

TFreqL = speedL * spatialFreqL;
TFreqR = speedR * spatialFreqR;

monitorParameters; %get monitor parameters

screenDistance = BpodSystem.StimulusDisplay.ScreenDistance; %in cm, needs to be converted to pixels
screenRes = Screen('Resolution',screenNumber);
pixelspercmX = screenRes.width/BpodSystem.StimulusDisplay.MonitorScreenXcm;
pixelspercmY = screenRes.height/BpodSystem.StimulusDisplay.MonitorScreenYcm;
screendistancepxls = (screenDistance*pixelspercmX);

gratingsize = round(tan(gratingsizeDeg * pi/180)*(screendistancepxls)); %convert to pixels
texsize = ceil(gratingsize/2);
% This is the visible size of the grating. It is twice the half-width
% of the texture plus one pixel to make sure it has an odd number of
% pixels and is therefore symmetric around the center of the texture:
visiblesize=2*texsize+1;

cycPerPixelL = (spatialFreqL * gratingsizeDeg) / gratingsize; %cycles/pixel
cycPerPixelR = (spatialFreqR * gratingsizeDeg) / gratingsize; %cycles/pixel

elevationPxlsL = round(tand(abs(elevationDegL)) *(screenDistance*pixelspercmY));
elevationPxlsR = round(tand(abs(elevationDegR)) *(screenDistance*pixelspercmY));

azimuthPxlsL = round(tand(abs(azimuthDegL)) *(screenDistance*pixelspercmX));
azimuthPxlsR = round(tand(abs(azimuthDegR)) *(screenDistance*pixelspercmX));

%define destination of stimuli
srcRect=[0 0 visiblesize visiblesize];
dstRect = CenterRect(srcRect,screenRect);
[xcenter,ycenter] = RectCenter(screenRect); %get the center coordinates
newXL = xcenter - azimuthPxlsL; %to the left of center is negative
newYL = ycenter - elevationPxlsL;%top left corner of monitor is 0,0. pixel positions increase downward (y direction), and to the right (x-direction)
locationStimL = CenterRectOnPoint(dstRect,newXL,newYL);

newXR = xcenter + azimuthPxlsR; %to the right of center is positive
newYL = ycenter - elevationPxlsR; 
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
numFrames1 = floor(frameRate/TFreqL); %temporal period, i.e. number of frames in one cycle of the drifting grating
gratingtex1 = nan(1,numFrames1);

[x,y]=meshgrid(-texsize:texsize,-texsize:texsize);
circle = white * (x.^2 + y.^2 <= (texsize)^2);%  Create circular aperture for the alpha-channel

for i=1:numFrames1
    phase=(i/numFrames1)*2*pi;
    % grating # 1
    angle=orientationAngleL*pi/180; % in radians
    f=cycPerPixelL*2*pi; % cycles/pixel
    a=cos(angle)*f;
    b=sin(angle)*f;
    graterEq=sin(a*x+b*y+phase);
    grater1(:,:,1) = gray+inc*graterEq;
    
    % Set 2nd channel (the alpha channel) of 'grating' to the aperture
    % defined in 'circle':
    grater1(:,:,2) = 0;
    grater1(1:2*texsize+1, 1:2*texsize+1, 2) = circle;

    gratingtex1(i)=Screen('MakeTexture', screenPTR, grater1,[], [], [], [], glsl);
    
end

numFrames2 = floor(frameRate/TFreqR); %temporal period, i.e. number of frames in one cycle of the drifting grating
gratingtex2 = nan(1,numFrames2);

for i = 1:numFrames2
    phase=(i/numFrames2)*2*pi;

    %grating #2
    angle=orientationAngleR*pi/180; % in radians
    f=cycPerPixelR*2*pi; % cycles/pixel
    a=cos(angle)*f;
    b=sin(angle)*f;
    graterEq=sin(a*x+b*y+phase);
    grater2(:,:,1) = gray+inc*graterEq;
    
    %  Create circular aperture for the alpha-channel:
    circle = white * (x.^2 + y.^2 <= (texsize)^2);
    
    % Set 2nd channel (the alpha channel) of 'grating' to the aperture
    % defined in 'circle':
    grater2(:,:,2) = 0;
    grater2(1:2*texsize+1, 1:2*texsize+1, 2) = circle;
    
    gratingtex2(i)=Screen('MakeTexture', screenPTR, grater2,[], [], [], [], glsl);
    
end
BpodSystem.StimulusDisplay.frameRate = frameRate;

BpodSystem.StimulusDisplay.Textures.StimSize = srcRect;
BpodSystem.StimulusDisplay.Textures.StimL = gratingtex1;
BpodSystem.StimulusDisplay.Textures.StimR = gratingtex2;
BpodSystem.StimulusDisplay.Textures.locationStimL = locationStimL;
BpodSystem.StimulusDisplay.Textures.locationStimR = locationStimR;
BpodSystem.StimulusDisplay.Textures.NumFramesStimL = numFrames1;
BpodSystem.StimulusDisplay.Textures.NumFramesStimR = numFrames2;
disp('done making gratings')


function [L,R] = assignLeftRightParams(param)

if numel(param) == 1
    L = param;
    R = param;

else
        L = param(1);
    R = param(2);
end

