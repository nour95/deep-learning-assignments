clear all; close all; clc

% Load data 
[trainX,trainY,trainy] = LoadBatch('data_batch_1.mat');
[validX,validY,validy] = LoadBatch('data_batch_2.mat');
[testX, testY, testy] = LoadBatch('test_batch.mat');
labels = load('batches.meta.mat');
label_names = labels.label_names;

%% Prepare data and initialize constants

% Compute mean of training data 
mean_X = mean(trainX, 2); 
std_X = std(trainX, 0, 2);

% Normalize data
trainX = trainX - repmat(mean_X, [1, size(trainX, 2)]);
trainX = trainX ./ repmat(std_X, [1, size(trainX, 2)]);


validX = validX - repmat(mean_X, [1, size(validX, 2)]);
validX = validX ./ repmat(std_X, [1, size(validX, 2)]);

testX = testX - repmat(mean_X, [1, size(testX, 2)]);
testX = testX ./ repmat(std_X, [1, size(testX, 2)]);

% Initialize parameters  
[K, ~] = size(trainY);
[d,n] = size(trainX);
nodes = 50; 
bias = 0;

rng(400)
[W,b] = initParams(nodes, d, K, bias);
[P,H] = EvalClassifier(trainX, W, b);


%% Testing the gradients

rng(400)
[W,b] = initParams(nodes, d, K, bias);
W1 = W{1};
W{1} = W1(:, 1:20);

[grad_b, grad_W] = ComputeGradsNumSlow2(trainX(1:20,1:2), trainY(:,1:2), W, b, 0, 1e-05);
[own_gradb,own_gradw] = ComputeGradients(trainX(1:20,1:2), trainY(:,1:2), W, b);

% Check error of gradient
eps = 1e-10;

errorb1 = norm(grad_b{1}  - own_gradb{1})/max(eps,norm(own_gradb{1})+norm(grad_b{1}));
errorb2 = norm(grad_b{2}  - own_gradb{2})/max(eps,norm(own_gradb{2})+norm(grad_b{2}));

errorW1 = norm(grad_W{1}  - own_gradw{1})/max(eps,norm(own_gradw{1})+norm(grad_W{1}));
errorW2 = norm(grad_W{2}  - own_gradw{2})/max(eps,norm(own_gradw{2})+norm(grad_W{2}));

%% Trying to overfit training data to check gradient

rng(400)
[W,b] = initParams(nodes, d, K, bias);

eta = 0.01; 
epochs = 200; 
cost = zeros(1,epochs);
valcost = zeros(1,epochs); 

for i = 1:epochs
    [gradb, gradW] = ComputeGradients(trainX(:,1:100), trainY(:,1:100), W, b);
    W{1} = W{1} - eta*gradW{1};
    W{2} = W{2} - eta*gradW{2};
    b{1} = b{1} - eta*gradb{1};
    b{2} = b{2} - eta*gradb{2};
    cost(i) = ComputeCost(trainX(:,1:100), trainY(:,1:100), W, b, 0);
    valcost(i) = ComputeCost(validX, validY, W, b, 0);
end

plot((1:1:epochs),cost, (1:1:epochs), valcost, 'LineWidth', 1.5)
title('Overfitting network to check gradient')
legend('Training data', 'Validation data')
xlabel('Epochs')
ylabel('Cost function')
set(gca,'FontSize',20)
set(gcf, 'Position',  [100, 100, 1000, 1000]);

%% Training network using cyclical learning rates

rng(400)
[W,b] = initParams(nodes, d, K, bias);
[~, n] = size(trainX);

eta_min = 1e-5; eta_max = 1e-1; ns = 500;
nbatch = 100; lambda = 0.01;

% Generating values for eta
etaup = eta_min + linspace(0, eta_max - eta_min, ns); % increasing part
etadown = eta_max - linspace(0, eta_max - eta_min, ns); % decreasing part
eta = [etaup, etadown];

W_curr = W; b_curr = b;


cost_train = zeros(11,1); loss_train = zeros(11,1); acc_train = zeros(11,1);
cost_valid = zeros(11,1); loss_valid = zeros(11,1); acc_valid = zeros(11,1);


plotidx = 1;

for t = 0:2*ns-1
    % Generating batch
    j = mod(t,n/nbatch) + 1; 
    j_start = (j-1)*nbatch + 1;
    j_end = j*nbatch;
    inds = j_start:j_end;
    Xbatch = trainX(:, inds); 
    Ybatch = trainY(:, inds);
    
    [gradb, gradW] = ComputeGradients(Xbatch,Ybatch,W_curr,b_curr,lambda);
    
    % Updating b and W 
    b_curr{1} = b_curr{1} - eta(t+1)*gradb{1};
    b_curr{2} = b_curr{2} - eta(t+1)*gradb{2};
    
    W_curr{1} = W_curr{1} - eta(t+1)*gradW{1};
    W_curr{2} = W_curr{2} - eta(t+1)*gradW{2};
    
    % Recording values every 100th iteration to plot for sanity check
    if mod(t,100) == 0        
    [costtrain, losstrain] = ComputeCost(trainX,trainY, W_curr, b_curr, lambda); 
    [costvalid, lossvalid] = ComputeCost(validX,validY, W_curr, b_curr, lambda);

    cost_train(plotidx) = costtrain; loss_train(plotidx) = losstrain;
    cost_valid(plotidx) = costvalid; loss_valid(plotidx) = lossvalid;
    
    acc_train(plotidx) = ComputeAccuracy(trainX,trainy, W, b); 
    acc_valid(plotidx) = ComputeAccuracy(validX,validy, W, b); 
    
          
    plotidx = plotidx + 1;
    end
    
end 

[costtrain, losstrain] = ComputeCost(trainX,trainY, W_curr, b_curr, lambda); 
[costvalid, lossvalid] = ComputeCost(validX,validY, W_curr, b_curr, lambda);

cost_train(plotidx) = costtrain; loss_train(plotidx) = losstrain;
cost_valid(plotidx) = costvalid; loss_valid(plotidx) = lossvalid; 

acc_train(plotidx) = ComputeAccuracy(trainX,trainy, W, b); 
acc_valid(plotidx) = ComputeAccuracy(validX,validy, W, b); 

% Figures of cost, loss and accuracy
figure
plot(0:100:2*ns,cost_train, 0:100:2*ns,cost_valid, 'LineWidth', 1.5)
xlabel('update step')
ylabel('cost')
ylim([0,4])
legend('training', 'validation')
title('Cost plot')
set(gca,'FontSize',20)
set(gcf, 'Position',  [100, 100, 1000, 1000]);

figure 
plot(0:100:2*ns,loss_train, 0:100:2*ns,loss_valid, 'LineWidth', 1.5)
xlabel('update step')
ylabel('loss')
ylim([0,4])
legend('training', 'validation')
title('Loss plot')
set(gca,'FontSize',20)
set(gcf, 'Position',  [100, 100, 1000, 1000]);

figure 
plot(0:100:2*ns, acc_train, 0:100:2*ns, acc_valid, 'LineWidth', 1.5)
xlabel('update step')
ylabel('accuracy')
ylim([0,4])
legend('training', 'validation')
title('Accuracy plot')
set(gca,'FontSize',20)
set(gcf, 'Position',  [100, 100, 1000, 1000]);


%% Performing mini-batch step

% Setting minibatch parameters
lambda = 0.1;
n_epochs = 40;
n_batch = 100;
eta = 0.001;

GDparams.nbatch = n_batch;
GDparams.eta = eta;
GDparams.nepochs = n_epochs;

% Mini-batch step
[Wstar, bstar, trainloss, valloss] = MiniBatchGD(trainX, trainY, validX, validY, ...
    GDparams, W, b, lambda);

% Computing accuracies
acc_train = ComputeAccuracy(trainX,trainy, Wstar,bstar);
acc_val = ComputeAccuracy(validX,validy, Wstar, bstar);
acc_test = ComputeAccuracy(testX,testy, Wstar, bstar);

%% Plotting cost function

epoch = (1:1:n_epochs);
plot(epoch, trainloss, epoch, valloss, 'LineWidth', 1.5)
title({'Training and validation loss for each epoch',...
    ['lambda = ' num2str(lambda)],...
    ['nbatch = ' num2str(n_batch)], ['eta = ' num2str(eta)],...
    ['nepochs = ' num2str(n_epochs)]})
xlabel('Epochs')
ylabel('Loss')
legend('Training loss', 'Validation loss', 'FontSize', 20)
set(gca,'FontSize',20)
set(gcf, 'Position',  [100, 100, 1000, 1000]);
filename = sprintf('lambda%0.5gnepochs%0.5gnbatch%0.5geta%0.5g.png', lambda, n_epochs, n_batch,eta);
% saveas(gcf,filename)

%% Displaying the learnt weight matrix

% Visualize templates
for i = 1:10
    im = reshape(Wstar(i,:), 32, 32, 3);
    s_im{i} = (im - min(im(:))) / (max(im(:)) - min(im(:)));
    s_im{i} = permute(s_im{i}, [2, 1, 3]);
    
end

% Assembling images
for i = 1:10
    subplot(2,5,i)
    imagesc(s_im{i})
    set(gca,'XTick',[], 'YTick', [])
    title(label_names{i})
end

set(gcf, 'Position',  [100, 100, 2000, 500]);
filename = sprintf('weight_lambda%0.5gnepochs%0.5gnbatch%0.5geta%0.5g.png', lambda, n_epochs, n_batch,eta);
sgtitle({'Learnt weight matrix for each class',...
    ['lambda = ' num2str(lambda)],...
    ['nbatch = ' num2str(n_batch)], ['eta = ' num2str(eta)],...
    ['nepochs = ' num2str(n_epochs)]})
% saveas(gcf,filename)


    


