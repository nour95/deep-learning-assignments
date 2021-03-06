function [gradb, gradW] = ComputeGradients(X,Y,W,b,lambda)
% Computes gradients for the weights W and bias b using forward and
% backward propagation
% W and b and the corresponding returned gradients, gradb and gradW, are on
% 1x2 cell form. 
% X and Y are the images and their labels. Lambda is the regularzation
% parameter.

W1 = W{1}; W2 = W{2};

[P,H] = EvalClassifier(X,W,b);

[~,n] = size(Y);

G = -(Y-P);

db2 = (1/n)*G*ones(n,1);
dW2 = (1/n)*G*H' + 2*lambda*W2;

G = W2'*G;
Ind = H > 0;
G = G.*Ind;

dW1 = (1/n)*G*X' + 2*lambda*W1;
db1 = (1/n)*G*ones(n,1);

gradW = {dW1, dW2};
gradb = {db1, db2};
end

