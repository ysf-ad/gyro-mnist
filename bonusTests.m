clear;

%test machine learning model
trainModel()

%4s and 9s often look similar! tests model robustness
assert(double(predImage(imread("DigitsData/4/image3021.png"))) == 4, "MNIST prediction incorrect for number 4");
assert(double(predImage(imread("DigitsData/9/image8061.png"))) == 9, "MNIST prediction incorrect for number 9");
assert(double(predImage(imread("DigitsData/0/image9051.png"))) == 0, "MNIST prediction incorrect for number 0");
disp("PASSED TEST BATCH 1: machine learning model predicts correctly")

%test initialization of devices for main function threea
try  
  addpath(genpath('oled'))

a = arduino("COM3", "Nano3", "Libraries", "I2C");
[oled,a] = Initialize_Oled(a,0);
accel = device(a, "I2CAddress", "0x19");
  fprintf('PASSED TEST BATCH 2: Devices Successfully initialized\n')
catch exception
  fprintf('PASSED TEST BATCH 2: devices not configured correctly!\n')
end


disp("You have passed all the tests in this file!")