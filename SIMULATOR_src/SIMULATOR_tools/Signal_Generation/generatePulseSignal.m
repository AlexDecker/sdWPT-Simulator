%generate Laplace Transform of the base voltage (bit 0)
%d = offset of the wave, f=frequency, v0 = amplitude
function [h1,h2]=generatePulseSignal(v0,v1,f,d,baudRate,center)
    %scalar to angular
    phi = 2*pi*d;
    w = 2*pi*f;
    a = center-1/(2*baudRate);
    b = center+1/(2*baudRate);
    syms s;
    %create the laplace transform for both Heaviside*sin functions
    h1 = (v1-v0)*exp(-a.*s)*((s.*sin(w*a+phi)+w*cos(w*a+phi))/(s.^2+w^2));
    h2 = (v1-v0)*exp(-b.*s)*((s.*sin(w*b+phi)+w*cos(w*b+phi))/(s.^2+w^2));
    %subtract them to get the pulse
    %p = h1-h2;
end