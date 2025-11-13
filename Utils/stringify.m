function arr = stringify(cellstrs)
if isstring(cellstrs)
    arr = cellstr(cellstrs);
elseif iscell(cellstrs)
    arr = cellfun(@char, cellstrs, 'uni', 0);
else
    arr = cellstr(string(cellstrs));
end
end

