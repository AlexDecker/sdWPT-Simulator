%Calculates the amount of the active power of the non-principal branches marked in bitmap group gR that is due
%the induction of the current of the coils marked in bitmap group gT. Curr is the current of each non-principal
%branch in phasor notation and Z is the impedance matrix.
function P = calculatePower(curr,Z,gT,gR)
    P = abs(curr'*diag(gT)*diag(gR)*Z*diag(gT)*curr);
end