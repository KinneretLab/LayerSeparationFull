% code directory
clear all;
addpath(genpath('\\phhydra\data-new\phkinnerets\Lab\CODE\Hydra')); %Path for all code
%% Parameters for creating cost image
% Calibration for z and xy of image stacks:
z_scale = 3; % um/pixel
% xy_scale = 0.99; % um/pixel for 10x lens with 1.6x magnification
% xy_scale = 1.28; % um/pixel for 10x lens with 1x magnification
xy_scale = 0.57 ;% um/pixel for lightsheet
outputZScale = 1; % Default: 1, can change if you want to downsample.
use_CLAHE = 1;  % Default: 1, set to 0 if don't want to use CLAHE to normalise gradients.
norm_window = 4; % Default: 4. norm_window*blocksigma is the length scale for normalisation of gradient using CLAHE. 
                 % Decreasing can sometimes help prevent jumps between surfaces.
saveDiffused = 0; % Set to one to save diffused images, and to zero to not save.                 

%% Define directories of original images to run over folders and create cost images (original images should be 3D image stacks saved as separate timepoints). 


topMainDir='\\phhydra\phhydraB\LS\Yonit\2019_10_07\Group1\'; % main folder of original files for layer separation
mainDirList= { ... % enter in the following line all the  movie dirs for cost calculation.
'View1\C1\', ...
'View2\C1\', ...
'View3\C1\', ...
'View4\C1\', ...
};

for i=1:length(mainDirList),mainInDirList{i}=[topMainDir,mainDirList{i}];end

topAnalysisDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\Lightsheet\'; % main folder for layer separation results
mainAnalysisDirList= { ... % enter in the following line all the output dirs for cost calculation.
%'2019_02_18_pos3\', ...
'2019_10_07_pos1\View1\', ...
'2019_10_07_pos1\View2\', ...
'2019_10_07_pos1\View3\', ...
'2019_10_07_pos1\View4\', ...
};
for i=1:length(mainAnalysisDirList),AnalysisDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end

%% Run over all folders in mainDirList and create cost images, which are saved in matching subfolders in topAnalysisDir.
for i=1:length(mainDirList)
    analysisDir=[AnalysisDirList{i},'\Layer_Separation\'];
    inputDir=mainInDirList{i};
    maskDir = [AnalysisDirList{i},'\Display\Masks\'];
    
    % Directories for saving diffused and cost images.
    dirGradient=[analysisDir,'\Gradient_1Layer'];
    dirDiffused=[analysisDir,'\Diffused'];
     
    % make all the needed directories
    mkdir(analysisDir);
    cd(analysisDir); mkdir(dirGradient);
    if saveDiffused ==1
        mkdir(dirDiffused);
    end
    
    save('CostParameters', 'z_scale','xy_scale','use_CLAHE','norm_window') % saves the variables including the analysis parameters used

    cd (inputDir);
    tpoints = dir('*tif*');
   % tpoints = dir('*C0*.tif*');
    
     parfor j = 1:length(tpoints)
        name_end = find(tpoints(j).name == '.');
        thisFileImName = [tpoints(j).name(1:(name_end-1))]
        CreateCost_Single_Layer(thisFileImName, inputDir, analysisDir,maskDir, z_scale,xy_scale,outputZScale, use_CLAHE, norm_window, saveDiffused);
        
    end
    
      
end


   
    
    


   