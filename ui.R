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
    "Facebook Feed Analyzer", id="nav", windowTitle="Dataset",
    tabPanel("Dataset",
      fileInput('dbfile', 'Load Dataset ::'),
      #actionButton("goButton", "Query"),
      progressInit(),
      fluidRow(
        checkboxGroupInput('show_vars', '', names(DF), selected = names(c(DF[4],DF[5],DF[7],DF[8],DF[10],DF[11],DF[12],DF[13],DF[14],DF[17])), inline = T)
        ),
      fluidRow(
        
        dataTableOutput(outputId="stream"),
        tags$head(tags$style("tfoot {display: table-header-group;}"))
    )
    ),

    tabPanel("Authors",
             fluidRow(
               
               dataTableOutput(outputId="authors"),
               tags$head(tags$style("tfoot {display: table-header-group;}")))
    ),
    tabPanel("Likers",
             
             fluidRow(
               dataTableOutput(outputId="likers"),
               tags$head(tags$style("tfoot {display: table-header-group;}")))
    ),
    tabPanel("Authors Graph",
             mainPanel(
               plotOutput('authorsGraph', height = 1200, width = '100%')
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
    ),
    tabPanel("Statistics",
             mainPanel(
               
               fluidRow(
                 column(5,
                 htmlOutput('Types'),
                 #plotOutput('Types', height = 400, width = 400)
                 HTML('<hr>')
               ),
               column(5,
                 htmlOutput('stat_objectLikes')
                 )),
               fluidRow(
               column(5,
                 htmlOutput('stat_objectPosts')
               ),
               column(5,
                # tags$head(tags$style("tfoot {display: hidden;}")),
                # HTML('<h1><b>Links</b></h1>'),
                # dataTableOutput(outputId = 'stat_links'),
                htmlOutput('stat_links'),
                HTML('<hr>')
               )),
               fluidRow(
               column(5,
                 # HTML('<h1><b>Applications</b></h1>'),
                 # dataTableOutput(outputId = 'stat_apps'),
                htmlOutput('stat_apps'),
                HTML('<hr>')
                 ))
             )
    ),
    tabPanel("Likers statistics",
    fluidRow(
      htmlOutput('stat_likers'),
      HTML('<hr>')
    )
  ))
)