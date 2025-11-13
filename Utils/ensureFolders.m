function ensureFolders(base, classNames)
if ~exist(base,'dir'), mkdir(base); end
for i = 1:numel(classNames)
    d = fullfile(base, classNames{i});
    if ~exist(d,'dir'), mkdir(d); end
end
end

