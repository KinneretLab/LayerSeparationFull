clear all;
% code directory
addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra')); %Path for all code
    
%% Define directories of input images (original image stacks), and analysis directory where heightmaps are saved and output projection images will be saved.
topMainDir='\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'; % main folder of original files for layer separation
mainDirList= { ... % enter in the following line all the  movie dirs for plotting.
'2019_02_18_pos3_EXAMPLE\Layer_Separation\Original_Files\', ...
'2019_02_18_pos3_EXAMPLE_2\Layer_Separation\Original_Files\', ...

};
for i=1:length(mainDirList),mainInDirList{i}=[topMainDir,mainDirList{i}];end

topAnalysisDir='\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'; % main folder for layer separation results
mainAnalysisDirList= { ... % enter in the following line all the output dirs for plotting.
'2019_02_18_pos3_EXAMPLE\', ...
'2019_02_18_pos3_EXAMPLE_2\', ...

};
for i=1:length(mainAnalysisDirList),AnalysisDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end

%% Run over all folders in mainDirList and create projection images, which are saved in the relevant subfolders in topAnalysisDir.
for j=1:length(mainDirList)
    heightDir0=[AnalysisDirList{j},'Layer_Separation\Output\Height_Maps_0\'];
    heightDir1=[AnalysisDirList{j},'Layer_Separation\Output\Height_Maps_1\'];
    inputDir=mainInDirList{j};
    outputDir=[AnalysisDirList{j},'Layer_Separation\Output\Surface_Plots\'];
    mkdir(outputDir);
    cd (heightDir0);
    tpoints = dir('*.tif*');    
    
    for i = 1:length(tpoints)
        name_end = find(tpoints(i).name == '.');
        thisFileImName = [tpoints(i).name(3:(name_end-1))]
        plotSurfaceOnStack_2_surfaces(thisFileImName, inputDir, heightDir0, heightDir1, outputDir );
    end
    
end