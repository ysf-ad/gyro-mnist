% function predImage(image)
%
% Author: Yousif Al-dakoki
% Date: 12/03/2024
% Course: EECS1011
%
% Function   : predImage
%
% Purpose    : Uses loaded AI model from `trainModel()` to classify an
% image array into a number
%
% Parameters : image - an image array; array of numbers that represent an
% image
%
% Examples of Usage:
%
%    >> predImage(canvas)
% 
%

function prediction = predImage(image)

%load classification model
load("myNet.mat", "net");

%define possible classes
classNames = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

%preprocess image for classification
image = single(image);
image = image * (255 / max(image(:)));

%evaluate array against model, use score vector to identify the predicted
%number 
scores = predict(net,image);
[~, mIndex] = max(scores);
disp(classNames(mIndex))
prediction = classNames(mIndex);
end




