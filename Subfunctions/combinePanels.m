function [] = combinePanels(inputDir1, inputDir2, Outputdir,FinalFileName)
%This function combines two video with the same name from different directories
% inputDir1 and inputDir2 are the directories of the original video we want
% to combine
% OutputDir is the directory where we want to save the movie
%FinalFileName si the name of the final file

cd (inputDir1);
tpoints = dir('*.tif*');
inds = find(Outputdir == '\');
exp_name = Outputdir((inds(end-1)+1): (inds(end)-1));
v = VideoWriter([Outputdir,'\',FinalFileName,'_' ,exp_name,'.avi']);
v.FrameRate =4;
open(v);
for i = 1:length(tpoints)

    nameEnd = find(tpoints(i).name == '.');
    imOneName = [tpoints(i).name(1:(nameEnd-1))];
    
    try % load image 1
        cd (inputDir1); thisIm1=importdata([imOneName,'.tiff']);
    catch
        try
            cd (inputDir1); thisIm1=importdata([imOneName,'.tif']);
        catch
            try
                cd (inputDir1); thisIm1=importdata([imOneName,'.png']);
            catch
                thisIm1=[];  disp (['no image found ',thisFileImName]); % if no image is found
            end
        end

    end
    
    try % load image 2
        cd (inputDir2); thisIm2=importdata([imOneName,'.tiff']);
    catch
        try
            cd (inputDir2); thisIm2=importdata([imOneName,'.tif']);
        catch
            try
                cd (inputDir2); thisIm2=importdata([imOneName,'.png']);
            catch
                thisIm2=[];  disp (['no image found ',thisFileImName]); % if no image is found
            end
        end

    end
    
    thisImNew = [thisIm1,thisIm2];
    finalIm = mat2gray(thisImNew);
    writeVideo(v,finalIm);
end
close(v);