function [spikeWindows, spikeTimes] = CARRealign(obj, spikeWindows, samplesIn, spikeTimes, neighbors)
    %CARREALIGN Realign spike peaks after applying local CAR
    if ~strcmpi(obj.hCfg.getOr('vcSpkRef', 'nmean'), 'nmean')
        return;
    end

    % find where true peaks are not in the correct place after applying local CAR
    spikeWindowsCAR = jrclust.utils.localCAR(single(spikeWindows), obj.hCfg);
    [shiftMe, shiftBy] = findShifted(spikeWindowsCAR, obj.hCfg);

    if isempty(shiftMe)
        return;
    end

    % adjust spike times
    shiftedTimes = spikeTimes(shiftMe) - int32(shiftBy(:));
    spikeTimes(shiftMe) = shiftedTimes;

    % extract windows at new shifted times
    spikeWindows(:, shiftMe, :) = obj.extractWindows(samplesIn, shiftedTimes, neighbors, 0);
end

%% LOCAL FUNCTIONS
function [shiftMe, shiftBy] = findShifted(spikeWindows, hCfg)
    %FINDSHIFTED
    %   spikeWindows: nSamples x nSpikes x nSites
    peakLoc = 1 - hCfg.evtWindowSamp(1);
    wts = exp( -((1:size(spikeWindows,1)) - peakLoc).^2/200); % bias peak-finding towards current peakLoc
    if hCfg.detectBipolar
        [val0, truePeakLoc0] = max(abs(spikeWindows(:, :, 1)).*wts(:));
        [val1, truePeakLoc1] = min(spikeWindows(:, :, 1));
        val1 = abs(val1);
        truePeakLoc = truePeakLoc0;
        d = (val1./val0);
        iix = d >= 1;
        truePeakLoc( iix ) = truePeakLoc1( iix ); % negative "peaks" should be aligned to if they exist
        
    else
        [~, truePeakLoc] = min(spikeWindows(:, :, 1));
    end

    shiftMe = find(truePeakLoc ~= peakLoc);
    shiftBy = peakLoc - truePeakLoc(shiftMe);

    shiftOkay = (abs(shiftBy) <= 8); % throw out drastic shifts
    shiftMe = shiftMe(shiftOkay);
    shiftBy = shiftBy(shiftOkay);
end