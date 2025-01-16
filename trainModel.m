% function trainModel()
%
% Author: Yousif Al-dakoki
% Date: 12/03/2024
% Course: EECS1011
%
% Function   : trainModel
%
% Purpose    : Train a classification model given the pre-labeled MNIST
% dataset, saves this model in `myNet.mat` for later use
%
% Examples of Usage:
%
%    >> trainModel()
% 
%


function trainModel()
%Majority of code was obtained from matlab docs on the deep learning
%toolkit: https://www.mathworks.com/help/deeplearning/ug/create-simple-deep-learning-network-for-classification.html

%Retrieve MNIST images to a `imageDataStore`
    imds = imageDatastore("DigitsData", ...
        IncludeSubfolders=true, ...
        LabelSource="foldernames");

    %Split testing and training data to validate model
    numTrainFiles = 750;
    [imdsTrain,imdsTest] = splitEachLabel(imds,numTrainFiles,"randomized");
    
    inputSize = [28 28 1];
    numClasses = numel(categories(imds.Labels));
    
    % Define layers for model, more layers were added to decrease loss
    layers = [
        imageInputLayer(inputSize)
        convolution2dLayer(5,32,"Stride",1,"Padding","same")
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(2,"Stride",2)
        convolution2dLayer(5,64,"Stride",1,"Padding","same")
        batchNormalizationLayer
        reluLayer
        maxPooling2dLayer(2,"Stride",2)
        fullyConnectedLayer(128)
        reluLayer
        fullyConnectedLayer(numClasses)
        softmaxLayer];
    
    % Training options
    options = trainingOptions("sgdm", ...
        MaxEpochs=4, ...
        Verbose=false, ...
        Plots="training-progress", ...
        Metrics="accuracy");
    
    %Train the model given data and configuration
    net = trainnet(imdsTrain,layers,"crossentropy",options);

    %Save model for later use in `predImage()`
    myNet = net;
    save myNet;
    
    % Validate against testing data and generate confusion matrix
    XTest = readall(imdsTest);
    TTest = imdsTest.Labels;
    classNames = categories(TTest);
    XTest = cat(4,XTest{:});
    XTest = single(XTest);
    YTest = minibatchpredict(net,XTest);
    YTest = onehotdecode(YTest,classNames,2);

    confusionchart(TTest,YTest)
end