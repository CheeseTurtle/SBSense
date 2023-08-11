function [V,dt,t00] = timecolonspace(t0,u,tf,varargin)
%if (minute(t0)+second(t0))==0
%    t00 = t0;
%    V = colonspace(t0,u,tf);
%    return;
%end
if nargin>3
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
    V = colonspace(t0,u,tf);
else
    dt1 = dt/u;
    dt1 = (floor(dt1) - dt1 + 1) * u;
    V = [ t0 colonspace(t0+dt1, u, tf) ];
end