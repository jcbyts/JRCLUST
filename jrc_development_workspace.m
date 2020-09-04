%% setup detect controller
hJRC = JRC('detect-sort', 'C:\Raw\Logan_2020-03-06_11-21-37_neuronexus_D9\ephys-jr.prm');
% hJRC = JRC('detect', 'C:\Raw\Logan_2020-03-04_09-51-54_neuronexus_D8\ephys-jr.prm');
obj = jrclust.detect.DetectController(hJRC.hCfg);

%% build recording object
iRec = 1;
fn = obj.hCfg.rawRecordings{iRec};
hRec = jrclust.detect.newRecording(fn, obj.hCfg);
%% load data
siteThresh = [];
rawFid = fopen(obj.hCfg.rawFile, 'w');
filtFid = fopen(obj.hCfg.filtFile, 'w');

%%

nSamples = 10e3;
iSamplesRaw = hRec.readRawROI(obj.hCfg.siteMap, 1:nSamples);
iSamplesRaw = iSamplesRaw';
%%
figure(10); clf
plot(double(iSamplesRaw) + (1:64)*500)

% obj.hCfg.filterType = 'differ';
% obj.hCfg.nDiffOrder = 4;
% obj.hCfg.CARMode = 'locmean8';
obj.hCfg.filterType = 'bandpass';
obj.hCfg.nDiffOrder = 2;
obj.hCfg.CARMode = 'mean';
%%


if isprop(obj.hCfg, 'artifactThresh') && isprop(obj.hCfg,'artifactNchan')
    iSamplesRaw = jrclust.filters.artifactRemoval(iSamplesRaw, obj.hCfg.artifactThresh, obj.hCfg.artifactNchan, obj.hCfg); % fft filter
end

if obj.hCfg.fftThresh > 0
    iSamplesRaw = jrclust.filters.fftClean(iSamplesRaw, obj.hCfg.fftThresh, obj.hCfg);
end

% filter spikes; samples go in padded and come out padded
try
    iSamplesFilt  = jrclust.filters.filtCAR(iSamplesRaw, [], [], 0, obj.hCfg);
catch ME % GPU filtering failed, retry in CPU
    obj.hCfg.updateLog('filtSamples', sprintf('GPU filtering failed: %s (retrying in CPU)', ME.message), 1, 0);
    
    obj.hCfg.useGPU = 0;
    iSamplesFilt = jrclust.filters.filtCAR(iSamplesRaw, [], [], 0, obj.hCfg);
end

figure(11); clf
plot(double(iSamplesFilt)*2 + (1:64)*500, 'k')
xlim([0 2e3])
%%
maxSample = 10e5;
siteRMS = jrclust.utils.estimateRMS(iSamplesFilt, maxSample);
chinds = setdiff(1:numel(siteRMS),obj.hCfg.ignoreSites);
mRMS = median(siteRMS(chinds));
siteRMS(chinds) = sqrt(sqrt(siteRMS(chinds)/mRMS))*mRMS;
siteThresh = siteRMS*obj.hCfg.qqFactor;

ix = abs(iSamplesFilt) > siteThresh;
figure(1); clf
plot(siteRMS); hold on
ss = jrclust.utils.subsample(iSamplesFilt, maxSample, 1);
plot(rms(ss))
% plot(siteThresh)


%%
clf
ch = ch + 1;
if ch > 64
    ch = 1;
end
histogram(abs(ss(:,ch)))

%%
samplesPre = [];
samplesPost = [];
nPadPre = 9;
nPadPost = 9;
keepMe = true(size(iSamplesFilt, 1), 1);

obj.hCfg.qqFactor = 3.5;
% obj.hCfg.evtGroupRad = 150;
% obj.hCfg.evtDetectRad = 150;

%%% detect spikes
loadData = struct('samplesRaw', [samplesPre; iSamplesRaw; samplesPost], ...
    'samplesFilt', iSamplesFilt, ...
    'keepMe', keepMe, ...
    'spikeTimes', [], ...
    'spikeSites', [], ...
    'siteThresh', [], ...
    'nPadPre', nPadPre, ...
    'nPadPost', nPadPost);

% find peaks: adds spikeAmps, updates spikeTimes, spikeSites,

loadData = obj.findPeaks(loadData);

figure(11); clf
siteOffsets = (1:64)*500;
plot(double(iSamplesFilt)*2 + siteOffsets, 'k')
xlim([0 2e3])
hold on
plot(loadData.spikeTimes, siteOffsets(loadData.spikeSites), 'ro')
%%
% subset imported samples in this recording interval
[impTimes, impSites] = deal([]);

recData = obj.detectOneRecording(hRec, [rawFid, filtFid], impTimes, impSites, siteThresh);

%%
hSort = jrclust.sort.SortController(obj.hCfg);
rez = hSort.sort(recData);

% recData.spikeFeatures(:,:,1)        
% res = hDetect.detect()
%%
Nf = 6;
X = single(iSamplesRaw);

% % [500 1000]
% Fpass = 300; %500
% Fstop = 3000;
% Fs = 30e3;
% 
% % d = designfilt('differentiatorfir','FilterOrder',Nf);
% d = designfilt('differentiatorfir','FilterOrder',Nf, ...
%     'PassbandFrequency',Fpass,'StopbandFrequency',Fstop, ...
%     'SampleRate',Fs);
% 
% % ix = 8e3:10e3;
% % ix = ix + 2e3;
% ix = 1:size(X,1);
% Xf = filter(d, X(ix,:));

figure(1); clf
plot(.1*X(ix,:)+(1:64)*200, 'k'); hold on
% plot(Xf + (1:64)*200)

[Xf, channelMeans] = jrclust.filters.filtCAR(X, [], [], 1, obj.hCfg);

figure(2); clf
plot(Xf + (1:64)*200, 'k'); hold on



% Nf = 6;
% Xf = jrclust.filters.fir1Filter(X(ix,:), Nf, [Fpass, Fstop]/Fs);
% figure(3); clf
% plot(Xf + (1:64)*500, 'r'); hold on