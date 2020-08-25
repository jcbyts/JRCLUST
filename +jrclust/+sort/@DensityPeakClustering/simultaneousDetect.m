function success = simultaneousDetect(obj, selected)
%SIMULTANEOUSDETECT Detect simultaneously occuring spikes
success = 0;



iCluster1 = selected(1);
iCluster2 = selected(2);
iSite = obj.clusterSites(iCluster1);

obj.hCfg.updateLog('simultaneousDetect', sprintf('Detecting simultaneous spikes cluster %d,%d', iCluster1, iCluster2), 1, 0);

% multisite
spikeSites = obj.hCfg.siteNeighbors(1:end - obj.hCfg.nSitesExcl, iSite);


iSpikes1 = obj.spikesByCluster{iCluster1};
iSpikes2 = obj.spikesByCluster{iCluster2};

sampledTraces1 = obj.getSpikeWindows(iSpikes1, spikeSites, 0, 1);
sampledTraces1 = reshape(sampledTraces1, [], size(sampledTraces1, 3));
sampledTraces2 = obj.getSpikeWindows(iSpikes2, spikeSites, 0, 1);
sampledTraces2 = reshape(sampledTraces2, [], size(sampledTraces2, 3));

wf1 = mean(sampledTraces1,2);
wf2 = mean(sampledTraces2,2);

shifts = -3:3;
simThresh = .6;

% compute residuals for Unit #1, assign new spikes to unit 2
ixs2 = [];
scs2 = [];
shift2 = [];
assignment2 = [];

residuals = sampledTraces1 - wf1;

for i = 1:numel(shifts)
    ishift = shifts(i);
    temp = circshift(wf2, ishift);
    simscore = corr(residuals, temp);
    
    ix = find(simscore>simThresh);
    sc = simscore(ix);
    
    [alreadyscored, loc] = ismember(ix, ixs2);
    if any(alreadyscored)
        remove = sc(alreadyscored)<scs2(loc(alreadyscored));
        ix = ix(remove);
        sc = sc(remove);
    end
    
    ixs2 = [ixs2; ix];
    scs2 = [scs2; sc];
    shift2 = [shift2; ones(numel(sc),1)*ishift];
    assignment2 = [assignment2; ones(numel(sc),1)*iCluster2];
end

% compute residuals for unit #2
residuals = sampledTraces2 - wf2;
ixs1 = [];
scs1 = [];
shift1 = [];
assignment1 = [];

for i = 1:numel(shifts)
    ishift = shifts(i);
    temp = circshift(wf1, ishift);
    simscore = corr(residuals, temp);
    
    ix = find(simscore>simThresh);
    sc = simscore(ix);
    
    [alreadyscored, loc] = ismember(ix, ixs1);
    if any(alreadyscored)
        remove = sc(alreadyscored)<scs1(loc(alreadyscored));
        ix = ix(remove);
        sc = sc(remove);
    end
    
    ixs1 = [ixs1; ix];
    scs1 = [scs1; sc];
    shift1 = [shift1; ones(numel(sc),1)*ishift];
    assignment1 = [assignment1; ones(numel(sc),1)*iCluster1];
end

nSpikesOld = obj.nSpikes;
ixs = [ixs1; ixs2];
scs = [scs1; scs2];
shift = [shift1; shift2];
assignment = [assignment1; assignment2;];
nSpikesAdd = numel(ixs);
assignments = unique(assignment);
% fields that need to be adjusted because the total number of spikes is
% changing
spikeFields = {'ordRho', 'spikeDelta', 'spikeNeigh', 'spikeSites2', 'spikeClusters',...
    'initialClustering', 'spikeAmps', 'spikePositions', 'spikeSites', 'spikeTimes', 'spikesRaw', ...
    'spikesFilt', 'spikeFeatures', 'spikesFiltVolt'};

Stemp = struct();
Smerge = struct();
for iField = 1:numel(spikeFields)
    sz = size(obj.(spikeFields{iField}));
    sz(sz==nSpikesOld) = nSpikesAdd;
    Stemp.(spikeFields{iField}) = zeros(sz, 'like', obj.(spikeFields{iField}));
    Smerge.(spikeFields{iField}) = obj.(spikeFields{iField});
end

addspikes = [iSpikes2(ixs1); iSpikes1(ixs2)];

for ispike = 1:nSpikesAdd
    for iField = 1:numel(spikeFields)
        sz = size(obj.(spikeFields{iField}));
        switch find(sz==nSpikesOld) % find the axis that spikes are stored along
            case 1
                if sz(2)==1
                    Stemp.(spikeFields{iField})(ispike) = obj.(spikeFields{iField})(addspikes(ispike));
                else
                    Stemp.(spikeFields{iField})(ispike,:) = obj.(spikeFields{iField})(addspikes(ispike),:);
                end
            case 3
                Stemp.(spikeFields{iField})(:,:,ispike) = obj.(spikeFields{iField})(:,:,addspikes(ispike));
            otherwise
                error('unrecognized shape')
        end
        
        switch spikeFields{iField}
            case 'spikeTimes' % offset by shift
                Stemp.spikeTimes(ispike) = int32(Stemp.spikeTimes(ispike) + shift(ispike));
            case 'initialClustering' % reassign spikes
                Stemp.initialClustering(ispike) = int32(assignment(ispike));
            case 'spikeClusters'
                Stemp.spikeClusters(ispike) = int32(assignment(ispike));
            case 'spikesRaw'
                Stemp.spikesRaw(:,:,ispike) = int16(single(Stemp.spikesRaw(:,:,ispike)) - single(obj.meanWfLocalRaw(:,:,setdiff(assignments, assignment(ispike)))));
            case 'spikesFilt'
                Stemp.spikesFilt(:,:,ispike) = int16(single(Stemp.spikesFilt(:,:,ispike)) - single(obj.meanWfLocal(:,:,setdiff(assignments, assignment(ispike)))));
            case 'spikesFiltVolt'
                Stemp.spikesFiltVolt(:,:,ispike) = Stemp.spikesFiltVolt(:,:,ispike) - obj.meanWfLocal(:,:,setdiff(assignments, assignment(ispike)))*obj.hCfg.bitScaling;
        end
        
    end
end

% for iField = 1:numel(spikeFields)
%     sz = size(obj.(spikeFields{iField}));
%     switch find(sz==nSpikesOld) % find the axis that spikes are stored along
%         case 1
%             obj.(spikeFields{iField}) = [obj.(spikeFields{iField}); Stemp.(spikeFields{iField})];
%         case 3
%             obj.(spikeFields{iField})(:,:,nSpikesOld + (1:nSpikesAdd)) = Stemp.(spikeFields{iField});
%     end
%     
% end
for iField = 1:numel(spikeFields)
    sz = size(Smerge.(spikeFields{iField}));
    switch find(sz==nSpikesOld) % find the axis that spikes are stored along
        case 1
            Smerge.(spikeFields{iField}) = [Smerge.(spikeFields{iField}); Stemp.(spikeFields{iField})];
        case 3
            Smerge.(spikeFields{iField})(:,:,nSpikesOld + (1:nSpikesAdd)) = Stemp.(spikeFields{iField});
    end
    
end
    
success = struct();
success.spikeClusters = Smerge.spikeClusters;
success.metadata = rmfield(Smerge, 'spikeClusters');

end