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
    "", id="nav", windowTitle="Dataset",
    tabPanel("Dataset",
      fileInput('dbfile', 'load database file:'),
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
               downloadButton('downloadGraph', 'Download Graph (Gephi)'),
               plotOutput('newGraph', height = 1200, width = '100%')
    ))
  )
)