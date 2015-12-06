function DualGrater
Screen('Preference', 'SkipSyncTests', 0);

% ___________________________________________________________________
%
% Display two animated grating. Adapted from DriftDemo
%
% This is a very simple, bare bones demo on how to do frame animation. For
% much more efficient ways to draw gratings and gabors, have a look at
% DriftDemo2, DriftDemo3, DriftDemo4, ProceduralGaborDemo, GarboriumDemo,
% ProceduralGarboriumDemo and DriftWaitDemo.

global Mstate
% _____________________
% This script calls Psychtoolbox commands available only in OpenGL-based
% versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
% only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
% an error message if someone tries to execute this script on a computer without
% an OpenGL Psychtoolbox
AssertOpenGL;

% Get the list of screens and choose the one with the highest screen number.
% Screen 0 is, by definition, the display with the menu bar. Often when
% two monitors are connected the one without the menu bar is used as
% the stimulus display.  Chosing the display with the highest dislay number is
% a best guess about where you want the stimulus displayed.
screens=Screen('Screens');
screenNumber=max(screens);

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

% Open a double buffered fullscreen window and select a gray background
% color:
[w,windowRect]=Screen('OpenWindow',screenNumber, gray);

priorityLevel=MaxPriority(w); %#ok<NASGU>

Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% Create a special texture drawing shader for masked texture drawing:
glsl = MakeTextureDrawShader(w, 'SeparateAlphaChannel');

speed1 = 50; %degrees/s
speed2 = 10; %degrees/s

spatialFreq1 = 0.05; %cycles/degree
spatialFreq2 = 0.05; %cycles/degree

orientationAngle1 = 45; %in degrees 
orientationAngle2 = 90; %in degrees 

movieDurationSecs = 1; % Run the movie animation for a fixed period.
gratingsizeDeg = 40; %in degrees, need to be converted into pixels

elevationDeg1 = 0;
elevationDeg2 = 0;

azimuthDeg1 = -40;
azimuthDeg2 = 40;

TFreq1 = speed1 * spatialFreq1;
TFreq2 = speed2 * spatialFreq2;
monitorParameters2; % monitor parameters

screenDistance = Mstate.ScreenDistance; %in cm, needs to be converted to pixels
screenRes = Screen('Resolution',screenNumber);
pixelspercmX = screenRes.width/Mstate.MonitorScreenXcm ;
pixelspercmY = screenRes.height/Mstate.MonitorScreenYcm ;
screendistancepxls = (screenDistance*pixelspercmX);

gratingsize = round(tan(gratingsizeDeg * pi/180)*(screendistancepxls)); %convert to pixels
texsize = ceil(gratingsize/2);
% This is the visible size of the grating. It is twice the half-width
% of the texture plus one pixel to make sure it has an odd number of
% pixels and is therefore symmetric around the center of the texture:
visiblesize=2*texsize+1;

cycPerPixel1 = (spatialFreq1 * gratingsizeDeg) / gratingsize; %cycles/pixel
cycPerPixel2 = (spatialFreq2 * gratingsizeDeg) / gratingsize; %cycles/pixel

elevationPxls1 = sign(elevationDeg1) * round(tand(abs(elevationDeg1)) *(screenDistance*pixelspercmY));
elevationPxls2 = sign(elevationDeg2) * round(tand(abs(elevationDeg2)) *(screenDistance*pixelspercmY));

azimuthPxls1 = sign(azimuthDeg1) * round(tand(abs(azimuthDeg1)) *(screenDistance*pixelspercmX));
azimuthPxls2 = sign(azimuthDeg2) * round(tand(abs(azimuthDeg2)) *(screenDistance*pixelspercmX));

%define destination of stimuli
srcRect=[0 0 visiblesize visiblesize]; %texture size
dstRect = CenterRect(srcRect,windowRect); %center location
[xcenter,ycenter] = RectCenter(windowRect); %get the center coordinates
newX1 = xcenter + azimuthPxls1; %x location of stimulus 1
newY1 = ycenter + elevationPxls1; %y location of stimulus 1
locationStim1 = CenterRectOnPoint(dstRect,newX1,newY1); %coordinates of stimulus 1

newX2 = xcenter + azimuthPxls2; 
newY2 = ycenter + elevationPxls2;
locationStim2 = CenterRectOnPoint(dstRect,newX2,newY2); %coordinates of stimulus 2

% If MacOSX does not know the frame rate the 'FrameRate' will return 0.
% That usually means we run on a flat panel with 60 Hz fixed refresh
% rate:
frameRate=Screen('FrameRate',screenNumber);

if frameRate == 0
    frameRate=60;
end

numFrames1 = frameRate/TFreq1; %temporal period, i.e. number of frames in one cycle of the drifting grating

% Compute each frame of the movie and convert the those frames, stored in
% MATLAB matices, into Psychtoolbox OpenGL textures using 'MakeTexture';
gratingtex1 = nan(1,numFrames1);

[x,y]=meshgrid(-texsize:texsize,-texsize:texsize);

circle = white * (x.^2 + y.^2 <= (texsize)^2);%  Create circular aperture for the alpha-channel

for i=1:numFrames1
    phase=(i/numFrames1)*2*pi;
    % grating # 1
    angle=orientationAngle1*pi/180; % in radians
    f=cycPerPixel1*2*pi; % cycles/pixel
    a=cos(angle)*f;
    b=sin(angle)*f;
    graterEq=sin(a*x+b*y+phase);
    grater1(:,:,1) = gray+inc*graterEq;
    
    % Set 2nd channel (the alpha channel) of 'grating' to the aperture
    % defined in 'circle':
    grater1(:,:,2) = 0;
    grater1(1:2*texsize+1, 1:2*texsize+1, 2) = circle;

    gratingtex1(i)=Screen('MakeTexture', w, grater1,[], [], [], [], glsl);
    
end

numFrames2 = frameRate/TFreq2; %temporal period, i.e. number of frames in one cycle of the drifting grating
gratingtex2 = nan(1,numFrames2);

for i = 1:numFrames2
    phase=(i/numFrames2)*2*pi;

    %grating #2
    angle=orientationAngle2*pi/180; % in radians
    f=cycPerPixel2*2*pi; % cycles/pixel
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
    
    gratingtex2(i)=Screen('MakeTexture', w, grater2,[], [], [], [], glsl);
    
end
    
% Convert movieDuration in seconds to duration in frames to draw:
movieDurationFrames=round(movieDurationSecs * frameRate);
movieFrameIndices1=mod(0:(movieDurationFrames-1), numFrames1) + 1;
movieFrameIndices2=mod(0:(movieDurationFrames-1), numFrames2) + 1;

% Use realtime priority for better timing precision:
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% Animation loop:
for i=1:movieDurationFrames
    % Draw image:
    Screen('DrawTexture', w, gratingtex1(movieFrameIndices1(i)),srcRect,locationStim1);
    Screen('DrawTexture', w, gratingtex2(movieFrameIndices2(i)),srcRect,locationStim2);

    % Show it at next display vertical retrace. Please check DriftDemo2
    % and later, as well as DriftWaitDemo for much better approaches to
    % guarantee a robust and constant animation display timing! This is
    % very basic and not best practice!
    Screen('Flip', w);
end

Priority(0);

% Close all textures. This is not strictly needed, as
% Screen('CloseAll') would do it anyway. However, it avoids warnings by
% Psychtoolbox about unclosed textures. The warnings trigger if more
% than 10 textures are open at invocation of Screen('CloseAll') and we
% have 12 textues here:
Screen('Close');

% Close window:
Screen('CloseAll');
