
% function drawGuess()
%
% Author: Yousif Al-dakoki
% Date: 12/03/2024
% Course: EECS1011
%
% Function   : drawGuess
%
% Purpose    : Initializes and utilizes various input devices to display a
% live drawing canvas, evaluates the drawn canvas to classify an image
% based off of an MNIST machine learning model.
%
% Examples of Usage:
%
%    >> drawGuess()
% 
%

function drawGuess()

%import OLED library https://github.com/AradhyaC/MATLAB-OLED-Lib
addpath(genpath('oled'))

% Initialize Arduino and I2C interface
disp('Setting up Arduino...');
a = arduino("COM3", "Nano3", "Libraries", "I2C");

%Initialize OLED
disp("Initializing OLED");
[oled,a] = Initialize_Oled(a,0);


% Initialize Accelerometer
disp("Initializing Accelerometer");
accel = device(a, "I2CAddress", "0x19");

% Initialize registries from arduino grove docs
writeRegister(accel, hex2dec('20'), hex2dec('57')); % CTRL_REG1: Enable X/Y/Z, ODR = 100 Hz
writeRegister(accel, hex2dec('23'), hex2dec('00')); % CTRL_REG4: +/-2g full scale, high-res disabled

% Initialize Accelerometer
disp("Initializing Button");
buttonPin = "D2";
configurePin(a, buttonPin, "DigitalInput");

% Calibration Phase to set the resting position
disp('Calibrating accelerometer... board should be flat at rest');
sampleSize = 10; %number of calibration samples
calibrationData = zeros(sampleSize, 3);

for i = 1:size(calibrationData, 1)
    calibrationData(i, :) = readAccelerometer(accel); 
end
bias = mean(calibrationData, 1); % Compute bias
disp(['Calibration complete. Bias: X=', num2str(bias(1)), ...
      ', Y=', num2str(bias(2)), ', Z=', num2str(bias(3))]);

% Initialize 28x28 canvas to store brush positions
gridSize = 28; 
canvas = zeros(gridSize, gridSize); 

% Scale accelerometer readings to canvas dimensions
xSense = 128; 
ySense = 64; 
xScale = xSense / gridSize / 10; % Reduced scaling factor for X
yScale = ySense / gridSize / 10; % Reduced scaling factor for Y


featheringStrength = 1; % How strong the stroke should be before feathering [0, 1]

% Initial brush position in the center of the grid
xBrush = gridSize / 2; 
yBrush = gridSize / 2; 

% Visualization setup
figure;
hold on;
hCanvas = imagesc(canvas); % Visualize the canvas as an intensity scaled image
colormap('gray');
axis equal;
axis([1 gridSize 1 gridSize]);
set(gca, 'YDir', 'reverse'); % Reverse Y-axis for proper orientation
title('28x28 Drawing Grid and Exact Position');
xlabel('X Grid Position');
ylabel('Y Grid Position');
grid on;

% Create exact position marker
hMarker = plot(xBrush, yBrush, 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'r');

% Add variables for tracking bottom right gesture - to trigger prediction
cornerTimeStart = []; 
cornerTimeThreshold = 5; 
bottomRightRegion = [gridSize-2, gridSize-2, gridSize, gridSize]; % Define trigger region


% Main drawing loop
disp('Starting drawing...');
while true
    % Read accelerometer data
    accelData = readAccelerometer(accel) - bias; % Remove bias (from calibration phase)
    
    % Apply movement threshold
    movementThreshold = 0.02;
    accelData(abs(accelData) < movementThreshold) = 0;

    % Update exact brush position
    xBrush = xBrush - accelData(1) / xScale; % Update X position
    yBrush = yBrush - accelData(2) / yScale; % Update Y position (Y-axis reversed)

    % Clamp brush position to grid boundaries
    xBrush = max(1, min(gridSize, xBrush)); 
    yBrush = max(1, min(gridSize, yBrush)); 


    % Check if the cursor is in the bottom-right trigger region
    inBottomRight = xBrush >= bottomRightRegion(1) && xBrush <= bottomRightRegion(3) && ...
                    yBrush >= bottomRightRegion(2) && yBrush <= bottomRightRegion(4);

    if inBottomRight
        if isempty(cornerTimeStart) % Start timer if not already started
            cornerTimeStart = tic;
        elseif toc(cornerTimeStart) >= cornerTimeThreshold % Trigger prediction after the threshold is reached
            disp("Predicting digit...");
            
            % Use the canvas as input for prediction
            prediction = predImage(canvas)
            disp(['Predicted Label: ', char(prediction)]);

            % use oled library to write predicted number on screen
            drawNumber = char(prediction);
            display_write(oled, 1, 1, 1, 128, 1, 8, 2, drawNumber)
            
            cornerTimeStart = [];
        end
    else
        cornerTimeStart = [];
    end


    % Check button state and draw on canvas if button is not held
    isButtonPressed = readDigitalPin(a, buttonPin);
    if ~isButtonPressed
        
        % Create feathering mask
        featheringMask = zeros(gridSize);
        
        % Find nearest brush XY coordinate
        xBrushRounded = round(xBrush);
        yBrushRounded = round(yBrush);
        
        % Apply intensities using a loop
        for i = -1:1
            for j = -1:1
                % Compute neighbor pixels
                xNeighbor = xBrushRounded + j;
                yNeighbor = yBrushRounded + i;
        
                % Check for canvas edges
                if xNeighbor >= 1 && xNeighbor <= gridSize && ...
                   yNeighbor >= 1 && yNeighbor <= gridSize
                    % Determine intensity based on the position
                    if i == 0 && j == 0
                        intensity = featheringStrength; % Center
                    elseif abs(i) + abs(j) == 1
                        intensity = featheringStrength / 5; % Edges
                    else
                        intensity = featheringStrength / 7; % Corners
                    end
        
                    % Apply intensity to the feathering mask
                    featheringMask(yNeighbor, xNeighbor) = intensity;
                end
            end
        end
        
        % Update the canvas (capped at 1)
        canvas = min(1, canvas + featheringMask);



    end

    % Update visualization
    set(hCanvas, 'CData', canvas);
    set(hMarker, 'XData', xBrush, 'YData', yBrush);
    drawnow;

end
end

% --- Helper function to read accelerometer data ---
% function readAccelerometer(accel)
%
% !!!!Author: Yousif Al-dakoki & CHATGPT from OpenAI!!!!
% Date: 12/03/2024
% Course: EECS1011
%
% Function   : readAccelerometer
%
% Purpose    : returns live accelerometer data given the accelerometer
% arduino device object

% Parameters: accel - device object for accelerometer
%
% Examples of Usage:
%
%    >> readAccelerometer(accelObject)
% 
%
    % GENERATED FROM CHATGPT given grove docs and prompt "how to read xyz
    % data from this sensor?"
function rawData = readAccelerometer(accel)
    % Read 6 consecutive bytes from the accelerometer (X, Y, Z low and high)
    rawBytes = zeros(1, 6, 'uint8');
    for i = 0:5
        rawBytes(i + 1) = readRegister(accel, hex2dec('28') + i, 'uint8');
    end

    % Combine the bytes into signed 16-bit integers
    rawData = typecast(uint8(rawBytes), 'int16');

    % Normalize and return as a row vector
    rawData = double(rawData(:))' / 16384;
end

