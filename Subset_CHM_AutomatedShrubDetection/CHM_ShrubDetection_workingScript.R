#############################################################

### Programmer: Abhinav Shrestha
### Contact information: shre9292@vandals.uidaho.edu

### Purpose: DSM and CHM generation tutorial - lidR package

### Last update: 01/02/2023
#############################################################

# tutorial follow along links: 
## * https://r-lidar.github.io/lidRbook/chm.html
## * Main paper: https://www.degruyter.com/document/doi/10.1515/geo-2020-0290/html?lang=en
##  + Tutorial in supplementary material: https://www.degruyter.com/document/doi/10.1515/geo-2020-0290/downloadAsset/suppl/geo-2020-0290_sm.pdf 


# load necessary libraries
require(lidR)
require(terra)
require(raster)
require(viridisLite)
require(ForestTools)
require(sp)
require(sf)
require(rLiDAR)
require(rgdal)
require(rayshader)

# STEP 1: Load point cloud dataset file 

# load point cloud (.las/.laz) file

# las_cat <- readLAScatalog("C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\DATA\\north_subset_PointCloud.las")
# 
# opt_output_files(las_cat) <- "C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\DSM_DTM_CHM_files"

las <- readLAS("C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\Clipped_SubsetPC\\sub_subset_PointCloud.las") 

plot(las, 
     size = 3, 
     bg = "white")

# STEP 2: CLASSIFY GROUND

## Sequence of windows sizes
ws <- seq(3,12,3)
## Sequence of height thresholds
th <- seq(0.1,1.5,length.out = length(ws))
## Set threads for classification: 
set_lidr_threads(4)
## Classify ground
ground_points <- classify_ground(las, pmf(ws,th)) # this takes very long as a las file, might be better loading as a LASCatalog and performing the classification (better memory and processing efficiency?) UPDATE: took about the same time with LASCatalog file (still long). Issue might be with the algorithm not being parallel-computing friendly (mentioned in the documentation: "In lidR some algorithms are fully computed in parallel, but some are not because they are not parallelizable"). Even using the set_lidr_threads to '4' (max available threads), the classify_ground function only uses 1 thread. 

writeLAS(ground_points, "C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\Clipped_SubsetPC\\ground_Classif.las")

ground_points <- readLAS("C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\Clipped_SubsetPC\\ground_Classif.las")

# STEP 3: CREATE DTM WITH GROUND POINTS

## Defining dtm function arguments
cs_dtm <- 1.0 # output cellsize of the dtm
# min cellsize possible is 0.01, when 0.001 is set, then the grid_terrain function will output "Error: memory exhausted (limit reached?)" and "Error: no more error handlers available (recursive errors?); invoking 'abort' restart"
# as resolution of processed DEM was around 0.70 m, cell size set to 1.0 (equivalent to 1 m as native coordinate system is UTM in m)

## Creating dtm
dtm <- grid_terrain(ground_points, cs_dtm, knnidw()) # using Invert distance weighting (IDW) to create DTM

## Plot and visualize the dtm in 3d 
plot_dtm3d(dtm) 

# STEP 4: HEIGHT NORMALIZATION OF POINT CLOUD
hnorm <- normalize_height(ground_points, dtm)
plot(hnorm, 
     size = 3, 
     bg = "white" 
     )

# STEP 5: CREATE CHM 

## Defining chm function arguments
cs_chm <- 0.2 # output cellsize of the chm 
# min cell size seems to be 0.01 since if 0.001 is set "Error: cannot allocate vector of size 1.7 Gb" is returned. But having too fine of a cellsize for chm might cause issues in processing time for automatic shrub detection as it uses a moving local maxima filter --> takes much longer for the kernel to move from pixel to pixel. could not set cs_chm to 0.5 (as shown in lidR example) as any number above 0.3 (including) returns "Error in data.table::setnames(where, c("X", "Y")) : Can't assign 2 names to a 1 column data.table" error. Hence, cs_chm set as 0.2.

## Creating chm
chm_1 <- grid_canopy(hnorm, cs_chm, p2r(na.fill = knnidw(k=3,p=2))) 

plot(chm_1, 
     col = col,
     main = "grid_canopy method with IDW fill")

## Exportin CHM 
writeRaster(chm_1, 'C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\DSM_DTM_CHM_files\\sub_subsetCHM_point02.tif')


#Individual shrub detection and segmentation using Local Maxima Filter (lmf, lidR) and Variable Window Filter (vwf, ForestTools)

# Load CHM 
chm <- raster("C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\DSM_DTM_CHM_files\\sub_subsetCHM_point02.tif")

# CHM Smoothing (3x3 kernel, uses mean value)
schm <- CHMsmoothing(chm, "mean", 3)

par(mfrow = c(1,2))
plot(chm, 
     col = height.colors(25))
plot(schm, 
     col = height.colors(25))
par(mfrow = c(1,1))

## ITD using lmf with lidR

ttops_lmf <- locate_trees(schm,lmf(2, hmin = 0, shape = "circular"))

plot(schm, col = height.colors(25), main = "ITD with LMF (lidR)")
plot(ttops_lmf$geometry, add = TRUE, col='black', pch = 1)

## ITD using vwf with ForestTools

### Set function for determining variable window radius
winFunction <- function(x){x * 0.04}
### Set minimum tree height (treetops below this height will not be detected)
minHgt <- 0.001
### Detect treetops in demo canopy height model
ttops_vwf <- vwf(schm, winFunction, minHgt)

plot(chm, col = height.colors(25), main = "ITD with VWF (ForestTools)")
plot(ttops_vwf, add = TRUE, col='black', pch = 1)


## Comparing ITD between lmf (red) and vwf (yellow)
plot(schm, col = viridis(25), main = "lmf vs vwf")
plot(ttops_vwf, add = TRUE, col='yellow', pch = 20)
plot(ttops_lmf$geometry, add = TRUE, col='red', pch = 20)

## ITCD with lidR 
crowns_silva <- silva2016(schm,ttops_lmf)()

plot(schm, col = viridis(25), main = "Shrub delineation silva2016")
plot(crowns_silva, add = TRUE, legend = FALSE, col = 'black')


## EXTRA - Rayshader: https://www.rayshader.com/ 

elmat = raster_to_matrix(chm)

elmat %>%
  sphere_shade(sunangle = 45, texture = "imhof3") %>%
  plot_3d(elmat, zscale = 0.1, fov = -5, theta = 15, zoom = 0.7, phi = 45, windowsize = c(1000, 800))

Sys.sleep(0.2)
render_snapshot()



# METHOD 1: POINT TO RASTER 

## Method explanation: algorithm establishes a user defined grid resolution and attributes the elevation of the highest point within the grid to the pixel. 

chm <- rasterize_canopy(hnorm, res = 1, algorithm = p2r()) # res = user defined resolution of the raster grid size (pixel size), p2r = point to raster algorithm
col <- viridis::viridis(25)
plot(chm, 
     col = col, 
     main = "Rasterize canopy method")

### Pros: This method is computationally simple and fast.
### Cons: May result in empty pixels when grid resolution is too fine for the point density of the .las file (**user defined grid resolution should factor in the point density of the point cloud**). Some cells in the raster might not contain any points, and thus the algorithm will return an NA value. An example of this is shown with the code chunk below: 

chm <- rasterize_canopy(hnorm, res = 0.5, algorithm = p2r()) # res is reduced to 0.5
plot(chm, 
     col = col)

### One option to reduce the number of 'holes' that return NA values due to the sparsity of the point cloud data set is to replace every point in the point cloud with a disk of a known radius. This disk is meant to simulate the laser footprint of a LiDAR ALS. 

chm <- rasterize_canopy(hnorm, res = 0.5, algorithm = p2r(subcircle = 0.15))
plot(chm, col = col)

### Another option is use the na.fill argument within the p2r fuction to interpolate the empty pixels. 

chm <- rasterize_canopy(hnorm, res = 0.5, p2r(0.2, na.fill = knnidw(k=3,p=2))) # uses Triangular Irregular Network (TIN) to fill the holes
plot(chm, col = col, main = "Rasterize canopy method with IDW fill")


