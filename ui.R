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
    "Facebook Graph Analyzer", id="nav", windowTitle="Dataset",
    tabPanel("Dataset",
      fileInput('dbfile', 'Load Dataset ::'),
      #actionButton("goButton", "Query"),
      progressInit(),
      fluidRow(
        checkboxGroupInput('show_vars', '', names(DF), selected = names(c(DF[1],DF[3],DF[5],DF[7],DF[8],DF[11],DF[14])), inline = T),
        dataTableOutput(outputId="stream"),
        tags$head(tags$style("tfoot {display: table-header-group;}"))
    )
    ),
    tabPanel("Likers",
      fluidRow(
        dataTableOutput(outputId="likers"),
        tags$head(tags$style("tfoot {display: table-header-group;}")))
     ),
    tabPanel("Commenters",
             fluidRow(
               dataTableOutput(outputId="commenters"),
               tags$head(tags$style("tfoot {display: table-header-group;}")))
    ),
    tabPanel("Commenters Graph",
             mainPanel(
               plotOutput('commentersGraph', height = 1200, width = '100%')
             )
             ),
    tabPanel("Likers Graph",
             tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
             fluidRow(
               sidebarPanel(
               HTML('<b>GRAPH DASHBOARD</b><br /><br />'),
               conditionalPanel(
                 condition = "exists('g')",
                 downloadButton('downloadGraph', 'Download Graph (Gephi)')
               ),width = 2),
               mainPanel(
                 plotOutput('likersGraph', height = 1200, width = '100%')
                 )
    )
)
  )
)