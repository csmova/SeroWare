function varargout = SeroSignalGen(varargin)
% SEROSIGNALGEN MATLAB code for SeroSignalGen.fig
%      SEROSIGNALGEN, by itself, creates a new SEROSIGNALGEN or raises the existing
%      singleton*.
%
%      H = SEROSIGNALGEN returns the handle to a new SEROSIGNALGEN or the handle to
%      the existing singleton*.
%
%      SEROSIGNALGEN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEROSIGNALGEN.M with the given input arguments.
%
%      SEROSIGNALGEN('Property','Value',...) creates a new SEROSIGNALGEN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SeroSignalGen_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SeroSignalGen_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SeroSignalGen

% Last Modified by GUIDE v2.5 14-Oct-2021 16:32:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SeroSignalGen_OpeningFcn, ...
                   'gui_OutputFcn',  @SeroSignalGen_OutputFcn, ...
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


% --- Executes just before SeroSignalGen is made visible.
function SeroSignalGen_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SeroSignalGen (see VARARGIN)

global C
global WaveformFrequency ScanRate SignalTotalPoints SegmentScanRate
global SegmentList StartPot EndPot NPoints NSegments lhSegment SelectedRow SegmentTime

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

if exist('Config.cfg','file')==2
    C=load('Config.cfg','-mat');
else
    C.PathDataFiles=getenv('USERPROFILE');
    C.PathFigures=getenv('USERPROFILE');
    C.PathSignals=getenv('USERPROFILE');
    PathFigures=C.PathFigures;
    PathDataFiles=C.PathDataFiles;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
end

%initialize waveform variables 
SegmentList=cellstr('');
StartPot(1)=0;
EndPot(1)=0;
NPoints(1)=0;
NSegments=0;
SelectedRow=1;
SegmentTime(1)=0;
SegmentScanRate(1)=0;
WaveformFrequency = 1;
ScanRate = 125000;

%set plot of waveform (Signal) parameters
ylabel(handles.pltSignal,'Potential (mV)','FontSize',8);
xlabel(handles.pltSignal,'Time (ms)','FontSize',8);
lhSegment=line(handles.pltSignal,[0 0],[0 0],'Color',[1 0 0]);

%show the module logo
axes(handles.axesLogo)
matlabImage = imread('SeroSignalGen.png');
image(matlabImage)
axis off
axis image

%update handles
Refresh_Segments(handles);

% Choose default command line output for SeroSignalGen
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SeroSignalGen wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SeroSignalGen_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in cmdAddSegment.
function cmdAddSegment_Callback(hObject, eventdata, handles)
% hObject    handle to cmdAddSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global SegmentList StartPot EndPot NPoints NSegments SegmentTime ScanRate SegmentScanRate

%get user defined potentials 
Answer = inputdlg('Set the start potential of the segment (mV)','Start Potential');
if (isempty(Answer)) || (isnan(str2double(Answer{1})))
    errordlg('Signal creation failed - not a number');
    return
end
AnsStartPot=str2double(Answer{1});

Answer = inputdlg('Set the end potential of the segment (mV)','End Potential');
if (isempty(Answer)) || (isnan(str2double(Answer{1})))
    errordlg('Signal creation failed - not a number');
    return
end
AnsEndPot=str2double(Answer{1});

%get user defined time or number of points.
Answer = inputdlg('Set the desired time of the segment (ms). Insert 0 to skip this step and set the number of points instead.','Segment Time');
if (isnan(str2double(Answer{1})))
    errordlg('Signal creation failed - not a number!');
    return
end

if str2double(Answer{1}) < 0
    errordlg('Signal creation failed - time cannot be negative!');
    return
end

if str2double(Answer{1})~=0
    AnsSegmentTime=str2double(Answer{1});
    AnsNPoints=ScanRate*(str2double(Answer{1})/1000);
end

if str2double(Answer{1})==0
    Answer = inputdlg('Set number of points to be sampled over this segment','Number of points');
    if (isempty(Answer)) || (isnan(str2double(Answer{1})))
        errordlg('Signal creation failed - not a number!');
        return
    end
    AnsNPoints = str2double(Answer{1});
    AnsSegmentTime = AnsNPoints/ScanRate*1000;
end

NSegments=NSegments+1; %add to segment counter

%set user inputs indexed by segment number
StartPot(NSegments)=AnsStartPot;
EndPot(NSegments)=AnsEndPot;
NPoints(NSegments)=AnsNPoints;
SegmentTime(NSegments)=AnsSegmentTime;
SegmentScanRate(NSegments)=(AnsEndPot-(AnsStartPot+(AnsEndPot-AnsStartPot)/AnsSegmentTime))/(AnsSegmentTime-1);

Refresh_Segments(handles);

function Refresh_Segments(handles)
global SegmentList StartPot EndPot NPoints NSegments lhSegment SelectedRow SegmentTime
global ScanRate WaveformFrequency SignalTotalPoints WaveformPeriod SegmentScanRate SampledPoints

SignalTotalPoints = WaveformPeriod * ScanRate; %calculate total points in the signal
handles.txtSignalTotalPoints.String = strcat('/', num2str(SignalTotalPoints)); %display the value in GUI

if NSegments==0 %set null values when no segments present
    handles.lstSegment.Value=1;
    handles.lstSegment.String=cellstr('');
    cla(handles.pltSignal);
    handles.lblStartPot.String='Start Potential (mV): --';
    handles.lblEndPot.String='End Potential (mV): --';
    handles.lblNPoints.String='Number of Points: --';
    handles.lblSegmentTime.String='Segment Time (ms): --';
    SampledPoints=str2double(handles.txtSampledPoints.String);
    handles.lblSamplingTime.String=num2str(1000*SampledPoints/ScanRate);
    handles.lblTotalPeriod.String=num2str(1000*WaveformPeriod);
    handles.savedWaveformFreq.String=WaveformFrequency; 
else
    SegmentList=cellstr('');%set empty array
    
    %fill array with numbered segments as strings
    for i=1:NSegments
        SegmentList{i}=num2str(i);
    end
    
    %set up the segment selector table
    lstSize=size(SegmentList);
    handles.lstSegment.Value=lstSize(2);
    SelectedRow=lstSize(2); 
    handles.lstSegment.String=SegmentList;
    
    %clear the signal plot and variable 
    cla(handles.pltSignal);
    ylabel(handles.pltSignal,'Potential (mV)','FontSize',8);
    xlabel(handles.pltSignal,'Time (ms)','FontSize',8);
    hold on;
    Signal=[];
    
    %vectorize the signal
    for i=1:NSegments
        Signal=[Signal linspace(StartPot(i)+(EndPot(i)-StartPot(i))/NPoints(i),EndPot(i),NPoints(i))];
        %PreviousEndPotPoint=PreviousEndPotPoint+NPoints(i);
    end
    
    %update the segment characteristics of the selected row
    handles.lblStartPot.String=strcat('Start Potential (mV): ',num2str(StartPot(SelectedRow)));
    handles.lblEndPot.String=strcat('End Potential (mV): ',num2str(EndPot(SelectedRow)));
    handles.lblNPoints.String=strcat('Number of Points: ',num2str(NPoints(SelectedRow)));
    
    try 
        handles.lblSegmentTime.String=strcat('Segment Time (ms): ',num2str(SegmentTime(SelectedRow)));
        handles.txtSegmentScanRate.String=strcat('Segment Scan Rate (V/s): ',num2str(SegmentScanRate(SelectedRow)));
    catch 
        errordlg('Could not load segment time/scan rate. Signal file may be from an old version. Continue to data acquisition or remake waveform.'); 
    end   
    
    SampledPoints=str2double(handles.txtSampledPoints.String);
    handles.lblSamplingTime.String=num2str(1000*SampledPoints/ScanRate);
    handles.lblTotalPeriod.String=num2str(1000*WaveformPeriod);
    handles.savedWaveformFreq.String=WaveformFrequency; 
    handles.savedSamplingFreq.String=ScanRate;
    %ScanRate=str2double(handles.txtScanRate.String);
    NTotalPoints=size(Signal);
    
    %plot the signal
    plot(handles.pltSignal,1000*(1:NTotalPoints(2))/ScanRate,Signal);
    ylabel(handles.pltSignal,'Potential (mV)','FontSize',8);
    xlabel(handles.pltSignal,'Time (ms)','FontSize',8);
    %highlight the selected segment
    PreviousEndPotPoint=1;
    for i=1:SelectedRow-1
        PreviousEndPotPoint=PreviousEndPotPoint+NPoints(i);
    end
    delete(lhSegment);
    lhSegment=line(handles.pltSignal,1000*[PreviousEndPotPoint PreviousEndPotPoint+NPoints(SelectedRow)-1]/ScanRate,[(StartPot(SelectedRow)+(EndPot(SelectedRow)-StartPot(SelectedRow))/NPoints(SelectedRow)) EndPot(SelectedRow)],'Color',[1 0 0]);
end



% --- Executes on button press in cmdDeleteSegment.
function cmdDeleteSegment_Callback(hObject, eventdata, handles)
% hObject    handle to cmdDeleteSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SelectedRow StartPot EndPot NPoints NSegments SegmentTime SegmentScanRate

%reset the index of all segments prior to the deleted segment
for i=SelectedRow:NSegments-1
    StartPot(i)=StartPot(i+1);
    EndPot(i)=EndPot(i+1);
    NPoints(i)=NPoints(i+1);
    SegmentTime(i)=SegmentTime(i+1);
    SegmentScanRate(i)=SegmentScanRate(i+1);
end
NSegments=NSegments-1;
Refresh_Segments(handles);

% --- Executes on selection change in lstSegment.
function lstSegment_Callback(hObject, eventdata, handles)
% hObject    handle to lstSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstSegment contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstSegment
global SelectedRow StartPot EndPot NPoints lhSegment NSegments SegmentTime SegmentScanRate
global ScanRate

%get the user-selected segment from the segment selector table and update
%the GUI to show correct segment charactersitics and highlighted segment.

if NSegments~=0
    SelectedRow=get(hObject,'Value');
    handles.lblStartPot.String=strcat('Start Potential (mV): ',num2str(StartPot(SelectedRow)));
    handles.lblEndPot.String=strcat('End Potential (mV): ',num2str(EndPot(SelectedRow)));
    handles.lblNPoints.String=strcat('Number of Points: ',num2str(NPoints(SelectedRow)));
    handles.lblSegmentTime.String=strcat('Segment Time (ms): ',num2str(SegmentTime(SelectedRow)));
    handles.txtSegmentScanRate.String=strcat('Segment Scan Rate (V/s): ',num2str(SegmentScanRate(SelectedRow)));
    % The starting point of the selected
    PreviousEndPotPoint=1;
    for i=1:SelectedRow-1
        PreviousEndPotPoint=PreviousEndPotPoint+NPoints(i);
    end
    delete(lhSegment);
    lhSegment=line(handles.pltSignal,1000*[PreviousEndPotPoint PreviousEndPotPoint+NPoints(SelectedRow)-1]/ScanRate,[(StartPot(SelectedRow)+(EndPot(SelectedRow)-StartPot(SelectedRow))/NPoints(SelectedRow)) EndPot(SelectedRow)],'Color',[1 0 0]);
end

% --- Executes during object creation, after setting all properties.
function lstSegment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdUp.
function cmdUp_Callback(hObject, eventdata, handles)
% hObject    handle to cmdUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SelectedRow StartPot EndPot NPoints SegmentTime SegmentScanRate

if SelectedRow~=1 %cannot move the first row up any further
    %reset indices if a segment is moved up
    SP=StartPot(SelectedRow-1);
    EP=EndPot(SelectedRow-1);
    NP=NPoints(SelectedRow-1);
    SeT = SegmentTime(SelectedRow-1);
    SSR = SegmentScanRate(SelectedRow-1);
    
    StartPot(SelectedRow-1)=StartPot(SelectedRow);
    EndPot(SelectedRow-1)=EndPot(SelectedRow);
    NPoints(SelectedRow-1)=NPoints(SelectedRow);
    SegmentTime(SelectedRow-1)=SegmentTime(SelectedRow);
    SegmentScanRate(SelectedRow-1);SegmentScanRate(SelectedRow);
    
    StartPot(SelectedRow)=SP;
    EndPot(SelectedRow)=EP;
    NPoints(SelectedRow)=NP;
    SegmentTime(SelectedRow)=SeT;
    SegmentScanRate(SelectedRow)=SSR;
    
    Refresh_Segments(handles);
end


% --- Executes on button press in cmdDown.
function cmdDown_Callback(hObject, eventdata, handles)
% hObject    handle to cmdDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SelectedRow StartPot EndPot NPoints NSegments SegmentTime SegmentScanRate

if SelectedRow~=NSegments %cannot move the first row up any further
    %reset indices if a segment is moved up
    SP=StartPot(SelectedRow+1);
    EP=EndPot(SelectedRow+1);
    NP=NPoints(SelectedRow+1);
    SeT = SegmentTime(SelectedRow-1);
    SSR = SegmentScanRate(SelectedRow-1);
    
    StartPot(SelectedRow+1)=StartPot(SelectedRow);
    EndPot(SelectedRow+1)=EndPot(SelectedRow);
    NPoints(SelectedRow+1)=NPoints(SelectedRow);
    SegmentTime(SelectedRow-1)=SegmentTime(SelectedRow);
    SegmentScanRate(SelectedRow-1)=SegmentTime(SelectedRow);
    
    StartPot(SelectedRow)=SP;
    EndPot(SelectedRow)=EP;
    NPoints(SelectedRow)=NP;
    SegmentTime(SelectedRow)=SeT;
    SegmentScanRate(SelectedRow)=SSR;
    
    Refresh_Segments(handles);
end


% --- Executes on button press in cmdLoadSignal.
function cmdLoadSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLoadSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global C NSegments StartPot EndPot NPoints SegmentTime SegmentScanRate ScanRate SampledPoints WaveformFrequency

%get the user input from the LoadSignal button and selected file
handles=guidata(hObject);

[NewFileName,PathName]=uigetfile('*.sig','Select signal file',C.PathSignals);
if NewFileName~=0
    FileName=NewFileName;
    C.PathSignals=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    
    %load variables for the signal
    load(strcat(PathName,FileName),'-mat','NSegments','StartPot','EndPot','NPoints','ScanRate','SampledPoints', 'WaveformFrequency', 'WaveformPeriod');
    
    %load optional variables from newer versions
    try 
      (load(strcat(PathName,FileName),'-mat','SegmentTime','SegmentScanRate','SampledPoints','WaveformName'));  
    catch
      errordlg('Could not load one or more newer varaibles, but that is ok. Signal file may be from an old version.'); 
    end
    
    %update displayed waveform characteristics 
    handles.txtScanRate.String=ScanRate;
    handles.txtSampledPoints.String=SampledPoints;
    handles.savedWaveformFreq.String=WaveformFrequency;
    handles.savedSamplingFreq.String=ScanRate;
    
    %set waveform frequency (Hz) based on saved file
    if WaveformFrequency == 1
        handles.Select1Hz.Value=1;
    else 
        handles.Select1Hz.Value=0;
    end 
    
    if WaveformFrequency == 2
        handles.Select2Hz.Value=1;
    else 
        handles.Select2Hz.Value=0;
    end 
        
    if WaveformFrequency == 3
        handles.Select3Hz.Value=1;
    else 
        handles.Select3Hz.Value=0;
    end   
        
    if WaveformFrequency == 4
        handles.Select4Hz.Value=1;
    else 
        handles.Select4Hz.Value=0;
    end 
    
    if WaveformFrequency == 5
        handles.Select5Hz.Value=1;
    else 
        handles.Select5Hz.Value=0;
    end 
    
    if WaveformFrequency == 10
        handles.Select10Hz.Value=1;
    else 
        handles.Select10Hz.Value=0; 
    end 
    
    if WaveformFrequency == 20
        handles.Select20Hz.Value=1;
    else 
        handles.Select20Hz.Value=0; 
    end 
    
    if WaveformFrequency == 30
        handles.Select30Hz.Value=1;
    else 
        handles.Select30Hz.Value=0; 
    end
    
    if WaveformFrequency == 40
        handles.Select40Hz.Value=1;
    else 
        handles.Select40Hz.Value=0; 
    end 
    
    if WaveformFrequency == 50
        handles.Select50Hz.Value=1;
    else 
        handles.Select50Hz.Value=0; 
    end 
    
    if WaveformFrequency == 60
        handles.Select60Hz.Value=1;
    else 
        handles.Select60Hz.Value=0;
    end 
    
    %if no radio button selected, set custom value from file
    if sum(ismember(WaveformFrequency,[1,2,3,4,5,10,20,30,40,50,60])) == 0
        handles.selectCustomPeriod.Value = 1;
        handles.txtCustomPeriod.String = 1/WaveformFrequency; 
        handles.savedWaveformFreq.String = WaveformFrequency; 
    end     
    
    %set scan rate (sampling frequency (Hz)) based on saved file
    %note this is the ScanRate of the acquisition card, not the waveform
    if ScanRate == 125000
        handles.ScanRateOpt125000.Value=1;
    else 
        handles.ScanRateOpt125000.Value=0;
    end 
    
    if ScanRate == 250000
        handles.ScanRateOpt250000.Value=1;
    else 
        handles.ScanRateOpt250000.Value=0;
    end 
    
    guidata(hObject,handles);
    
    Refresh_Segments(handles);
end

% --- Executes on button press in cmdSaveSignal.
function cmdSaveSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSaveSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global C NSegments StartPot EndPot NPoints ScanRate SignalTotalPoints WaveformFrequency WaveformPeriod SegmentTime SegmentScanRate WaveformName SampledPoints
Answer = questdlg('Are the waveform parameters configured correctly?', 'Warning','Yes', 'No','No');

if strcmp(Answer,'Yes')==1
    
    TotalPoints=0;
    
    %iterate over the segments to sum total points
    for i=1:NSegments
        TotalPoints=TotalPoints+NPoints(i);
    end
    
    %check that total points adds up correctly
    if num2str(TotalPoints) == num2str(SignalTotalPoints) 
        [FileName,PathName]=uiputfile('*.sig','Introduce the name of the signal file',C.PathSignals);
        if FileName~=0
            C.PathSignals=PathName;
            WaveformName = FileName;
            PathDataFiles=C.PathDataFiles;
            PathFigures=C.PathFigures;
            PathSignals=C.PathSignals;
            save('Config.cfg','PathDataFiles','PathFigures','PathSignals');

            SampledPoints=str2double(handles.txtSampledPoints.String);
            
            try 
                save(strcat(PathName,FileName),'NSegments','StartPot','EndPot','NPoints','ScanRate','SampledPoints','WaveformFrequency', 'WaveformPeriod','SegmentTime','SegmentScanRate','WaveformName');
            catch
                errordlg('Could not save one or more variables. Signal file may be from an old version.');
            end 
        end
    else
        msgbox(strcat('Signal cannot be saved. The duration of the signal should be ', num2str(SignalTotalPoints),' ms'),'Error');
    end 
end


% --- Executes on button press in cmdClearSignal.
function cmdClearSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdClearSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global NSegments SegmentTime SegmentScanRate

%reset all variables 
NSegments=0;
SegmentTime(1)=0;
SegmentScanRate(1)=0;
Refresh_Segments(handles);


function txtSampledPoints_Callback(hObject, eventdata, handles)
% hObject    handle to txtSampledPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSampledPoints as text
%        str2double(get(hObject,'String')) returns contents of txtSampledPoints as a double
get(hObject,'String')
Refresh_Segments(handles)

% --- Executes during object creation, after setting all properties.
function txtSampledPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSampledPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Select1Hz.
function Select1Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select1Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select1Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 1;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);



% --- Executes on button press in Select2Hz.
function Select2Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select2Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select2Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 2; 
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);


% --- Executes on button press in Select3Hz.
function Select3Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select3Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select3Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 3;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);


% --- Executes on button press in Select4Hz.
function Select4Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select4Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select4Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 4;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select5Hz.
function Select5Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select5Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select5Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 5;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select10Hz.
function Select10Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select10Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select10Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 10;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select20Hz.
function Select20Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select20Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select20Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 20;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select30Hz.
function Select30Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select30Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select30Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 30;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select40Hz.
function Select40Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select40Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select40Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 40;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select50Hz.
function Select50Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select50Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select50Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 50;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

% --- Executes on button press in Select60Hz.
function Select60Hz_Callback(hObject, eventdata, handles)
% hObject    handle to Select60Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Select60Hz

global WaveformFrequency WaveformPeriod

WaveformFrequency = 60;
WaveformPeriod = 1/WaveformFrequency;
Refresh_Segments(handles);

function txtCustomPeriod_Callback(hObject, eventdata, handles)
% hObject    handle to txtCustomPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtCustomPeriod as text
%        str2double(get(hObject,'String')) returns contents of txtCustomPeriod as a double

global WaveformFrequency WaveformPeriod

WaveformPeriod = str2double(handles.txtCustomPeriod.String);
WaveformFrequency = 1/WaveformPeriod;
Refresh_Segments(handles);


% --- Executes during object creation, after setting all properties.
function txtCustomPeriod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtCustomPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in ScanRateOpt125000.
function ScanRateOpt125000_Callback(hObject, eventdata, handles)
% hObject    handle to ScanRateOpt125000 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ScanRateOpt125000

global ScanRate
handles=guidata(hObject);
%set scan rate (i.e., sampling frequency) as user input and update GUI

ScanRate = 125000;

if ScanRate == 125000
    ScanRateOpt125000.Value=1;
else 
    ScanRateOpt125000.Value=0;
end 

if get(hObject,'Value')==1
    handles.txtSamplingFrequency.Enable='off';
end
handles.savedSamplingFreq.String=ScanRate;
Refresh_Segments(handles);

% --- Executes on button press in ScanRateOpt250000.
function ScanRateOpt250000_Callback(hObject, eventdata, handles)
% hObject    handle to ScanRateOpt250000 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ScanRateOpt250000

global ScanRate
%set scan rate (i.e., sampling frequency) as user input and update GUI

ScanRate = 250000;

if ScanRate == 250000
    ScanRateOpt250000.Value=1;
else 
    ScanRateOpt250000.Value=0;
end 

if get(hObject,'Value')==1
    handles.txtSamplingFrequency.Enable='off';
end
handles.savedSamplingFreq.String=ScanRate;

Refresh_Segments(handles);

function txtSamplingFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to txtSamplingFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ScanRate

%set scan rate (i.e., sampling frequency) as user input and update GUI
ScanRate = str2double(handles.txtSamplingFrequency.String);
handles.savedSamplingFreq.String=ScanRate;
Refresh_Segments(handles);
% Hints: get(hObject,'String') returns contents of txtSampledPoints as text
%        str2double(get(hObject,'String')) returns contents of txtSampledPoints as a double


% --- Executes during object creation, after setting all properties.
function txtSamplingFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSamplingFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ScanRateOptCustom.
function ScanRateOptCustom_Callback(hObject, eventdata, handles)
% hObject    handle to ScanRateOptCustom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ScanRateOptCustom

%enable the text box for custom sampling if the button is pressed.
if get(hObject,'Value')==1
    handles.txtSamplingFrequency.Enable='on';
end


% --- Executes during object creation, after setting all properties.
function lblStartPot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblStartPot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function lblNPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblNPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function txtSignalTotalPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSignalTotalPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function lblSegmentTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblSegmentTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function lblSamplingTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblSamplingTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function lblTotalPeriod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblTotalPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function savedWaveformFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to savedWaveformFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function savedSamplingFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to savedSamplingFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function txtSegmentScanRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSegmentScanRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function axesLogo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesLogo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axesLogo
