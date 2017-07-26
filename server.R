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
      names(x) <- c("orig.lat", "orig.lon")
      x
    })
    
    # output$coords <- renderTable({
    #   originalCoords()
    # }, digits = 5)
    
    output$coordsElevation <- renderTable({
      if (input$elevation == FALSE) {
        x <- data.frame(originalCoords(), convertedCoords())
      } else {
        data.frame(originalCoords(), convertedCoords(), elevation())
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
            write.csv(convertedCoords(), file, row.names = FALSE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords())
            df <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE) 
            write.csv(df, file, row.names = FALSE)
          }
        } else {
          if (input$append == FALSE) {
            x <- data.frame(convertedCoords(), elevation())
            write.csv(x, file, row.names = FALSE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords(), elevation())
            df <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE) 
            write.csv(df, file, row.names = FALSE)
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
    
    originalCoords <- reactive({
      x <- input$file
      if (is.null(x))
        return(NULL)
      else {
        if (input$fileFormat %in% "CSV") {
          x <- read.csv(x$datapath, header = FALSE, sep = input$sep,
                        encoding = "UTF-8", stringsAsFactors = FALSE)
          colnames(x) <- c("orig.lat", "orig.lon")
          x
        }
        else {
          x <- readGPX(x$datapath)
          x <- x$waypoints[ ,1:2]
          colnames(x) <- c("orig.lat", "orig.lon")
          x
        }}
    })
    
    convertedCoords <- reactive({
      coordinates(convertFileToGK(coordFileInput(), crs = input$crs))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertFileToGK(coordFileInput(), crs = input$crs), crs = input$crs))
    })
    
    output$coordsElevation <- renderTable({
      if (input$elevation == FALSE) {
        data.frame(originalCoords(), convertedCoords())
      } else {
        data.frame(originalCoords(), convertedCoords(), elevation())
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
            write.csv(convertedCoords(), file, row.names = FALSE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords())
            write.csv(x, file, row.names = FALSE)
          }
        } else {
          if (input$append == FALSE) {
            x <- data.frame(convertedCoords(), elevation())
            write.csv(x, file, row.names = FALSE)
          } else {
            x <- data.frame(originalCoords(), convertedCoords(), elevation())
            write.csv(x, file, row.names = FALSE)
          }
        }
      }
    )
    
  })
})
