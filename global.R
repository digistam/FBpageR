if (!require("RSQLite")) {
  install.packages("RSQLite", repos="http://cran.rstudio.com/") 
  library("RSQLite") 
}
if (!require("igraph")) {
  install.packages("igraph", repos="http://cran.rstudio.com/") 
  library("igraph") 
}
if (!require("tm")) {
  install.packages("tm", repos="http://cran.rstudio.com/") 
  library("tm") 
}
windowsFonts(Arial=windowsFont("TT Arial"))
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
DF <- data.frame(replicate(17,sample(0:1,20,rep=TRUE)))
names(DF) <- c("post_id","id","object_id","object_name","actor","actor_id","date","message","story","link","description","comments","likes","application","like_id","liker","liker_id")

as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}

textMine <- function(x) {
  DF.corpus <- Corpus(VectorSource(x))
  DF.corpus <- tm_map(DF.corpus, removePunctuation)
  DF.stopwords <- c(stopwords('english'), stopwords('dutch'))
  DF.corpus <- tm_map(DF.corpus, removeWords, DF.stopwords)
  DF.dtm <<- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(2,10)))
}