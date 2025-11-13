function idx = multinomial_pick(p)
% Pick one index according to probabilities p (sum to 1).
u = rand();
cs = cumsum(p(:));
idx = find(u <= cs, 1, 'first');
if isempty(idx), idx = numel(p); end
end


