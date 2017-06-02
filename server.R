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

shinyServer(function(input, output) {
  
  ### Text input
  observeEvent(input$convertText, {
    
    coordInput <- reactive({
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x <- prepareCoords(x)
      x
    })
    
    convertedCoords <- reactive({
      coordinates(convertToGK(coordInput()))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertToGK(coordInput())))
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
      coordinates(convertFileToGK(coordFileInput()))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertFileToGK(coordFileInput())))
    })
    
    
    output$new.coords <- renderTable({
      coordinates(convertedCoords())
    }, digits = 2)
    
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
