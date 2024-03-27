function applySmoothMask(thisFileImName, maskDir, rawImageDir, outputDir, sigmaInMicron, xyCalib)
%APPLYSMOOTHMASK Summary of this function goes here
%   Detailed explanation goes here

%   Read mask from file
    try 
        cd (maskDir); thisMask =importdata([thisFileImName,'.tiff']); 
    catch
        try
            cd (maskDir); thisMask =importdata([thisFileImName,'.tif']); 
        catch
            thisMask =[] ;disp (['no mask found ',thisFileImName]); % if no image is found
        end  
    end
    
    %Read raw image from file
    try 
        cd (rawImageDir); thisRawImage =imread([thisFileImName,'.tiff']); 
    catch
        try
            cd (maskDir); thisRawImage =imread([thisFileImName,'.tif']); 
        catch
            thisRawImage =[] ;disp (['no raw image found ',thisFileImName]); % if no image is found
        end  
    end
    sigmaInPixel = sigmaInMicron/ xyCalib;
    blurredMask = imgaussfilt(thisMask,sigmaInPixel);
    blurredMask = im2double(blurredMask);
    thisRawImageDouble= im2double(thisRawImage);
    maskedImage = thisRawImageDouble.* blurredMask;
    rawImageWBlurredMask = im2uint16(maskedImage);
    dest= fullfile(outputDir, [thisFileImName,'.tiff']);
    imwrite(rawImageWBlurredMask, dest);
    


end

