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
   
  output$epsg <- renderTable({
    epsg[,1:3]
  })
  
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
    
    originalCoords <- reactive({
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x <- data.frame(matrix(x, ncol = 2, byrow = TRUE))
      names(x) <- c("lat", "lon")
      x
    })
    
    output$coords <- renderTable({
      originalCoords()
    }, digits = 5)
    
    output$coordsElevation <- renderTable({
      if (input$elevation == FALSE) {
        x <- data.frame(convertedCoords())
      } else {
        data.frame(convertedCoords(), elevation())
      }
    })
    
    output$selected.crs <- renderText({
      paste("CRS in use:", input$crs)
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
    
    elevation <- reactive({
      if (input$elevation == TRUE) { 
        elev <- google_elevation(df_locations = as.data.frame(coordsForLeaflet()),
                                 location_type = "individual", 
                                 key = "AIzaSyATwD1Zqpv8M0SPddTLIsDPNo4QAikVTg4",
                                 simplify = TRUE)
        df <- data.frame("elevation" = elev$results$elevation)
      }
      else
        NULL
    })
    
    output$download <- downloadHandler(
      filename = function() { paste("converted", ".csv", sep="") },
      content = function(file) {
        if (input$add.elevation == FALSE) {
          if (input$append == FALSE) {
            x <- data.frame(convertedCoords())
            colnames(x) <- c("new.lon", "new.lat")
            write.csv(x, file, row.names = FALSE, col.names = TRUE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords())
            colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat")
            df <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE) 
            write.csv(df, file, row.names = FALSE, col.names = TRUE)
          }
        } else {
          if (input$append == FALSE) {
            x <- data.frame(convertedCoords(), elevation())
            colnames(x) <- c("new.lon", "new.lat", "elevation")
            write.csv(x, file, row.names = FALSE, col.names = TRUE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords(), elevation())
            colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat", "elevation")
            df <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE) 
            write.csv(df, file, row.names = FALSE, col.names = TRUE)
          }
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
        if (grepl(pattern = ".csv", x$name, ignore.case = TRUE)) {
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
    
    originalCoords <- reactive({
      x <- input$file
      if (is.null(x))
        return(NULL)
      else {
        if (grepl(pattern = ".csv", x$name, ignore.case = TRUE)) {
          x <- read.csv(x$datapath, header = FALSE, sep = input$sep,
                        encoding = "UTF-8", stringsAsFactors = FALSE)
          colnames(x) <- c("lat", "lon")
          x
        }
        else {
          x <- readGPX(x$datapath)
          x <- x$waypoints[,1:2]
          colnames(x) <- c("lat", "lon")
          x
        }}
    })
    
    output$coords <- renderTable({
      originalCoords()
    }, digits = 5)
    
    convertedCoords <- reactive({
      coordinates(convertFileToGK(coordFileInput(), crs = input$crs))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertFileToGK(coordFileInput(), crs = input$crs), crs = input$crs))
    })
    
    output$coordsElevation <- renderTable({
      if (input$elevation == FALSE) {
        x <- data.frame(convertedCoords())
      } else {
        data.frame(convertedCoords(), elevation())
      }
    })
    
    output$selected.crs <- renderText({
      paste("CRS in use:", input$crs)
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
    
    elevation <- reactive({
      if (input$elevation == TRUE) { 
        elev <- google_elevation(df_locations = as.data.frame(coordsForLeaflet()),
                                 location_type = "individual", 
                                 key = "AIzaSyATwD1Zqpv8M0SPddTLIsDPNo4QAikVTg4",
                                 simplify = TRUE)
        df <- data.frame("elevation" = elev$results$elevation)
      }
      else
        NULL
    })
    
    output$download <- downloadHandler(
      filename = function() { paste("converted", ".csv", sep="") },
      content = function(file) {
        if (input$add.elevation == FALSE) {
          if (input$append == FALSE) {
            x <- data.frame(convertedCoords())
            colnames(x) <- c("new.lon", "new.lat")
            write.csv(x, file, row.names = FALSE, col.names = TRUE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords())
            colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat")
            write.csv(x, file, row.names = FALSE, col.names = TRUE)
          }
        } else {
          if (input$append == FALSE) {
            x <- data.frame(convertedCoords(), elevation())
            colnames(x) <- c("new.lon", "new.lat", "elevation")
            write.csv(x, file, row.names = FALSE, col.names = TRUE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords(), elevation())
            colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat", "elevation")
            write.csv(x, file, row.names = FALSE, col.names = TRUE)
          }
        }
      }
    )
    
  })
})
