clear all;
% code directory
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
warning('off', 'MATLAB:MKDIR:DirectoryExists');% this supresses warning of existing directory

%% Parameters for surface projections
calibrationXY = 1.28;
calibrationZ = 5;
offset = [-5:1]; % Range of offest from the detected surface to use for projection images. Test a few and choose what range you need.
CLAHE = 0; % Set to 1 if want to normalise intensity in images using CLAHE.
ZLimits = {[],1}; % If there is a disturbing feature in the stack that you would like to leave out of projections, set a limit to what slices can be used from the z-stack.
                  % Leave empty if you don't want to specify any limits.
%% Define directories of input images (original image stacks), and analysis directory where heightmaps are saved and output projection images will be saved.
topMainDir='\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'; % main folder of original files for creating the projected images.
mainDirList= { ... % enter in the following line all the original movie dirs for the projection calculation.

'2019_02_18_pos3_EXAMPLE\Layer_Separation\Original_Files\', ...
'2019_02_18_pos3_EXAMPLE_2\Layer_Separation\Original_Files\', ...

};
for i=1:length(mainDirList),mainInDirList{i}=[topMainDir,mainDirList{i}];end

topAnalysisDir='\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'; % main folder for layer separation results
mainAnalysisDirList= { ... % enter in the following line all the output dirs for projection calculation.

'2019_02_18_pos3_EXAMPLE\', ...
'2019_02_18_pos3_EXAMPLE_2\', ...
};
for i=1:length(mainAnalysisDirList),AnalysisDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end

%% Run over all folders in mainDirList and create projection images, which are saved in the relevant subfolders in topAnalysisDir.
for j=1:length(mainDirList)
    
    heightDir0=[AnalysisDirList{j},'\Layer_Separation\Output\Height_Maps_0\'];
    inputDir=mainInDirList{j}
    maskDir = [AnalysisDirList{j},'\Display\Masks\'];
 
    outputDir0=[AnalysisDirList{j},'\Layer_Separation\Output\Matlab_Projections_0\'];
    smoothHeightDir0 = [AnalysisDirList{j},'\Layer_Separation\Output\Smooth_Height_Maps_0\'];
    fvDir0 = [AnalysisDirList{j},'\Layer_Separation\Output\FV_0\'];
    mkdir(fvDir0);
    mkdir(outputDir0);
    mkdir(smoothHeightDir0);
    cd (heightDir0);
    tpoints = dir('*.tif*');    
    
   
    parfor i = 1:length(tpoints)
        name_end = find(tpoints(i).name == '.');
        thisFileImName = [tpoints(i).name(3:(name_end-1))]
        smoothHM = smoothHeightMap(thisFileImName, maskDir, heightDir0,smoothHeightDir0,fvDir0, calibrationXY, calibrationZ);
        makeFrameProjection_smoothedHM(thisFileImName, inputDir, outputDir0,calibrationXY, offset,smoothHM,CLAHE, zLimits );
    end
    
    heightDir1=[AnalysisDirList{j},'\Layer_Separation\Output\Height_Maps_1\'];
    
    smoothHeightDir1 = [AnalysisDirList{j},'\Layer_Separation\Output\Smooth_Height_Maps_1\'];
    fvDir1 = [AnalysisDirList{j},'\Layer_Separation\Output\FV_1\'];
    outputDir1=[AnalysisDirList{j},'\Layer_Separation\Output\Matlab_Projections_1\'];
    mkdir(fvDir1);
    mkdir(outputDir1);
    mkdir(smoothHeightDir1);
    cd (heightDir1);
    tpoints = dir('*.tif*');
  %  zLimit=64;
    parfor i = 1:length(tpoints)

        name_end = find(tpoints(i).name == '.');
        thisFileImName = [tpoints(i).name(3:(name_end-1))]
        smoothHM = smoothHeightMap(thisFileImName,maskDir, heightDir1,smoothHeightDir1, fvDir1, calibrationXY, calibrationZ);
       makeFrameProjection_smoothedHM(thisFileImName, inputDir, outputDir1,calibrationXY, offset,smoothHM,CLAHE, zLimits);
    end

    cd ([AnalysisDirList{j},'\Layer_Separation\Output']);
    save('ProjectionParameters', 'calibrationXY','calibrationZ','CLAHE','offset') % saves the variables including the analysis parameters used

end
