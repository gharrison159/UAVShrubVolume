library(lidR)
library(lidRviewer)
library(terra)
library(sp)
library(sf)
library(htmlwidgets)
library(rgl)
library(grDevices)
library(geometry)

las <- readLAS("Outputs\\Clipped_SubsetPC\\PC_height_Normalized_shrub.las")

shp <- vect("Outputs\\ShrubDelineation\\shrubtops_vwf.shp")

ras <- rast("Outputs\\ShrubDelineation\\IndvShrubs_Silva_VWF.tif")


sf <- st_as_sf(shp)

sf$height <- (sf$height + (0.1*sf$height))

lidR::plot(las,
           color = "RGB", 
           bg = "white", 
           size = 2)

plot(las, color = "RGB") |> add_treetops3d(sf, radius = 0.1, fastTransparency = TRUE, alpha = 0.8, z = "height", color = "blue") #|> add_dtm3d(ras, bg = "black", clear_artifacts = TRUE) 
