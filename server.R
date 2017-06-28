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
source("saveData.R")

shinyServer(function(input, output) {
  
  #########################################
  ### SOME RANDOM BUT IMPORTANT OBJECTS ###
  #########################################
  
  output$epsg <- renderTable({
    epsg[,1:3]
  })
  
  cluster <- reactive({
    if (input$cluster == TRUE) { markerClusterOptions() } else { NULL }
  })
  output$leaflet <- renderLeaflet({
    leaflet() %>% 
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)) %>%
      addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE)) %>% 
      setView(lng = 14.47035, lat = 46.05120, zoom = 9)
  })
  
  
  #########################
  ### COORDINATES INPUT ###
  #########################
  
  textInput <- eventReactive(input$text, {
    x <- input$text
    if (is.null(x))
      return(NULL)
    else {
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x$input <- "text"
      saveData(x)
      x
    }
  })
  
  fileInput <- eventReactive(input$file, {
    x <- input$file
    if (is.null(x))
      return(NULL)
    else {
      if (grepl(pattern = ".csv", x$name, ignore.case = TRUE)) {
        x <- read.csv(x$datapath, header = FALSE, sep = input$sep, 
                      encoding = "UTF-8", stringsAsFactors = FALSE)
        x$input <- "CSV"
        saveData(x)
        x
      }
      else {
        gpx <- readGPX(x$datapath)
        x <- data.frame(lat = gpx$waypoints[,2], lon = gpx$waypoints[,1])
        x$input <- "GPX"
        saveData(x)
        x
      }
    }
  })
  
  observeEvent(input$pickFromMap, {
    
    clickInput <- reactive({
      click <- input$leaflet_click
      x <- data.frame(click$lat, click$lng)
      x$input <- "click"
      saveData(x)
      x
    })
  })
  
  originalCoords <- reactive({
    x <- get("input", envir = .GlobalEnv)
    print(x)
  })
  
  output$originalCoords <- renderTable({
    if (exists("originalCoords")) {
      originalCoords()
    } else { NULL }
  })
  
  
  ################################
  ### PREPARE & CONVERT COORDS ###
  ################################
  
  
  preparedCoords <- function(x) {
    if (exists("input", envir = .GlobalEnv)) {
      prepareCoords(responses[,1:2])
    } else { NULL }
  }
  
  convertedCoords <- reactive({
    if (exists("preparedCoords")) {
      coordinates(convertToGK(preparedCoords(), crs = input$crs))
    } else { NULL }
  })
  
  coordsForLeaflet <- reactive({
    if (exists("preparedCoords")) {
      coordinates(convertBackToWGS(convertToGK(preparedCoords, crs = input$crs), crs = input$crs))
    } else { NULL }
  })
  
  #########################
  ### OUTPUT & DOWNLOAD ###
  #########################
  
  crs <- reactive({
    crs <- input$crs
    crs
  })
  
  elevation <- reactive({
    if (input$add.elevation == TRUE) { 
      elev <- google_elevation(df_locations = as.data.frame(coordsForLeaflet()),
                               location_type = "individual", 
                               key = "AIzaSyATwD1Zqpv8M0SPddTLIsDPNo4QAikVTg4",
                               simplify = TRUE)
      df <- data.frame("elevation" = elev$results$elevation)
    }
    else
      NULL
  })
  
  
  output$coordsElevation <- renderTable({
    if (input$add.elevation == FALSE) {
      if (input$append == FALSE) {
        x <- data.frame(convertedCoords())
        colnames(x) <- c("new.lon", "new.lat")
        x
      } else {
        x <- data.frame(originalCoords(), convertedCoords())
        colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat")
        x
      }
    } else {
      if (input$append == FALSE) {
        x <- data.frame(convertedCoords(), elevation())
        colnames(x) <- c("new.lon", "new.lat", "elevation")
        x
      } else {
        x <- data.frame(originalCoords(), convertedCoords(), elevation())
        colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat", "elevation")
        x
      }
    }
  })
  
  output$selected.crs <- renderText({
    paste("CRS in use:", input$crs)
  })
  
  
  coordLabel <- apply(coordinates(coordsForLeaflet()), MARGIN = 1, FUN = function(z) {
    sprintf("lon: %s lat: %s", z[1], z[2])
  })
  
  observe({
    leafletProxy("leaflet", data = coordsForLeaflet()) %>% 
      addMarkers(data = coordsForLeaflet(), clusterOptions = cluster(),
                 label = coordLabel)
  })
  
  
  output$download <- downloadHandler(
    filename = function() { paste("converted", ".csv", sep="") },
    content = function(file) {
      if (input$add.elevation == FALSE) {
        if (input$append == FALSE) {
          x <- data.frame(convertedCoords())
          colnames(x) <- c("new.lon", "new.lat")
          write.csv(x, file, row.names = FALSE)
        } else {
          x <- data.frame(originalCoords(), convertedCoords())
          colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat")
          df <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE) 
          write.csv(df, file, row.names = FALSE)
        }
      } else {
        if (input$append == FALSE) {
          x <- data.frame(convertedCoords(), elevation())
          colnames(x) <- c("new.lon", "new.lat", "elevation")
          write.csv(x, file, row.names = FALSE)
        } else {
          x <- data.frame(originalCoords(), convertedCoords(), elevation())
          colnames(x) <- c("orig.lat", "orig.lon", "new.lon", "new.lat", "elevation")
          df <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE) 
          write.csv(df, file, row.names = FALSE)
        }
      }
    }
  )
  
})

#######################
### RESTART SESSION ###
#######################

observeEvent(input$removePoints, {
  base::rm(responses, envir = .GlobalEnv)
  output$leaflet <- renderLeaflet({
    leaflet() %>% 
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)) %>%
      addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE)) %>% 
      setView(lng = 14.47035, lat = 46.05120, zoom = 9)
  })
})