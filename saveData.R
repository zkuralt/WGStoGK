saveData <- function(data) {
  if (exists("responses")) {
    input <<- rbind(input, data)
  } else {
    input <<- data
  }
}