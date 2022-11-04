# UAVShrubVolume
Supporting code for working with point cloud data from UAV to calculate canopy size

Flow of the code:
1. Start with the "creating shapefiles" code. This reads in the field data and shrub corner markers, and creates a SpatialPolygonDataFrame
2. SliceNDice code: Trim the dense point cloud by the SpatialPolygonDataFrame
