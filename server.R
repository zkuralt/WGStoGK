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
  
  textInput <- reactive({
    x <- input$text
    if (is.null(x))
      return(NULL)
    else {
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x$input <- "text"
      print(x)
      saveData(x)
    }
  })
  
  fileInput <- reactive({
    x <- input$file
    if (is.null(x))
      return(NULL)
    else {
      if (grepl(pattern = ".csv", x$name, ignore.case = TRUE)) {
        x <- read.csv(x$datapath, header = FALSE, sep = input$sep, 
                      encoding = "UTF-8", stringsAsFactors = FALSE)
        x <- prepareCoords(x)
        x
        x$input <- "CSV"
        saveData(x)
      }
      else {
        gpx <- readGPX(x$datapath)
        x <- data.frame(lat = gpx$waypoints[,2], lon = gpx$waypoints[,1])
        x
        x$input <- "GPX"
        saveData(x)
      }
    }
  })
  
  
  clickInput <- reactive({
    x <- input$leaflet_click
    if (is.null(x))
      return(NULL)
    else {
      click <- input$leaflet_click
      x <- data.frame(click$lat, click$lng)
      x
      x$input <- "click"
      saveData(x)
    }
  })
  
  
  output$originalCoords <- renderTable({
    if (!exists(responses))
      return(NULL)
    else {
      colnames(responses) <- c("lat", "lon")
      responses
    }
  })
  
  
  observeEvent(input$convert, {
    
    ################################
    ### PREPARE & CONVERT COORDS ###
    ################################
    
    
    preparedCoords <- prepareCoords(responses[,1:2])
    
    convertedCoords <- reactive({
      coordinates(convertToGK(preparedCoords(), crs = input$crs))
    })
    
    coordsForLeaflet <- reactive({
      coordinates(convertBackToWGS(convertToGK(preparedCoords, crs = input$crs), crs = input$crs))
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
})