function varargout = mainWin(varargin)
% MAINWIN MATLAB code for mainWin.fig
%      MAINWIN, by itself, creates a new MAINWIN or raises the existing
%      singleton*.
%
%      H = MAINWIN returns the handle to a new MAINWIN or the handle to
%      the existing singleton*.
%
%      MAINWIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAINWIN.M with the given input arguments.
%
%      MAINWIN('Property','Value',...) creates a new MAINWIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mainWin_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mainWin_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mainWin

% Last Modified by GUIDE v2.5 28-Apr-2019 13:38:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mainWin_OpeningFcn, ...
                   'gui_OutputFcn',  @mainWin_OutputFcn, ...
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


% --- Executes just before mainWin is made visible.
function mainWin_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mainWin (see VARARGIN)

% Choose default command line output for mainWin
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
initialize_gui(hObject, handles, false);

% UIWAIT makes mainWin wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
if isfield(handles, 'audio') && ~isreset
    return;
end
clear handles.audio.mainRecorder;
clear handles.audio.mainPlayer;

handles.audio.mainRecorder=audiorecorder(22050,16,2);
handles.audio.mainPlayer=0;

handles.audio.audioData=0;
% Update handles structure
guidata(handles.figure1, handles);




% --- Outputs from this function are returned to the command line.
function varargout = mainWin_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in recordB.
function recordB_Callback(hObject, eventdata, handles)
% hObject    handle to recordB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Start speaking.')
record(handles.audio.mainRecorder);
while(isrecording(handles.audio.mainRecorder))
    sec = mod(handles.audio.mainRecorder.CurrentSample/handles.audio.mainRecorder.SampleRate,60); 
    min = floor(handles.audio.mainRecorder.CurrentSample/handles.audio.mainRecorder.SampleRate/60);
    set(handles.recordT,'String',strcat(int2str(min),':',int2str(sec)));
    pause(1);
end


% --- Executes on button press in playB.
function playB_Callback(hObject, eventdata, handles)
% hObject    handle to playB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%handles.audio.audioData = getaudiodata(handles.audio.mainRecorder);
audiodata=handles.audio.audioData;
if isequal(audiodata,0)
    return;
end
if  handles.audio.mainPlayer ~= 0
    if(isplaying(handles.audio.mainPlayer))
        return;
    end
end

disp('play.')
len = length(audiodata);
if strcmp(handles.playEffectG.SelectedObject.Tag,'kuaifangB')
    Fs = handles.audio.mainRecorder.SampleRate;
    rate = str2double(get(handles.kuaifangT,'String'));
    handles.audio.mainPlayer = audioplayer(audiodata,rate*Fs);
else
    switch handles.playEffectG.SelectedObject.Tag
        case 'noeffectB'
        case 'jianruoB'
            for i=len/2+1 : len 
                audiodata(i,:)=audiodata(i,:)*(len-i)/(len/2); 
            end    
        case 'jianqiangB'
            for i=1 : (len/2) 
                audiodata(i,:)=audiodata(i,:)*i/(len/2); 
            end
        case 'daofangB'
            audiodata(:,1) = handles.audio.audioData(end:-1:1,1);
            audiodata(:,2) = handles.audio.audioData(end:-1:1,2);
        case 'biandaoB'
            audiodata(:,1)=handles.audio.audioData(:,2);
            audiodata(:,2)=handles.audio.audioData(:,1);
        case 'huiyinB'
            huiyin(:,1)=([audiodata(:,1); zeros(10000,1)]+[zeros(10000,1); audiodata(:,1)])/2;
            huiyin(:,2)=([audiodata(:,2); zeros(10000,1)]+[zeros(10000,1); audiodata(:,2)])/2;
            clear audiodata;
            audiodata=huiyin;
        case 'lvboB'
            popup_sel_index=get(handles.lvboP,'Value');
            switch popup_sel_index
                case 2
                    fs=handles.audio.mainRecorder.SampleRate;%采样频率
                    ap=0.1;%通带最大衰减
                    as=6;%阻带最大衰减

                    wp=4000;%通带截止频率
                    ws=5000; %阻带截止频率

                    wpp=wp/(fs/2);
                    wss=ws/(fs/2); %归一化;
                    [n, wn]=buttord(wpp,wss,ap,as); %计算阶数截止频率
                    [b, a]=butter(n,wn); %计算N阶巴特沃斯数字滤波器系统函数分子、分母多项式的系数向量b、a。

                    audiodata(:,1)=filtfilt(b,a,audiodata(:,1)); %滤波b、a滤波器系数，滤波前序列
                    audiodata(:,2)=filtfilt(b,a,audiodata(:,2));
                case 1
                    fs=handles.audio.mainRecorder.SampleRate;%采样频率
                    ap=0.1;%通带最大衰减
                    as=6;%阻带最大衰减

                    wp=4000;%通带截止频率
                    ws=5000; %阻带截止频率

                    wpp=wp/(fs/2);
                    wss=ws/(fs/2); %归一化;
                    [n, wn]=buttord(wpp,wss,ap,as,'s'); %计算阶数截止频率
                    [z,p,k]=buttap(n);
                    [b,a]=zp2tf(z,p,k);
                    [b,a]=lp2hp(b,a,wn);
                    audiodata(:,1)=filtfilt(b,a,audiodata(:,1)); %滤波b、a滤波器系数，滤波前序列
                    audiodata(:,2)=filtfilt(b,a,audiodata(:,2));
            end
    end
    Fs = handles.audio.mainRecorder.SampleRate;
    handles.audio.mainPlayer = audioplayer(audiodata,Fs);
end
axes(handles.axes1);
cla;
plot(audiodata);
play(handles.audio.mainPlayer);
sec = mod(handles.audio.mainPlayer.TotalSample/handles.audio.mainPlayer.SampleRate,60); 
min = floor(handles.audio.mainPlayer.TotalSample/handles.audio.mainPlayer.SampleRate/60);
set(handles.recordT,'String',strcat(int2str(min),':',int2str(sec)));
guidata(hObject, handles);
while(isplaying(handles.audio.mainPlayer))
    sec = mod(handles.audio.mainPlayer.CurrentSample/handles.audio.mainPlayer.SampleRate,60); 
    min = floor(handles.audio.mainPlayer.CurrentSample/handles.audio.mainPlayer.SampleRate/60);
    set(handles.playT,'String',strcat(int2str(min),':',int2str(sec)));
    pause(1);
end


% --- Executes on button press in pauseB.
function pauseB_Callback(hObject, eventdata, handles)
% hObject    handle to pauseB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('pause.')
pause(handles.audio.mainRecorder);


% --- Executes on button press in resumeB.
function resumeB_Callback(hObject, eventdata, handles)
% hObject    handle to resumeB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Resume')
resume(handles.audio.mainRecorder);
while(isrecording(handles.audio.mainRecorder))
    sec = mod(handles.audio.mainRecorder.CurrentSample/handles.audio.mainRecorder.SampleRate,60); 
    min = floor(handles.audio.mainRecorder.CurrentSample/handles.audio.mainRecorder.SampleRate/60);
    set(handles.recordT,'String',strcat(int2str(min),':',int2str(sec)));
    pause(1);
end


% --- Executes on button press in stopB.
function stopB_Callback(hObject, eventdata, handles)
% hObject    handle to stopB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('End of speaking.')
stop(handles.audio.mainRecorder);
handles.audio.audioData = getaudiodata(handles.audio.mainRecorder);
guidata(handles.figure1, handles);
axes(handles.axes1);
cla;
plot(handles.audio.audioData);


% --- Executes on button press in resetB.
function resetB_Callback(hObject, eventdata, handles)
% hObject    handle to resetB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.recordT,'String','0:0');
set(handles.playT,'String','0:0');
axes(handles.axes1);
cla;
plot(0);
initialize_gui(hObject, handles, true);


% --- Executes on button press in ppauseB.
function ppauseB_Callback(hObject, eventdata, handles)
% hObject    handle to ppauseB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('pause.')
pause(handles.audio.mainPlayer);

% --- Executes on button press in presumeB.
function presumeB_Callback(hObject, eventdata, handles)
% hObject    handle to presumeB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('resume.')
resume(handles.audio.mainPlayer);
while(isplaying(handles.audio.mainPlayer))
    sec = mod(handles.audio.mainPlayer.CurrentSample/handles.audio.mainPlayer.SampleRate,60); 
    min = floor(handles.audio.mainPlayer.CurrentSample/handles.audio.mainPlayer.SampleRate/60);
    set(handles.playT,'String',strcat(int2str(min),':',int2str(sec)));
    pause(1);
end



% --- Executes on button press in pstopB.
function pstopB_Callback(hObject, eventdata, handles)
% hObject    handle to pstopB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('stop.')
stop(handles.audio.mainPlayer);
set(handles.playT,'String','0:0');



function kuaifangT_Callback(hObject, eventdata, handles)
% hObject    handle to kuaifangT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of kuaifangT as text
%        str2double(get(hObject,'String')) returns contents of kuaifangT as a double


% --- Executes during object creation, after setting all properties.
function kuaifangT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to kuaifangT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hunyinT_Callback(hObject, eventdata, handles)
% hObject    handle to hunyinT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hunyinT as text
%        str2double(get(hObject,'String')) returns contents of hunyinT as a double


% --- Executes during object creation, after setting all properties.
function hunyinT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hunyinT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lvboP.
function lvboP_Callback(hObject, eventdata, handles)
% hObject    handle to lvboP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lvboP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lvboP


% --- Executes during object creation, after setting all properties.
function lvboP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lvboP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'High-pass filter', 'Low-pass filter'});
