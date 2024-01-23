function varargout = SignalAnalyzer(varargin)
% SIGNALANALYZER MATLAB code for SignalAnalyzer.fig
%      SIGNALANALYZER, by itself, creates a new SIGNALANALYZER or raises the existing
%      singleton*.
%
%      H = SIGNALANALYZER returns the handle to a new SIGNALANALYZER or the handle to
%      the existing singleton*.
%
%      SIGNALANALYZER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIGNALANALYZER.M with the given input arguments.
%
%      SIGNALANALYZER('Property','Value',...) creates a new SIGNALANALYZER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SignalAnalyzer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SignalAnalyzer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SignalAnalyzer

% Last Modified by GUIDE v2.5 11-Aug-2022 11:23:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SignalAnalyzer_OpeningFcn, ...
                   'gui_OutputFcn',  @SignalAnalyzer_OutputFcn, ...
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


% --- Executes just before SignalAnalyzer is made visible.
function SignalAnalyzer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SignalAnalyzer (see VARARGIN)
global V hfrmMain ColorArray N_Signals OxPeak OxPeakFiltered DisplaySignal
global C FileName 
global Saved_Data_Array

%dispaly logo
axes(handles.axesLogo)
matlabImage = imread('Seroware.jpg');
image(matlabImage)
axis off
axis image

%load data from SeroDataProcess 
C=load('Config.cfg','-mat');
hfrmMain=getappdata(0,'hfrmMain');
V=getappdata(hfrmMain,'V');
OxPeak=getappdata(hfrmMain,'OxPeak');
OxPeakFiltered=getappdata(hfrmMain,'OxPeakFiltered');
DisplaySignal=getappdata(hfrmMain,'DisplaySignal');
FileName=getappdata(hfrmMain,'FileName');

%clear plots
cla(handles.pltOxPeak);
cla(handles.pltCurrentSignal);

%show filter that was selected
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
    hold(handles.pltOxPeak,'on');
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
    hold(handles.pltOxPeak,'on');
end

%set up plots
title(handles.pltOxPeak,FileName(1:length(FileName)-4), 'FontSize', 11, 'Color', 'k','Interpreter','none');
ylabel(handles.pltOxPeak,'Current (nA)','FontSize',10);
xlabel(handles.pltOxPeak,'Time (100 ms)','FontSize',10);
handles.cmdClearSignals.Enable='off';
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
zoom(handles.pltOxPeak,'out');
zoom(handles.pltOxPeak,'reset');

%ColorArray=colormap(hsv(15));
%TODO: autogenerate/allow UI; allow >100 peaks
%assign colors to peak markers/voltammograms

ColorArray(1,1:3)=[1 0 0];
ColorArray(2,1:3)=[0 0.68627451 0];
ColorArray(3,1:3)=[0 0 1];
ColorArray(4,1:3)=[1 0 1];
ColorArray(5,1:3)=[0 0 0];
ColorArray(6,1:3)=[0 1 1];
ColorArray(7,1:3)=[0 1 0];
ColorArray(8,1:3)=[0.705882353 0.705882353 0];
ColorArray(9,1:3)=[1 0.498039216 0];
ColorArray(10,1:3)=[0.498039216 0 0.498039216];
ColorArray(11,1:3)=[0 0.498039216 0.498039216];
ColorArray(12,1:3)=[0.498039216 0 1];
ColorArray(13,1:3)=[0.749019608 0 0];
ColorArray(14,1:3)=[0.749019608 0.749019608 0];
ColorArray(15,1:3)=[0.749019608 0.749019608 0.749019608];
ColorArray(16,1:3)=[0.749019608 0.494117647 0.501960784];
ColorArray(17,1:3)=[0.941176471 0.737254902 0.752941176];
ColorArray(18,1:3)=[0.37254902 0.368627451 0.250980392];
ColorArray(19,1:3)=[0.341176471 0.670588235 0.874509804];
ColorArray(20,1:3)=[0.439215686 0.839215686 0.71372549];
ColorArray(21,1:3)=[1 0 0];
ColorArray(22,1:3)=[0 0.68627451 0];
ColorArray(23,1:3)=[0 0 1];
ColorArray(24,1:3)=[1 0 1];
ColorArray(25,1:3)=[0 0 0];
ColorArray(26,1:3)=[0 1 1];
ColorArray(27,1:3)=[0 1 0];
ColorArray(28,1:3)=[0.705882353 0.705882353 0];
ColorArray(29,1:3)=[1 0.498039216 0];
ColorArray(30,1:3)=[0.498039216 0 0.498039216];
ColorArray(31,1:3)=[0 0.498039216 0.498039216];
ColorArray(32,1:3)=[0.498039216 0 1];
ColorArray(33,1:3)=[0.749019608 0 0];
ColorArray(34,1:3)=[0.749019608 0.749019608 0];
ColorArray(35,1:3)=[0.749019608 0.749019608 0.749019608];
ColorArray(36,1:3)=[0.749019608 0.494117647 0.501960784];
ColorArray(37,1:3)=[0.941176471 0.737254902 0.752941176];
ColorArray(38,1:3)=[0.37254902 0.368627451 0.250980392];
ColorArray(39,1:3)=[0.341176471 0.670588235 0.874509804];
ColorArray(40,1:3)=[0.439215686 0.839215686 0.71372549];
ColorArray(41,1:3)=[1 0 0];
ColorArray(42,1:3)=[0 0.68627451 0];
ColorArray(43,1:3)=[0 0 1];
ColorArray(44,1:3)=[1 0 1];
ColorArray(45,1:3)=[0 0 0];
ColorArray(46,1:3)=[0 1 1];
ColorArray(47,1:3)=[0 1 0];
ColorArray(48,1:3)=[0.705882353 0.705882353 0];
ColorArray(49,1:3)=[1 0.498039216 0];
ColorArray(50,1:3)=[0.498039216 0 0.498039216];
ColorArray(51,1:3)=[0 0.498039216 0.498039216];
ColorArray(52,1:3)=[0.498039216 0 1];
ColorArray(53,1:3)=[0.749019608 0 0];
ColorArray(54,1:3)=[0.749019608 0.749019608 0];
ColorArray(55,1:3)=[0.749019608 0.749019608 0.749019608];
ColorArray(56,1:3)=[0.749019608 0.494117647 0.501960784];
ColorArray(57,1:3)=[0.941176471 0.737254902 0.752941176];
ColorArray(58,1:3)=[0.37254902 0.368627451 0.250980392];
ColorArray(59,1:3)=[0.341176471 0.670588235 0.874509804];
ColorArray(60,1:3)=[0.439215686 0.839215686 0.71372549];
ColorArray(61,1:3)=[1 0 0];
ColorArray(62,1:3)=[0 0.68627451 0];
ColorArray(63,1:3)=[0 0 1];
ColorArray(64,1:3)=[1 0 1];
ColorArray(65,1:3)=[0 0 0];
ColorArray(66,1:3)=[0 1 1];
ColorArray(67,1:3)=[0 1 0];
ColorArray(68,1:3)=[0.705882353 0.705882353 0];
ColorArray(69,1:3)=[1 0.498039216 0];
ColorArray(70,1:3)=[0.498039216 0 0.498039216];
ColorArray(71,1:3)=[0 0.498039216 0.498039216];
ColorArray(72,1:3)=[0.498039216 0 1];
ColorArray(73,1:3)=[0.749019608 0 0];
ColorArray(74,1:3)=[0.749019608 0.749019608 0];
ColorArray(75,1:3)=[0.749019608 0.749019608 0.749019608];
ColorArray(76,1:3)=[0.749019608 0.494117647 0.501960784];
ColorArray(77,1:3)=[0.941176471 0.737254902 0.752941176];
ColorArray(78,1:3)=[0.37254902 0.368627451 0.250980392];
ColorArray(79,1:3)=[0.341176471 0.670588235 0.874509804];
ColorArray(80,1:3)=[0.439215686 0.839215686 0.71372549];
ColorArray(81,1:3)=[1 0 0];
ColorArray(82,1:3)=[0 0.68627451 0];
ColorArray(83,1:3)=[0 0 1];
ColorArray(84,1:3)=[1 0 1];
ColorArray(85,1:3)=[0 0 0];
ColorArray(86,1:3)=[0 1 1];
ColorArray(87,1:3)=[0 1 0];
ColorArray(88,1:3)=[0.705882353 0.705882353 0];
ColorArray(89,1:3)=[1 0.498039216 0];
ColorArray(90,1:3)=[0.498039216 0 0.498039216];
ColorArray(91,1:3)=[0 0.498039216 0.498039216];
ColorArray(92,1:3)=[0.498039216 0 1];
ColorArray(93,1:3)=[0.749019608 0 0];
ColorArray(94,1:3)=[0.749019608 0.749019608 0];
ColorArray(95,1:3)=[0.749019608 0.749019608 0.749019608];
ColorArray(96,1:3)=[0.749019608 0.494117647 0.501960784];
ColorArray(97,1:3)=[0.941176471 0.737254902 0.752941176];
ColorArray(98,1:3)=[0.37254902 0.368627451 0.250980392];
ColorArray(99,1:3)=[0.341176471 0.670588235 0.874509804];
ColorArray(100,1:3)=[0.439215686 0.839215686 0.71372549];

%initialize signals to 0, since none loaded yet
N_Signals=0;

%enable various buttons
handles.chkSubstractBackground.Enable='off';
handles.chkAverageSignals.Enable='off';
handles.cmdExtractData.Enable='off';
handles.txtAverageInterval.Enable='off';
handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
handles.cmdCopyplyCurrentSignal.Enable='off';
handles.cmdSavepltCurrentSignal.Enable='off';

%only allow peaks to be loaded if they exist
if V.N_Peaks==0 
    handles.cmdLoadPeaks.Enable='off';
else
    handles.cmdLoadPeaks.Enable='on';
end

% Choose default command line output for SignalAnalyzer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SignalAnalyzer wait for user response (see UIRESUME)
% uiwait(handles.frmSignalAnalyzer);


% --- Outputs from this function are returned to the command line.
function varargout = SignalAnalyzer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close frmSignalAnalyzer.
function frmSignalAnalyzer_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to frmSignalAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hfrmMain

%close SignalAnalyzer, open SeroDataProcess 
hfrmMain.Visible='on';
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in cmdAddSignal.
function cmdAddSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdAddSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V N_Signals ColorArray FileName
global Saved_Data_Array

if N_Signals==100 %TODO: update
    msgbox('A maximum of 100 signals can be displayed in this mode','Limit of displayed signals');
else
    %get user input
    [x,y,button]=ginput(1);
    
    %add to signal count
    N_Signals=N_Signals+1;
    SignalX=round(x);
    
    %plot
    line(handles.pltOxPeak,[SignalX SignalX],handles.pltOxPeak.YLim,'Color',ColorArray(N_Signals,1:3));
    plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),V.Gain*Saved_Data_Array((SignalX)*V.PointsPerCycle+1:(SignalX+1)*V.PointsPerCycle),'Color',ColorArray(N_Signals,1:3));
    title(handles.pltCurrentSignal,FileName(1:length(FileName)-4), 'FontSize', 11, 'Color', 'k','Interpreter','none');
    ylabel(handles.pltCurrentSignal,'Current (nA)','FontSize',10);
    xlabel(handles.pltCurrentSignal,'Samples','FontSize',10);
    hold(handles.pltCurrentSignal,'on');
    
    %enable buttons
    handles.cmdLoadPeaks.Enable='off';
    handles.cmdClearSignals.Enable='on';
    handles.cmdCopyplyCurrentSignal.Enable='on';
    handles.cmdSavepltCurrentSignal.Enable='on';
end


% --- Executes on button press in cmdClearSignals.
function cmdClearSignals_Callback(hObject, eventdata, handles)
% hObject    handle to cmdClearSignals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V N_Signals OxPeak OxPeakFiltered DisplaySignal FileName
global Saved_Data_Array

%reset background subtraction option
handles.chkSubstractBackground.Value=0;

%reset plots
cla(handles.pltOxPeak);
title(handles.pltCurrentSignal,'');
ylabel(handles.pltCurrentSignal,'');
xlabel(handles.pltCurrentSignal,'');
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
end
cla(handles.pltCurrentSignal);
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
zoom(handles.pltOxPeak,'out');
zoom(handles.pltOxPeak,'reset');

%reset signals
N_Signals=0;
legend(handles.pltCurrentSignal,'hide');

%enable buttons
handles.chkSubstractBackground.Enable='off';
handles.chkAverageSignals.Enable='off';
handles.cmdExtractData.Enable='off';
handles.txtAverageInterval.Enable='off';
handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
handles.cmdCopyplyCurrentSignal.Enable='off';
handles.cmdSavepltCurrentSignal.Enable='off';
if V.N_Peaks==0 
    handles.cmdLoadPeaks.Enable='off';
else
    handles.cmdLoadPeaks.Enable='on';
end
handles.cmdAddSignal.Enable='on';

% --- Executes on button press in cmdLoadPeaks.
function cmdLoadPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLoadPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V N_Signals ColorArray OxPeak OxPeakFiltered DisplaySignal FileName
global Saved_Data_Array

%plot data with correct filter
cla(handles.pltOxPeak);
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
end
cla(handles.pltCurrentSignal);
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
zoom(handles.pltOxPeak,'out');
zoom(handles.pltOxPeak,'reset');

%initialize and count signals 
N_Signals=0;
for i=1:V.N_Peaks
    N_Signals=N_Signals+1;
    PeakX=V.PP_Peaks(i); %iterate through peak points
    
    %draw a line at peak point
    line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(N_Signals,1:3));
    plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle),'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
    hold(handles.pltCurrentSignal,'on');
end

%plot
title(handles.pltCurrentSignal,FileName(1:length(FileName)-4), 'FontSize', 11, 'Color', 'k','Interpreter','none');
ylabel(handles.pltCurrentSignal,'Current (nA)','FontSize',10);
xlabel(handles.pltCurrentSignal,'Samples','FontSize',10);
legend(handles.pltCurrentSignal,'show');

%enable buttons
handles.chkSubstractBackground.Enable='on';
handles.chkAverageSignals.Enable='on';
handles.cmdExtractData.Enable='on';
handles.cmdCopyplyCurrentSignal.Enable='on';
handles.cmdSavepltCurrentSignal.Enable='on';
handles.chkSubstractBackground.Value=0;
handles.cmdAddSignal.Enable='off';
handles.cmdClearSignals.Enable='on';


% --- Executes on button press in chkSubstractBackground.
function chkSubstractBackground_Callback(hObject, eventdata, handles)
% hObject    handle to chkSubstractBackground (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkSubstractBackground
global V N_Signals ColorArray OxPeak OxPeakFiltered DisplaySignal FileName
global Saved_Data_Array

if handles.chkSubstractBackground.Value==1
    cla(handles.pltCurrentSignal);
    for i=1:V.N_Peaks
        PeakX=V.PP_Peaks(i);
        BackX=V.SP_Peaks(i);
        line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(i,1:3));
        line(handles.pltOxPeak,[BackX BackX],handles.pltOxPeak.YLim,'Color',ColorArray(i,1:3),'LineStyle','--');
        if handles.chkAverageSignals.Value==1
            AverageInterval=str2double(handles.txtAverageInterval.String);
            AverageSignal(1:V.PointsPerCycle)=0;
            for j=-AverageInterval:AverageInterval
                AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX+j)*V.PointsPerCycle+1:(BackX+j+1)*V.PointsPerCycle);
            end
            SubstractedSignal=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
        else
            SubstractedSignal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
        end
        %SubstractedSignal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
        plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),SubstractedSignal,'Color',ColorArray(i,1:3),'DisplayName',V.PeaksLabel{1,i});
        hold(handles.pltCurrentSignal,'on');
    end
else
    cla(handles.pltOxPeak);
    if (DisplaySignal==1) || (DisplaySignal==3)
        plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
    end
    if (DisplaySignal==2) || (DisplaySignal==3)
        plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
    end
    cla(handles.pltCurrentSignal);
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    zoom(handles.pltOxPeak,'out');
    zoom(handles.pltOxPeak,'reset');
    N_Signals=0;
    for i=1:V.N_Peaks
        N_Signals=N_Signals+1;
        PeakX=V.PP_Peaks(i);
        line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(N_Signals,1:3));
        if handles.chkAverageSignals.Value==1
            AverageInterval=str2double(handles.txtAverageInterval.String);
            AverageSignal(1:V.PointsPerCycle)=0;
            for j=-AverageInterval:AverageInterval
                AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle);
            end
            Signal=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
        else
            Signal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle);
        end
        plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),Signal,'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
        %plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle),'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
        hold(handles.pltCurrentSignal,'on');
    end
end
    


% --- Executes on button press in cmdSavepltOxPeak.
function cmdSavepltOxPeak_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSavepltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global C
[FileName,PathName]=uiputfile('*.fig','Introduce the name of the figure file',C.PathFigures);
if FileName~=0
    C.PathFigures=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    InterfaceObj=findobj(gcf,'Enable','on');
    set(InterfaceObj,'Enable','off');
    Fig1 = figure('Visible','off');
    copyobj(handles.pltOxPeak,Fig1);
    set(gca,'ActivePositionProperty','Position');
    set(gca,'Units','normalized');
    set(gca,'Position',[0 0 1 1]);
    set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);
    set(Fig1, 'Position', get(0,'Screensize'));
    set(Fig1, 'Visible','on');
    hgsave(Fig1, strcat(PathName,FileName));
    delete(Fig1);
    set(InterfaceObj,'Enable','on');
end


% --- Executes on button press in cmdSavepltCurrentSignal.
function cmdSavepltCurrentSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSavepltCurrentSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global C
[FileName,PathName]=uiputfile('*.fig','Introduce the name of the figure file',C.PathFigures);
if FileName~=0
    C.PathFigures=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    InterfaceObj=findobj(gcf,'Enable','on');
    set(InterfaceObj,'Enable','off');
    Fig1 = figure('Visible','off');
    copyobj(handles.pltCurrentSignal,Fig1);
    set(gca,'ActivePositionProperty','Position');
    set(gca,'Units','normalized');
    set(gca,'Position',[0 0 1 1]);
    set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);
    legend(gca,'show');
    set(Fig1, 'Position', get(0,'Screensize'));
    set(Fig1, 'Visible','on');
    hgsave(Fig1, strcat(PathName,FileName));
    delete(Fig1);
    set(InterfaceObj,'Enable','on');
end

% --- Executes on button press in cmdCopypltOxPeak.
function cmdCopypltOxPeak_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCopypltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
InterfaceObj=findobj(gcf,'Enable','on');
set(InterfaceObj,'Enable','off');
Fig1 = figure('Visible','off');
copyobj(handles.pltOxPeak,Fig1);
set(gca,'ActivePositionProperty','Position');
set(gca,'Units','normalized');
set(gca,'Position',[0 0 1 1]);
set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);
set(Fig1, 'Position', get(0,'Screensize'));
hgexport(Fig1,'-clipboard');
delete(Fig1);
set(InterfaceObj,'Enable','on');

% --- Executes on button press in cmdCopyplyCurrentSignal.
function cmdCopyplyCurrentSignal_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCopyplyCurrentSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

InterfaceObj=findobj(gcf,'Enable','on');
set(InterfaceObj,'Enable','off');
Fig1 = figure('Visible','off');
copyobj(handles.pltCurrentSignal,Fig1,'legacy');
set(gca,'ActivePositionProperty','Position');
set(gca,'Units','normalized');
set(gca,'Position',[0 0 1 1]);
set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);
legend(gca,'show');
set(Fig1, 'Position', get(0,'Screensize'));
hgexport(Fig1,'-clipboard');
delete(Fig1);
set(InterfaceObj,'Enable','on');


% --- Executes on button press in cmdExtractData.
function cmdExtractData_Callback(hObject, eventdata, handles)
% hObject    handle to cmdExtractData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global C V FileName
global Saved_Data_Array

progress_bar = waitbar(0.1, 'Starting extraction...');

FileNameWithoutExtension=strsplit(FileName,'.');
if handles.optExtractMatlab.Value==1
    ExtractFileName=strcat(FileNameWithoutExtension{1},'.mat');
    [ExtractFileName,PathName]=uiputfile('*.mat','Introduce the name of the MATLAB file',strcat(C.PathDataFiles,ExtractFileName));
else
    Answer = questdlg('What type of file do you want to generate?','Format File','Excel','CSV (.)','CSV (,)','Excel');
    if strcmp(Answer,'Excel')==1
        ExtractFileName=strcat(FileNameWithoutExtension{1},'.xlsx');
        [ExtractFileName,PathName]=uiputfile('*.xlsx','Introduce the name of the Excel file',strcat(C.PathDataFiles,ExtractFileName));
    else
        ExtractFileName=strcat(FileNameWithoutExtension{1},'.csv');
        [ExtractFileName,PathName]=uiputfile('*.csv','Introduce the name of the CSV file',strcat(C.PathDataFiles,ExtractFileName));
    end
end

if ExtractFileName~=0
    %%begin updated code with start/end option 06242022 by CM%%
    intAnswer=questdlg('How would you like to extract your data?','Extraction Options','Extract only peak point','Extract custom interval at peak point','Treat peak point and end point as interval','Extract only peak point');
    
    waitbar(0.5, progress_bar,'Still extracting...');

    if strcmp(intAnswer,'Treat peak point and end point as interval') == 1


        k=1;
        for i=1:length(V.PP_Peaks)
            for j=(V.PP_Peaks(i)):(V.EP_Peaks(i))
                PPEP_Peaks_Int(k) = j;
                k=k+1;
            end 
        end 
        
%
%         for i=1:length(V.SP_Peaks)
%             for j=(-peakInterval):(peakInterval)
%                 SP_Peaks_Int(k) = (V.SP_Peaks(i))+j;
%                 k=k+1;
%             end 
%         end 
        
        k=1;
        for i=1:length(V.PeaksLabel)
            for j=(V.PP_Peaks(i)):(V.EP_Peaks(i))
                PeaksLabel_with_interval{k} = V.PeaksLabel{i};
                k=k+1;
            end 
        end 
        
        N_Peaks_with_interval = length(PPEP_Peaks_Int);
        
        for i=1:N_Peaks_with_interval
            PeakX=PPEP_Peaks_Int(i);
            %BackX=SP_Peaks_Int(i);
            if handles.chkSubstractBackground.Value==1
                h = errordlg('Background subtraction not configured for this extraction method');
%                 if handles.chkAverageSignals.Value==1
%                     AverageInterval=str2double(handles.txtAverageInterval.String);
%                     AverageSignal(1:V.PointsPerCycle)=0;
%                     for j=-AverageInterval:AverageInterval
%                         AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX+j)*V.PointsPerCycle+1:(BackX+j+1)*V.PointsPerCycle);
%                     end
%                     Signals(i,1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
%                 else
%                     Signals(i,1:V.PointsPerCycle)=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
%                 end
            else 
                if handles.chkAverageSignals.Value==1
                      h = errordlg('Average signals not configured for this extraction method');
%                     AverageInterval=str2double(handles.txtAverageInterval.String);
%                     AverageSignal(1:V.PointsPerCycle)=0;
%                     for j=-AverageInterval:AverageInterval
%                         AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle);
%                     end
%                     Signals(i,1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
                else
                    Signals(i,1:V.PointsPerCycle)=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle);
                end
            end
        end
        PeaksLabel=cell(1);
        for i=1:N_Peaks_with_interval
            PeaksLabel{i}=PeaksLabel_with_interval{i};%TODO:update
        end
        if handles.optExtractMatlab.Value==1
            save(strcat(PathName,ExtractFileName),'PeaksLabel','Signals');
        else
            if strcmp(Answer,'Excel')==1
                for i=1:N_Peaks_with_interval
                    ExcelData{1,i}=PeaksLabel_with_interval{i};
                    for j=1:V.PointsPerCycle
                        ExcelData{j+1,i}=Signals(i,j);
                    end
                end
                xlswrite(strcat(PathName,ExtractFileName),ExcelData)
            else
                fileID = fopen(strcat(PathName,ExtractFileName),'w');
                formatSpec = '%s\n';
                Labels='';
                for i =1:N_Peaks_with_interval
                    if strcmp(Answer,'CSV (,)')==1
                        Labels=[Labels PeaksLabel_with_interval{i} ';'];
                    else
                        Labels=[Labels PeaksLabel_with_interval{i} ','];
                    end
                end
                fprintf(fileID,formatSpec,Labels);
                for i =1:V.PointsPerCycle
                    ValuesStr='';
                    for j=1:N_Peaks_with_interval
                        if strcmp(Answer,'CSV (,)')==1
                            ValuesStr=[ValuesStr num2str(Signals(j,i)) ';'];
                            ValuesStr(ValuesStr=='.')=',';
                        else
                            ValuesStr=[ValuesStr num2str(Signals(j,i)) ','];
                        end
                    end
                    fprintf(fileID,formatSpec,ValuesStr);
                end
                fclose(fileID);
            end
        end
    end 
    
    %%begin updated code with interval 06092021 by CM%%
    %intAnswer=questdlg('Extract intervals from peak?','Interval Option');
    if strcmp(intAnswer,'Extract custom interval at peak point') == 1
        peakInterval=inputdlg('Enter interval (+/- voltammograms from peak point)','Input Interval');
        peakInterval=cellfun(@str2num,peakInterval);
        
        k=1;
        for i=1:length(V.PP_Peaks)
            for j=(-peakInterval):(peakInterval)
                PP_Peaks_Int(k) = (V.PP_Peaks(i))+j;
                k=k+1;
            end 
        end 
        
        k=1;
        for i=1:length(V.SP_Peaks)
            for j=(-peakInterval):(peakInterval)
                SP_Peaks_Int(k) = (V.SP_Peaks(i))+j;
                k=k+1;
            end 
        end 
        
        k=1;
        for i=1:length(V.PeaksLabel)
            for j=(-peakInterval):(peakInterval)
                PeaksLabel_with_interval{k} = V.PeaksLabel{i};
                k=k+1;
            end 
        end 
        
        N_Peaks_with_interval = length(PP_Peaks_Int);
        
        for i=1:N_Peaks_with_interval
            PeakX=PP_Peaks_Int(i);
            BackX=SP_Peaks_Int(i);
            if handles.chkSubstractBackground.Value==1
                if handles.chkAverageSignals.Value==1
                    AverageInterval=str2double(handles.txtAverageInterval.String);
                    AverageSignal(1:V.PointsPerCycle)=0;
                    for j=-AverageInterval:AverageInterval
                        AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX+j)*V.PointsPerCycle+1:(BackX+j+1)*V.PointsPerCycle);
                    end
                    Signals(i,1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
                else
                    Signals(i,1:V.PointsPerCycle)=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
                end
            else 
                if handles.chkAverageSignals.Value==1
                    AverageInterval=str2double(handles.txtAverageInterval.String);
                    AverageSignal(1:V.PointsPerCycle)=0;
                    for j=-AverageInterval:AverageInterval
                        AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle);
                    end
                    Signals(i,1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
                else
                    Signals(i,1:V.PointsPerCycle)=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle);
                end
            end
        end
        PeaksLabel=cell(1);
        for i=1:N_Peaks_with_interval
            PeaksLabel{i}=PeaksLabel_with_interval{i};%TODO:update
        end
        if handles.optExtractMatlab.Value==1
            save(strcat(PathName,ExtractFileName),'PeaksLabel','Signals');
        else
            if strcmp(Answer,'Excel')==1
                for i=1:N_Peaks_with_interval
                    ExcelData{1,i}=PeaksLabel_with_interval{i};
                    for j=1:V.PointsPerCycle
                        ExcelData{j+1,i}=Signals(i,j);
                    end
                end
                xlswrite(strcat(PathName,ExtractFileName),ExcelData)
            else
                fileID = fopen(strcat(PathName,ExtractFileName),'w');
                formatSpec = '%s\n';
                Labels='';
                for i =1:N_Peaks_with_interval
                    if strcmp(Answer,'CSV (,)')==1
                        Labels=[Labels PeaksLabel_with_interval{i} ';'];
                    else
                        Labels=[Labels PeaksLabel_with_interval{i} ','];
                    end
                end
                fprintf(fileID,formatSpec,Labels);
                for i =1:V.PointsPerCycle
                    ValuesStr='';
                    for j=1:N_Peaks_with_interval
                        if strcmp(Answer,'CSV (,)')==1
                            ValuesStr=[ValuesStr num2str(Signals(j,i)) ';'];
                            ValuesStr(ValuesStr=='.')=',';
                        else
                            ValuesStr=[ValuesStr num2str(Signals(j,i)) ','];
                        end
                    end
                    fprintf(fileID,formatSpec,ValuesStr);
                end
                fclose(fileID);
            end
        end
    end
    %%Previous code without interval%%
    %TODO: change to SPEPoption =1
    %intAnswer=questdlg('Extract single peak?','Interval Option');
    if strcmp(intAnswer,'Extract only peak point') == 1
        for i=1:V.N_Peaks
            PeakX=V.PP_Peaks(i);
            BackX=V.SP_Peaks(i);
            if handles.chkSubstractBackground.Value==1
                if handles.chkAverageSignals.Value==1
                    AverageInterval=str2double(handles.txtAverageInterval.String);
                    AverageSignal(1:V.PointsPerCycle)=0;
                    for j=-AverageInterval:AverageInterval
                        AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX+j)*V.PointsPerCycle+1:(BackX+j+1)*V.PointsPerCycle);
                    end
                    Signals(i,1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
                else
                    Signals(i,1:V.PointsPerCycle)=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
                end
            else 
                if handles.chkAverageSignals.Value==1
                    AverageInterval=str2double(handles.txtAverageInterval.String);
                    AverageSignal(1:V.PointsPerCycle)=0;
                    for j=-AverageInterval:AverageInterval
                        AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle);
                    end
                    Signals(i,1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
                else
                    Signals(i,1:V.PointsPerCycle)=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle);
                end
            end
        end
        PeaksLabel=cell(1);
        for i=1:V.N_Peaks
            PeaksLabel{i}=V.PeaksLabel{i};
        end
        if handles.optExtractMatlab.Value==1
            save(strcat(PathName,ExtractFileName),'PeaksLabel','Signals');
        else
            if strcmp(Answer,'Excel')==1
                for i=1:V.N_Peaks
                    ExcelData{1,i}=V.PeaksLabel{i};
                    for j=1:V.PointsPerCycle
                        ExcelData{j+1,i}=Signals(i,j);
                    end
                end
                xlswrite(strcat(PathName,ExtractFileName),ExcelData)
            else
                fileID = fopen(strcat(PathName,ExtractFileName),'w');
                formatSpec = '%s\n';
                Labels='';
                for i =1:V.N_Peaks
                    if strcmp(Answer,'CSV (,)')==1
                        Labels=[Labels V.PeaksLabel{i} ';'];
                    else
                        Labels=[Labels V.PeaksLabel{i} ','];
                    end
                end
                fprintf(fileID,formatSpec,Labels);
                for i =1:V.PointsPerCycle
                    ValuesStr='';
                    for j=1:V.N_Peaks
                        if strcmp(Answer,'CSV (,)')==1
                            ValuesStr=[ValuesStr num2str(Signals(j,i)) ';'];
                            ValuesStr(ValuesStr=='.')=',';
                        else
                            ValuesStr=[ValuesStr num2str(Signals(j,i)) ','];
                        end
                    end
                    fprintf(fileID,formatSpec,ValuesStr);
                end
                fclose(fileID);
            end
        end    
    end
    
    if strcmp(intAnswer,'Cancel') == 1
    end 

close(progress_bar);
msgbox('Extraction complete!');
end

% --- Executes on button press in chkAverageSignals.
function chkAverageSignals_Callback(hObject, eventdata, handles)
% hObject    handle to chkAverageSignals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkAverageSignals
global V N_Signals ColorArray OxPeak OxPeakFiltered DisplaySignal
global Saved_Data_Array

if handles.chkSubstractBackground.Value==1
    cla(handles.pltCurrentSignal);
    for i=1:V.N_Peaks
        PeakX=V.PP_Peaks(i);
        BackX=V.SP_Peaks(i);
        line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(i,1:3));
        line(handles.pltOxPeak,[BackX BackX],handles.pltOxPeak.YLim,'Color',ColorArray(i,1:3),'LineStyle','--');
        if handles.chkAverageSignals.Value==1
            handles.txtAverageInterval.Enable='on';
            handles.lblAverageInterval.ForegroundColor=[0 0 0];
            AverageInterval=str2double(handles.txtAverageInterval.String);
            AverageSignal(1:V.PointsPerCycle)=0;
            for j=-AverageInterval:AverageInterval
                AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX+j)*V.PointsPerCycle+1:(BackX+j+1)*V.PointsPerCycle);
            end
            SubstractedSignal=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval+1);
        else
            handles.txtAverageInterval.Enable='off';
            handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
            SubstractedSignal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
        end
        %SubstractedSignal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
        plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),SubstractedSignal,'Color',ColorArray(i,1:3),'DisplayName',V.PeaksLabel{1,i});
        hold(handles.pltCurrentSignal,'on');
    end
else
    cla(handles.pltOxPeak);
    if (DisplaySignal==1) || (DisplaySignal==3)
        plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
    end
    if (DisplaySignal==2) || (DisplaySignal==3)
        plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
    end
    cla(handles.pltCurrentSignal);
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    zoom(handles.pltOxPeak,'out');
    zoom(handles.pltOxPeak,'reset');
    N_Signals=0;
    for i=1:V.N_Peaks
        N_Signals=N_Signals+1;
        PeakX=V.PP_Peaks(i);
        line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(N_Signals,1:3));
        if handles.chkAverageSignals.Value==1
            handles.txtAverageInterval.Enable='on';
            handles.lblAverageInterval.ForegroundColor=[0 0 0];
            AverageInterval=str2double(handles.txtAverageInterval.String);
            AverageSignal(1:V.PointsPerCycle)=0;
            for j=-AverageInterval:AverageInterval
                AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle);
            end
            Signal=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
        else
            handles.txtAverageInterval.Enable='off';
            handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
            Signal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle);
        end
        plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),Signal,'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
        %plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle),'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
        hold(handles.pltCurrentSignal,'on');
    end
end


function txtAverageInterval_Callback(hObject, eventdata, handles)
% hObject    handle to txtAverageInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtAverageInterval as text
%        str2double(get(hObject,'String')) returns contents of txtAverageInterval as a double
global V N_Signals ColorArray OxPeak OxPeakFiltered DisplaySignal
global Saved_Data_Array

if str2double(handles.txtAverageInterval.String)<1
    msgbox('The average interval should be an integer value higher than 0');
    handles.txtAverageInterval.String='15';
else
    if handles.chkSubstractBackground.Value==1
        cla(handles.pltCurrentSignal);
        for i=1:V.N_Peaks
            PeakX=V.PP_Peaks(i);
            BackX=V.SP_Peaks(i);
            line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(i,1:3));
            line(handles.pltOxPeak,[BackX BackX],handles.pltOxPeak.YLim,'Color',ColorArray(i,1:3),'LineStyle','--');
            if handles.chkAverageSignals.Value==1
                AverageInterval=str2double(handles.txtAverageInterval.String);
                AverageSignal(1:V.PointsPerCycle)=0;
                for j=-AverageInterval:AverageInterval
                    AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX+j)*V.PointsPerCycle+1:(BackX+j+1)*V.PointsPerCycle);
                end
                SubstractedSignal=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
            else
                SubstractedSignal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
            end
            %SubstractedSignal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle)-V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle);
            plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),SubstractedSignal,'Color',ColorArray(i,1:3),'DisplayName',V.PeaksLabel{1,i});
            hold(handles.pltCurrentSignal,'on');
        end
    else
        cla(handles.pltOxPeak);
        if (DisplaySignal==1) || (DisplaySignal==3)
            plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
        end
        if (DisplaySignal==2) || (DisplaySignal==3)
            plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
        end
        cla(handles.pltCurrentSignal);
        hzoom=zoom(handles.pltOxPeak);
        hzoom.ActionPostCallback = '';
        zoom(handles.pltOxPeak,'out');
        zoom(handles.pltOxPeak,'reset');
        N_Signals=0;
        for i=1:V.N_Peaks
            N_Signals=N_Signals+1;
            PeakX=V.PP_Peaks(i);
            line(handles.pltOxPeak,[PeakX PeakX],handles.pltOxPeak.YLim,'Color',ColorArray(N_Signals,1:3));
            if handles.chkAverageSignals.Value==1
                AverageInterval=str2double(handles.txtAverageInterval.String);
                AverageSignal(1:V.PointsPerCycle)=0;
                for j=-AverageInterval:AverageInterval
                    AverageSignal(1:V.PointsPerCycle)=AverageSignal(1:V.PointsPerCycle)+V.Gain*Saved_Data_Array((PeakX+j)*V.PointsPerCycle+1:(PeakX+j+1)*V.PointsPerCycle);
                end
                Signal=AverageSignal(1:V.PointsPerCycle)/(2*AverageInterval);
            else
                Signal=V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle);
            end
            plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),Signal,'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
            %plot(handles.pltCurrentSignal,(1:V.PointsPerCycle),V.Gain*Saved_Data_Array((PeakX)*V.PointsPerCycle+1:(PeakX+1)*V.PointsPerCycle),'Color',ColorArray(N_Signals,1:3),'DisplayName',V.PeaksLabel{1,i});
            hold(handles.pltCurrentSignal,'on');
        end
    end
end

% --- Executes during object creation, after setting all properties.
function txtAverageInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtAverageInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdExporttoExcel.
function cmdExporttoExcel_Callback(hObject, eventdata, handles)
% hObject    handle to cmdExporttoExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DisplaySignal V OxPeakFiltered
global OxPeak  C FileName
global Saved_Data_Array

FileNameWithoutExtension=strsplit(FileName,'.');
Answer = questdlg('What type of file do you want to generate?','Format File','Excel','CSV (.)','CSV (,)','Excel');
if Answer~=0
    if strcmp(Answer,'Excel')==1
        ExportFileName=strcat(FileNameWithoutExtension{1},'.xlsx');
        [ExportFileName,PathName]=uiputfile('*.xlsx','Introduce the name of the Excel file',strcat(C.PathDataFiles,ExportFileName));
    else
        ExportFileName=strcat(FileNameWithoutExtension{1},'.csv');
        [ExportFileName,PathName]=uiputfile('*.csv','Introduce the name of the CSV file',strcat(C.PathDataFiles,ExportFileName));
    end
    if ExportFileName~=0
        if (DisplaySignal==1) || (DisplaySignal==3)
            for i=1:V.N_Cycles
                ExcelData{i,2}=V.Gain*OxPeak(i);
            end
        else
            for i=1:V.N_Cycles
                ExcelData{i,2}=V.Gain*OxPeakFiltered(i);
            end
        end
        
        for i=1:V.N_Peaks
            ExcelData{V.SP_Peaks(i),1}=V.PeaksLabel{i};
            ExcelData{V.PP_Peaks(i),1}=V.PeaksLabel{i};
        end
        if strcmp(Answer,'Excel')==1
            xlswrite(strcat(PathName,ExportFileName),ExcelData)
        else
            fileID = fopen(strcat(PathName,ExportFileName),'w');
            formatSpec = '%s\n';
            for row = 1:V.N_Cycles
                ValueStr=num2str(ExcelData{row,2});
                if strcmp(Answer,'CSV (,)')==1
                    ValueStr(ValueStr=='.')=',';
                    rowText=[ExcelData{row,1} ';' ValueStr];
                else
                    rowText=[ExcelData{row,1} ',' ValueStr];
                end
                
                fprintf(fileID,formatSpec,rowText);
            end
            fclose(fileID);
        end
    end
end


% --- Executes on button press in optExtractMatlab.
function optExtractMatlab_Callback(hObject, eventdata, handles)
% hObject    handle to optExtractMatlab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optExtractMatlab


% --- Executes on button press in optExtractExcel.
function optExtractExcel_Callback(hObject, eventdata, handles)
% hObject    handle to optExtractExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optExtractExcel


% --- Executes during object creation, after setting all properties.
function pltCurrentSignal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pltCurrentSignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate pltCurrentSignal


% --- Executes on button press in btnColorPlot.
function btnColorPlot_Callback(hObject, eventdata, handles)
% hObject    handle to btnColorPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V Saved_Data_Array ScansBeyond

if handles.chkSubstractBackground.Value==1 && handles.chkAverageSignals.Value==0

    load('C:\Users\csmov\fscv_software\SeroDataProcess\CM Dev\fscv_software\SeroAcq\myCustomColormap.mat','-mat');
    %TODO: update color map location
    
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    
    for j=1:V.N_Peaks
        PeaksToSubtract=linspace(V.SP_Peaks(j),V.SP_Peaks(j)+ScansBeyond,ScansBeyond+1);
        BackX=V.SP_Peaks(j);
        CP_Signal = [];
        for k=1:length(PeaksToSubtract)
            CP_Signal(:,k)=V.Gain*Saved_Data_Array((PeaksToSubtract(k)*V.PointsPerCycle+1:(PeaksToSubtract(k)+1)*V.PointsPerCycle))-(V.Gain*Saved_Data_Array((BackX)*V.PointsPerCycle+1:(BackX+1)*V.PointsPerCycle));
        end 
        figure('Name',V.PeaksLabel{j},'NumberTitle','on')
        colorPlot=pcolor(PeaksToSubtract,1:V.PointsPerCycle,CP_Signal);                 
        xlabel('Scan Number'); 
        ylabel('Sampled Point');
        colorPlot.EdgeColor = 'none';
        colormap(myCustomColormap); 
        colorbar;

    end

    showWaveform = inputdlg('Show waveform? 1 for yes, 0 for no.');
    if str2num(showWaveform{1}) == 1
         figure('Name','Waveform','NumberTitle','off');
    %TODO: Change 3 to multiplier value from SeroAcq
         plot(1:V.PointsPerCycle,V.Signal_Cycle(1:V.PointsPerCycle)/3);
         xlabel('Sampled Point');
         ylabel('Voltage');
     end 
    
else
    msgbox('Background subtraction must be enabled for colot plotting. Averaging must be disabled.')
end 




function txtScansToDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to txtScansToDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtScansToDisplay as text
%        str2double(get(hObject,'String')) returns contents of txtScansToDisplay as a double
global ScansBeyond

ScansBeyond = str2double(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function txtScansToDisplay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtScansToDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
