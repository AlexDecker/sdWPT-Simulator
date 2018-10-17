%generate all envLists for the evaluation through distance values

%If the other definition is no longer applicable
%M0 = -ones(7);

disp('Using pre-processed TX submatrix');
M0 = [25.7591,    0.4825,    0.0462,    0.4709,    0.1404,    0.0326,    -1;
    0.4825,   25.7591,    0.4825,    0.1403,    0.4709,    0.1404,    -1;
    0.0462,    0.4825,   25.7591,    0.0326,    0.1403,    0.4709,    -1;
    0.4709,    0.1403,    0.0326,   25.7591,    0.4825,    0.0462,    -1;
    0.1404,    0.4709,    0.1403,    0.4825,   25.7591,    0.4825,    -1;
    0.0326,    0.1404,    0.4709,    0.0462,    0.4825,   25.7591,    -1;
   -1.0000,   -1.0000,   -1.0000,   -1.0000,   -1.0000,   -1.0000,   -1];

M = MagMIMOOrientationTracking(true, false, true,'envMIMOOrient02.mat',0.02,M0,10,4);

%if isempty(M)
%	error('could not access M data');
%end

%M0 = [	M(1:6,1:6),	-ones(6,1);
%		-ones(1,6),	-1			];
		
M = MagMIMOOrientationTracking(true, false, true,'envMIMOOrient10.mat',0.1,M0,10,4)
M = MagMIMOOrientationTracking(true, false, true,'envMIMOOrient20.mat',0.2,M0,10,4)
M = MagMIMOOrientationTracking(true, false, true,'envMIMOOrient40.mat',0.4,M0,10,4)
