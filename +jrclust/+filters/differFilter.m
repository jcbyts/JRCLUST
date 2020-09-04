function samplesIn = differFilter(samplesIn, nDiffOrder, sampleRate, freqLimBP)
% Applys a nth-order differentiator filter (requires signal procesing
% toolbox)
% samplesOut = differFilter(samplesOut, nDiffOrder, sampleRate, freqLimBP)

d = designfilt('differentiatorfir','FilterOrder',nDiffOrder, ...
    'PassbandFrequency',freqLimBP(1),'StopbandFrequency',freqLimBP(2), ...
    'SampleRate',sampleRate);

delay = mean(grpdelay(d));

samplesIn = filter(d, samplesIn);

samplesIn = circshift(samplesIn, -delay, 1); % padding handled outside this function