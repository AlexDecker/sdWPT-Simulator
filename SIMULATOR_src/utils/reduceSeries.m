%generates a temporal series of size out_size from a larger series
function s = reduceSeries(serie, smooth_radius, out_size)
    b = (1/smooth_radius)*ones(1,smooth_radius);
    a = 1;
    s = filter(b,a,serie);
    s = s(round(linspace(1,length(s), out_size)));
end
