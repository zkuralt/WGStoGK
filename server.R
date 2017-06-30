library(shiny)
library(sp)
library(measurements)
library(leaflet)
library(rgdal)
library(googleway)
library(plotKML)
library(DBI)
source("anyWGStoDec.R")
source("testElements.R")
source("convertBackToWGS.R")
source("convertToGK.R")
source("prepareCoords.R")

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
  
  observeEvent(input$submitText, {
    x <- read.table(text = input$text, stringsAsFactors = FALSE)
    colnames(x) <- c("lat", "lon")
    x$type <- "text"
    saveData(x, path)
    x
  })
  
  observeEvent(input$submitFile, {
    x <- input$file
    if (is.null(x))
      return(NULL)
    else {
      if (grepl(pattern = ".csv", x$name, ignore.case = TRUE)) {
        x <- read.csv(x$datapath, header = FALSE, sep = input$sep,
                      encoding = "UTF-8", stringsAsFactors = FALSE)
        colnames(x) <- c("lat", "lon")
        x$type <- "CSV"
        message(class(mydb))
        saveData(x, path)
        x
      }
      else {
        gpx <- readGPX(x$datapath)
        x <- data.frame(lat = gpx$waypoints[,2], lon = gpx$waypoints[,1])
        x$type <- "GPX"
        message(class(mydb))
        saveData(x, path)
        x
      }
    }
  })
  
  observeEvent(input$pickFromMap, {
    observeEvent(input$leaflet_click, {
      click <- input$leaflet_click
      if (is.null(click))
        return(NULL)
      else {
        x <- data.frame(lat = click$lat, lon = click$lng)
        x$type <- "click"
        x[, 1:2] <- round(x[, 1:2], 5)
        saveData(x, path)
        x
      }
    })
  })
  
  observeEvent(c(input$submitText, input$submitFile, input$leaflet_click), {
    output$inputCoords <- renderTable({
      x <- loadData(path)
      x <- x[nrow(x):1, ]
      x
    }, rownames = TRUE)
    
    ############################
    ### DISPLAY INPUT ON MAP ###
    ############################
    
    preparedCoords <- reactive({
      x <- loadData(path)
      x <- x[nrow(x):1, ]
      prepareCoords(x[, 1:2])
    })
    
    coordsForLeaflet <- reactive({
      x <- preparedCoords()
      if (all(is.na(x))) return(NULL)
      
      coordinates(convertBackToWGS(convertToGK(x, crs = input$crs), crs = input$crs))
    })
    
    if (!is.null(coordsForLeaflet())) {
      coordLabel <- apply(coordinates(coordsForLeaflet()), MARGIN = 1, FUN = function(z) {
        sprintf("lon: %s lat: %s", z[1], z[2])
      })
      leafletProxy("leaflet", data = coordsForLeaflet()) %>%
        addMarkers(clusterOptions = cluster())
    } 
    
  })
  
  ######################
  ### CONVERT COORDS ###
  ######################
  
  convertedCoords <- reactive({
    if (exists("preparedCoords")) {
      coordinates(convertToGK(preparedCoords(), crs = input$crs))
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
    if (input$addElevation == TRUE) { 
      elev <- google_elevation(df_locations = as.data.frame(coordsForLeaflet()),
                               location_type = "individual", 
                               key = "AIzaSyATwD1Zqpv8M0SPddTLIsDPNo4QAikVTg4",
                               simplify = TRUE)
      df <- data.frame("elevation" = elev$results$elevation)
    }
    else
      NULL
  })
  
  
  observeEvent(input$convert, {
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
  })
  
  output$selectedCRS <- renderText({
    paste("CRS in use:", input$crs)
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
  
  dbRemoveTable(mydb, "input") # removes table
  
  output$leaflet <- renderLeaflet({ # reloads map
    leaflet() %>% 
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)) %>%
      addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE)) %>% 
      setView(lng = 14.47035, lat = 46.05120, zoom = 9)
  })
  
  on.exit({
    dbDisconnect(mydb)
    unlink(path)
  })
})
