function makeDualGrater(parameters)
%% create textures for dual grating stimulus
     
global BpodSystem
t = tic;
screenNumber = BpodSystem.PluginObjects.StimulusDisplay.screenNumber;
screenPTR = BpodSystem.PluginObjects.StimulusDisplay.screenPTR;
screenRect = BpodSystem.PluginObjects.StimulusDisplay.screenRect;

Screen('FillRect', screenPTR, 128);
Screen('Flip', screenPTR);


%load parameters
gratingsizeDeg = parameters.StimSize; %in degrees, need to be converted into pixels
sFreqL = parameters.SFreqs(1);%cycles/degree
sFreqR = parameters.SFreqs(2);%cycles/degree
contrastL = parameters.StimContrasts(1);
contrastR = parameters.StimContrasts(2);
elevationDeg = parameters.Elevation;%degrees
azimuthDeg = parameters.Azimuth;%degrees

Priority(1)
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
newYL = ycenter - (sign(elevationDeg)*elevationPxls);%top left corner of monitor is 0,0. pixel positions increase downward (y direction), and to the right (x-direction)
locationStimL = CenterRectOnPoint(dstRect,newXL,newYL);

newXR = xcenter + azimuthPxls; %to the right of center is positive
newYL = ycenter - (sign(elevationDeg)*elevationPxls); 
locationStimR = CenterRectOnPoint(dstRect,newXR,newYL);

% Build a procedural sine grating texture for a grating with a support of
% res(1) x res(2) pixels and a RGB color offset of 0.5 -- a 50% gray.
radius = gratingsize/2;
contrastVecL = [0.5 0.5 0.5 0];
contrastVecR = [0.5 0.5 0.5 0];
LgratingTex = CreateProceduralSineGrating(screenPTR, gratingsize,gratingsize, contrastVecL, radius);
RgratingTex = CreateProceduralSineGrating(screenPTR, gratingsize, gratingsize, contrastVecR, radius);


BpodSystem.PluginObjects.StimulusDisplay.Textures.StimSize = srcRect;
BpodSystem.PluginObjects.StimulusDisplay.Textures.StimL = LgratingTex;
BpodSystem.PluginObjects.StimulusDisplay.Textures.StimR = RgratingTex;
BpodSystem.PluginObjects.StimulusDisplay.Textures.locationStimL = locationStimL;
BpodSystem.PluginObjects.StimulusDisplay.Textures.locationStimR = locationStimR;
BpodSystem.PluginObjects.StimulusDisplay.Textures.CyclesPerPixelL = cycPerPixelL;
BpodSystem.PluginObjects.StimulusDisplay.Textures.CyclesPerPixelR = cycPerPixelR;

disp('done making gratings')
Priority(0);
toc(t)

