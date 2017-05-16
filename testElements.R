testCoordFormat <- function(x) {
  do.split <- strsplit(x, split = " ")[[1]]
  test <- grepl("\\.", do.split)
  
  if (all(length(do.split) == 1 & test[1])) {
    message(sprintf("This is dec_deg, dd.ddddd°"))
    return(anyWGStoDec(x))
  }
  
  if (all(length(do.split) == 2 & test[2])) {
    message(sprintf("This is deg_dec, dd°mm.mmm'"))
    return(anyWGStoDec(x))
  }
  
  if (all(length(do.split) == 3 & test[3])) {
    message(sprintf("This is deg_min_sec, dd°mm'ss.s''"))
    return(anyWGStoDec(x))
  }
  return("Coordinate could not be detected.")
}
