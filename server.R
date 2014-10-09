options(shiny.maxRequestSize=100*1024^2)
library(lubridate)
if (!require("lubridate")) {
  install.packages("lubridate", repos="http://cran.rstudio.com/") 
  library("lubridate") 
}
shinyServer(function(input, output, session) {
  observe({
    inFile<-input$dbfile
    print(inFile)
    if(is.null(inFile))
      return(NULL)
    connectSQL(inFile$datapath)
    dbtbl <- dbListTables(con)
    
    output$stream <- renderDataTable({
      #input$goButton
      isolate({
        q <- dbGetQuery(con, "SELECT * FROM stream ORDER BY date DESC")
        DF <- as.data.frame.matrix(q)
        DF$date <- as.POSIXct(DF$date,format = "%Y-%m-%dT%H:%M:%S+0000", tz = "UTC")
        DF$date <- with_tz(DF$date, "Europe/Paris")
        #         DF$date <- as.POSIXct(DF$created_at,format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
        #         DF$created_at <- with_tz(DF$created_at, "Europe/Paris")
        #         DF$followers <- as.numeric(DF$followers)
        #         DF <<- DF
        DF
      })
      DF[, input$show_vars, drop = FALSE]
    })
  })
})