clear all;
% code directory
addpath(genpath('Z:\Analysis\users\Projects\Eran')); %Path for all code

%% enter color for surfaces
colors = [255,0,0; 0,102,0];
% enter increment for coloring the surface
increment = 5;
%% Define directories of input images (original image stacks), and analysis directory where heightmaps are saved and output projection images will be saved.
topMainDir='\\phhydra\phhydraB\SD2\2021\Yonit\2021_05\2021_05_06\TIFF_Files\'; % main folder of original files for layer separation
mainDirList= { ... % enter in the following line all the  movie dirs for plotting.
'Pos_6\C0\', ...

};
for i=1:length(mainDirList),mainInDirList{i}=[topMainDir,mainDirList{i}];end

topAnalysisDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\'; % main folder for layer separation results
mainAnalysisDirList= { ... % enter in the following line all the output dirs for plotting.
'2021_05_06_pos6\', ...

};
for i=1:length(mainAnalysisDirList),AnalysisDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end

%% Run over all folders in mainDirList and create projection images, which are saved in the relevant subfolders in topAnalysisDir.
for j=1:length(mainDirList)
    heightDir0=[AnalysisDirList{j},'Layer_Separation\Output\Smooth_Height_Maps_0\'];
    heightDir1=[AnalysisDirList{j},'Layer_Separation\Output\Smooth_Height_Maps_1\'];
    maskDir = [AnalysisDirList{j},'Display\Masks\'];
    inputDir=mainInDirList{j};
    outputDir=[AnalysisDirList{j},'Layer_Separation\Output\Surface_Plots\'];
    mkdir(outputDir);
    cd (heightDir0);
    tpoints = [dir('*.tif*'); dir('*.mat*')];    
    
    % rescaling colors data double (number between 0 and 1)
    newColors = rescale(colors);
    for i = 1:length(tpoints)
        name_end = find(tpoints(i).name == '.');
        thisFileImName = [tpoints(i).name(1:(name_end-1))]
        plotSurfaceOnStack_2_surfaces(thisFileImName, inputDir, heightDir0, heightDir1, maskDir, outputDir, newColors, increment );
    end
    
end