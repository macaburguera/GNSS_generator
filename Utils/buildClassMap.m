function [names, code2name] = buildClassMap(jamCodes)
code2name = @(code) localMap(code);
names = {};
for k = 1:numel(jamCodes)
    nm = code2name(jamCodes(k));
    if ~isempty(nm) && ~any(strcmp(names,nm)), names{end+1} = nm; end %#ok<AGROW>
end
order = {'NoJam','SingleAM','SingleChirp','SingleFM','DME','NB'};
names = sortByOrder(names, order);
end

