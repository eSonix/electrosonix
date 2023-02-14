function psReadSEP_Raw(Parms)
%% PhotoSound Reader
% PSread_AMA_200123.m will read PhotoSound data into workspace and plot 1D
% (i.e., Fast time vs. amplitude) or 2D (i.e., Fast Time vs. Slow Time with
% amplitude as color) representations of AE Data
%% Copyright Electrosonix 2020

%% TOC - 
% @00 - Initial Definitions
% @01 - Load M-Mode

PSCh = 0; % # betweeen 1 and 32 representing channel to look at images for feedback in real time; Select 0 if you want to do all channels
% Photosound Reader 200328

%% @00 - Initial Definitions
% Create a directory to save the .h5 files 
if ~exist(Parms.Format.filename2,'dir')
    mkdir(Parms.Format.filename2)
end
if ~exist([Parms.Format.filename2 '/Photosound'],'dir')
    mkdir([Parms.Format.filename2 '/Photosound'])
end

inpDel = 0; % (samples) Delay from Trigger
padFast = 400; % (samples) Padding for downsampling/resampling

NumXPts = Parms.Scan.Xpt; % Number of X Points
NumYPts = Parms.Scan.Ypt; % Number of Y Points
NumAvg = Parms.Scan.Avg; % Number of Averages in Scan
NumTrig = Parms.Daq.HF.PulseRate*(Parms.Scan.Duration_ms/1000); % [int32] Define the number of triggers taken per average in the scan for 2D plot
% Sensor to Channel Mapping based on PhotoSound .map file [int32] 
% % % % sensToChan= [18,17,20,19,23,24,21,22,26,25,28,27,30,29,32,31;...    
% % % %              02,01,04,03,06,05,08,07,10,09,12,11,14,13,16,15];
sensToChan= [18,17,20,19,23,24,21,22,26,25,28,27,30,29,32,31,...    
             02,01,04,03,06,05,08,07,10,09,12,11,14,13,16,15];
% % % % [filename,filepath] = uigetfile('Data_*','Multiselect','on'); % Select .mat that contains PS Data
[filename,filepath] = uigetfile('*.raw','Multiselect','on'); % Select .mat that contains PS Data
fid = fopen(fullfile(filepath,filename),'r');
if fid == -1
    disp('Error: failed to open RAW data file');
    return;
end

[format_version,num_frames,~,...
    ~,sample_rate,num_channels,num_samples,...
    ~,~,~] = RawReadHeader(fid);

if (format_version ~= 2)
    disp('Error: invalid RAW data file format');
    fclose(fid);
    return;
end
%% @01 Load M-Mode
% start timer
tic
% Load all triggers from file(s)
nTrig = NumAvg*NumTrig; % (samples) Number of triggers at a single scan point
disp(['Collected ' num2str((nTrig*NumXPts*NumYPts)-num_frames) ' fewer triggers than expected'])
% Create variable trigPerFile to determine how many triggers come in datasets that include multiple files
% % % % if iscell(filename)
% % % %     trigPerFile = zeros(numel(filename),1);
% % % %     for fileIdx = 1:numel(filename)
% % % %         if fileIdx == 1
% % % %             load(char(filename(fileIdx)),'sample_rate')
% % % %             fs = sample_rate/1e6; % (mHz) Sampling frequency of PhotoSound
% % % %             load(char(filename(fileIdx)),'data_0')
% % % %             NumSamples = size(data_0,1); % (samples) Number of HF Samples collected on PS
% % % %             clear data_0; clear sample_rate;
% % % %             trigDel = round((inpDel/fs)*Parms.Daq.HF.Rate_mhz); % (samples) Downsampled trigger delay
% % % %             if trigDel == 0 % Modify trigDel so that it is an index of 1 if there was no delay
% % % %                 trigDel = 1;
% % % %             end        
% % % %         end
% % % %         load(char(filename(fileIdx)),'trigger_time');
% % % %         if fileIdx == 1
% % % %             trigPerFile(fileIdx) = 0;
% % % %         end
% % % %         trigPerFile(fileIdx+1) = numel(trigger_time)-1;
% % % %         clear trigs;
% % % %     end
% % % % % % %         if sum(trigPerFile) < nTrig
% % % % % % %         mode(diff(trigger_time))    
% % % % else
% % % %     load(filename,'sample_rate')
    fs = sample_rate/1e6; % (mHz) Sampling frequency of PhotoSound
% % % %     load(filename,'data_0')
% % % %     NumSamples = size(data_0,1); % (samples) Number of HF Samples collected on PS
    NumSamples = num_samples;
% % % %     clear data_0; clear sample_rate;
    trigDel = round((inpDel/fs)*Parms.Daq.HF.Rate_mhz); % (samples) Downsampled trigger delay
    if trigDel == 0 % Modify trigDel so that it is an index of 1 if there was no delay
        trigDel = 1;
    end            
% % % %     trigPerFile(1) = 0;
% % % %     load(filename,'trigger_time');
% % % %     trigPerFile(2) = numel(trigger_time)-1;
% % % %     diffy = diff(trigger_time);
% % % %     modhiji = round(1/(Parms.Daq.HF.PulseRate/1000));
% % % %     missy = find(diffy>modhiji);
% % % %     nummissed = diffy(missy);
% % % %     missy2 = find(nummissed~=NumTrig);
% % % %     missedtrigs = missy(missy2);
% % % %     trigmissed = diffy(missedtrigs);
% % % % end

% Find the larger of X or Y to set as outer for loop
if NumYPts >= NumXPts
    idxOne = 1:NumYPts;
    idxTwo = 1:NumXPts;
else
    idxOne = 1:NumXPts;
    idxTwo = 1:NumYPts;
end

tic
% % % % idxFile = 1;
% Loop over X and Y Scan Points
for idxFirst = 1:length(idxOne)
    for idxSecond = 1:length(idxTwo) %1:allparam.board.daq.NumAcq
        if NumYPts >= NumXPts
            idxY = idxFirst;
            idxX = idxSecond;
        else 
            idxX = idxFirst;
            idxY = idxSecond;
        end
        disp(['Loading XPt' (num2str(idxX)) '_YPt' (num2str(idxY))]);

        % Create array to load data into (total number of triggers at a
        % single scan point and single average)
        dataArray = zeros(nTrig,NumSamples,32);
% %         if sum(trigPerFile) < nTrig*length(idxOne)*length(idxTwo)-1
% %             trigMax = trigPerFile(end);
% %         else
% %             trigMax = nTrig;
% %         end
        % Loop over all triggers in an average
        for idx=1:nTrig
            % Determine the appropriate data_N variable to load based
            % on scan point, average, and trigger numbers
%                     NameIdx = ((idxFirst-1)*(length(idxTwo)*nTrig))+((idxSecond-1)*nTrig)-(sum(trigPerFile(1:fileIdx)))+idx;
% % % %             NameIdx = ((idxFirst-1)*(length(idxTwo)*nTrig))+((idxSecond-1)*nTrig)+idx;
% % % %             skipToEnd = NameIdx >= sum(trigPerFile)+1;
% % % %             if NameIdx > trigPerFile(idxFile+1) && iscell(filename)
% % % %                 if NameIdx == sum(trigPerFile(1:idxFile+1))+1 && NameIdx ~= sum(trigPerFile)+1
% % % %                     clear -regexp ^data_
% % % %                     idxFile = idxFile + 1;
% % % %                     load(char(filename(idxFile)))
% % % %                 end
% % % %                 NameIdx = NameIdx - sum(trigPerFile(1:idxFile))-1;
% % % %             elseif NameIdx > trigPerFile(idxFile+1) && ~iscell(filename)
% % % %                 NameIdx = trigPerFile(idxFile+1);
% % % %             elseif idx == 0
% % % %                 if iscell(filename)
% % % %                     load(char(filename(idxFile)))
% % % %                 else
% % % %                     load(filename)
% % % %                 end
% % % %             end
% % % %             if ~skipToEnd
                % Define the name of the data in that trigger
% % % %                 Name = ['data_',num2str(NameIdx)];
                % Load into workspace 
                [success,~,~,~,data] = RawReadFrame(fid,num_channels,num_samples);
                if ~success
                    fprintf('\nError: failed to read data packet\n');
                    break;
                end
                tmp = permute(data,[2,1]);
% % % %                 tmp=double(eval(Name));

                % Scale to V
% % % %                 tmp = tmp./(2^16)*2;
                tmp = double(tmp)./(2^16)*2;
                % Write the data from the selected sensor/channel into
                % dataArray
    %             dataArray(idx+1,:) = squeeze(tmp(:,sensIdx(2),sensIdx(1)));
% % % %                 dataArray(idx+1,:,:,:) = tmp;
                dataArray(idx,:,:) = tmp;
                % Subtract Mean
% % % %                 dataArray(idx+1,:,:,:) = dataArray(idx+1,:,:,:)-mean(dataArray(idx+1,:,:,:));
                dataArray(idx,:,:) = dataArray(idx,:,:)-mean(dataArray(idx,:,:));
% % % %             end
        end
%         disp([num2str(toc) ' secs to load PS file']);
        if PSCh ~= 0
            psChannels = PSCh;
        else
            psChannels = 1:32;
        end
        for sizey = psChannels
            sensSel = sizey; % Select the sensor from the counter
            % Find the index of the channel that corresponds to the current sensor
% % % %             [sensIdx(1),sensIdx(2)] = find(sensToChan == sensSel);
            sensIdx = find(sensToChan == sensSel);
            saveArray = squeeze(dataArray(:,:,sensIdx));
            
            % Create saveName for file based on XPt, YPt, and channel and
            % created h5 file
            saveName = [Parms.f_root '/Photosound' '/' Parms.f_root  '_PSCh' num2str(sensSel) '_XPt' num2str(idxX) '_YPt' num2str(idxY) '.h5'];     
            if ~exist(saveName, 'file')
                h5create(saveName,'/PSData',[Parms.daq.HFdaq.pts,NumTrig,NumAvg])
            end
            
            % Convert padding into new resampled size
            padFastRS = padFast/(double(fs)/Parms.Daq.HF.Rate_mhz);
            % Pad and downsample into NI (using resample with default
            % anti-aliasing filter)
            saveArray  = padarray(saveArray,[0 padFast],'replicate','both');    
            downSampled = resample(double(saveArray'),Parms.Daq.HF.Rate_mhz,double(fs));
            downSampled = downSampled(padFastRS+1:end-padFastRS,:);

            % Place the downSampled Array into an array of zeros the size
            % of the NI file
            inPlace = zeros(Parms.daq.HFdaq.pts,size(downSampled,2));
            inPlace(trigDel:trigDel+size(downSampled,1)-1,:) = downSampled;

            % Reshape by Number of Triggers x Number of Averages at a
            % single scan point and write to file
            finSize = reshape(inPlace,[size(inPlace,1),NumTrig,NumAvg]);
            if size(finSize,1) > Parms.daq.HFdaq.pts
                finSize = finSize(1:Parms.daq.HFdaq.pts,:,:);
            end
            h5write(saveName,'/PSData',finSize,[1,1,1],[size(finSize,1),size(finSize,2),size(finSize,3)])
        end
    end
end
fclose(fid);

disp([num2str(toc) ' secs to load PS Data']);    
end