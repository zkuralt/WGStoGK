convertFileToGK <- function(x){
  x <- sapply(x, anyWGStoDec)
  x <- data.frame(matrix(x, ncol = 2, byrow = FALSE))
  names(x) <- c("lat", "lon")
  coordinates(x) <- c("lon", "lat")
  
  # Define input and output coordinate systems.
  proj4string(x) <- CRS("+init=epsg:4326") # WGS 84
  CRS.new <- CRS("+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs")
  x.new <- spTransform(x, CRS.new)
  x.new
}