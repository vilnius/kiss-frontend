#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(rgdal)
library(data.table)
library(geosphere)
darzeliai <- readRDS("darzeliai.RDS") %>% sort
allkg <- fread("data/istaigos.csv", encoding = "UTF-8")
allkg1 <- allkg %>% filter(LABEL %in% darzeliai) %>% 
  select(LABEL, GIS_X, GIS_Y) %>% filter(GIS_X != 0)
coordinates(allkg1) <- c("GIS_X", "GIS_Y")
proj4string(allkg1) <- CRS("+init=EPSG:3346")
tmp <- spTransform(allkg1, CRS("+proj=longlat +datum=WGS84"))
#apply(tmp@data, 1, function(x, ))



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  # output$distPlot <- renderPlot({
  #   
  #   # generate bins based on input$bins from ui.R
  #   x    <- faithful[, 2] 
  #   bins <- seq(min(x), max(x), length.out = input$bins + 1)
  #   
  #   # draw the histogram with the specified number of bins
  #   hist(x, breaks = bins, col = 'darkgray', border = 'white')
  #   
  # })
  observeEvent(input$go, {
    output$table <- renderTable({
      distVincentyEllipsoid(tmp, c(25.275,54.693))
      data.frame(a = 1:2, b = 3:4)
    })
    
  })
  
  
})
