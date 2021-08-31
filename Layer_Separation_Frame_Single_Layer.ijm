

/* Parameters that will be given as input:
 *
 *  thisFileImName - name of file without .tiff ending.
 *  inputDir - input directory of original image files
 *  dirGradient - input directory of cost (gradient) files
 *  rescalexy
 *  rescalez
 *  maxdz
 *  max
 *  min
 *  heightDir0

 */
argList = split(getArgument(), " ");
thisFileImName = argList[0];
inputDir = argList[1];
dirGradient = argList[2];
rescalexy = argList[3];
rescalez = argList[4];
maxdz = argList[5];
max = argList[6];
min = argList[7];
heightDir0 = argList[8];


// print(thisFileImName);

// Find original image and cost image files whether ending is .tiff or .tiff
if (File.exists(inputDir+thisFileImName+".tiff")){
	orig_name = thisFileImName+".tiff"
	else if (File.exists(inputDir+thisFileImName+".tif")){
		orig_name = thisFileImName+".tif"
	}
}

if (File.exists(dirGradient+"Grad"+thisFileImName+".tiff")){
	cost_name = "Grad"+thisFileImName+".tiff"
	else if (File.exists(dirGradient+"Grad"+thisFileImName+".tif")){
		cost_name = "Grad"+thisFileImName+".tif"
	}
}

// Perform layer separation if original and cost files exist. This will prevent crashing if some frames are missing.

if (File.exists(inputDir+orig_name)){

	if (File.exists(dirGradient+cost_name)){

		open(inputDir+orig_name);
		open(dirGradient+cost_name);

		run("Min cost Z Surface", "input="+orig_name+" cost="+cost_name+" rescale_x,y=&rescalexy rescale_z=&rescalez max_delta_z=&maxdz display_volume(s) volume=&display max_distance=&max min_distance=&min");

		// Uncomment the following section if you would like to save images of detected surfaces directly.
		/*
		File.makeDirectory(outdir+"Layers\\");
		saveAs("Tiff", outdir+"Layers\\"+"layer0_Min_"+min+"_"+orig_name);
		run("Close");
		*/
		selectWindow("altitude map");
		saveAs("Tiff", heightDir0+"\\HM"+orig_name);
		run("Close All");

		else
		{
			print("Cost image not found");
		}
	}
	else
	{
	print("Original image not found");
	}
}