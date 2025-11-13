function h = rrc_filter_local(alpha, span, sps)
% Wrapper using Communications Toolbox if present; otherwise design via rcosdesign.
try
    h = rcosdesign(alpha, span, sps, 'sqrt');
catch
    % Fallback: polyphase approximation
    t = (-span/2 : 1/sps : span/2);
    h = zeros(size(t));
    for i=1:numel(t)
        tau = t(i);
        if abs(1 - (4*alpha*tau).^2) < 1e-12
            h(i) = (pi/4) * sinc(1/(2*alpha));
        else
            h(i) = sinc(tau) .* cos(pi*alpha*tau) ./ (1 - (2*alpha*tau).^2);
        end
    end
    h = h / norm(h);
end
h = h(:);
end
