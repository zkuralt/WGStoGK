#' Convert any WGS format to decimal degrees
#'  
#' function takes different formats of WGS coordinates and converts them to decimal degrees
#' 
#' @param x data frame containing WGS coordinates in deg°min'sec'' or deg°min' format

anyWGStoDec <- function(x){
  y <- testElements(x)
  
  xy <- tryCatch(sapply(x, measurements::conv_unit, from = y, to = 'dec_deg'),
                 error = function(e) e, warning = function(w) w)
  if (is.character(xy)) {
    return(as.numeric(xy))
  }
 
  return("No conversion found.")
}
