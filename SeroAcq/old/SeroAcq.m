function varargout = SeroAcq(varargin)
% SEROACQ MATLAB code for SeroAcq.fig
%      SEROACQ, by itself, creates a new SEROACQ or raises the existing
%      singleton*.
%
%      H = SEROACQ returns the handle to a new SEROACQ or the handle to
%      the existing singleton*.
%
%      SEROACQ('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEROACQ.M with the given input arguments.
%
%      SEROACQ('Property','Value',...) creates a new SEROACQ or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SeroAcq_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SeroAcq_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SeroAcq

% Last Modified by GUIDE v2.5 05-Oct-2022 14:19:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SeroAcq_OpeningFcn, ...
                   'gui_OutputFcn',  @SeroAcq_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SeroAcq is made visible.
function SeroAcq_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SeroAcq (see VARARGIN)
global TotalPoints PointsPerCycle CyclesPerRefresh TotalRefreshBatches RefreshPerWindow
global s Signal_Cycle linehCurrent linehOxPeakV linehSignal labelhOxPeak Gain
global PCOM TimerPulse labelInjectionTime Injection_Running
global C G PortList
global RefElecX RefElecY RefElecZ StimElecX StimElecY StimElecZ 
global txtRV
global daqName
global specMeasCycles discardData VoltageDriver

try
    if isdeployed
        % User is running an executable in standalone mode.
        [status, result] = system('set PATH');
        executableFolder = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
        % 			fprintf(1, '\nIn function GetExecutableFolder(), currentWorkingDirectory = %s\n', executableFolder);
    else
        % User is running an m-file from the MATLAB integrated development environment (regular MATLAB).
        executableFolder = pwd;
    end
catch ME
    errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ME.stack(1).name, ME.stack(1).line, ME.message);
    uiwait(warndlg(errorMessage));
end

cd(executableFolder);
diary('log.txt');
diary on;

%look for Calibration file, if needed
%TODO: is this still needed?
if exist('Calibration.cfg','file')==2
    load('Calibration.cfg','-mat');
else
    msgbox('Calibration file not found');
    %handles.LoadSignal.Enable='off';
    return
end

%show the module logo
axes(handles.axesLogo)
matlabImage = imread('SeroAcq.jpg');
image(matlabImage)
axis off
axis image

%load false color map
load('myCustomColormap.mat');

%look for/create Config file
if exist('Config.cfg','file')==2
    C=load('Config.cfg','-mat');
else
    C.PathDataFiles=getenv('USERPROFILE');
    C.PathFigures=getenv('USERPROFILE');
    C.PathSignals=getenv('USERPROFILE');
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
end

%if exist('device.config','file')==2
%    load('device.config','-mat');
%    daqName = 'Dev0'
%else
%    msgbox('DAQ Device config file device.config not found');
%    return
%end

%set defaults
specMeasCycles=0;
discardData = 0;


%find and configure ports
Puertos_Activos=instrfind;
if isempty(Puertos_Activos)==0 
    fclose(Puertos_Activos); 
    delete(Puertos_Activos) 
    clear Puertos_Activos 
end

[status,list]=dos('REG QUERY HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM');
pos=regexp(list,'VCP');
PortList{1}='NONE';
tam=size(pos');
for i=1:tam(1)
    COMLine=list(pos(i):length(list));
    [start]=regexp(COMLine,'COM');
    if isnumeric(list(start(1)+4))
        PortList{i+1}=COMLine(start(1):start(1)+4);
    else
        PortList{i+1}=COMLine(start(1):start(1)+3);
    end
end
handles.lstInjectionCOM.String=PortList;
PCOM=serial('COM1');

%set Gain defaults
Gain=200;
handles.txtCustomGain.Enable='off';

VoltageDriver = 1.0;

%Custom headstage gain options (no longer in use)
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if handles.optx1.Value==1
%     if handles.opt1.Value==1
%         Gain=G(7,2)/Rp;
%     end
%     if handles.opt2.Value==1
%         Gain=G(6,2)/Rp;
%     end
%     if handles.opt5.Value==1
%         Gain=G(5,2)/Rp;
%     end
%     if handles.opt10.Value==1
%         Gain=G(4,2)/Rp;
%     end
%     if handles.opt20.Value==1
%         Gain=G(3,2)/Rp;
%     end
%     if handles.opt50.Value==1
%         Gain=G(2,2)/Rp;
%     end
%     if handles.opt100.Value==1
%         Gain=G(1,2)/Rp;
%     end
% else
%     if handles.opt1.Value==1
%         Gain=G(7,1)/Rf1;
%     end
%     if handles.opt2.Value==1
%         Gain=G(6,1)/Rf1;
%     end
%     if handles.opt5.Value==1
%         Gain=G(5,1)/Rf1;
%     end
%     if handles.opt10.Value==1
%         Gain=G(4,1)/Rf1;
%     end
%     if handles.opt20.Value==1
%         Gain=G(3,1)/Rf1;
%     end
%     if handles.opt50.Value==1
%         Gain=G(2,1)/Rf1;
%     end
%     if handles.opt100.Value==1
%         Gain=G(1,1)/Rf1;
%     end
% end

%show user the Gain on GUI
handles.lblGain.String=Gain;

handles.lblAccumulationVoltage.ForegroundColor=[0.5 0.5 0.5];
handles.lblAccumulationTime.ForegroundColor=[0.5 0.5 0.5];

%for future release; initialize electrode positions to 0
RefElecX = 0;
RefElecY = 0;
RefElecZ = 0;

StimElecX = 0;
StimElecY = 0;
StimElecZ = 0;
txtRV = str2double(handles.txtRestingVoltage.String);

% Choose default command line output for SeroAcq
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SeroAcq wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SeroAcq_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in cmdLoadSignal.
function cmdLoadSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLoadSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global TotalPoints PointsPerCycle G ScanRate cmdhStimulation opthInjectionMode opthStimulationMode
global s Signal_Cycle linehCurrent linehOxPeakV linehSignal labelhOxPeak Gain
global TimerPulse labelInjectionTime Injection_Running C PathDataFiles PathFigures PathSignals
global NonSampledPoints CP_Data_All
global SignalFrequency SignalPeriod
global daqName VoltageMultiplier WaveformName SampledPoints

[NewFileName,PathName]=uigetfile('*.sig','Select the waveform to load (.sig).',C.PathSignals);

if NewFileName~=0
    InterfaceObj=findobj(gcf,'Enable','on'); % Disable all the objects of the window
    drawnow;
    set(InterfaceObj,'Enable','off');
    FileName=NewFileName;
    C.PathSignals=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    
    %load waveform parameters
    load(strcat(PathName,FileName),'-mat','NSegments','StartPot','EndPot','NPoints','ScanRate','SampledPoints', 'WaveformFrequency', 'WaveformPeriod', 'WaveformName');
    WaveformName = FileName;
    handles.txtWaveformName.String = WaveformName;
    %set peak slider max
    handles.sldOxPeak.Max=SampledPoints;
    
    % Open and configure NI cards session
    daq.reset;
    s=daq.createSession('ni'); 
    
    
    %------------------- Start of signal configuration --------------------------
    
    %multiplier value is vendor-specific to potentiostat
    %for the Pine WaveNeuro, it is 3
    %pineMultiplier = str2double(inputdlg('Set potentiostat multiplier value if desired (e.g., 3). If you accounted for the multiplier during signal generation, insert 1.','Set Multiplier Value'));
    VoltageMultiplier = str2double(handles.txtMultiplier.String);
    %fill the signal cycle array using the loaded waveform parameters
    Signal_Cycle=[];
    
    for i=1:NSegments
        Signal_Cycle=[Signal_Cycle linspace(StartPot(i),EndPot(i),NPoints(i))];
    end
    
    %incorporate the multiplier and convert mV to V
    Signal_Cycle = VoltageMultiplier*Signal_Cycle/1000;

    PointsPerCycle=SampledPoints;
    SignalSize=size(Signal_Cycle);
    TotalPoints=SignalSize(2);
    
    % Establish the scan rate (sampling frequency)
    % Note this is NOT waveform scan rate
    s.Rate = ScanRate;
    handles.txtSamplingFrequency.String = ScanRate;
    NonSampledPoints = TotalPoints - PointsPerCycle; %number of points in a cycle that are not sampled
    
    SignalFrequency = WaveformFrequency;
    SignalPeriod = WaveformPeriod;
    handles.txtWaveformFrequency.String = SignalFrequency;
    %------------------- End of signal configuration --------------------------
    
    %Continuously generate output signals until the session is stopped, 
    %but do not automatically set a minimum value of ScansQueued.
    s.IsNotifyWhenScansQueuedBelowAuto = false;
    s.IsContinuous = true;
    
    %TODO: declare variable for Dev0?
    %establish analog I/O
    addAnalogOutputChannel(s,'Dev0',0,'Voltage'); % Channel 0 for signal generation (DAC0)
    addAnalogOutputChannel(s,'Dev0',1,'Voltage'); % Channel 1 for stimulation generation (DAC1)
    addAnalogInputChannel(s,'Dev0',0,'Voltage');
    
    %plot the loaded waveform
    xlabel(handles.pltWaveform,'Time');
    ylabel(handles.pltWaveform,'Voltage (V)');
    plot(handles.pltWaveform, (1:PointsPerCycle),Signal_Cycle(1:PointsPerCycle)/VoltageMultiplier);
    
    %label temporal current plot axes
    xlabel(handles.pltSequence,'Time (sec)');
    ylabel(handles.pltSequence,'Current (nA)');
    
    %label current voltammogram axes
    xlabel(handles.pltCycle,'Samples');
    ylabel(handles.pltCycle,'Voltage (V)');
    
%     %label cyclic voltammogram axes
%     xlabel(handles.plotCV,'Voltage (V)');
%     ylabel(handles.plotCV,'Current (nA)');
    
    %clear axes
    cla(handles.pltCycle);
    
    %plot waveform
    linehSignal=line(handles.pltCycle,(1:PointsPerCycle),(Signal_Cycle(1:PointsPerCycle))/VoltageMultiplier,'Color','b');
    %drawnow;
    %pause(1);

    %set markers to origin
    linehOxPeakV=line(handles.pltCycle,[0 0],ylim(handles.pltCycle),'Color','k');
    linehCurrent=line(handles.pltCycle,[0 0],[0 0],'Color','r');
    
    %set labels
    labelhOxPeak=handles.lblOxPeak;
    labelInjectionTime=handles.lblInjectionTime;
    
    %define handles
    cmdhStimulation=handles.cmdStimulation;
    opthInjectionMode=handles.optInjectionMode;
    opthStimulationMode=handles.optStimulationMode;
    
    %initialize variable
    Injection_Running=0;
    
    %creates timer 
    TimerPulse=timer(); %define timer to schedule command execution (logic pulse)
    set(TimerPulse,'ExecutionMode','singleShot') %timer callback executes once
    set(TimerPulse,'StartDelay',1) %delay between timer start and first execution (s)
    set(TimerPulse,'BusyMode','error') %throw error if task added to non empty queue 
    set(TimerPulse,'TimerFcn',{@Timer,handles}) %timer callback
    set(TimerPulse,'StartDelay',2) 
    
    %enable GUI buttons
    set(InterfaceObj,'Enable','on');
    handles.cmdMeasure.Enable='on';
end



% --- Executes on button press in cmdMeasure.
function cmdMeasure_Callback(hObject, eventdata, handles)
% hObject    handle to cmdMeasure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global PointsPerCycle CyclesPerRefresh TotalRefreshBatches RefreshPerWindow TotalPoints
global s Signal Signal_Cycle Total_Data lhout lhin lherror StimRefreshSignal
global N_Refresh phSequence phCycle Execution_Time linehCurrent
global OxPeak SampleOxPeak linehSignal linehOxPeakV SignalShift
global Injections N_Injections InjectionsLabel
global FileName hcmdMeasure C 
global hcmdStop hcmdResetPlot hcmdInjection Injection_Running Stimulation_Running
global OxPeakVM N_Peaks SP_Peaks PP_Peaks EP_Peaks PeaksLabel AppliedSignal
global SignalFrequency SignalPeriod
global sampleIgnoreStart sampleNumIgnoredPoints Gain VoltageMultiplier
global CV_Data phCV phCP
global specMeasCycles

%ensure correct gain and multiplier values.
Answer = questdlg(strcat('The gain is set to',{' '}, num2str(Gain), ' and the multiplier is set to',{' '}, num2str(VoltageMultiplier),'. Is this correct?'),'Warning','Yes', 'No','No');

if strcmp(Answer,'Yes')==1
    Answer = questdlg('Is the current scale correctly configured?', 'Warning','Yes', 'No','No');
    
    if strcmp(Answer,'Yes')==1
        [FileName,PathName]=uiputfile('*.dat','Introduce the name of the measurement data file',C.PathDataFiles);
        
        if FileName~=0
            C.PathDataFiles=PathName;
            PathDataFiles=C.PathDataFiles;
            PathFigures=C.PathFigures;
            PathSignals=C.PathSignals
            save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
            
            %enable/disable various GUI buttons
            handles.cmdMeasure.Enable='off';
            handles.cmdStop.Enable='on';
            handles.cmdResetPlot.Enable='on';
            if handles.optInjectionMode.Value==1
                if handles.lstInjectionCOM.Value~=1
                    handles.cmdInjection.Enable='on';
                    handles.cmdLoad.Enable='on';
                end
                handles.cmdStimulation.Enable='off';
            end
            if handles.optStimulationMode.Value==1
                handles.cmdInjection.Enable='off';
                handles.cmdLoad.Enable='off';
                handles.cmdStimulation.Enable='on';
            end
            handles.optInjectionMode.Enable='off';
            handles.optStimulationMode.Enable='off';
            
            %define handles, initialize variables
            hcmdMeasure=handles.cmdMeasure;
            hcmdStop=handles.cmdStop;
            hcmdResetPlot=handles.cmdResetPlot;
            hcmdInjection=handles.cmdInjection;
            Injection_Running=0;
            Stimulation_Running=0;
            
            %define the total measurement time of session (s)
            TotalTimeSeg=str2double(handles.txtMeasurementTime.String);
            
            %define the time window for pltSequence (s)
            WindowTimeSeg=str2double(handles.txtWindowTime.String);
            
            %define the refresh time for pltSequence (# cycles)
            %i.e., how often pltSequence updates to add recent data
            RefreshTimes=cellstr(handles.lstRefreshTime.String);
            CyclesPerRefresh = str2double(RefreshTimes(handles.lstRefreshTime.Value));

            if (specMeasCycles == 0)
                %calculate max # refreshes needed
                TotalRefreshBatches=ceil(TotalTimeSeg*SignalFrequency/CyclesPerRefresh); %ceiling function allows for non-integer frequency
            else
                %TotalTimeSeg is not actually time segment but rather a specification of number of cycles
                %divide measurement time by refresh time to get #refreshes
                rem = mod(TotalTimeSeg, CyclesPerRefresh);
                if (rem ~= 0)
                    msgbox('Specified number of measurement cycles must be multiple of cycles per refresh batch');
                    return
                else
                    TotalRefreshBatches = TotalTimeSeg / CyclesPerRefresh; % not time seg, but really num cycles
                end
            end
            
            RefreshPerWindow=ceil(WindowTimeSeg*SignalFrequency/CyclesPerRefresh); 
            SignalShift=0; %used to shift window for reset plot
            
            %clear and delete handles and axes
            clc;
            delete(linehCurrent);
            cla(handles.pltSequence);
            delete(linehSignal);
            
            %initialize variables 
            Total_Data(1:TotalRefreshBatches*CyclesPerRefresh*PointsPerCycle)=0;
            OxPeak(1:TotalRefreshBatches*CyclesPerRefresh)=0;
            SampleOxPeak=round(get(handles.sldOxPeak,'Value'));
            
            %plot line where sample is being monitored 
            linehOxPeakV=line(handles.pltCycle,SampleOxPeak,ylim,'Color','k');
            
            %initialize variables
            N_Peaks=0;
            SP_Peaks=[];
            PP_Peaks=[];
            EP_Peaks=[];
            PeaksLabel{1}='';
            Injections=[];
            InjectionsLabel{1}='';
            N_Injections=0;
            Execution_Time=[];
            N_Refresh=0;
            Signal=[];
            StimRefreshSignal=[];
            StimRefreshSignal(1:TotalPoints*CyclesPerRefresh)=0;
            
            %build the signal repeated per refresh
            for i=1:CyclesPerRefresh
                Signal=[Signal Signal_Cycle];
            end
            
            Signal=Signal';
            AppliedSignal=Signal; % Needed for the accumulation algorithm
            StimRefreshSignal=StimRefreshSignal';
            
            %set handle and label temporal current plot
            phSequence=handles.pltSequence;
            ylabel(handles.pltCycle,'Current (nA)');
            
            %set handle for voltammogram plot
            phCycle=handles.pltCycle;
            
            %set handle and label cyclic voltammogram plot (retired)
            %phCV = handles.plotCV;
            %xlabel(handles.plotCV,'Potential (V)');
            %ylabel(handles.plotCV,'Current (nA)');

            %color plot code 
            phCP = handles.pltColorPlot;
            xlabel(handles.pltColorPlot,'Time (s)');
            ylabel(handles.pltColorPlot,'Volotage');
            
            %ignoring block of samples within the number of sampled points
            sampleIgnoreStart = str2double(handles.txtIgnoreStart.String);
            sampleNumIgnoredPoints = str2double(handles.txtNumIgnore.String);
            
            %disable ignore-related text boxes once measurement starts
            handles.txtIgnoreStart.Enable = 'off';  
            handles.txtNumIgnore.Enable = 'off';
            handles.chkIgnore.Enable = 'off';
            
            %notify when scans needed and data ready for next refresh
            s.NotifyWhenScansQueuedBelow=TotalPoints*CyclesPerRefresh;
            s.NotifyWhenDataAvailableExceeds=TotalPoints*CyclesPerRefresh;
            
            %set up listeners 
            lhout = addlistener(s,'DataRequired',@Output_Data);
            lhin = addlistener(s,'DataAvailable', @Read_Data);
            lherror=addlistener(s,'ErrorOccurred', @Process_Error);
            
            tic %start stopwatch
            queueOutputData(s,[Signal StimRefreshSignal]); %queue analog output data
            startBackground(s); %starts session
        end
    end 
end 



function Output_Data(src,event)
global Signal StimRefreshSignal StimSignal N_Refresh 
global StimFlag StimRefresh TotalStimRefreshCycles
global Injections N_Injections CyclesPerRefresh TotalPoints 
global Inj_Time Stimulation_Running cmdhStimulation
global opthInjectionMode opthStimulationMode AppliedSignal
global AccumulationFlag Accumulation_Running TotalAccuRefreshCycles AccuRefresh AccuVoltage
global PointsPerCycle NonSampledPoints StimLabelOnly
global chkRV 
global txtRV

%display(src.ScansQueued)
%disp(['Output_Data -> ' num2str(N_Refresh)]);
StimLabelOnly = handles.chkStimLabelOnly.Value; 

if StimFlag==1
    StimFlag=0; %reset flag
    N_Injections=N_Injections+1; %add injection
    Injections(N_Injections)=N_Refresh*CyclesPerRefresh; %cycle at which injection occured
    Inj_Time=tic; %start stopwatch
    Stimulation_Running=1;
    %disable buttons
    cmdhStimulation.Enable='off';
    opthInjectionMode.Enable='off';
    opthStimulationMode.Enable='off';
end

if AccumulationFlag==1
    AccumulationFlag=0; %reset flag 
    Accumulation_Running=1;
end

if Stimulation_Running==1
    if StimLabelOnly == 0 %TODO: ensure this feature works
        if StimRefresh==TotalStimRefreshCycles
            StimRefreshSignal(1:TotalPoints*CyclesPerRefresh)=0;
            Stimulation_Running=0;
            cmdhStimulation.Enable='on';
        else
            StimRefreshSignal(1:TotalPoints*CyclesPerRefresh)=StimSignal(StimRefresh*CyclesPerRefresh*TotalPoints+1:(StimRefresh+1)*CyclesPerRefresh*TotalPoints);
            StimRefresh=StimRefresh+1;
        end 
    else 
        if StimRefresh==TotalStimRefreshCycles
            StimRefreshSignal(1:TotalPoints*CyclesPerRefresh)=0;
            Stimulation_Running=0;
            cmdhStimulation.Enable='on';
        else
            StimRefresh=StimRefresh+1;
        end 
    end  
end

if Accumulation_Running==1
    AppliedSignal(1:TotalPoints*CyclesPerRefresh)=AccuVoltage; %set signal to accumulation voltage
    AccuRefresh=AccuRefresh+1;
    if AccuRefresh==TotalAccuRefreshCycles %note that a refresh cycle is a multiple of the waveform cycle (ex: 5)
        Accumulation_Running=0;
    end
else
     if chkRV==1
        RestVoltage=txtRV/1000; %convert mV to V
        AppliedSignal = []; 
        for i=0:(CyclesPerRefresh-1) %build applied signal using rest voltage during non-sampled points
            AppliedSignal((1+i*TotalPoints):(PointsPerCycle+i*TotalPoints)) =  Signal((1+i*TotalPoints):(PointsPerCycle+i*TotalPoints));
            AppliedSignal((PointsPerCycle+1+i*TotalPoints):(NonSampledPoints + PointsPerCycle+i*TotalPoints)) = RestVoltage;
            AppliedSignal = AppliedSignal';
        end
      else 
        AppliedSignal=Signal; 
    end
end

src.queueOutputData([AppliedSignal StimRefreshSignal]);
%display(src.ScansQueued)



function safeStopDAQ()
global s AppliedSignal StimRefreshSignal
global lhout lhin lherror

if s.IsRunning==true
    msgbox('Stopping session. Do not press any buttons.','In progress','warn');
    stop(s);
end

delete(lhout);
pause(1);
delete(lhin);
delete(lherror);
lhout = addlistener(s,'DataRequired',@Output_Data);
sigsize = size([AppliedSignal StimRefreshSignal],1); % num cols
zeromatrix = zeros(sigsize, 2);
queueOutputData(s,zeromatrix); % apply a bunch of zeros
startBackground(s);
pause(1);
if s.IsRunning==true
    stop(s);
end
delete(lhout);
pause(1);
delete(lhin);
delete(lherror);
msgbox('DAQ stopped safely.','Success','help');


function saveHelper()
%this function is called by other functions to save data to the .dat file
global N_Refresh CyclesPerRefresh sampleIgnoreStart sampleNumIgnoredPoints 
global Execution_Time 
global Injections N_Injections InjectionLabel Gain PointsPerCycle Total_Data CP_Data_All ScanRate WaveformName
global Signal_Cycle OxPeakVM N_Peaks SP_Peaks PP_Peaks EP_Peaks PeaksLabel IgnoreSelected VoltageMultiplier SignalFrequency

global FileName C

msgbox('Saving data. Do not press any buttons.','In progress','warn');

N_Cycles=N_Refresh*CyclesPerRefresh; %total number of cycles in data acquired

if exist(WaveformName) == 0
    WaveformName = 'NoName';
end
    
if (IgnoreSelected == 1) %status of ignore checkbox when data collection was started

    %disp(sampleIgnoreStart);
    %disp(sampleNumIgnoredPoints);
    data1_width = sampleIgnoreStart - 1;
    data2_start = sampleIgnoreStart + sampleNumIgnoredPoints;
    %disp(data2_start);
    data2_width = PointsPerCycle - (data2_start) + 1;
    
    save_unit_width = 0;
    
    if (data1_width > data2_width)
        save_unit_width = data1_width;
    else
        save_unit_width = data2_width;
    end
    
    Saved_Data = zeros(2, N_Cycles*save_unit_width);
    
    %Refresh_block_width = CyclesPerRefresh*PointsPerCycle;
    
    %disp(data1_width);
    %disp(data2_width);
    %disp(save_unit_width);
    %disp(Refresh_block_width);
    
    for i=1:N_Cycles
        Saved_Data(1, ((i-1)*save_unit_width)+1:((i-1)*save_unit_width+data1_width)) = Total_Data(((i-1)*PointsPerCycle+1):((i-1)*PointsPerCycle+data1_width));
        Saved_Data(2, ((i-1)*save_unit_width)+1:((i-1)*save_unit_width+data2_width)) = Total_Data(((i-1)*PointsPerCycle+data2_start):((i-1)*PointsPerCycle+PointsPerCycle));
    end
    
    save(strcat(C.PathDataFiles,FileName),'N_Cycles','Saved_Data','Execution_Time','Injections','N_Injections','InjectionLabel','Gain','PointsPerCycle','Signal_Cycle','OxPeakVM','N_Peaks','SP_Peaks','PP_Peaks','EP_Peaks','PeaksLabel', 'IgnoreSelected','CP_Data_All','SignalFrequency','VoltageMultiplier', 'ScanRate', 'WaveformName');

else
    Saved_Data=Total_Data(1:N_Refresh*CyclesPerRefresh*PointsPerCycle);
    
    save(strcat(C.PathDataFiles,FileName),'N_Cycles','Saved_Data','Execution_Time','Injections','N_Injections','InjectionLabel','Gain','PointsPerCycle','Signal_Cycle','OxPeakVM','N_Peaks','SP_Peaks','PP_Peaks','EP_Peaks','PeaksLabel', 'IgnoreSelected','CP_Data_All','SignalFrequency', 'VoltageMultiplier', 'ScanRate', 'WaveformName');
msgbox('Data saved!','Success','help');
end


function Read_Data(src,event)
global PointsPerCycle CyclesPerRefresh TotalRefreshBatches RefreshPerWindow TotalPoints
global s lhout lhin lherror Total_Data N_Refresh phSequence phCycle Execution_Time SignalShift
global labelhOxPeak linehCurrent SampleOxPeak OxPeak linehOxPeakV Gain 
global Injections N_Injections InjectionLabel opthInjectionMode
global FileName C cmdhStimulation opthStimulationMode hcmdInjection
global hcmdMeasure hcmdStop hcmdResetPlot
global OxPeakVM N_Peaks SP_Peaks PP_Peaks EP_Peaks PeaksLabel 
global labelInjectionTime Inj_Time Injection_Running Stimulation_Running
global SignalFrequency VoltageDriver 
global CV_Data Signal_Cycle phCV discardData phCP CP_Data CP_Data_All generateCP


%Execution_Time(N_Refresh+1)=toc(Exe_Time);

Exe_Time=tic;
%disp(src.ScansAcquired)
if (Injection_Running==1) || (Stimulation_Running==1)
    labelInjectionTime.String=round(toc(Inj_Time));
end
N_Refresh=N_Refresh+1;
%disp(['Read_Data -> ' num2str(N_Refresh)]);

%CV_Data = zeros(1,PointsPerCycle); %creates matrix of zeros with size of 1xPointsPerCycle
CP_Data = zeros(PointsPerCycle, CyclesPerRefresh); %create matrix for color plot current intensity

for i=1:CyclesPerRefresh 
    Total_Data((N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+(i-1)*PointsPerCycle+1:(N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+i*PointsPerCycle)=VoltageDriver*event.Data((i-1)*TotalPoints+1:(i-1)*TotalPoints+PointsPerCycle)';%e.g., change from -event.Data... to + for Pine Potentiostat
    OxPeak((N_Refresh-1)*CyclesPerRefresh+i)=Total_Data((N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+(i-1)*PointsPerCycle+1+SampleOxPeak);
    current_batch = VoltageDriver*event.Data((i-1)*TotalPoints+1:(i-1)*TotalPoints+PointsPerCycle)'; %e.g., change from -event.Data... to + for Pine Potentiostat; dependent on RE or WE-driven potentiostat
    %CV_Data = CV_Data + current_batch;
    CP_Data(:,i) = current_batch';
end

%retired CV and color plot (CP) code
%CV_Data = (1/CyclesPerRefresh) * Gain * CV_Data; % multiply by Gain to get current from collected voltages, then divide by CyclesPerRefresh (averaged over cycles)
CP_Data = CP_Data*Gain; 
CP_Data = reshape(CP_Data,PointsPerCycle,CyclesPerRefresh);
CP_Data = CP_Data';
%CP_Data_All = [CP_Data_All CP_Data];
%cla(phCV);
cla(phCP); % clears handle for Color Plot (CP)
xlabel(phCP,'Time');
ylabel(phCP,'Voltage');
%plot(phCV, Signal_Cycle(1:PointsPerCycle), CV_Data);
%xlabel(phCV,'Potential (V)');
%ylabel(phCV,'Current (nA)');

if N_Refresh<=RefreshPerWindow
    cla(phSequence);
    cla(phCP)
    line(phSequence,(1/SignalFrequency)*(SignalShift*CyclesPerRefresh+1:N_Refresh*CyclesPerRefresh),Gain*OxPeak(SignalShift*CyclesPerRefresh+1:N_Refresh*CyclesPerRefresh));
    pcolor(phCP,(1/SignalFrequency)*(SignalShift*CyclesPerRefresh+1:N_Refresh*CyclesPerRefresh),1:PointsPerCycle,CP_Data);
    phCP.EdgeColor = 'none';
    phCP.colormap(myCustomColormap); 
    phCP.colorbar;

else
    cla(phSequence);
    line(phSequence,(1/SignalFrequency)*((N_Refresh+SignalShift-RefreshPerWindow)*CyclesPerRefresh+1:N_Refresh*CyclesPerRefresh),Gain*OxPeak((N_Refresh+SignalShift-RefreshPerWindow)*CyclesPerRefresh+1:N_Refresh*CyclesPerRefresh));
    pcolor(phCP,(1/SignalFrequency)*((N_Refresh+SignalShift-RefreshPerWindow)*CyclesPerRefresh+1:N_Refresh*CyclesPerRefresh),1:PointsPerCycle,CP_Data);
    phCP.EdgeColor = 'none';
    phCP.colormap(myCustomColormap); 
    phCP.colorbar;
    if SignalShift>0
        SignalShift=SignalShift-1;
    end
end
for i=1:N_Injections
    if ((1/SignalFrequency)*Injections(i)>phSequence.XLim(1)) && ((1/SignalFrequency)*Injections(i)<phSequence.XLim(2))
        line(phSequence,[(1/SignalFrequency)*Injections(i) (1/SignalFrequency)*Injections(i)],phSequence.YLim,'Color','r');
        text(phSequence,(1/SignalFrequency)*Injections(i),phSequence.YLim(2),InjectionLabel{i});
    end
end
%toc
cla(phCycle);
line(phCycle,(1:PointsPerCycle),Gain*Total_Data((N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+1:(N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+PointsPerCycle),'Color','r');
line(phCycle,[SampleOxPeak SampleOxPeak],phCycle.YLim,'Color','k');

set(labelhOxPeak,'String',Gain*Total_Data((N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+SampleOxPeak));
% set(labelhOxPeak,'String',Total_Data((N_Refresh-1)*PointsPerCycle*CyclesPerRefresh+SampleOxPeak));
%toc
if N_Refresh==TotalRefreshBatches
    safeStopDAQ();

    OxPeakVM=SampleOxPeak;
%     N_Cycles=N_Refresh*CyclesPerRefresh;
%     Saved_Data=Total_Data(1:N_Refresh*CyclesPerRefresh*PointsPerCycle);
%     save(strcat(C.PathDataFiles,FileName),'N_Cycles','Saved_Data','Execution_Time','Injections','N_Injections','InjectionLabel','Gain','PointsPerCycle','Signal_Cycle','OxPeakVM','N_Peaks','SP_Peaks','PP_Peaks','EP_Peaks','PeaksLabel');
    
    
    if (discardData == 0)
            saveHelper();
    end
    
    msgbox('Measurement complete. Data were saved','End of Measurement');
    hcmdMeasure.Enable='on';
    hcmdStop.Enable='off';
    hcmdResetPlot.Enable='off';
    hcmdInjection.Enable='off';
    cmdhStimulation.Enable='off';
    opthInjectionMode.Enable='on';
    opthStimulationMode.Enable='on';
end
Execution_Time(N_Refresh)=toc(Exe_Time);


function Process_Error(src,event)
global s lhout lhin lherror Total_Data N_Refresh CyclesPerRefresh PointsPerCycle Execution_Time
global Injections N_Injections InjectionLabel Gain Signal_Cycle
global OxPeakVM N_Peaks SP_Peaks PP_Peaks EP_Peaks PeaksLabel  opthInjectionMode
global hcmdMeasure hcmdStop hcmdResetPlot hcmdInjection cmdhStimulation opthStimulationMode

disp(getReport(event.Error))
%daq.reset;
% pause(10);
% delete(lhout);
% pause(1);
% delete(lhin);
%delete(lherror);

stop(event.Source);
OxPeakVM=round(get(handles.sldOxPeak,'Value'));

% N_Cycles=N_Refresh*CyclesPerRefresh;
% Saved_Data=Total_Data(1:N_Refresh*CyclesPerRefresh*PointsPerCycle);
% save(strcat(C.PathDataFiles,FileName),'N_Cycles','Saved_Data','Execution_Time','Injections','N_Injections','InjectionLabel','Gain','PointsPerCycle','Signal_Cycle','OxPeakVM','N_Peaks','SP_Peaks','PP_Peaks','EP_Peaks','PeaksLabel');

saveHelper();

msgbox('An error occurred during measurement. Data were saved','End of Measurement');
hcmdMeasure.Enable='on';
hcmdStop.Enable='off';
hcmdResetPlot.Enable='off';
hcmdInjection.Enable='off';
cmdhStimulation.Enable='off';
opthInjectionMode.Enable='on';
opthStimulationMode.Enable='on';


% --- Executes on button press in cmdStop.
function cmdStop_Callback(hObject, eventdata, handles)
% hObject    handle to cmdStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s lhout lhin lherror Total_Data N_Refresh CyclesPerRefresh PointsPerCycle Execution_Time
global Injections N_Injections InjectionLabel Gain Signal_Cycle
global FileName C
global OxPeakVM N_Peaks SP_Peaks PP_Peaks EP_Peaks PeaksLabel
global AppliedSignal StimRefreshSignal
global discardData bkgdCP_All CP_All_Data CP_Data

safeStopDAQ();

%disable buttons
handles.cmdStop.Enable='off';
handles.cmdResetPlot.Enable='off';
handles.cmdInjection.Enable='off';
handles.cmdLoad.Enable='off';
handles.cmdStimulation.Enable='off';
handles.optStimulationMode.Enable='on';
handles.optInjectionMode.Enable='on';

OxPeakVM=round(get(handles.sldOxPeak,'Value'));

if (discardData == 0)
    saveHelper();
end

%clear variables 
clear bkgdCP_All CP_All_Data CP_Data

%Saved_Data=Total_Data(1:N_Refresh*CyclesPerRefresh*PointsPerCycle);
%save(strcat(C.PathDataFiles,FileName),'N_Cycles','Saved_Data','Execution_Time','Injections','N_Injections','InjectionLabel','Gain','PointsPerCycle','Signal_Cycle','OxPeakVM','N_Peaks','SP_Peaks','PP_Peaks','EP_Peaks','PeaksLabel', 'IgnoreSelected');

msgbox('Measurement stopped by the user. Data were saved','End of Measurement');
handles.cmdMeasure.Enable='on';


% --- Executes on slider movement.
function sldOxPeak_Callback(hObject, eventdata, handles)
% hObject    handle to sldOxPeak (see GCBO)
% eventdata  freserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global linehOxPeakV Signal_Cycle SampleOxPeak VoltageMultiplier

SampleOxPeak=round(get(hObject,'Value')); %round to integer

%replot the sample monitoring marker
delete(linehOxPeakV);
linehOxPeakV=line(handles.pltCycle,[SampleOxPeak SampleOxPeak],ylim,'Color','k');

%display voltages and sample number that are being monitored 
if SampleOxPeak==0
    set(handles.lblOxPeakVoltage,'String',Signal_Cycle(1));
    set(handles.lblSample,'String',1);
    set(handles.lblOxPeakVoltage_Multiplier,'String',(1/VoltageMultiplier)*Signal_Cycle(1));
else
    set(handles.lblOxPeakVoltage,'String',Signal_Cycle(SampleOxPeak));
    set(handles.lblSample,'String',SampleOxPeak);
    set(handles.lblOxPeakVoltage_Multiplier,'String',(1/VoltageMultiplier)*Signal_Cycle(SampleOxPeak));
end;


% --- Executes during object creation, after setting all properties.
function sldOxPeak_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s PCOM TimerPulse

SessionOpened=true;
try
    MeasurementRunning=s.IsRunning;
catch ME
    MeasurementRunning=false;
    SessionOpened=false;
end

if MeasurementRunning==true
    Answer = questdlg('The system is running do you want to stop it and exit without saving data?', 'Warning','Yes', 'No','No');
    if strcmp(Answer,'Yes')==1
        % Stop measurement
        stop(s);
        delete(s);
        clear s;
        
        % Close COM Port
        fclose(PCOM);
        delete(PCOM);
        clear PCOM;
        
        % Close Timer
        delete(TimerPulse);
        clear TimerPulse
        
        % disp('Adios');
        % Hint: delete(hObject) closes the figure
        delete(hObject);
    end
    
else
    if SessionOpened==true
        % Delete session
        delete(s);
        clear s;
    end
    % Close COM Port
    fclose(PCOM);
    delete(PCOM);
    clear PCOM;
    
    % Close Timer
    delete(TimerPulse);
    clear TimerPulse
    
    %disp('Adios');
    %Hint: delete(hObject) closes the figure
    delete(hObject);
    
end


% --- Executes on button press in cmdResetPlot.
function cmdResetPlot_Callback(hObject, eventdata, handles)
% hObject    handle to cmdResetPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SignalShift N_Refresh RefreshPerWindow

if N_Refresh<=RefreshPerWindow
    SignalShift=N_Refresh-1;
else
    SignalShift=RefreshPerWindow-1;
end


% --- Executes on button press in cmdStimulation.
function cmdStimulation_Callback(hObject, eventdata, handles)
% hObject    handle to cmdStimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global N_Injections CyclesPerRefresh InjectionLabel PointsPerCycle
global StimSignal TotalPoints StimFlag ScanRate StimRefresh TotalStimRefreshCycles
global AccumulationFlag TotalAccuRefreshCycles AccuRefresh AccuVoltage StimLabelOnly

% TODO: signal frequency not always 10Hz
StimLabelOnly = handles.chkStimLabelOnly.Value; 

if StimLabelOnly == 0 %if we only want to do an event marker, do not make a stim signal

    %set local stimulation variables from user input boxes
    StimFrequencies=cellstr(handles.lstStimFrequency.String);
    StimFrequency=str2double(StimFrequencies(handles.lstStimFrequency.Value));
    StimPulseWidth=str2double(handles.txtStimPulseWidth.String)/1000; %converts mV to V
    StimDuration=str2double(handles.txtStimDuration.String);
    StimVoltage=str2double(handles.txtStimVoltage.String)/1000; %converts mV to V

    %check if the number of points in the stimulation exceeds the number of
    %points collected in a refresh cycle of acquired data

    %if the number of stimulation points is greater than total points,
    %initialize a new StimSignal of custom length and calculate a custom value
    %for TotalStimRefreshCycles
    if StimDuration*ScanRate>CyclesPerRefresh*TotalPoints
        StimSignal(1:ScanRate*StimDuration)=0;
        TotalStimRefreshCycles=StimDuration*ScanRate/(CyclesPerRefresh*TotalPoints);

    %if the number of stimulation points is equal/less than total points,
    %initialize a StimSignal of same length length 
    else
        StimSignal(1:CyclesPerRefresh*TotalPoints)=0;
        TotalStimRefreshCycles=1;
    end

    if handles.chkStimNoiseReduction.Value==0 %no noise reduction
        Cycle=round(ScanRate/StimFrequency); %what fraction of time is spent stimulating
        if handles.chkBiphasicStimulation.Value==0 %not biphasic
            for i=1:StimFrequency*StimDuration %number of stims
                for j=1:StimPulseWidth*ScanRate %number of points/stim
                    StimSignal((i-1)*Cycle+j)=StimVoltage; %build stim signal
                end
            end
        else %biphasic so divide by 2 and shift between +/-
            for i=1:StimFrequency*StimDuration
                for j=1:round(StimPulseWidth*ScanRate/2)%first half of pulse
                    StimSignal((i-1)*Cycle+j)=StimVoltage;
                end
                for j=round(StimPulseWidth*ScanRate/2)+1:StimPulseWidth*ScanRate %second half of pulse
                    StimSignal((i-1)*Cycle+j)=-StimVoltage;
                end
            end
        end
    else %noise reduction
        NPulsesPerCycle=StimFrequency/10; %TODO: update?; currently gives NStims per waveform applied (cycle)
        StimSignal(1:StimDuration*ScanRate)=0;
        IntervalPulses=(0.1-PointsPerCycle/ScanRate+0.001)/(StimFrequency*0.1); % Interval between pulses: 100 ms - signal cycle time + 1 ms
        StimOffset=(PointsPerCycle/ScanRate+0.001); 
        if handles.chkBiphasicStimulation.Value==0 %not biphasic
            for i=1:StimDuration*10 %TODO: update? why 10? why 0.1?
                for j=1:NPulsesPerCycle
                    for k=1:StimPulseWidth*ScanRate
                        StimSignal(round((i-1)*0.1*ScanRate+(StimOffset+(j-1)*IntervalPulses)*ScanRate+k))=StimVoltage;
                    end
                end
            end
        else %biphasic
            for i=1:StimDuration*10 %TODO: update? why 10? why 0.1?
                for j=1:NPulsesPerCycle
                    for k=1:round(StimPulseWidth*ScanRate/2) %first half of pulse
                        StimSignal(round((i-1)*0.1*ScanRate+(StimOffset+(j-1)*IntervalPulses)*ScanRate+k))=StimVoltage;
                    end
                    for k=round(StimPulseWidth*ScanRate/2)+1:StimPulseWidth*ScanRate %second half of pulse
                        StimSignal(round((i-1)*0.1*ScanRate+(StimOffset+(j-1)*IntervalPulses)*ScanRate+k))=-StimVoltage;
                    end
                end
            end
        end
    end
end 

if handles.chkAccumulation.Value==1
    AccuTime=str2double(handles.txtAccumulationTime.String);
    AccuVoltage=str2double(handles.txtAccumulationVoltage.String)/1000; %convert mV to V
    AccumulationFlag=1;
    TotalAccuRefreshCycles=AccuTime*ScanRate/(CyclesPerRefresh*TotalPoints);
    AccuRefresh=0;   
end

InjectionLabel{N_Injections+1}=get(handles.txtInjection,'String'); % To avoid using handles in function Output_Data
handles.lblLastInject.String = InjectionLabel{N_Injections+1};%display it

StimFlag=1;
StimRefresh=0;


% --- Executes on button press in cmdInjection.
function cmdInjection_Callback(hObject, eventdata, handles)
% hObject    handle to cmdInjection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global N_Refresh Injections N_Injections CyclesPerRefresh InjectionLabel
global PCOM TimerPulse Inj_Time Injection_Running

global AccumulationFlag TotalAccuRefreshCycles AccuRefresh AccuVoltage

%disable buttons
handles.cmdInjection.Enable='off';
handles.cmdLoad.Enable='off';
handles.optInjectionMode='off';
handles.optStimulationMode='off';

if handles.chkInvInjLoad.Value==0
    set(PCOM,'RequestToSend','on'); % Clear Inject line to 0V
else
    set(PCOM,'DataTerminalReady','on'); % Clear Inject line to 0V
end
start(TimerPulse); %timer starts when inject button is hit by user

N_Injections=N_Injections+1;
Injections(N_Injections)=N_Refresh*CyclesPerRefresh;

if handles.chkAccumulation.Value==1
    AccuTime=str2double(handles.txtAccumulationTime.String);
    AccuVoltage=str2double(handles.txtAccumulationVoltage.String)/1000;
    AccumulationFlag=1;
    TotalAccuRefreshCycles=AccuTime*ScanRate/(CyclesPerRefresh*TotalPoints);
    AccuRefresh=0; 
end

InjectionLabel{N_Injections+1}=get(handles.txtInjection,'String'); %add label to list
handles.lblLastInject.String = InjectionLabel{N_Injections+1};%display it

Inj_Time=tic;
Injection_Running=1; %set flag


% --- Executes on button press in cmdLoad.
function cmdLoad_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global PCOM TimerPulse Injection_Running

%disable buttons
handles.cmdInjection.Enable='off';
handles.cmdLoad.Enable='off';
handles.optInjectionMode='off';
handles.optStimulationMode='off';

if handles.chkInvInjLoad.Value==0
    set(PCOM,'DataTerminalReady','on'); % Clear Load line to 0V
else
    set(PCOM,'RequestToSend','on'); % Clear Load line to 0V
end
start(TimerPulse); %timer is started when load button hit by user
Injection_Running=0; %reset flag



function Timer(hObject, eventdata, handles)
global PCOM

%enable buttons once timer has elapsed
handles.cmdInjection.Enable='on';
handles.cmdLoad.Enable='on';
handles.optInjectionMode='on';
handles.optStimulationMode='on';

set(PCOM,'RequestToSend','off'); % Set Inject line to +3,3V
set(PCOM,'DataTerminalReady','off'); % Set Load line to +3,3V


function txtInjection_Callback(hObject, eventdata, handles)
% hObject    handle to txtInjection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtInjection as text
%        str2double(get(hObject,'String')) returns contents of txtInjection as a double


% --- Executes during object creation, after setting all properties.
function txtInjection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtInjection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in opt200.
function opt200_Callback(hObject, eventdata, handles)
% hObject    handle to opt200 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of opt200
global Gain 

if get(hObject,'Value')==1
    Gain = 200;
    handles.lblGain.String=Gain;
end


% --- Executes on button press in opt1000.
function opt1000_Callback(hObject, eventdata, handles)
% hObject    handle to opt1000 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of opt1000
global Gain 

if get(hObject,'Value')==1
    Gain = 1000;
    handles.lblGain.String=Gain;
end


% --- Executes on button press in optCustom.
function optCustom_Callback(hObject, eventdata, handles)
% hObject    handle to optCustom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Gain 

if get(hObject,'Value')==1
    handles.txtCustomGain.Enable='on';
%     Gain = str2double(handles.txtCustomGain.String);
%     handles.lblGain.String=Gain;
end


% Hint: get(hObject,'Value') returns toggle state of optCustom
function txtCustomGain_Callback(hObject, eventdata, handles)
% hObject    handle to txtCustomGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtCustomGain as text
%        str2double(get(hObject,'String')) returns contents of txtCustomGain as a double

global Gain 

Gain = str2double(handles.txtCustomGain.String);
handles.lblGain.String=Gain;


% --- Executes during object creation, after setting all properties.
function txtCustomGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtCustomGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%----------Start legacy code for gain calibration----------%
% % --- Executes on button press in opt100.
% function opt100_Callback(hObject, eventdata, handles)
% % hObject    handle to opt100 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt100
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(1,1)/Rf1;
%     else
%         Gain=G(1,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
    

% % --- Executes on button press in opt50.
% function opt50_Callback(hObject, eventdata, handles)
% % hObject    handle to opt50 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt50
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(2,1)/Rf1;
%     else
%         Gain=G(2,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% 
% % --- Executes on button press in opt20.
% function opt20_Callback(hObject, eventdata, handles)
% % hObject    handle to opt20 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt20
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(3,1)/Rf1;
%     else
%         Gain=G(3,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% 
% % --- Executes on button press in opt10.
% function opt10_Callback(hObject, eventdata, handles)
% % hObject    handle to opt10 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt10
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(4,1)/Rf1;
%     else
%         Gain=G(4,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% 
% % --- Executes on button press in opt5.
% function opt5_Callback(hObject, eventdata, handles)
% % hObject    handle to opt5 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt5
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(5,1)/Rf1;
%     else
%         Gain=G(5,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% % --- Executes on button press in opt2.
% function opt2_Callback(hObject, eventdata, handles)
% % hObject    handle to opt2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt2
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(6,1)/Rf1;
%     else
%         Gain=G(6,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% 
% % --- Executes on button press in opt1.
% function opt1_Callback(hObject, eventdata, handles)
% % hObject    handle to opt1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of opt1
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rf1=Rf1*1000;
% Rp=Rp*1000;
% 
% if get(hObject,'Value')==1
%     if handles.optx0_1.Value==1
%         Gain=G(7,1)/Rf1;
%     else
%         Gain=G(7,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% % --- Executes on button press in optx1.
% function optx1_Callback(hObject, eventdata, handles)
% % hObject    handle to optx1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of optx1
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf2=str2double(handles.txtRf2.String);
% Rp=(Rf1*Rf2)/(Rf1+Rf2);
% Rp=Rp*1000;
% 
% if get(hObject,'Value')==1
%     if handles.opt1.Value==1
%         Gain=G(7,2)/Rp;
%     end
%     if handles.opt2.Value==1
%         Gain=G(6,2)/Rp;
%     end
%     if handles.opt5.Value==1
%         Gain=G(5,2)/Rp;
%     end
%     if handles.opt10.Value==1
%         Gain=G(4,2)/Rp;
%     end
%     if handles.opt20.Value==1
%         Gain=G(3,2)/Rp;
%     end
%     if handles.opt50.Value==1
%         Gain=G(2,2)/Rp;
%     end
%     if handles.opt100.Value==1
%         Gain=G(1,2)/Rp;
%     end
%     handles.lblGain.String=Gain;
% end
% 
% % --- Executes on button press in optx0_1.
% function optx0_1_Callback(hObject, eventdata, handles)
% % hObject    handle to optx0_1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of optx0_1
% global Gain G
% 
% Rf1=str2double(handles.txtRf1.String);
% Rf1=Rf1*1000;
% if get(hObject,'Value')==1
%     if handles.opt1.Value==1
%         Gain=G(7,1)/Rf1;
%     end
%     if handles.opt2.Value==1
%         Gain=G(6,1)/Rf1;
%     end
%     if handles.opt5.Value==1
%         Gain=G(5,1)/Rf1;
%     end
%     if handles.opt10.Value==1
%         Gain=G(4,1)/Rf1;
%     end
%     if handles.opt20.Value==1
%         Gain=G(3,1)/Rf1;
%     end
%     if handles.opt50.Value==1
%         Gain=G(2,1)/Rf1;
%     end
%     if handles.opt100.Value==1
%         Gain=G(1,1)/Rf1;
%     end
%     handles.lblGain.String=Gain;
% end
%----------End legacy code for gain calibration----------%

%TODO: for future release
% --- Executes on button press in chkInvInjLoad.
function chkInvInjLoad_Callback(hObject, eventdata, handles)
% hObject    handle to chkInvInjLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkInvInjLoad



function txtMeasurementTime_Callback(hObject, eventdata, handles)
% hObject    handle to txtMeasurementTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMeasurementTime as text
%        str2double(get(hObject,'String')) returns contents of txtMeasurementTime as a double



% --- Executes during object creation, after setting all properties.
function txtMeasurementTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMeasurementTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtWindowTime_Callback(hObject, eventdata, handles)
% hObject    handle to txtWindowTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtWindowTime as text
%        str2double(get(hObject,'String')) returns contents of txtWindowTime as a double


% --- Executes during object creation, after setting all properties.
function txtWindowTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtWindowTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtRefreshTime_Callback(hObject, eventdata, handles)
% hObject    handle to txtRefreshTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRefreshTime as text
%        str2double(get(hObject,'String')) returns contents of txtRefreshTime as a double


% --- Executes during object creation, after setting all properties.
function txtRefreshTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtRefreshTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtStimDuration_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimDuration as text
%        str2double(get(hObject,'String')) returns contents of txtStimDuration as a double


% --- Executes during object creation, after setting all properties.
function txtStimDuration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtStimDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtStimPulseWidth_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimPulseWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimPulseWidth as text
%        str2double(get(hObject,'String')) returns contents of txtStimPulseWidth as a double


% --- Executes during object creation, after setting all properties.
function txtStimPulseWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtStimPulseWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtStimFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimFrequency as text
%        str2double(get(hObject,'String')) returns contents of txtStimFrequency as a double


% --- Executes during object creation, after setting all properties.
function txtStimFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtStimFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optStimulationMode.
function optStimulationMode_Callback(hObject, eventdata, handles)
% hObject    handle to optStimulationMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optStimulationMode
if get(hObject,'Value')==1
    handles.chkInvInjLoad.Enable='off';
    handles.lstStimFrequency.Enable='on';
    handles.txtStimPulseWidth.Enable='on';
    handles.txtStimDuration.Enable='on';
    handles.txtStimVoltage.Enable='on';
end


% --- Executes on button press in optInjectionMode.
function optInjectionMode_Callback(hObject, eventdata, handles)
% hObject    handle to optInjectionMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optInjectionMode
if get(hObject,'Value')==1
    handles.chkInvInjLoad.Enable='on';
    handles.lstStimFrequency.Enable='off';
    handles.txtStimPulseWidth.Enable='off';
    handles.txtStimDuration.Enable='off';
    handles.txtStimVoltage.Enable='off';
end



function txtStimVoltage_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimVoltage as text
%        str2double(get(hObject,'String')) returns contents of txtStimVoltage as a double


% --- Executes during object creation, after setting all properties.
function txtStimVoltage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtStimVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lstRefreshTime.
function lstRefreshTime_Callback(hObject, eventdata, handles)
% hObject    handle to lstRefreshTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstRefreshTime contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstRefreshTime


% --- Executes during object creation, after setting all properties.
function lstRefreshTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstRefreshTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkBiphasicStimulation.
function chkBiphasicStimulation_Callback(hObject, eventdata, handles)
% hObject    handle to chkBiphasicStimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkBiphasicStimulation


% --- Executes on selection change in lstInjectionCOM.
function lstInjectionCOM_Callback(hObject, eventdata, handles)
% hObject    handle to lstInjectionCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstInjectionCOM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstInjectionCOM
global PortList PCOM

if isvalid(PCOM)==1
    if strcmp(PCOM.status,'open')==1
        fclose(PCOM);
    end
end
SelectedCOM=handles.lstInjectionCOM.Value;
if SelectedCOM~=1
    % COM port for LOAD/INJECTION control
    COMString=PortList{SelectedCOM};
    PCOM=serial(COMString);
    set(PCOM,'BaudRate',9600);
    set(PCOM,'DataBits',8);
    set(PCOM,'Parity','none');
    set(PCOM,'StopBits',1);
    set(PCOM,'FlowControl','none'); % No flow control (RTS and DTR controlled manually)
    set(PCOM,'RequestToSend','off'); % Set Inject line to +3,3V
    set(PCOM,'DataTerminalReady','off'); % Set Inject line to +3,3V
    fopen(PCOM);
    if strcmp(handles.cmdResetPlot.Enable,'on')==1
        handles.cmdInjection.Enable='on';
        handles.cmdLoad.Enable='on';
    end
else
    handles.cmdInjection.Enable='off';
    handles.cmdLoad.Enable='off';
end

% --- Executes during object creation, after setting all properties.
function lstInjectionCOM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstInjectionCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%Legacy code for feedback resistor custom headstage
% 
% function txtRf1_Callback(hObject, eventdata, handles)
% % hObject    handle to txtRf1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of txtRf1 as text
% %        str2double(get(hObject,'String')) returns contents of txtRf1 as a double
% 
% 
% % --- Executes during object creation, after setting all properties.
% function txtRf1_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtRf1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% 
% function txtRf2_Callback(hObject, eventdata, handles)
% % hObject    handle to txtRf2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'String') returns contents of txtRf2 as text
% %        str2double(get(hObject,'String')) returns contents of txtRf2 as a double


% % --- Executes during object creation, after setting all properties.
% function txtRf2_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to txtRf2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: edit controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% --- Executes on button press in chkStimNoiseReduction.
function chkStimNoiseReduction_Callback(hObject, eventdata, handles)
% hObject    handle to chkStimNoiseReduction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkStimNoiseReduction


% --- Executes on selection change in lstStimFrequency.
function lstStimFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to lstStimFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstStimFrequency contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstStimFrequency


% --- Executes during object creation, after setting all properties.
function lstStimFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstStimFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkAccumulation.
function chkAccumulation_Callback(hObject, eventdata, handles)
% hObject    handle to chkAccumulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkAccumulation
if handles.chkAccumulation.Value==0
    handles.lblAccumulationVoltage.ForegroundColor=[0.5 0.5 0.5];
    handles.lblAccumulationTime.ForegroundColor=[0.5 0.5 0.5];
    handles.txtAccumulationVoltage.Enable='off';
    handles.txtAccumulationTime.Enable='off';
else
    handles.lblAccumulationVoltage.ForegroundColor=[0 0 0];
    handles.lblAccumulationTime.ForegroundColor=[0 0 0];
    handles.txtAccumulationVoltage.Enable='on';
    handles.txtAccumulationTime.Enable='on';
end


function txtAccumulationVoltage_Callback(hObject, eventdata, handles)
% hObject    handle to txtAccumulationVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtAccumulationVoltage as text
%        str2double(get(hObject,'String')) returns contents of txtAccumulationVoltage as a double


% --- Executes during object creation, after setting all properties.
function txtAccumulationVoltage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtAccumulationVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtAccumulationTime_Callback(hObject, eventdata, handles)
% hObject    handle to txtAccumulationTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtAccumulationTime as text
%        str2double(get(hObject,'String')) returns contents of txtAccumulationTime as a double


% --- Executes during object creation, after setting all properties.
function txtAccumulationTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtAccumulationTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RefElecUp.
function RefElecUp_Callback(hObject, eventdata, handles)
% hObject    handle to RefElecUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RefElecY StepIncrement

RefElecY = RefElecY + StepIncrement;
updateElecPos('R');

% --- Executes on button press in RecElecDown.
function RecElecDown_Callback(hObject, eventdata, handles)
% hObject    handle to RecElecDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RefElecY StepIncrement

RefElecY = RefElecY - StepIncrement;
updateElecPos('R');

% --- Executes on button press in RecElecLeft.
function RecElecLeft_Callback(hObject, eventdata, handles)
% hObject    handle to RecElecLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RefElecX StepIncrement

RefElecX = RefElecX - StepIncrement;
updateElecPos('R');

% --- Executes on button press in RefElecRight.
function RefElecRight_Callback(hObject, eventdata, handles)
% hObject    handle to RefElecRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RefElecX StepIncrement

RefElecX = RefElecX + StepIncrement;
updateElecPos('R');

% --- Executes on button press in RefElecIn.
function RefElecIn_Callback(hObject, eventdata, handles)
% hObject    handle to RefElecIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RefElecZ StepIncrement

RefElecZ = RefElecZ - StepIncrement;
updateElecPos('R');

% --- Executes on button press in RefElecOut.
function RefElecOut_Callback(hObject, eventdata, handles)
% hObject    handle to RefElecOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global RefElecZ StepIncrement

RefElecZ = RefElecZ + StepIncrement;
updateElecPos('R');

% --- Executes on button press in StimElecUp.
function StimElecUp_Callback(hObject, eventdata, handles)
% hObject    handle to StimElecUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StimElecY StepIncrement

StimElecY = StimElecY + StepIncrement;
updateElecPos('S');

% --- Executes on button press in StimElecDown.
function StimElecDown_Callback(hObject, eventdata, handles)
% hObject    handle to StimElecDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StimElecY StepIncrement

StimElecY = StimElecY - StepIncrement;
updateElecPos('S');

% --- Executes on button press in StimElecLeft.
function StimElecLeft_Callback(hObject, eventdata, handles)
% hObject    handle to StimElecLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StimElecX StepIncrement

StimElecX = StimElecX - StepIncrement;
updateElecPos('S');

% --- Executes on button press in StimElecRight.
function StimElecRight_Callback(hObject, eventdata, handles)
% hObject    handle to StimElecRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StimElecX StepIncrement

StimElecX = StimElecX + StepIncrement;
updateElecPos('S');


% --- Executes on button press in StimElecIn.
function StimElecIn_Callback(hObject, eventdata, handles)
% hObject    handle to StimElecIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StimElecZ StepIncrement

StimElecZ = StimElecZ - StepIncrement;
updateElecPos('S');


% --- Executes on button press in StimElecOut.
function StimElecOut_Callback(hObject, eventdata, handles)
% hObject    handle to StimElecOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StimElecZ StepIncrement

StimElecZ = StimElecZ + StepIncrement;
updateElecPos('S');


% --- Executes on button press in OneMMStep.
function OneMMStep_Callback(hObject, eventdata, handles)
% hObject    handle to OneMMStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OneMMStep

global StepIncrement

if (get(hObject, 'Value'))
    StepIncrement = 1000;
end


% --- Executes on button press in HundredMicronStep.
function HundredMicronStep_Callback(hObject, eventdata, handles)
% hObject    handle to HundredMicronStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of HundredMicronStep

global StepIncrement

if (get(hObject, 'Value'))
    StepIncrement = 100;
end


% --- Executes on button press in TenMicronStep.
function TenMicronStep_Callback(hObject, eventdata, handles)
% hObject    handle to TenMicronStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TenMicronStep

global StepIncrement

if (get(hObject, 'Value'))
    StepIncrement = 10;
end


% --- Executes on button press in OneMicronStep.
function OneMicronStep_Callback(hObject, eventdata, handles)
% hObject    handle to OneMicronStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OneMicronStep

global StepIncrement 

if (get(hObject, 'Value'))
    StepIncrement = 1;
end


function updateElecPos(refStim)
%updates reference electrode position with current coordinates in global
%variables

global RefElecX RefElecY RefElecZ StimElecX StimElecY StimElecZ REF_ELEC_COM_PORT STIM_ELEC_COM_PORT

%based on Sutter Micromanipulator USBTester sample code

    % convert target position in um to step moter microstep
    if (refStim == 'R')
        Motor_X = (RefElecX*16);
        Motor_Y = (RefElecY*16);
        Motor_Z = (RefElecZ*16);
    end
    
    if (refStim == 'S')
        Motor_X = (StimElecX*16);
        Motor_Y = (StimElecY*16);
        Motor_Z = (StimElecZ*16);
    end
        
    i=1;
    xc=uint8([0 0 0 0]);% microstep represented by bytes
    
    while (Motor_X > 0)
        xc(i)=uint8(mod(Motor_X,16^2));
        Motor_X=floor(Motor_X/(16^2));
        i=i+1;
    end
    
    yc=uint8([0 0 0 0]);% microstep represented by bytes
    i=1;
    
    while (Motor_Y > 0)
        yc(i)=uint8(mod(Motor_Y,16^2));
        Motor_Y=floor(Motor_Y/(16^2));
        i=i+1;
    end
    
    zc=uint8([0 0 0 0]);% microstep represented by bytes
    i=1;
    while (Motor_Z > 0)
        zc(i)=uint8(mod(Motor_Z,16^2));
        Motor_Z=floor(Motor_Z/(16^2));
        i=i+1;
    end

    if (refStim == 'R')
        
        fwrite(REF_ELEC_COM_PORT, uint8(['M' xc(1) xc(2) xc(3) xc(4) yc(1) yc(2) yc(3) yc(4) zc(1) zc(2) zc(3) zc(4)]))% fast move command   
    end
    
    if (refStim == 'S')
        
        fwrite(STIM_ELEC_COM_PORT, uint8(['M' xc(1) xc(2) xc(3) xc(4) yc(1) yc(2) yc(3) yc(4) zc(1) zc(2) zc(3) zc(4)]))% fast move command   

    end
        

function RefComPortEnter_Callback(hObject, eventdata, handles)
% hObject    handle to RefComPortEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RefComPortEnter as text
%        str2double(get(hObject,'String')) returns contents of RefComPortEnter as a double

%based on Sutter Micromanipulator USBTester sample code

global REF_ELEC_COM_PORT

REF_ELEC_COM_PORT = serial(get(hObject, 'String'),'BaudRate',128000,'Terminator','CR','DataBits',8,'StopBits',1,'FlowControl','none');
fopen(REF_ELEC_COM_PORT);
REF_ELEC_COM_PORT.Parity = 'none';
REF_ELEC_COM_PORT.BaudRate = 128000;
REF_ELEC_COM_PORT.DataBits = 8;
REF_ELEC_COM_PORT.StopBits = 1;
REF_ELEC_COM_PORT.FlowControl = 'none';

qstring=sprintf('Connected to Sutter Instrument ROE. ROE must be calibrated to work properly.\n\nWould you like to calibrate now?');
Calib_Prompt=questdlg(qstring,'Calibration Required','Yes','Not now','Yes');
switch Calib_Prompt
    case 'Yes'
        fprintf(REF_ELEC_COM_PORT,'%c','N');
end

% --- Executes during object creation, after setting all properties.
function RefComPortEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RefComPortEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StimComPortEnter_Callback(hObject, eventdata, handles)
% hObject    handle to StimComPortEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StimComPortEnter as text
%        str2double(get(hObject,'String')) returns contents of StimComPortEnter as a double

%based on Sutter Micromanipulator USBTester sample code

global STIM_ELEC_COM_PORT

STIM_ELEC_COM_PORT = serial(get(hObject, 'String'),'BaudRate',128000,'Terminator','CR','DataBits',8,'StopBits',1,'FlowControl','none');
fopen(STIM_ELEC_COM_PORT);
STIM_ELEC_COM_PORT.Parity = 'none';
STIM_ELEC_COM_PORT.BaudRate = 128000;
STIM_ELEC_COM_PORT.DataBits = 8;
STIM_ELEC_COM_PORT.StopBits = 1;
STIM_ELEC_COM_PORT.FlowControl = 'none';

qstring=sprintf('Connected to Sutter Instrument ROE. ROE must be calibrated to work properly.\n\nWould you like to calibrate now?');
Calib_Prompt=questdlg(qstring,'Calibration Required','Yes','Not now','Yes');
switch Calib_Prompt
    case 'Yes'
        fprintf(STIM_ELEC_COM_PORT,'%c','N');
end

% --- Executes during object creation, after setting all properties.
function StimComPortEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StimComPortEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkRestingVoltage.
function chkRestingVoltage_Callback(hObject, eventdata, handles)
global chkRV
global txtRV
chkRV= handles.chkRestingVoltage.Value;
txtRV = str2double(handles.txtRestingVoltage.String);
% hObject    handle to chkRestingVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkRestingVoltage

if handles.chkRestingVoltage.Value==0
    handles.lblRestingVoltage.ForegroundColor=[0.5 0.5 0.5];
    handles.txtRestingVoltage.Enable='off';
else
    handles.lblRestingVoltage.ForegroundColor=[0 0 0];
    handles.txtRestingVoltage.Enable='on';
end



function txtRestingVoltage_Callback(hObject, eventdata, handles)
% hObject    handle to txtRestingVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRestingVoltage as text
%        str2double(get(hObject,'String')) returns contents of txtRestingVoltage as a double

global txtRV
txtRV = str2double(handles.txtRestingVoltage.String);


% --- Executes during object creation, after setting all properties.
function txtRestingVoltage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtRestingVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnConstantDC.
function btnConstantDC_Callback(hObject, eventdata, handles)
% hObject    handle to btnConstantDC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnConstantDC


% --- Executes on button press in btnEquidistantPulses.
function btnEquidistantPulses_Callback(hObject, eventdata, handles)
% hObject    handle to btnEquidistantPulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnEquidistantPulses


% --- Executes on button press in btnPseudoRandomPulses.
function btnPseudoRandomPulses_Callback(hObject, eventdata, handles)
% hObject    handle to btnPseudoRandomPulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnPseudoRandomPulses



function txtIgnoreStart_Callback(hObject, eventdata, handles)

% hObject    handle to txtIgnoreStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtIgnoreStart as text
%        str2double(get(hObject,'String')) returns contents of txtIgnoreStart as a double

global sampleIgnoreStart

sampleIgnoreStart = str2double(get(hObject, 'String'));


% --- Executes during object creation, after setting all properties.
function txtIgnoreStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtIgnoreStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtNumIgnore_Callback(hObject, eventdata, handles)
% hObject    handle to txtNumIgnore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtNumIgnore as text
%        str2double(get(hObject,'String')) returns contents of txtNumIgnore as a double

global sampleNumIgnoredPoints

sampleNumIgnoredPoints = str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function txtNumIgnore_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtNumIgnore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkIgnore.
function chkIgnore_Callback(hObject, eventdata, handles)
% hObject    handle to chkIgnore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkIgnore
global IgnoreSelected

IgnoreSelected = get(hObject, 'Value');


% --- Executes on button press in btnSpecMeasCycles.
function btnSpecMeasCycles_Callback(hObject, eventdata, handles)
% hObject    handle to btnSpecMeasCycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnSpecMeasCycles
global specMeasCycles

specMeasCycles = get(hObject, 'Value');


% --- Executes on button press in btnDiscardData.
function btnDiscardData_Callback(hObject, eventdata, handles)
% hObject    handle to btnDiscardData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnDiscardData
global discardData
%TODO: update to get(hObject,'Value') rather than hard code?
discardData = 1;


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)    


% --- Executes during object deletion, before destroying properties.
function btnGenerateCP_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to btnGenerateCP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%Example code for real time color plot%
% % --- Executes on button press in btnGenerateCP.
% function btnGenerateCP_Callback(hObject, eventdata, handles)
% % hObject    handle to btnGenerateCP (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% global generateCP CyclesPerRefresh N_Refresh PointsPerCycle CP_Data_All
% 
% generateCP=1;
% if generateCP == 1
%     clear bkgdCP_All
%     figure(2)
%     generateCP = 0;
%     bkgdCP = inputdlg('Define scan number of background.'); 
%     bkgdCP = str2num(bkgdCP{1})
%     load myCustomColormap;
%     %bkgdCP_All=bsxfun(@minus, CP_Data_All, CP_Data_All(:,bkgdCP));
%     disp(CyclesPerRefresh*N_Refresh)
%     disp(PointsPerCycle)
%     disp(size(bkgdCP_All))
%     
%     CPTest2 = pcolor(1:CyclesPerRefresh*N_Refresh,1:PointsPerCycle,bkgdCP_All);
% 
%     CPTest2.EdgeColor = 'none';
%     colormap(myCustomColormap); 
%     colorbar;
% end


% --- Executes during object creation, after setting all properties.
function lblGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in optWEdriven.
function optWEdriven_Callback(hObject, eventdata, handles)
% hObject    handle to optWEdriven (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optWEdriven
global VoltageDriver

WEdriven = (get(hObject,'Value'));
if WEdriven == 1
    VoltageDriver = 1.0;
end 

% --- Executes on button press in optREdriven.
function optREdriven_Callback(hObject, eventdata, handles)
% hObject    handle to optREdriven (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optREdriven
global VoltageDriver

REdriven = (get(hObject,'Value'));
if REdriven == 1
    VoltageDriver = -1.0;
end 


function txtMultiplier_Callback(hObject, eventdata, handles)
% hObject    handle to txtMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMultiplier as text
%        str2double(get(hObject,'String')) returns contents of txtMultiplier as a double
global VoltageMultiplier

VoltageMultiplier = str2double(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function txtMultiplier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkStimLabelOnly.
function chkStimLabelOnly_Callback(hObject, eventdata, handles)
% hObject    handle to chkStimLabelOnly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkStimLabelOnly
global StimLabelOnly

StimLabelOnly = (get(hObject,'Value'));
