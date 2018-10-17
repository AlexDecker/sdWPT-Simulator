%generate all envLists for the evaluation through distance values

M = MagMIMODistanceTracking(true, false, true,'envMIMODist10.mat',0.1,-ones(7));

if isempty(M)
	error('could not access M data');
end

M0 = [	M(1:6,1:6),	-ones(6,1);
		-ones(1,6),	-1			];
		
M = MagMIMODistanceTracking(true, false, true,'envMIMODist20.mat',0.2,M0)
M = MagMIMODistanceTracking(true, false, true,'envMIMODist30.mat',0.3,M0)
M = MagMIMODistanceTracking(true, false, true,'envMIMODist40.mat',0.4,M0)
