function out = sortByOrder(names, order)
used = false(size(names)); out  = {};
for k = 1:numel(order)
    idx = find(strcmp(names, order{k}), 1);
    if ~isempty(idx), out{end+1} = names{idx}; used(idx) = true; end %#ok<AGROW>
end
rest = names(~used);
if ~isempty(rest), rest = sort(rest); out = [out, rest]; end
end

