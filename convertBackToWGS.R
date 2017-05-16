convertBackToWGS <- function(x){
  
  # Define input and output coordinate systems.
  proj4string(x) <- CRS("+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs")
  wgs <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  x.map <- spTransform(x, wgs)
  x.map
}