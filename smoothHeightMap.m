function [smoothHM] = smoothHeightMap(thisFileImName, maskDir, heightDir, smoothHeightDir,fvDir, calibrationXY, calibrationZ)
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
    thisMask=thisMask(1:xyScale:end,1:xyScale:end);

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
xSize=size (HeightMap,1); ySize=size (HeightMap,2); zSize=round(maxZ - minZ +1);
[X,Y,Z] = meshgrid(1:ySize,1:xSize,1:zSize); X=X*xyScale*calibrationXY;Y=Y*xyScale*calibrationXY;Z=double(Z)*calibrationZ; % this gives the grid in real units
repHeightMap = repmat(HeightMap,1,1,zSize)*calibrationZ; % generate 3D matriz which has z=z(x,y) for all z
Mask3D = single(Z > repHeightMap); % makes a matrix with 1 when z>z(x,y) and 0 below

% 3D Gaussian filtering with a sigma of 1 voxel
SmoothMask3D = imgaussfilt3(Mask3D,sigma);
% Remove triangles and vertices outside the mask
% [maskedX,maskedY] = find(thismask==0);
% SmoothMask3D(maskedX,maskedY,:) = NaN;

%%
try [f,v] = isosurface(X,Y,Z,SmoothMask3D,0.5); % find the isosurface with value =0.5
catch f = []; v=[];
end

%% Rescale coordinates x,y,z to pixels, and interpolate surface z(x,y) to original x,y grid
if length(v) == 0
    v = zeros(1,3);
    smoothHM = ones(origSize(2),origSize(1));
else
    rescaledV = [1/calibrationXY, 1/calibrationXY,1/calibrationZ].*v ;
    [newX,newY] = meshgrid(1:origSize(2),1:origSize(1));
    interp = scatteredInterpolant(rescaledV(:,1),rescaledV(:,2),rescaledV(:,3));
    smoothHM = interp(newX,newY);
end

%% Save surface triangles and vertices for distance calculations
TRIV = f;
VERT = [1/calibrationXY, 1/calibrationXY,1].*v ;
m = size(TRIV,1);
n = size(VERT,1);

cd(fvDir); save(thisFileImName,'TRIV','VERT','m','n');

%% Save smoothed height map

 cd(smoothHeightDir); save(thisFileImName,'smoothHM'); % save adjusted image

end