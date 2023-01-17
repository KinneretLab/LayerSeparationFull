function makeFrameProjection_smoothedHM(thisFileImName, inputDir, maskDir, outputDir,calibrationXY, offset, smoothHM, CLAHE,zLimit)
% makeFrameProjection(thisFileImName, inputDir, heightDir, outputDir, scalingxy, offset, nProject, typeProject );
%
% this function takes a 3D image matrix data from file thisFileImName in inputDir [N x M x Planes] and a
% heightMap z(x,y) from a file in "heightDir" which is scaled by the factor "scalingxy" to a size [N*scalingxy x M*scalingxy].
% The function calculates the projected images along a
% surface that is at distance "offset" in the z direction from the
% surface defined by the heightMap. The projection is done over "nProject"
% number of image planes using the "typeProj" projection.
%
% Input variables:
% thisFileImName    the (base) file name
% inputDir          the full directory name of the input 3D image
% heightDir         the full directory name of the input height map
% outputDir         the full directory name of the output (projection images)
% scalingxy         the factor of scaling of in the xy direction (<1 for downsampling, =1 for no scaling)
% offset            offset distance in the z-direction (integer in z-planes) determining the position of the 1st plane of
%                   the surface wanted from the heightmap. Positive for above, negative for below.
%                   Can be a vector and then the output will contain multiple planes
% zLimit           Set limits for z-stack if there is a disturbing feature in the image stack that you would like to leave out of projections
%                   even if that plane is supposed to be included in the
%                   projection.
%%
% read input 3D image
try
image3D = read3Dstack ([thisFileImName,'.tiff'],inputDir);
catch
    image3D = read3Dstack ([thisFileImName,'.tif'],inputDir);
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


%%
heightZ = smoothHM;
maxZ=size (image3D,3);

% padd the 3D stack with NaNs for the required planes from min offset to max offset + nProject
rOffset = round (offset); % round the offsets to ensure they are integer
maxPadZPlane = maxZ + max(rOffset) - 1; % this is the maximal plane that will be needed for the projections
minPadZPlane = max(0,-min(rOffset)); % % this is the minimal plane that will be needed for the projections
image3DPadded = ones (size (image3D,1),size (image3D,2),(minPadZPlane+maxPadZPlane)).*NaN;
image3DPadded (:,:,(1+minPadZPlane):(maxZ+minPadZPlane)) = image3D; % put image here
sizeX=size (image3DPadded,1);sizeY=size (image3DPadded,2);sizeZ=size (image3DPadded,3);

z_sigma = 0.5; % Variance of gaussian for determining intensity for off-grid z value.

% now after padding we perform the projection in each pixel
for j = 1:length(offset),
    newZ= minPadZPlane+heightZ+rOffset(j)-1; % this is the z value at each position for offset j and plane k for the projection
    if ~isempty(zLimit{1})
    newZ(find (newZ < zLimit{1}))= zLimit{1};
    end
    if ~isempty(zLimit{2})
    newZ(find (newZ > zLimit{2}))= zLimit{2};
    end
    zrange = (1+minPadZPlane):(maxZ+minPadZPlane);
    [xq,yq,zq] = meshgrid(1:sizeY,1:sizeX,zrange);
    zweights = normpdf(zq,newZ,z_sigma);
    weighed3dIm = zweights.*image3DPadded (:,:,(1+minPadZPlane):(maxZ+minPadZPlane));
    thisSurfaceProj = sum(weighed3dIm,3);
    surfaceProj(:,:,j)=uint16(thisSurfaceProj);     % this is the projected image with offset j
end

surfaceProj(repmat(thisMask,1,1,size(surfaceProj,3))==0) = NaN;

%% normalize image intensity using "adapthisteq" (CLAHE filter)
if CLAHE == 1
    % adapthisteq parameters for CLAHE analysis of incoming image
    % this seems to be better for generating nicer gradient over larger
    % portions of the image by equalizing the intensity locally over regions of
    % 4*blocksigma
    %blocksigma=5*1.28/calibration;
    blocksigma = 3*1.28/calibrationXY;
    imSize1 = size(image3D,1); imSize2 = size(image3D,2); maxZ=size (image3D,3);
    NumTiles = [ round(imSize1/blocksigma/4), round(imSize2/blocksigma/4)]; % split the image into blocks of size 4*blocksigma where the histograms will be equalized
    Distribution = 'Rayleigh'; % this is a peaked distribution
    for j=1:length(offset)
        thisIm = surfaceProj(:,:,j);
        nIm = adapthisteq(thisIm, 'NumTiles', NumTiles, 'Distribution',Distribution,'Alpha',0.4, 'ClipLimit', 0.01); % Alpha and ClipLimit are taken at defualt calues
        surfaceProj(:,:,j) = nIm;
        % figure; imshow(surfaceProj(:,:,j),[])
    end
end

write3Dstack (surfaceProj, [thisFileImName,'.tiff'], outputDir);

end
