function [smoothHM] = smoothHeightMap(thisFileImName, maskDir, heightDir, smoothHeightDir,fvDir, calibrationXY, calibrationZ,extrapolate,layerNum)
% Take height maps given by surface detection algorithm for layer
% separation, and smooth by binarising, blurring using gaussian kernel and selecting
% isosurface with I=0.5.
%% Load height map
try % load the height maps
    cd (heightDir); HeightMapOrig =importdata(['HM',thisFileImName,'.tiff']); 
catch
    try
        cd (heightDir); HeightMapOrig =importdata(['HM',thisFileImName,'.tif']); 
    catch
        HeightMapOrig=[] ;disp (['no height map found ',thisFileImName]); % if no image is found
    end  
   
end

try % load the corresponding masks
    cd (maskDir); thisMask =importdata([thisFileImName,'.tiff']); 
catch
    try
        cd (maskDir); thisMask =importdata([thisFileImName,'.tif']); 
    catch
        thisMask =[] ;disp (['no mask found ',thisFileImName]); % if no image is found
    end  
end
origSize = size(HeightMapOrig);
%% Downsample HeightMap and mask to have similar xy and z resolution
xyScale= ceil(calibrationZ/calibrationXY);
if xyScale>1,
    HeightMap=HeightMapOrig(1:xyScale:end,1:xyScale:end);
    resizedMask=thisMask(1:xyScale:end,1:xyScale:end);

else HeightMap = HeightMapOrig; 
end
% HeightMap = HeightMapOrig; mask=maskOrig;

%% take the downsmapled HeightMap and redefine it after Gaussian smoothing and isosurface
% 1) make a 3D mask from the surface within the masked region
% 2) smooth the 3D mask with a 3D Gaussian filter
% 3) define isosurface at 0.5
sigma=[1,1,1]; % this is the sigma for the gaussian smoothing of the 3D mask below
minZ=1; % when minZ = 1 the height will retain the original values
maxZ = max(max(HeightMap)); % define the height of the 3D mask
xSize=size (HeightMap,2); ySize=size (HeightMap,1); zSize=round(maxZ - minZ +1);
[X,Y,Z] = meshgrid(1:xSize,1:ySize,1:zSize); X=X*xyScale*calibrationXY;Y=Y*xyScale*calibrationXY;Z=double(Z)*calibrationZ; % this gives the grid in real units
repHeightMap = repmat(HeightMap,1,1,zSize)*calibrationZ; % generate 3D matrix which has z=z(x,y) for all z
Mask3D = single(Z > repHeightMap); % makes a matrix with 1 when z>z(x,y) and 0 below

% Pad Mask3D to prevent holes in surface mesh from isosurface
Mask3D = cat(3,zeros(size(HeightMap)),Mask3D,ones(size(HeightMap)));
X = cat(3,X(:,:,1),X,X(:,:,1));
Y = cat(3,Y(:,:,1),Y,Y(:,:,1));
Z = cat(3,zeros(size(Z,1:2)),Z,ones(size(Z,1:2))*(zSize+1)*calibrationZ);

% 3D Gaussian filtering with a sigma of 1 voxel
SmoothMask3D = imgaussfilt3(Mask3D,sigma);

% Dilate mask a bit before removing values outside mask: (Not currently
% used)
% SE = strel("disk",xyScale);
% resizedMask = imdilate(resizedMask,SE);

% Prepare mask for surface detection with NaN values outside mask so
% triangulated surface is only inside mask region:
 SmoothMask3D(repmat(resizedMask,1,1,size(SmoothMask3D,3))==0) = NaN;

%%

[origX,origY,origZ] = meshgrid(calibrationXY*(1:origSize(2)),calibrationXY*(1:origSize(1)),calibrationZ*double((0:(zSize+1))));

interpSmoothMask3D = interp3(X,Y,double(Z),SmoothMask3D,origX,origY,origZ);

try [f,v] = isosurface(origY,origX,origZ,interpSmoothMask3D,0.5); % find the isosurface with value = 0.5
catch f = []; v = [];
end


%% Rescale coordinates x,y,z to pixels, and interpolate surface z(x,y) to original x,y grid
if length(v) == 0
    v = zeros(1,3);
    smoothHM = ones(origSize(2),origSize(1));
else
    rescaledV = [1/calibrationXY, 1/calibrationXY,1/calibrationZ].*v ; % Return to pixels of original resolution in x,y,z
    [newX,newY] = meshgrid(1:origSize(2),1:origSize(1));
    interp = scatteredInterpolant(rescaledV(:,2),rescaledV(:,1),rescaledV(:,3));
    smoothHM = interp(newX,newY);
    SE = strel("disk",round(20/calibrationXY)); % Dilate mask by 20um to be less sensitive to inaccuracies
    dilatedMask = imdilate(thisMask,SE);
    smoothHM (dilatedMask == 0 ) = 1;
end
%% Save surface triangles and vertices for distance calculations
TRIV = f;
VERT = [1/calibrationXY, 1/calibrationXY,1/calibrationXY].*v ; % For mesh, keep all dimensions in dimensions of pixels in xy
m = size(TRIV,1);
n = size(VERT,1);

cd(fvDir); save(thisFileImName,'TRIV','VERT','m','n');


%% If desired, also cut edges of HM and perform extrapolation to correct them
if extrapolate == 1
    heightEdge = 5; % Set edge width of height map for smoothening purposes
    zFactor =  calibrationZ*(10^-3); % Step size of height maps in mm, this is the scale Elad used in his extrapolation
    extrapolatedHM = extrapolateEdgesHM(newX,newY,smoothHM*zFactor,thisMask,heightEdge);
    extrapolatedHM = extrapolatedHM/zFactor;
    outputDir = fullfile(smoothHeightDir, '..');
    extrapolatedHeightDir = [outputDir,'\extrapolated_HM_',num2str(layerNum)];
    mkdir(extrapolatedHeightDir);

    cd(extrapolatedHeightDir); save(thisFileImName,'extrapolatedHM'); % save extrapolated heightmap

    % Create new tirangulation mesh for extrapolated heightmap using existing mesh and replacing Z values:

 
    F = griddedInterpolant(extrapolatedHM);
    VERT(:,3) = F(VERT(:,1),VERT(:,2));
    
    TRIV = f;
    VERT = [1, 1, 1*(calibrationZ/calibrationXY)].*VERT;
 
    extrapolatedMeshDir = [outputDir,'\extrapolated_Mesh_',num2str(layerNum)];
    mkdir(extrapolatedMeshDir);
    cd(extrapolatedMeshDir); save(thisFileImName,'TRIV','VERT');
end


%% Save smoothed height map

 cd(smoothHeightDir); save(thisFileImName,'smoothHM'); % save adjusted image

end

