function car = getCAR(samplesIn, CARMode, ignoreSites)
    %GETCAR Get common average reference for samples (mean or median)
    if ~isempty(ignoreSites)
        samplesIn(:, ignoreSites) = nan;
    end

    nind = regexp(CARMode, '\d');
    if ~isempty(nind)
        n = str2double(CARMode(nind:end));
        CARMode = CARMode(1:nind-1);
    end
    
    switch CARMode
        case 'median'
            car = nanmedian(samplesIn, 2);
        case 'mean'
            car = nanmean(samplesIn, 2);
        case 'locmed'
            car = zeros(size(samplesIn), 'single');
            goodsites = ~isnan(sum(samplesIn));
            car(:,goodsites) = medfilt1(single(samplesIn(:,goodsites)), n, [], 2);
        case 'locmean'
            car = zeros(size(samplesIn), 'single');
            goodsites = ~isnan(sum(samplesIn));
            I = toeplitz([zeros(1,2) ones(1,n) zeros(1,sum(goodsites)-n-2)]);
            car(:,goodsites) = single(samplesIn(:,goodsites))*I./sum(I);
        otherwise
            car = samplesIn;
    end
end
