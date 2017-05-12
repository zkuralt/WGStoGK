#' Convert any WGS format to decimal degrees
#'  
#' function takes different formats of WGS coordinates and converts them to decimal degrees
#' 
#' @param x data frame containing WGS coordinates in deg°min'sec'' or deg°min' format

anyWGStoDec <- function(x){
  # browser()
  # x <- sapply(x, gsub, pattern = "°|'|''", replacement = " ")
  # x <- sapply(x, FUN = function(my) gsub(pattern = "°|'|''", replacement = " ", x = my))
  # x$V1 <- gsub(x$V1, pattern = "°|'|''", replacement = " ")
  # x$V2 <- gsub(x$V2, pattern = "°|'|''", replacement = " ")
  
    
  
  xy <- tryCatch(sapply(x, measurements::conv_unit, from = 'deg_min_sec', to = 'dec_deg'), 
                 error = function(e) e, warning = function(w) w) 
  if (is.character(xy)) { 
    return(as.numeric(xy))
  }
  xy <- tryCatch(sapply(x, measurements::conv_unit, from = 'deg_dec_min', to = 'dec_deg'), 
                 error = function(e) e, warning = function(w) w) 
  # xy <- sapply(x, measurements::conv_unit, from = 'deg_dec_min', to = 'dec_deg')
  
  
  if (is.character(xy)) { 
    return(as.numeric(xy))
  }
  xy <- tryCatch(sapply(x, measurements::conv_unit, from = 'dec_deg', to = 'dec_deg'), 
                 error = function(e) e, warning = function(w) w) 
  if (is.character(xy)) { 
    return(as.numeric(xy))
  }
  
  return("No conversion found.")
  
}
