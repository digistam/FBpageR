if (!require("shiny")) {
  install.packages("shiny", repos="http://cran.rstudio.com/") 
  library("shiny") 
}
if (!require(devtools)) {
  install.packages("devtools")
  devtools::install_github("rstudio/shiny-incubator")
}
library(shinyIncubator)

shinyUI(
  
  navbarPage(  
    "Facebook Data Analyzer", id="nav", windowTitle="Dataset",
    tabPanel("Dataset",
      fileInput('dbfile', 'Load Dataset ::'),
      #actionButton("goButton", "Query"),
      fluidRow(
        checkboxGroupInput('show_vars', '', names(DF), selected = names(c(DF[3],DF[5],DF[7],DF[8])), inline = T),
        dataTableOutput(outputId="stream"),
        tags$head(tags$style("tfoot {display: table-header-group;}"))
    )
    ),
    tabPanel("Actors",
      fluidRow(
        dataTableOutput(outputId="influence"),
        tags$head(tags$style("tfoot {display: table-header-group;}")))
     ),
    tabPanel("Graph",
             fluidRow(
               sidebarPanel(
               sliderInput('visibleNodes', 'Minimal degree', 2, min = 2, max = 5, step = 1),
               sliderInput('highDegree', 'Define high degree', 20, min = 1, max = 100, step = 1),
               sliderInput('labelSizeHighDegree', 'Label size high degree', 3, min = 1, max = 10, step = 1),
               sliderInput('labelSizeLowerDegree', 'Label size lower degree', 0.9, min = 0.5, max = 3, step = 0.1),
               sliderInput('labelSizeLowDegree', 'Label size lowest degree', 0.5, min = 0, max = 2, step = 0.1),
               HTML('<br /><br />'),
               conditionalPanel(
                 condition = "exists('ng')",
                 downloadButton('downloadGraph', 'Download Graph (Gephi)')
               ),width = 2),
               mainPanel(
                 plotOutput('newGraph', height = 1200, width = '100%')
                 )
    )
)
    #     tabPanel("TimeSeries",
    #              
    #              p('dataset: '),
    #              
    #              textOutput('Time_myKeyword'),
    #              
    #              fluidRow(
    #                htmlOutput('timeSeries')),
    #              p(),
    #              sliderInput('timeSlider', 'Period in hours', 12, min =1, max = 24, step = 1),
    #              checkboxInput("useSlider", "Unlimited period", FALSE),
    #              verbatimTextOutput('sliderinfo')
    #     ),
  )
)