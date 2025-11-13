function v = getfield_safe(S, name)
if isfield(S, name), v = S.(name); else, v = []; end
end

function S = maybeSet(S, name, val)
if ~isempty(val)
    try
        S.(name) = val;
    catch
        % ignore if ParamJam doesn't accept this field
    end
end
end
