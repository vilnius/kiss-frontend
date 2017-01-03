#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
library(magrittr)
library(shiny)
library(rgdal)
library(data.table)
library(geosphere)
library(DT)
library(dplyr)
library(dtplyr)

darzeliai <- readRDS("darzeliai.RDS") %>% sort
allkg <- fread("data/istaigos.csv", encoding = "UTF-8")
allkg1 <- data.frame(allkg) %>% filter(LABEL %in% darzeliai) %>% 
  select(LABEL, GIS_X, GIS_Y) %>% filter(GIS_X != 0)
coordinates(allkg1) <- c("GIS_X", "GIS_Y")
proj4string(allkg1) <- CRS("+init=epsg:3346")
tmp <- spTransform(allkg1, CRS("+proj=longlat +datum=WGS84"))
#apply(tmp@data, 1, function(x, ))



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  rv <- reactiveValues()
  
  observeEvent(input$go, {
    output$table <- DT::renderDataTable({
      prio <- input$twoyears + input$school + input$threemore +
        input$unable + input$lonely + (length(input$otherkids) > 0)
      if(input$city == "2") {
        prio <- prio + 1e2
      } else if (input$city == "3") {
        prio <- prio + 1e3
      }
      age <- (Sys.Date() - input$birthddate) %>% as.integer %>% 
        `%/%`(365)
      req(rv$home)
      req(rv$work)
      kgs <- data.frame(
        Darzelis = tmp@data, 
        Namai = distVincentyEllipsoid(tmp, rv$home)/1e3,
        Darbas = distVincentyEllipsoid(tmp, rv$work)/1e3
      )
    })
  })
  output$google_maps_API <- renderUI({
    connection_info <- readLines('private/google-api-key.csv')
    HTML(paste0(
            '<script async defer src=" https://maps.googleapis.com/maps/api/js?key=',
            connection_info,'&libraries=places&callback=initMap"></script>'
                )
        )
  })
  
  observeEvent(input$marker_lat, {
    req(input$marker_lat)
    req(input$marker_id == "home-map")
    rv$home <- c(input$marker_lng, input$marker_lat)
  })
  
  observeEvent(input$marker_lat, {
    req(input$marker_lat)
    req(input$marker_id == "work-map")
    rv$work <- c(input$marker_lng, input$marker_lat)
  })
  
  # output$coords <- renderUI({
  #   req(input$marker_id, input$marker_lat, input$marker_lng)
  #   tagList(
  #     div(input$marker_id),
  #     div(input$marker_lat),
  #     div(input$marker_lng)
  #   )
  #   
  #   #browser()
  # })
  
  
})
