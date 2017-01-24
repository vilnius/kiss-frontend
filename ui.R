#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
library(magrittr)
library(shiny)
library(data.table)

#seniunija <- readRDS("dists.RDS") %>% sort 
seniunija <- fread("data/seniunijos.csv", encoding = "UTF-8")
# darzeliai <- readRDS("darzeliai.RDS") %>% sort
darzeliai <- fread("data/darzeliai.csv", encoding = "UTF-8") %>% 
  arrange(LABEL)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  tags$link(rel = "stylesheet", type = "text/css", href = "maps.css"),
  tags$script(src = "addMap.js"),
  tags$script("
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-72198439-2', 'auto');
  ga('send', 'pageview');"),
  
  # Application title
  tags$a(
    tags$img(src='vilnius-logo.svg', class="city-logo"),
    href="http://www.vilnius.lt"),
  titlePanel("Kindergarten Info System (KISS)"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      dateInput("birthdate", "Gimimo data", min = "2009-01-01",
                max = "2030-01-01"),
      selectizeInput("district", label = "Pasirinkite seniūnijas, kuriose bent vienas iš tėvų registruotas ne mažiau 2 metų",
                     choices = setNames(seniunija$ID, seniunija$LABEL), 
                     multiple = TRUE),
      selectizeInput(
        "city", label = "Deklaruoti mieste",
        choices = setNames(1:3, c("Abu tėvai", "Vienas iš tėvų",
                                  "Nei vienas iš tėvų"))),
      # checkboxInput(
      #   "twoyears",
      #   label = "Bent vienas iš tėvų registruotas Vilniuje ne mažiau 2 metų?"),
      checkboxInput(
        "school",
        label = "Vienas iš tėvų mokosi bendrojo ugdymo mokykloje?"),
      # checkboxInput("citydeclared", label = "Deklaruotas mieste"),
      checkboxInput("threemore", label = "3 ir daugiau"),
      checkboxInput("unable", label = "Žemas darbingumas"),
      conditionalPanel(
        condition = "input.city == 1", 
        checkboxInput("lonely", label = "Augina 1 iš tėvų")
      ),
      checkboxInput("otherkids", label = "Ar turite kitų vaikų Vilniaus darželiuose?"),
      conditionalPanel(
        condition = "input.otherkids",
        selectizeInput("otherkg", label = "Kuriuose?",
                       choices = setNames(darzeliai$ID, darzeliai$LABEL), 
                       multiple = TRUE)
      ),
      selectizeInput(
        "language", label = "Kalba", 
        choices = setNames(1:4, c("Hebrajų", "Lenkų", "Lietuvių", "Rusų")),
        selected = 3),
      checkboxInput("special", label = "Specialūs poreikiai"),
      checkboxInput("disclaimer", label = "Suprantu, kad šis įrankis yra tik rekomendacinio pobūdžio, ir tikroji eilė gali skirtis nuo prognozuojamos."),
      actionButton("go", label = "Prognozuoti")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      fluidRow(
        column(6,
               HTML('<input id="home-input" class="controls" type="text" placeholder="Namų adresas">'),
               div(id='home-map')      
        ),
        column(6,
               HTML('<input id="work-input" class="controls" type="text" placeholder="Darbovietės adresas">'),
               div(id='work-map')
        )
      ),
      #plotOutput("distPlot")
      uiOutput("priority"),
      uiOutput("no_work_home"),
      tags$h4("Rezultatai"),
      DT::dataTableOutput("table")
    )
  ),
  uiOutput("google_maps_API")#,
  # uiOutput("coords")
))
