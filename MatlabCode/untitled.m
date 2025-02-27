beta = smallestEigenVector(d)

A = beta([1 2 3; 2 4 5; 3 5 6]); %make symmetric
dA = det(A);

if dA < 0
    A = -A;
    beta = -beta;
    dA = -dA; %Compensate for -A.
end

V = -0.5*(A\beta(7:9)); %hard iron offset

function beta = smallestEigenVector(d)

% Use SVD to compute the eigenvalues and eigenvectors.
[~,~,V] = svd(d,'econ');
beta = V(:,end); % Solution has smallest eigenvalue.

% A more compact but less accurate approach. 

% dtd = d.' * d;
%   
% [evc, evlmtx] = schur(dtd);
% 
% eigvals = diag(evlmtx);
% [~, idx] = min(eigvals);
% 
% beta = evc(:,idx); % Solution has smallest eigenvalue.
end