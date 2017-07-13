# Bpod-Visual-Stimuli

Instructions and example protocols for interfacing [Bpod](https://sites.google.com/site/bpoddocumentation/) (r0.5) and [Psychtoolbox](http://psychtoolbox.org/) for visual psychophysics experiments. Josh Sanders, the mastermind behind Bpod, has a plugin solution available on the Bpod wiki ([see PsychtoolboxVideoServer](https://sites.google.com/site/bpoddocumentation/bpod-user-guide/function-reference-beta/psychtoolboxvideoserver)), but the plugin does not support a dedicated monitor for displaying the fullscreen stimulus. I implemented  a couple of solutions a few years ago for interfacing Bpod  with Psychtoolbox for visual stimuli.

The first approach uses a single computer connected to two monitors. Both Bpod and Psychtoolbox are running on the same machine and instance of MATLAB. This is the most "convenient" approach as it does not require a second computer, however, it is not the most straightforward to setup in *Ubuntu*. In the [Single Computer Example folder](https://github.com/kachiO/Bpod-Visual-Stimuli/tree/master/Single%20Computer%20Example) there is a guideline for setting up Ubuntu to recognize two monitors independently on the Psychtoolbox side. Recognizing two monitors is trivial in Windows or MacOSX, hence if you have Bpod running on either operating system (Windows or MacOSX) you need not worry about the guideline. (Note: I used Ubuntu for running Bpod experiments because it offers low latency delivery of auditory stimuli, compared to Windows PC.). The potential downside with the single computer approach is that the visual stimulus generation could slowdown/overload the computer and thereby increase latency of visual stimulus delivery. This could be addressed by using a much faster computer (plus better graphics card) or using a two computer setup.  

The second approach is a two computer set-up: One machine for Bpod/behavioral data acqusition and second machine for Psychtoolbox visual stimuli display. Both computers communicate via UDP (or TCP/IP) communication protocol, which are generally low latency. (Tip: To reduce communication latency, make sure the two computers are directly connected to each other via an ethernet cable.) The dedicated visual display computer is advantageous when complex stimuli need to be generated on every trial, which could potentially slowdown a single computer. This approach is identical to a solution used in the [Visual Stimuluator software package from the Callaway Lab] (https://sites.google.com/site/iannauhaus/home/matlab-code). 

**Disclaimer**: I have not performed a benchtest (side-by-side) comparison of the two approaches to affirm which approach is better. In principle, both approaches should work equally well. The performance will depend on the needs of your experiment and current computer specifications/operating system (e.g. graphics card, Ubuntu vs. PC). 

In any case, measure the latency of the visual stimulus delivery of your setup. Sanworks has a really cool monitor photodetector module [Frame2TTL](https://sites.google.com/site/frame2ttl/home) for detecting events on a monitor ([purchase here](https://sanworks.io/shop/viewproduct?productID=1501)). 

Hopefully this repository will serve as a starting point for using Bpod for visual experiments with a monitor display. 


## SpeedyHare
The SpeedyHare is an example Bpod behavior protocol interfacing with Psychtoolbox for visual stimulus display . In this paradigm, subjects are presented with two gratings (left and right) drifting at two different speeds (in degrees/sec). The subjects report to the side with the grating with the fastest drift speed. 

For the single computer example, copy the "SpeedyHare" folder directly into the Bpod/Protocols folder to test. Key Functions: 
+ **TheSpeedyHare.m** - Main protocol function
+ **PsychToolboxDisplayServer.m** - Function(s) for communicating with configuring and displaying visual stimuli .Equivalent to Bpod's PsychToolboxSoundServer.m or PsychToolboxVideoServer.m
+ **makeDualGrater.m** - Creates grating stimuli to monitor
+ **playDualGrater.m** - Play grating stimuli to monitor
+ **monitorParameters.m** - Local file specifying parameters of stimulus monitor. These variables could be added to main parameter GUI
+ **BpodParameterGUI_Visual.m** - Custom-ish Bpod parameter GUI. Optional.
+ **SoftCodeHandler_StimulusDisplay.m** - Specifies which function to call for software triggers in state machine. In this case calls, "PsychToolboxDisplayServer". 

For the dual computer example, copy the "TheSpeedyHare_2computers" into the Bpod/Protocols folder. Copy "StimulusDisplayClient" to a directory in the MATLAB path on the visual stimulus display computer. 
