#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

seniunija <- readRDS("dists.RDS")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  tags$link(rel = "stylesheet", type = "text/css", href = "maps.css"),
  tags$script(src = "addMap.js"),
  
  # Application title
  #tags$img(src='')
  titlePanel("Kindergarten Info System (KISS)"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      # strong("Gimimo data"),
      # selectizeInput("birthyear", label = "Metai", 
      #                choices = 2009:2017),
      # selectizeInput("birthmonth", label = "Mėnuo", 
      #                choices = 1:12),
      # selectizeInput("birthday", label = "Diena",
      #                choices = 1:30),
      dateInput("birthddate", "Gimimo data", min = "2009-01-01",
                max = "2030-01-01"),
      selectizeInput("district", label = "Seniūnija",
                     choices = seniunija),
      checkboxInput("city", label = "Deklaruotas mieste"),
      checkboxInput("3more", label = "3 ir daugiau"),
      checkboxInput("unable", label = "Žemas darbingumas"),
      checkboxInput("lonely", label = "Augina 1 iš tėvų"),
      actionButton("go", label = "Prognozuoti")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       #plotOutput("distPlot")

      fluidRow(
        column(6,
               div(id='map')      
        ),
        column(6,
               div(id='map2')
        )
      )
    )
  ),
  uiOutput("google_maps_API")
))
