if (!require("RSQLite")) {
  install.packages("RSQLite", repos="http://cran.rstudio.com/") 
  library("RSQLite") 
}
connectSQL <- function(x) {
  set.seed(111)
  drv <<- dbDriver("SQLite")
  con <<- dbConnect(drv, x)
  dbListTables(con)
}
queryTable <- function(x) {
  set.seed(111)
  q <- dbGetQuery(con, paste("SELECT * FROM ", x, "", sep=""))
  DF <<- as.data.frame(q)
}
DF <- data.frame(replicate(12,sample(0:1,20,rep=TRUE)))
names(DF) <- c("id",         "object_id",        "object_name",   "post_id",   
               "actor",      "actor_id",         "date",          "message",   
               "story",     "comments",         "likes",    "application")  