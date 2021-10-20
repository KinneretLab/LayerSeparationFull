% code directory
clear all;
addpath(genpath('Z:\Analysis\users\Yonit\MatlabCodes\GroupCodes\July2021')); %Path for all code
warning('off', 'MATLAB:MKDIR:DirectoryExists');% this supresses warning of existing directory

%% Define directories of original images to run over folders and create cost images (original images should be 3D image stacks saved as separate timepoints).

topMainDir='\\phhydra\TempData\SD2\Yonit\2021_08\2021_08_19\TIFF_Files\'; % main folder of original files for layer separation
mainDirList= { ... % enter in the following line all the  movie dirs for cost calculation.
    
'Pos_1\C0\',...

};
for i=1:length(mainDirList),mainInDirList{i}=[topMainDir,mainDirList{i}];end

topAnalysisDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\TestSet\'; % main folder for layer separation results
mainAnalysisDirList= { ... % enter in the following line all the output dirs for cost calculation.
    
'2021_08_19_pos1\', ...

};
for i=1:length(mainAnalysisDirList),AnalysisDirList{i}=[topAnalysisDir,mainAnalysisDirList{i}];end

%% define path for dir (for Java codes)
scriptDir = regexprep(mfilename('fullpath'), '\\\w*$', '');
fijiExe = "%HOMEDRIVE%%HOMEPATH%\\Fiji.app\\ImageJ-win64.exe --headless -macro";

%% Parallel processing
% Set the number of parallel workers for performing tasks. The default is
% the number of cores you have on your computer, but if you get an 'out of
% memory' error, try setting to fewer.
numPar = 6;

%% Parameters for creating cost image
% Calibration for z and xy of image stacks:
z_scale = 3; % um/pixel
xy_scale = 0.52; % um/pixel for 10x lens with 1x magnification, 0.99 for 10x lens with 1.6x magnification, 0.65 for 20x lens with 1x magnification, 0.57 for lightsheet
outputZScale = 1; % Default: 1, can change if you want to downsample.
use_CLAHE = 1;  % Default: 1, set to 0 if don't want to use CLAHE to normalise gradients.
norm_window = 4; % Default: 4. norm_window*blocksigma is the length scale for normalisation of gradient using CLAHE.
% Decreasing can sometimes help prevent jumps between surfaces.
saveDiffused = 0; % Set to one to save diffused images, and to zero to not save.
numLayers = 2 ; % Set to 2 for two layers (default), and set to 1 for single layer.

%% Parameters for layer separation
rescalexy = 0.5; % Rescaling when running min cost algorithm. 0.5 for xy significantly speeds calculation, and also helps limit the maximum slope of the detected surface (see maxdz).
rescalez = 1; % Rescaling when running min cost algorithm. Not recommended for z direction so performance is not compromised.
display = 0; % Set to 1 to display results in ImageJ, and 0 to prevent display. Not sure if this is relevant when running from command line. 
min = 15; % Minimum distance in um between surfaces to use for detection. 
interval = 30; % Range for distance between layeres for detection in um (so minimum distance will be min, and maximum will be min+interval).

% The following are calculated from the parameters above and typically don't need to be chagned:
maxdz = round((3/z_scale)+0.49); % This is the maximum allowed step in z between neighbouring pixels in xy (after rescaling according to above). This was found to be optimal.
min=(round(min*rescalez/z_scale)); % Convert minimum distance from um to pixels
max = min+(round(interval*rescalez/z_scale)); % Calculate maximum distance and convert from um to pixels.

%% Parameters for surface projections
offset = [-7:3]; % Range of offest from the detected surface to use for projection images. Test a few and choose what range you need.
CLAHE = 0; % Set to 1 if want to normalise intensity in images using CLAHE. DEFAULT IS 0.
zLimits = {[],[]}; % If there is a disturbing feature in the stack that you would like to leave out of projections, set a limit to what slices can be used from the z-stack.
% Leave empty if you don't want to specify any limits.

%% Parameters for creating 2D final projected image
% These are better to set after you have created the matlab projections and
% looked at them to choose the relevant planes. If not run in batch mode, code will ask you for your
% input as to whether to run this section:

planesCortices = [7:10]; % Planes out of matlab projection stack 0 that will be used to create final 2D image (max projection of these planes).
planesFibres = [7:9]; % Planes out of matlab projection stack 1 that will be used to create final 2D image (max projection of these planes).
layerCortices = 1; % Numbering of cortices layer by layer separation algorithm. Leave empty if not relevant.
layerFibres = 0; % Numbering of cortices layer by layer separation algorithm.  Leave empty if not relevant.


%% Run over all folders in mainDirList and create cost images, which are saved in matching subfolders in topAnalysisDir.
for i=1:length(mainDirList)
    analysisDir = [AnalysisDirList{i},'\Layer_Separation\'];
    inputDir = mainInDirList{i}
    maskDir = [AnalysisDirList{i},'\Display\Masks\'];
    outputDir = [analysisDir,'\Output'];
    
    % Directories for saving diffused and cost images.
    dirGradient=[analysisDir,'\Gradient\'];
    dirDiffused=[analysisDir,'\Diffused\'];
    
    if numLayers == 1
        dirGradient=[analysisDir,'\Gradient_1Layer\'];
    end
    
    % Directories for height maps and surface projections
    heightDir0=[analysisDir,'\Output\Height_Maps_0\'];
    matlabProjDir0=[AnalysisDirList{i},'\Layer_Separation\Output\Matlab_Projections_0\'];
    smoothHeightDir0 = [AnalysisDirList{i},'\Layer_Separation\Output\Smooth_Height_Maps_0\'];
    fvDir0 = [AnalysisDirList{i},'\Layer_Separation\Output\FV_0\'];
    
    
    % make all the needed directories
    mkdir(analysisDir);
    cd(analysisDir);
    mkdir(dirGradient);
    mkdir(outputDir);
    mkdir(heightDir0);
    mkdir(fvDir0);
    mkdir(matlabProjDir0);
    mkdir(smoothHeightDir0);
    if saveDiffused ==1
        mkdir(dirDiffused);
    end
    
    % define and make directories for second layer:
    
    if numLayers == 2
        heightDir1=[analysisDir,'\Output\Height_Maps_1\'];
        matlabProjDir1=[AnalysisDirList{i},'\Layer_Separation\Output\Matlab_Projections_1\'];
        smoothHeightDir1 = [AnalysisDirList{i},'\Layer_Separation\Output\Smooth_Height_Maps_1\'];
        fvDir1 = [AnalysisDirList{i},'\Layer_Separation\Output\FV_1\'];
        mkdir(heightDir1);
        mkdir(fvDir1);
        mkdir(matlabProjDir1);
        mkdir(smoothHeightDir1);
    end
    
    save('CostParameters', 'z_scale','xy_scale','use_CLAHE','norm_window','numLayers') % saves the variables including the analysis parameters used
    
    cd (maskDir);
    tpoints = dir('*tif*');
    % tpoints = dir('*C0*.tif*');
    parpool('local', numPar);
    parfor j = 1:length(tpoints)

        name_end = find(tpoints(j).name == '.');
        thisFileImName = [tpoints(j).name(1:(name_end-1))]
        if numLayers == 2
            % Preprocessing before layer separation - matlab code for making the input to the layer seapartion ("Layer separation before")
            CreateCost_with_CLAHE(thisFileImName, inputDir, analysisDir,maskDir, z_scale,xy_scale,outputZScale, use_CLAHE, norm_window, saveDiffused);
            
            % Main layer seapartion function - using ImageJ ("Layer separation - ImageJ")
            % Here run the macro "Layer_Separation_Frame" with the
            % following input parameters:
            
%           *  thisFileImName - name of file without .tiff ending.
%           *  inputDir - input directory of original image files
%           *  dirGradient - input directory of cost (gradient) files
%           *  rescalexy
%           *  rescalez
%           *  maxdz
%           *  max
%           *  min
%           *  heightDir0
%           *  heightDir1
            system(sprintf('%s %s/Layer_Separation_Frame.ijm "%s %s %s %f %f %f %f %f %s %s %f"', ...
                           fijiExe, scriptDir, thisFileImName, inputDir, dirGradient, rescalexy, rescalez, maxdz, max, min, ...
                           heightDir0, heightDir1, display));

            % postprocessing after layer separation - matlab code for making projected images at given z from height maps
            % ("Layer separation after" - first automated step that creates many planes)
            % NOW RUN FUNCTION TO CREATE SURFACE PROJECTIONS:
            % Run on first layer
            smoothHM = smoothHeightMap(thisFileImName, maskDir, heightDir0,smoothHeightDir0,fvDir0, xy_scale, z_scale);
            makeFrameProjection_smoothedHM(thisFileImName, inputDir, matlabProjDir0,xy_scale, offset,smoothHM,CLAHE, zLimits );
            % Run on second layer
            smoothHM = smoothHeightMap(thisFileImName, maskDir, heightDir1,smoothHeightDir1,fvDir1, xy_scale, z_scale);
            makeFrameProjection_smoothedHM(thisFileImName, inputDir, matlabProjDir1,xy_scale, offset,smoothHM,CLAHE, zLimits );
            
        elseif numLayers == 1
            CreateCost_Single_Layer(thisFileImName, inputDir, analysisDir,maskDir, z_scale,xy_scale,outputZScale, use_CLAHE, norm_window, saveDiffused);
           % Here run the macro "Layer_Separation_Frame_Single_Layer" with the
            % following input parameters:
                           
            %  *  thisFileImName - name of file without .tiff ending.
            %  *  inputDir - input directory of original image files
            %  *  dirGradient - input directory of cost (gradient) files
            %  *  rescalexy
            %  *  rescalez
            %  *  maxdz
            %  *  max
            %  *  min
            %  *  heightDir0
            system(sprintf('%s %s/Layer_Separation_Frame_Single_Layer.ijm "%s %s %s %f %f %f %f %f %s %f"', ...
                                       fijiExe, scriptDir, thisFileImName, inputDir, dirGradient, rescalexy, rescalez, maxdz, ...
                                       max, min, heightDir0, display));

            % NOW RUN FUNCTION TO CREATE SURFACE PROJECTIONS:
            % Run on first layer
            smoothHM = smoothHeightMap(thisFileImName, maskDir, heightDir0,smoothHeightDir0,fvDir0, xy_scale, z_scale);
            makeFrameProjection_smoothedHM(thisFileImName, inputDir, matlabProjDir0,xy_scale, offset,smoothHM,CLAHE, zLimits );
            
        end
        
    end
    
end

%% Create 2D image from surface projection stack
% postprocessing after layer separation - matlab code for making a single projected plane for apical ("cells") and basal ("fibers") surface (requires manual check to see what are the best planes to project)
 % ("Layer separation after" - second step that generates final projected images)
if ~batchStartupOptionUsed
    check = input('Please press 1 and enter to create final 2D projected images once you have selected the planes you would like to use. Press any other key to exit, change plane nubmers, and then re-run this section.');
else
    check = 1;
end
if check ~=1 , disp('***Running was stopped. Please select planes and re-run.***'); return, end
for i=1:length(mainDirList)
    analysisDir = [AnalysisDirList{i},'\Layer_Separation\'];
    outputDir = [analysisDir,'\Output'];
    % Directories for surface projections
    matlabProjDir0 = [outputDir,'\Matlab_Projections_0\'];
    matlabProjDir1 = [outputDir,'\Matlab_Projections_1\'];
    corticesImDir = [AnalysisDirList{i},'\Cells'];
    fibresImDir = [AnalysisDirList{i},'\Orientation_Analysis'];
    mkdir(corticesImDir); mkdir(fibresImDir);
    createSinglePlaneProj(matlabProjDir0,matlabProjDir1,layerCortices,layerFibres,planesCortices,planesFibres,corticesImDir,fibresImDir)
end
