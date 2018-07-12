%generate Laplace Transform of the base voltage (bit 0)
%d = offset of the wave, f=frequency, v0 = amplitude
function B=generateAndSolveBaseSignal(v0, f, d, Z, T)
    %scalar to angular
    phi = 2*pi*d;
    w = 2*pi*f;
    syms s;syms t;
    b = ilaplace(Z*v0*((s*sin(phi)+w*cos(phi))/(s^2+w^2)));
    tic;
    B = eval(subs(matlabFunction(b),t,T));
    %B = eval(subs(b,t,T));
    toc;
end