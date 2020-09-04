function refractoryViolations(obj)

    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end
          
    %%
    n = obj.hClust.rmRefracSpikes(obj.selected);
    
    obj.hClust.computeQualityScores(obj.selected)
    
    return
       
    
    % TODO: DO a better job of this
    figure(2000); clf
    
    iix = obj.hClust.spikesByCluster{obj.selected};
%     wf = squeeze(obj.hClust.spikesFilt(:,1,iix));
%     plot(wf)
    st = obj.hClust.spikeTimes(iix);
    
    bins = 0:1:200;
    dst = diff(st);
    cnts = histcounts(dst, bins);
    stairs(bins(1:end-1), cnts)
    
    rfviols = find(dst < obj.hCfg.refracIntSamp);
    
    
    histogram(st(rfviols+1) - st(rfviols))
    
    w1 = reshape(obj.hClust.spikesFilt(:,:,rfviols), [], numel(rfviols));
    w2 = reshape(obj.hClust.spikesFilt(:,:,rfviols-1), [], numel(rfviols));
    figure(2001); clf
    subplot(1,2,1)
    plot(w1(:,1))
    subplot(1,2,2)
    plot(w2(:,1))
    
    X = zeros(size(w1));
    
    
    doubleCounted = sum((w1-w2).^2)==0;
    fprintf('%d/%d refractory violations are double-counting the same waveform and will be removed.\n', sum(doubleCounted), numel(doubleCounted))
    
    toremove = rfviols(doubleCounted);
    
    %%
    cc = obj.selected;
    mw = reshape(obj.hClust.meanWfLocal(:,:,cc), [], 1);
    cs = obj.hClust.clusterSites(cc);
    neighs = find(obj.hClust.clusterSites==cs);
%     obj.hClust.spikesFilt(:,:,rfviols(
    figure(2001); clf; 
    ii = ii + 1
    plot(w1(:,ii)); hold on
    plot(w2(:,ii))
    plot(mw, 'k')
    %%
    
%     
%     
%     %%
%     obj.showSubset = 1:obj.hClust.nClusters;
%     jrclust.views.plotFigWav(hFigWav, obj.hClust, obj.maxAmp, obj.channel_idx, obj.showSubset);
%     
%     nOldSpikes = obj.hClust.nSpikes;
%     rez = obj.hClust.simultaneousDetect(obj.selected);
%     newSpikes = numel(rez.spikeClusters);
%     msg = sprintf('added %d spikes', newSpikes-nOldSpikes);
%     fprintf([msg '\n'])
%     obj.hClust.commit(rez.spikeClusters, rez.metadata, msg);
%     
%     disp('Done')
    
end

