library(shiny)
library(sp)
library(measurements)
library(leaflet)
library(rgdal)
library(googleway)
library(plotKML)
source("anyWGStoDec.R")
source("testElements.R")
source("convertBackToWGS.R")
source("convertToGK.R")
source("prepareCoords.R")
source("convertFileToGK.R")

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

shinyServer(function(input, output) {
  
  crs <- reactive({
    crs <- input$crs
    crs
  })
  
  ### Text input
  observeEvent(input$convertText, {

    coordInput <- reactive({
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x <- prepareCoords(x)
      x
    })
    
    convertedCoords <- reactive({
      coordinates(convertToGK(coordInput(), crs = input$crs))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertToGK(coordInput(), crs = input$crs), crs = input$crs))
    })
    
    output$coords <- renderTable({
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x <- data.frame(matrix(x, ncol = 2, byrow = TRUE))
      names(x) <- c("lat", "lon")
      x
    }, digits = 5)
    
    output$new.coords <- renderTable({
      coordinates(convertedCoords())
    }, digits = 2)
    
    output$selected.crs <- renderText({
      paste("CRS:", input$crs)
    })
    
    output$leaflet <- renderLeaflet({
      coordLabel <- apply(coordinates(coordsForLeaflet()), MARGIN = 1, FUN = function(z) {
        sprintf("lon: %s lat: %s", z[1], z[2])
      })
      
      leaflet() %>%
        addProviderTiles(providers$OpenStreetMap.Mapnik,
                         options = providerTileOptions(noWrap = TRUE)) %>%
        addMarkers(data = coordsForLeaflet(), clusterOptions = markerClusterOptions(),
                   label = coordLabel) %>%
        addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE))
      
    })
    
    output$elevation <- renderTable({
      if (input$elevation == TRUE) { 
        elev <- google_elevation(df_locations = as.data.frame(coordsForLeaflet()),
                                 location_type = "individual", 
                                 key = "AIzaSyATwD1Zqpv8M0SPddTLIsDPNo4QAikVTg4",
                                 simplify = TRUE)
        df <- data.frame("Elevation" = elev$results$elevation)
      }
      else
        NULL
    }, digits = 0)
    
    output$download <- downloadHandler(
      filename = function() { paste("converted", ".csv", sep="") },
      content = function(file) {
        if(input$append == FALSE) {
          write.csv(convertedCoords(), file, row.names = FALSE)
        } else {
          x <- input$text
          if (is.null(x))
            return(NULL)
          x <- read.table(text = input$text, stringsAsFactors = FALSE)
          x <- sapply(x, gsub, pattern = "\U00B0", replacement = "\U00B0")
          x <- data.frame(matrix(x, ncol = 2, byrow = TRUE))
          x <- data.frame(matrix(sapply(x, as.character), ncol = 2, byrow = TRUE))
          x <- cbind(x, convertedCoords())
          names(x) <- c("lat.orig", "long.orig", "long.new", "lat.new")
          write.csv(x, file, row.names = FALSE, fileEncoding = "UTF-8")
        }
        
      }
    )
  })
  
  ### File input
  observeEvent(input$convertFile, {
    
    coordFileInput  <- reactive({
      x <- input$file
      if (is.null(x))
        return(NULL)
      else {
        if (input$fileFormat %in% "CSV") {
          x <- read.csv(x$datapath, header = FALSE, sep = input$sep, 
                        encoding = "UTF-8", stringsAsFactors = FALSE)
          x <- prepareCoords(x)
          x
        }
        else {
          gpx <- readGPX(x$datapath)
          x <- data.frame(lat = gpx$waypoints[,2], lon = gpx$waypoints[,1])
          x <- prepareCoords(x)
          x
        }
      }
    })
    
    output$coords <- renderTable({
      x <- input$file
      if (is.null(x))
        return(NULL)
      else {
        if (input$fileFormat %in% "CSV") {
      x <- read.csv(x$datapath, header = FALSE, sep = input$sep,
                    encoding = "UTF-8", stringsAsFactors = FALSE)
      colnames(x) <- c("lat", "lon")
      x
        }
        else {
          x <- readGPX(x$datapath)
          x <- x$waypoints[,1:2]
          x
        }}
    }, digits = 5)
      
    
    convertedCoords <- reactive({
      coordinates(convertFileToGK(coordFileInput(), crs = input$crs))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertFileToGK(coordFileInput(), crs = input$crs), crs = input$crs))
    })
    
    
    output$new.coords <- renderTable({
      coordinates(convertedCoords())
    }, digits = 2)
    
    output$selected.crs <- renderText({
      paste("CRS:", input$crs)
    })
    
    output$leaflet <- renderLeaflet({
      
      coordLabel <- apply(coordinates(coordsForLeaflet()), MARGIN = 1, FUN = function(z) {
        sprintf("long: %s lat: %s", z[1], z[2])
      })
      
      leaflet() %>%
        addProviderTiles(providers$OpenStreetMap.Mapnik,
                         options = providerTileOptions(noWrap = TRUE)) %>%
        addMarkers(data = coordsForLeaflet(), clusterOptions = markerClusterOptions(),
                   label = coordLabel) %>%
        addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE))
      
    })
    
    output$elevation <- renderTable({
      if (input$elevation == TRUE) { 
        elev <- google_elevation(df_locations = as.data.frame(coordsForLeaflet()),
                                 location_type = "individual", 
                                 key = "AIzaSyATwD1Zqpv8M0SPddTLIsDPNo4QAikVTg4",
                                 simplify = TRUE)
        df <- data.frame("Elevation" = elev$results$elevation)
      }
      else
        NULL
    }, digits = 0)
    
    output$download <- downloadHandler(
      filename = function() { paste("converted", ".csv", sep="") },
      content = function(file) {
        if(input$append == FALSE) {
          write.csv(convertedCoords(), file, row.names = FALSE)
        } else {
          x <- input$file
          if (is.null(x))
            return(NULL)
          x <- read.csv(x$datapath, header = FALSE, sep = input$sep,
                        encoding = "UTF-8", stringsAsFactors = FALSE)
          x <- sapply(x, gsub, pattern = "\U00B0", replacement = "\U00B0")
          print(x)
          x <- cbind(x,convertedCoords())
          colnames(x) <- c("lat.orig", "long.orig", "long.new", "lat.new")
          write.csv(x, file, row.names = FALSE, fileEncoding = "UTF-8")
        }
        
      }
    )
  })
  
  
})
