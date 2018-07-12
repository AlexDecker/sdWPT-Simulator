%generate Laplace Transform of the base voltage (bit 0)
%d = offset of the wave, f=frequency, v0 = amplitude
function b=generateBaseSignal(v0, f, d)
    %scalar to angular
    phi = 2*pi*d;
    w = 2*pi*f;
    syms s;
    b = v0*((s*sin(phi)+w*cos(phi))/(s^2+w^2));
end