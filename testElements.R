#' Check format of input coordinates
#'  
#' function splits elements based on whitespace an infers input coordinates format
#' 
#' @param x data frame containing WGS coordinates separated by whitespace

testElements <- function(x) {
  do.split <- strsplit(x, split = " ")[[1]]
  test <- grepl("\\.", do.split)
  if (all(length(do.split) == 1 & test[1])) {
    message(sprintf("This is dec_deg, dd.ddddd°"))
    return("dec_deg")
  }
  
  if (all(length(do.split) == 2 & test[2])) {
    message(sprintf("This is deg_dec_min, dd°mm.mmm'"))
    return("deg_dec_min")
  }
  
  if (all(length(do.split) == 3 & test[3])) {
    message(sprintf("This is deg_min_sec, dd°mm'ss.s''"))
    return("deg_min_sec")
  }
  return("Coordinate could not be detected.")
}
