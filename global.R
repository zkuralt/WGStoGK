# This chunk will create EPSG codes and display it in desired order.
library(rgdal)
library(DBI)

epsg <- make_EPSG()
epsg$pretty.name <- paste("EPSG:", epsg$code, sep = "")
ui.crs <- as.character(epsg$prj4)
names(ui.crs) <- epsg$pretty.name
top.choice <- c("3915", "3912", "3787")

### Source for EPSG:3915 - https://epsg.io/3912-3915
ui.crs <- c(ui.crs, "EPSG.3915" = "+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs")
find.important <- which(grepl(paste(top.choice, collapse = "|"), x = names(ui.crs)))
ui.crs <- c(ui.crs[find.important], ui.crs[-find.important])

ui.crs <- split(ui.crs, f = c(rep(1, length.out = length(top.choice)), rep(2, length.out = length(ui.crs) - 3)))
names(ui.crs) <- c("Slovenia", "Other")

path <- sample(letters, 15, replace = TRUE)
path <- paste(paste(path, collapse = ""), ".sqlite", sep = "")

mydb <- dbConnect(RSQLite::SQLite(), path)

dbSendQuery(conn = mydb, "CREATE TABLE input(
            lat CHARACTER,
            lon CHARACTER,
            type CHARACTER
            )")

saveData <- function(data, path) {
  dbWriteTable(mydb, "input", data, append = TRUE)
  data
  }

loadData <- function(db) {
  x <- dbReadTable(mydb, "input")
  x
}

