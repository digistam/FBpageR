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
    "Facebook Analyzer", id="nav", windowTitle="Dataset",
    tabPanel("Dataset",
     
      fileInput('dbfile', 'Load Dataset ::'),
      #actionButton("goButton", "Query"),
      progressInit(),
      fluidRow(
        column(2,
               htmlOutput('Types'),
               offset = 0
        ),
        column(1,
               htmlOutput('stat_objectLikes'),
               offset = 1
        ),
        column(2,
               htmlOutput('stat_objectPosts'),
               offset = 2
        )),
      fluidRow(
        column(2,
               htmlOutput('stat_links'),
               offset = 0
        ),
        column(1,
               htmlOutput('stat_apps'),
               offset = 1
        ),
        column(2,
               htmlOutput('stat_video'),
               offset = 2
        ))

    ),
    
    tabPanel("DataTable",
#              fluidRow(
#                checkboxGroupInput('show_vars', '', names(DF), selected = names(c(DF[2],DF[4],DF[5],DF[7],DF[9],DF[10],DF[11],DF[12],DF[13],DF[14],DF[15],DF[16],DF[17],DF[21],DF[22])), inline = T)
#               ),
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
             dataTableOutput(outputId="likers"),
             tags$head(tags$style("tfoot {display: table-header-group;}"))
#              fluidRow(
#                dataTableOutput(outputId="likers"),
#                tags$head(tags$style("tfoot {display: table-header-group;}")))
    ),
    tabPanel("Authors Graph",
             plotOutput('authorsGraph', height = 1200, width = '100%')
#              mainPanel(
#                plotOutput('authorsGraph', height = 1200, width = '100%')
#              )
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
    )#,
#     tabPanel("Statistics",
#                fluidRow(
#                  column(5,
#                  htmlOutput('Types'),
#                  offset = 0
#                ),
#                column(5,
#                  htmlOutput('stat_objectLikes'),
#                  offset = 1
#                  )),
#                fluidRow(
#                column(5,
#                  htmlOutput('stat_objectPosts'),
#                  offset = 0
#                ),
#                column(5,
#                 htmlOutput('stat_links'),
#                 offset = 1
#                )),
#                fluidRow(
#                column(5,
#                 htmlOutput('stat_apps'),
#                 offset = 0
#                  ))
#     ),

#     tabPanel("Likers statistics",
#     fluidRow(
#       htmlOutput('stat_likers'),
#       HTML('<hr>')
#     )
#)
))