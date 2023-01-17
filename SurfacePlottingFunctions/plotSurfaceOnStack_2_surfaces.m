function plotSurfaceOnStack_2_surfaces(thisFileImName, inputDir, heightDir0, heightDir1, maskDir, outputDir, colors, increment )
% plotSurfaceOnStack(thisFileImName, inputDir, heightDir, outputDir, scalingxy, offset, nProject, typeProject );
%
% this function takes a 3D image matrix data from file thisFileImName in inputDir [N x M x Planes] and a
% heightMap z(x,y) from a file in "heightDir" .
% The function generates a stack which contains the original image and
% draws the surface on it.
%
% Input variables:
% thisFileImName    the (base) file name
% inputDir          the full directory name of the input 3D image
% heightDir         the full directory name of the input height map
% outputDir         the full directory name of the output (projection images)
% maskDir           the full directory name of the masks
% colors            the colors data for coloring the surface
% increment         the increment for coloring the surface every increment points

% read input 3D image
try
    image3D = read3Dstack ([thisFileImName,'.tiff'],inputDir);
catch
    image3D = read3Dstack ([thisFileImName,'.tif'],inputDir);
end

% rescale image data to double (number beetween 0 and 1)
newImage3D = rescale(image3D);
% read 3D image into a 4D (RGB stack) image
image4D = [];
for i=1:size(image3D, 3)
    image4D(:,:,:,i) = cat(3,newImage3D(:,:,i),newImage3D(:,:,i),newImage3D(:,:,i));
end


% read the height image in dir heightdir with name THAT CONTAINS thisFileImName
cd(heightDir0); S = dir(fullfile(heightDir0,'*.mat*'));
N = {S.name}; X = ~cellfun('isempty',strfind(N,thisFileImName));
heightMap0 = load (fullfile(heightDir0,N{X}));

% read the second height image in dir heightdir with name THAT CONTAINS thisFileImName
cd(heightDir1); S = dir(fullfile(heightDir1,'*.mat*'));
N = {S.name}; X = ~cellfun('isempty',strfind(N,thisFileImName));
heightMap1 = load (fullfile(heightDir1,N{X}));

% read masks with name THAT CONTAINS thisFileImName
cd(maskDir); S = dir(fullfile(maskDir,'*.tif*'));
N = {S.name}; X = ~cellfun('isempty',strfind(N,thisFileImName));
mask = imread (fullfile(maskDir,N{X}));


% make heightmap discrete and within range of 3D image
maxZ=size (image3D,3);
heightZ = round(heightMap0.smoothHM); heightZ (find(heightZ<1)) = NaN; heightZ (find(heightZ>maxZ)) = NaN; heightZ (mask == 0) = NaN;% discretized heightMap and make sure it is within range
[Y,X] = meshgrid(1:size(heightMap0.smoothHM,1),1:size(heightMap0.smoothHM,2)); % Y=size(heightMap,2)+1-Y; X=size(heightMap,1)+1-X;% do we need to flip the Y-axis?
drawRegion=find(~isnan(heightZ(:))); % define points to draw on

% make heightmap discrete and within range of 3D image
maxZ=size (image3D,3);
heightZ1 = round(heightMap1.smoothHM); heightZ1 (find(heightZ1<1)) = NaN; heightZ1 (find(heightZ1>maxZ)) = NaN; heightZ1 (mask == 0) = NaN; % discretized heightMap and make sure it is within range
[Y,X] = meshgrid(1:size(heightMap1.smoothHM,1),1:size(heightMap1.smoothHM,2)); % Y=size(heightMap,2)+1-Y; X=size(heightMap,1)+1-X;% do we need to flip the Y-axis?
drawRegion1=find(~isnan(heightZ1(:))); % define points to draw on


% now draw the surface on the image
newImage4D=image4D;
% draw every increment points
for i=1:increment:length(drawRegion),
    for j=1:size(image4D, 3)
        newImage4D(X(drawRegion(i)),Y(drawRegion(i)),j,heightZ(drawRegion(i)))=colors(1,j);
    end
end

% now draw the second surface on the image, draw every increment points
for i=1:increment:length(drawRegion1),
    for j=1:size(image4D, 3)
        newImage4D(X(drawRegion1(i)),Y(drawRegion1(i)),j,heightZ1(drawRegion1(i)))=colors(2,j);
    end
end

mkdir(outputDir);
%save the 4D image if desired
write4Dstack (newImage4D, [thisFileImName,'.tiff'], outputDir);
end

