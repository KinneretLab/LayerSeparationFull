function totHM = extrapolateEdgesHM(X,Y,hm,msk,erd)
%SMOOTHENHEIGHT is a tool for extrapolating the Height Map in 
%  its non-reliable area
%   INPUT:
%       * X, Y: {Arrays} contains the grid with relevant units
%       * hm: {Array} The height-map array for each x,y 
%                        (can be empty for 2d landmarks - will insert z=0)
%       * msk : {Array} The mask image of the tissue
%       * erd : {int} size of exterior last smoothing
%   OUPUT:
%       * totHM: {Array} Fixed Height Map after extrapolation
%          

%% Parameters
thrs = -6e-4; % Threshold for derivative (find first significant drop)
dr = 1; % Average over dr jumps of r
Ds = [3,4,5,7,10,11,13,17]; % Different d_theta to run over (for smoothening)
cut = round(30/dr); % Ignore close circle to start (noisy due to discritization)

%% Initalize
mid = 0.5*(X(1) + X(end)); % Find middle point of grid
X = X - mid; Y = Y - mid; % Shift X,Y to middle 
r = hypot(X,Y); theta = rad2deg(atan2(Y,X)) + 180; % Polar [px,deg 0-360]

% Set height maps
totHM = zeros(size(hm));
prevHm = hm; % Save original Height-map

for d_theta = Ds
    hm = prevHm;  % Load original Height-map
    lastdeg = 360-d_theta;  
for t = 0:d_theta:lastdeg
     % Select relevant pixels in cut
    idx = theta >= t & theta < (t + d_theta)  & msk > 0;
    r_t = r(idx); h_t = hm(idx);
%     imshow(idx,[]);pause(0.001); % Show cut
    
    
    
    hst = accumarray(round(r_t/dr)+1,h_t(:),[],@mean); % Average over cut in dr jumps
    r_min = findFirstLocalMax(hst,thrs,cut); % Find where to cut
    rng = dr*(cut - 0.5):dr:dr*(r_min-0.5); % Set range for fit function

%     Plots
%     plot(smooth(smooth(hst(15:r_min))));hold on
%     plot(r_min-14:length(hst)-14,smooth(smooth(hst(r_min:end))),'--'); 
%     title(['t = ' num2str(t)]);
    
    % Fit 2-order Polynomial
    hst = hst(cut:r_min);
    if length(rng) < 3
        continue
    end
    [xData, yData] = prepareCurveData( rng', hst);

    [fitresult, gof] = fit( xData, yData, fittype( 'poly2' ), fitoptions( 'Method', 'LinearLeastSquares'));
    if gof.rsquare > 0.1 && fitresult.p1 > 0 
        hm(idx & r > rng(end)) = fitresult(r(idx & r > rng(end)));
    end

% More Plots
%     plot(-13:max(r_t)/dr - 14,fitresult(1:max(r_t)/dr),'--');pause(2)
    hold off
    
end
totHM = totHM + (1/length(Ds))*hm; % Average over different d_theta jumps
end

% Smoothen external part
if erd > 0
msk = double(msk./ max(msk(:)));
rel = imerode(msk,strel('disk',erd));
non_rel = msk - rel; % External part
% Gaussian smoothening:
totHM = nanArr(nanconv(nanArr(totHM,non_rel),fspecial('gaussian',30,5), 'nanout'),[]) + rel.*totHM; 

% % Show smoothing
% surf(nanArr(hm,non_rel),totHM);hold on
% surf((nanconv(nanArr(hm,non_rel),fspecial('gaussian',30,5), 'nanout')),totHM)
% shading interp;colormap('parula');grid off;hold off; % Set graphics and shading of surface.
end

close (gcf)
end


function locmin = findFirstLocalMax(vec,thrs,cut)
vec = vec(cut:end); % Cur not-relevant part
j = diff(smooth(medfilt1(smooth(vec),7))); % Apply derivative and smoothen 
minDf = find(j < thrs, 1, 'first'); % Find first under threshhold
if isempty(minDf) % If didn't find any - find where vec is minimal
    [~, minDf] = min(j); 
end
locmin = find(j(1:minDf) > 0,1,'last') + cut - 1; % Find first peak before drop
if isempty(locmin)
    locmin = 1;
end
end

function arr = nanArr(arr,msk)
    if isempty(msk)
        arr(isnan(arr)) = 0;
    else
        arr(msk == 0) = nan;
    end
end