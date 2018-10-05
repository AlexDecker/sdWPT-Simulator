%gera uma série temporal de tamanho menor dado uma série temporal de temanho maior
function s = reduceSeries(serie, smooth_radius, out_size)
	s = zeros(length(serie),1);
	for i=1:length(serie)
		i0 = max(1,i-smooth_radius);
		i1 = min(length(serie),i+smooth_radius);
		s(i) = mean(serie(i0:i1));
	end
	s = s(ceil(linspace(1,length(s), out_size)));
end
