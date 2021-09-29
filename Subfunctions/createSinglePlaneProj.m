function [] = createSinglePlaneProj(matlabProjDir0,matlabProjDir1,layerCortices,layerFibres,planesCortices,planesFibres,corticesImDir,fibresImDir)
% This function creates single plane, 2D projection images from the stack
% of possible projection images after layer separation.

if ~isempty(layerFibres)
  fibreProjDir = eval(['matlabProjDir',num2str(layerFibres)]);
  cd (fibreProjDir);
  tpoints = dir('*tif*');
  mkdir([fibresImDir,'\Raw Images']);
    parfor j = 1:length(tpoints)      
          name_end = find(tpoints(j).name == '.');
          thisFileImName = [tpoints(j).name(1:(name_end-1))];
          try
              projStack = read3Dstack ([thisFileImName,'.tif'],fibreProjDir);
          catch
              projStack = read3Dstack ([thisFileImName,'.tiff'],fibreProjDir);
          end
          newStack = projStack(:,:,planesFibres);
          fibreIm = max(newStack,[],3);
          cd([fibresImDir,'\Raw Images']);
          imwrite(fibreIm,thisFileImName + ".tiff");

    end
end

if ~isempty(layerCortices)
  corticesProjDir = eval(['matlabProjDir',num2str(layerCortices)]);
  cd (corticesProjDir);
  tpoints = dir('*tif*');
  mkdir([corticesImDir,'\Raw Cortices']);

    parfor j = 1:length(tpoints)      
          name_end = find(tpoints(j).name == '.');
          thisFileImName = [tpoints(j).name(1:(name_end-1))];
          try
              projStack = read3Dstack ([thisFileImName,'.tif'],corticesProjDir);
          catch
              projStack = read3Dstack ([thisFileImName,'.tiff'],corticesProjDir);
          end
          newStack = projStack(:,:,planesCortices);
          corticesIm = max(newStack,[],3);
          cd([corticesImDir,'\Raw Cortices']);
          imwrite(corticesIm,thisFileImName + ".tiff");
          
    end
end
end

