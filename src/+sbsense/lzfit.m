function [yprime,params,resnorm] = lzfit(x,y,p0)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%options = optimoptions('lsqcurvefit','MaxIterations',1000000000);
options=optimset('Display','off');
[params,resnorm] = lsqcurvefit(@lorentzianFunc,p0,x,y,[],[],options);
yprime = lorentzianFunc(params,x);
end

function F = lorentzianFunc(p,x)
%F = (p(1)/(2*pi)) ./ ( (x-p(2)).^2 + (p(1)/2).^2 ) + p(3);

F = p(4) + p(2)*(2*p(1)/pi) ./ ( 4*(x-p(3)).^2 + p(2)^2 );


end % LFUN3C