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
library(lidR)
library(terra)
library(raster)

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
ground_points <- classify_ground(las, pmf(ws,th)) #this takes very long as a las file, might be better loading as a LASCatalog and performing the classification (better memory and processing efficiency?)

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
cs_chm <- 0.5 # output cellsize of the chm 
# min cell size seems to be 0.01 since if 0.001 is set "Error: cannot allocate vector of size 1.7 Gb" is returned. But having too fine of a cellsize for chm might cause issues in processing time for automatic shrub detection as it uses a moving local maxima filter --> takes much longer for the kernel to move from pixel to pixel. 

## Creating chm
chm_1 <- grid_canopy(hnorm, cs_chm, p2r(na.fill = knnidw(k=3,p=2))) 

plot(chm_1, 
     col = col,
     main = "grid_canopy method with IDW fill")

## Exportin CHM 
writeRaster(chm_1, 'C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\Subset_CHM_AutomatedShrubDetection\\Outputs\\DSM_DTM_CHM_files\\sub_subsetCHM.tif')


#Individual shrub detection and segmentation

chm_M <- readAll(chm_1) ###function needs to load CHM into memory to process
ttops <- locate_trees(chm_1,lmf(hmin))

plot(chm_M, col = rev(heat.colors(5)))
plot(ttops$geometry, add = TRUE, col='black')

# METHOD 1: POINT TO RASTER 

## Method explanation: algorithm establishes a user defined grid resolution and attributes the elevation of the highest point within the grid to the pixel. 

chm <- rasterize_canopy(hnorm, res = 1, algorithm = p2r()) # res = user defined resolution of the raster grid size (pixel size), p2r = point to raster algorithm
col <- height.colors(25)
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


