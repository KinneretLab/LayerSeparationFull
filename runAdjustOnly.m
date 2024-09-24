% code directory
% clear all;
% addpath(genpath('\\phhydra\phhydraB\Analysis\users\Noam\PipelineCodes')); %Path for all code
% warning('off', 'MATLAB:MKDIR:DirectoryExists');% this supresses warning of existing directory

%% Define directories of original images to run over folders and create cost images (original images should be 3D image stacks saved as separate timepoints).

%% Define mainDirList

topAnalysisDir='Z:\Analysis\users\Liora\Movie_Analysis\Airyscan\2024_09_13\20xairzoom_1_1_SR680_processed_overnight\'; % main folder for layer separation results
mainAnalysisDirList= { ... % enter in the following line all the output dirs for cost calculation.

'\View1\', ...
'\view2\', ...
'\view3\', ...
'\view4\', ...
'\view5\', ...
'\view6\', ...
'\view7\', ...
'\view8\', ...
'\view9\', ...
'\view10\', ...

};
for i=1:length(mainAnalysisDirList),AnalysisDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end

%% Parallel processing
% Set the number of parallel workers for performing tasks. The default is
% the number of cores you have on your computer, but if you get an 'out of
% memory' error, try setting to fewer.
numPar = 6;

%% Parameters for creating cost image
% Calibration for z and xy of image stacks:
z_scale = 3; % um/pixel
xy_scale = 1.04; % um/pixel for 10x lens with 1x magnification, 0.99 for 10x lens with 1.6x magnification, 0.65 for 20x lens with 1x magnification, 0.57 for lightsheet
outputZScale = 1; % Default: 1, can change if you want to downsample.
use_CLAHE = 1;  % Default: 1, set to 0 if don't want to use CLAHE to normalise gradients.
norm_window = 4; % Default: 4. norm_window*blocksigma is the length scale for normalisation of gradient using CLAHE.
% Decreasing can sometimes help prevent jumps between surfaces.
saveDiffused = 0; % Set to one to save diffused images, and to zero to not save.
numLayers = 2 ; % Set to 2 for two layers (default), and set to 1 for single layer.


%% Parameters for Adjust Images
inputFolderNameFibers = 'Orientation_Analysis\Raw Images';
outputFolderNameFibers = 'Orientation_Analysis\AdjustedImages';

inputFolderNameCells = 'Cells\Raw Cortices';
outputFolderNameCells = 'Cells\Adjusted_cortices';

saveFormat = 2; % Choose 1 for PNG, 2 for TIFF
sigma = 0; % Kernel size for gaussian blur, set to zero if no blur needed.
sigmaForMaskSmoothingInMicron = 2.6;
saveStretched = 0; % Set to 1 if you want to save the images separately with stretched histograms (relevant mostly for images from SD2).
toNormalize = 1; % Normalize  histogram between 0 and 2^16-1 before CLAHE (suitable for older spinning disk) if signal is not too weak.
multiplicationFactor = 0; % For images from the up&under system, multiply by a constant factor. Default is 10. Set to 0 if not relevant.

%% Parameters for combining video
CombineParameter=0; %put 0 if you dont want to combine
FinalName ='Cells_and_Fibers'; %define the name of the combined video
%% Frames to the layer seperation on
framesList = cell(1,length(mainAnalysisDirList));
% framesList = {336:371}; % Enter specific frame ranges in this format if you

parpool(numPar);
%% Run AdjustImages
for j=1:length(AnalysisDirList)
    maskDir = [AnalysisDirList{i},'\Display\Masks\'];
    
    inputDirFibers=[AnalysisDirList{j},inputFolderNameFibers];
    outputDirFibers=[AnalysisDirList{j},outputFolderNameFibers];
    mkdir(outputDirFibers);
    
    inputDirCells=[AnalysisDirList{j},inputFolderNameCells];
    outputDirCells=[AnalysisDirList{j},outputFolderNameCells];
    mkdir(outputDirCells);
  
    cd (inputDirCells);
    tpoints = dir('*.tif*');    
    
    parfor i = 1:length(tpoints)

        name_end = find(tpoints(i).name == '.');
        thisFileImName = [tpoints(i).name(1:(name_end-1))]
        applySmoothMask(thisFileImName, maskDir, inputDirFibers, inputDirFibers, sigmaForMaskSmoothingInMicron, xy_scale);
        applySmoothMask(thisFileImName, maskDir, inputDirCells, inputDirCells, sigmaForMaskSmoothingInMicron, xy_scale);

        adjustImages(thisFileImName, inputDirFibers, outputDirFibers, xy_scale,saveFormat,sigma,saveStretched, toNormalize,multiplicationFactor);
        adjustImages(thisFileImName, inputDirCells, outputDirCells, xy_scale,saveFormat,sigma,saveStretched, toNormalize,multiplicationFactor);
    end
    
    if CombineParameter==1
     combinePanels(outputDirCells, outputDirFibers, AnalysisDirList{j}, FinalName);
    end
end
%% Combine after adjust
if CombineParameter==1
    for j=1:length(AnalysisDirList)
        
        outputDirFibers=[AnalysisDirList{j},outputFolderNameFibers];
        
        outputDirCells=[AnalysisDirList{j},outputFolderNameCells];
        
        if CombineParameter==1
            combinePanels(outputDirCells, outputDirFibers, AnalysisDirList{j}, FinalName);
        end
    end
end
%% Utility Functions
function result=isInFramesList(thisFileImName, framesForDir)
    if isempty(framesForDir)
        result=true;
        return;
    end
    parts = strsplit(thisFileImName, '_');
    frameNumber=str2double(parts{end});
    if ismember(frameNumber, framesForDir)
        result=true;
    else
        result=false;
    end
end