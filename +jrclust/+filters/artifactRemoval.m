function samplesOut = artifactRemoval(samplesIn, artifactThresh, artifactNchan, hCfg)
    %FFTCLEAN Remove across-channel artifacts
    if artifactThresh == 0 || isempty(artifactThresh) || artifactNchan == 0 || isempty(artifactNchan)
        samplesOut = samplesIn;
        return;
    end

    hCfg.updateLog('artifactRemoval', 'Removing across-channel artifacts', 1, 0);

    nSamples = size(samplesIn, 1); % total number of samples (rows) in array
    [nLoads, nSamplesLoad, nSamplesFinal] = jrclust.utils.partitionLoad(nSamples, round(nSamples/hCfg.ramToGPUFactor));
    samplesOut = zeros(size(samplesIn), 'like', samplesIn);

    for iLoad = 1:nLoads
        offset = (iLoad - 1)*nSamplesLoad;

        if iLoad < nLoads
            rows = offset + (1:nSamplesLoad);
        else
            rows = offset + (1:nSamplesFinal);
        end
        samplesOut_ = samplesIn(rows, :);

        if hCfg.useGPU
            try                
               samplesOut(rows, :) = doArtifactDetect(samplesOut_, artifactThresh, artifactNchan, 1);
            catch ME
                hCfg.updateLog('artifactRemoval', sprintf('GPU artifact removal failed: %s (retrying in CPU)', ME.message), 1, 0);
                samplesOut(rows, :) = doArtifactDetect(samplesOut_, artifactThresh, artifactNchan, 0);
            end
        else
            samplesOut(rows, :) = doArtifactDetect(samplesOut_, artifactThresh, artifactNchan, 0);
        end
    end % for
    nart = sum(sum(samplesOut==0,2)==size(samplesOut,2));
    hCfg.updateLog('artifactRemoval', sprintf('Removed %d samples', nart), 0, 1);
end

%% LOCAL FUNCTIONS
function samplesOut = doArtifactDetect(samplesIn, artifactThresh, artifactNchan, useGPU)
    if artifactThresh == 0 || isempty(artifactThresh) || artifactNchan == 0 || isempty(artifactNchan)
        samplesOut = samplesIn;
        return;
    end
    
    samplesIn = jrclust.utils.tryGpuArray(samplesIn, useGPU);
    pad = 50;
    ix = find(sum(abs(samplesIn) > artifactThresh,2) > artifactNchan);
    ix = unique(bsxfun(@plus, ix, -pad:pad));
    ix(ix < 1) = [];
    ix(ix > size(samplesIn,1)) = [];
    
    samplesOut = single(samplesIn);
    samplesOut(ix,:) = 0;
    
    [samplesIn, samplesOut] = jrclust.utils.tryGather(samplesIn, samplesOut);
    samplesOut = cast(samplesOut, jrclust.utils.trueClass(samplesIn)); % cast back to the original type
end
