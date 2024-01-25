function [V,dt,t00] = timecolonspace1(threshFactor, t0,u,tf,varargin)
%if (minute(t0)+second(t0))==0
%    t00 = t0;
%    V = colonspace(t0,u,tf);
%    return;
%end
if nargin>4
    t00=varargin{1};
elseif isduration(t0) 
    %if (minutes(t0)==0) && (seconds(t0)==0)
    %    t00 = t0;
    %else
        t00=round(t0, 'hours');
    %end
elseif (minute(t0)==0) && (second(t0)==0)
        t00 = t0;
else
    t00=dateshift(t0,'start','hour');
end
dt = t0 - t00;
if dt==0
    V = sbsense.utils.sbsense.utils.colonspace1(threshFactor, t0,u,tf);
else
    dt1 = dt/u;
    dt1 = (floor(dt1) - dt1 + 1) * u;
    t01 = t0 + dt1;
    if t01 < tf
        V = [ t0 sbsense.utils.sbsense.utils.colonspace1(threshFactor, t0+dt1, u, tf) ];
    else
        V = [ t0 tf ];
    end
end