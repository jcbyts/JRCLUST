function binaryPursuit(obj)
    %AUTOSPLIT
    if numel(obj.selected) < 2
        warning('must select two units')
        return;
    end
    
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    nOldSpikes = obj.hClust.nSpikes;
    rez = obj.hClust.simultaneousDetect(obj.selected);
    newSpikes = numel(rez.spikeClusters);
    msg = sprintf('added %d spikes', newSpikes-nOldSpikes);
    fprintf([msg '\n'])
    obj.hClust.commit(rez.spikeClusters, rez.metadata, msg);
    
    disp('Done')
    
end

