%Verifica a integridade do marcador de grupo (matriz binária, com um número de linhas maior ou
%igual ao número de colunas, com ao menos duas linhas e duas colunas e com exatamente uma
%ocorrência não nula em cada linha)
%groupMarking: groupMarking(i,j) = {1 caso i pertença ao grupo j e 0 caso contrário}.

function r = checkGroupMarking(groupMarking)
	s = size(groupMarking);
	r = sum(sum((groupMarking==0)|(groupMarking==1))) == s(1)*s(2);
	r = r && (s(1)>=s(2))&&(s(1)>=2)&&(s(2)>=2);
	r = r && (sum(sum(groupMarking')==1) == s(1));
end
