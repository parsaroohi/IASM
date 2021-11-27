clc
clear
close all
% read image
[Image,cmap]= imread('C:\Users\ASUS\Desktop\boat.png');
subplot(2,2,1), imshow(Image,cmap)
title('original image');

% add noise
Noise_Level=input('How much noise do you want to add? (eg input 0.1 for 10%):');
Noisy_image = imnoise(Image,'salt & pepper',Noise_Level);
subplot(2,2,2), imshow(Noisy_image,cmap)
title('Corrupted with salt and pepper noise');

% 3-by-3 median filter
output_med = medfilt2(Noisy_image,[3 3]);
subplot(2,2,3), imshow(output_med,cmap)
title('Image filtered by Adaptive Median filter 3x3');

% IMF: noise detection
originalImage = Noisy_image;
windowWidth = 3;
halfWidth = floor(windowWidth/2);
[width,height]= size(originalImage);
flags = zeros(width,height);
for i= windowWidth:width-windowWidth
    for j= windowWidth:height-windowWidth
        % step 1
        thisWindow= originalImage(i-halfWidth : i + halfWidth, j-halfWidth : j + halfWidth);
        sortedWindow = sortValuesInWindow(thisWindow);
        [minVal, maxVal, medVal] = thisWindowValues(sortedWindow);
        % step 2
        if medVal == minVal || medVal == maxVal
            % step 4
            [minValue,maxValue,newThisWindow] = newWindow(originalImage, i, j);
            % step 5
            flags = checkPixels(newThisWindow,minValue,maxValue,flags,i,j);
        else
            % step 3
            flags = checkPrevWindow(flags,thisWindow,minVal, maxVal,i,j);
        end
    end
end

% IMF: noise removal
temp_window = originalImage;
for i= windowWidth:width-windowWidth
    for j= windowWidth:height-windowWidth
        % step 1
        thisWindow= originalImage(i-halfWidth : i + halfWidth, j-halfWidth : j + halfWidth);
        counter = numberOfOneFlags(flags,i,j);
        if counter ==9
            % step 3
            temp_window = changeElements(temp_window,i,j);
        else
            % step 2
            medOfNoiseFreePixels=medianValNoiseFree(thisWindow,flags,i,j);
            temp_window = changeElementsWithMed(medOfNoiseFreePixels,temp_window,flags,i,j);
        end
    end
end

% finally show the image which noises were reomved by IMF algorithm
subplot(2,2,4), imshow(temp_window,cmap)
title('Image filtered by Improved Median filter');

% funcs for noise detection
function sortedWindow = sortValuesInWindow(thisWindow)
    sortedWindow = sort(thisWindow, 2);
    sortedWindow = sort(sortedWindow, 'ascend');
    a=sortedWindow;
    b = a(1,end);
    c = a(2,2);
    d = a(end,1);
    a(1,end)=0;
    a(2,2)=0;
    a(end,1)=0;
    newmat=[b;c;d];
    newmat = sort(newmat,'ascend');
    a(1,end)=newmat(1);
    a(2,2)=newmat(2);
    a(end,1)=newmat(3);
    sortedWindow=a;
end

function [minVal, maxVal, medVal] = thisWindowValues(sortedWindow)
    minVal= sortedWindow(1);
    maxVal= sortedWindow(end);
    medVal= sortedWindow(2,2);
end

function [minValue,maxValue,thisWindow] = newWindow(originalImage, i, j)
    windowWidth = 5;
    halfWidth = floor(windowWidth/2);
    thisWindow=originalImage(i-halfWidth : i + halfWidth, j-halfWidth : j + halfWidth);
    sort5x5 = sort5x5Values(thisWindow);
    sortedValuesInWindow = sort5x5Values(sort5x5);
    % max min median
    minValue = sortedValuesInWindow(1);
    maxValue = sortedValuesInWindow(end);
    % medianValue = sortedValuesInWindow(3,3);
end

function sort5x5 = sort5x5Values(tempWindow)
    tempWindow_1 = sort(tempWindow(1,:),2);
    tempWindow_2 = sort(tempWindow(1,:),2,'descend');
    tempWindow_3 = sort(tempWindow(3,:),2);
    tempWindow_4 = sort(tempWindow(3,:),2,'descend');
    tempWindow_5 = sort(tempWindow(5,:),2);
    tempWindow_final = [tempWindow_1;tempWindow_2;tempWindow_3;tempWindow_4;tempWindow_5];
    tempWindow_final = sort(tempWindow_final,'ascend');
    sort5x5 = tempWindow_final;
end

function flags = checkPixels(newThisWindow,minVal,maxVal,flags,i,j)
    i=i-2;
    j=j-2;
    for ii=1:5
        for jj=1:5
           if newThisWindow(ii,jj) == minVal || newThisWindow(ii,jj) == maxVal
               flags(i+ii-1,j+jj-1)=1;
           else
               flags(i+ii-1,j+jj-1)=0;
           end
        end
    end
end

function flags = checkPrevWindow(flags,thisWindow,minVal, maxVal,i,j)
    i=i-1;
    j=j-1;
    for ii=1:3
        for jj=1:3
            if thisWindow(ii,jj)==minVal || thisWindow(ii,jj)==maxVal
               flags(i+ii-1,j+jj-1)=1;
            else
               flags(i+ii-1,j+jj-1)=0;
            end
        end
    end
end
%-------------------------------------------------------------------------------
% funcs for noise removal
function counter = numberOfOneFlags(flags,i,j)
    i=i-1;
    j=j-1;
    counter=0;
    for ii=1:3
        for jj=1:3
            if flags(i+ii-1,j+jj-1)==1
                counter = counter + 1;
            else
                counter = counter - 1;
            end
        end
    end
end

function temp_window = changeElements(temp_window,i,j)
    i=i-1;
    j=j-1;
    for ii=1:3
        for jj=1:3
            if jj==1
                temp_window(i+ii-1,j+jj-1)=temp_window(i+ii-1,j+jj-1);
            else
                temp_window(i+ii-1,j+jj-1) = temp_window(i+ii-1,j+jj-2);
            end
        end
    end
end

function medOfNoiseFreePixels=medianValNoiseFree(thisWindow,flags,i,j)
    i=i-1; 
    j=j-1;
    tempWindow=zeros(3,3);
    for ii=1:3
        for jj=1:3
            if flags(i+ii-1,j+jj-1)==0
                tempWindow(ii,jj)=thisWindow(ii,jj);
            end
        end
    end
    tempWindow_2=nonzeros(tempWindow);
    tempWindow_2=sort(tempWindow_2,'ascend');
    len = length(tempWindow_2);
    if len == 0
        medOfNoiseFreePixels = 0;
    else 
        if rem(len,2)==0
            middle_1 = len/2;
            middle_2 = middle_1 + 1;
            middle_3 = (tempWindow_2(middle_1,1) + tempWindow_2(middle_2,1)) / 2;
            medOfNoiseFreePixels = floor(middle_3);
        else
            middle = ceil(len/2);
            medOfNoiseFreePixels = tempWindow_2(middle,1);
        end
    end
end

function temp_window = changeElementsWithMed(medOfNoiseFreePixels,temp_window,flags,i,j)
    i=i-1;
    j=j-1;
    for ii=1:3
        for jj=1:3
            if flags(i+ii-1,j+jj-1)==1
               temp_window(i+ii-1,j+jj-1) = medOfNoiseFreePixels; 
            end
        end
    end
end


