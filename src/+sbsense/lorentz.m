function y = lorentz(x,xdata)
y = (x(3) * x(2)) ./ ( (x(2))^2 + (xdata - x(1)).^2 );
end