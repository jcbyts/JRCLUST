function showTraces(obj)
    %SHOWTRACES Show raw traces with spikes
    hTraces = jrclust.views.TracesController(obj.hCfg, obj.selected);
    hTraces.show([], 0, obj.hClust);
end