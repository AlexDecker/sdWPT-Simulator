function iZ=calculateInverseZMatrix(R,C,M)
    syms s;
    Z = s*M+diag(1/s*1./C+R);
    iZ = inv(Z);
end