# judges with a db
library(DBI)
library(RPostgreSQL)
library(dbplyr)

dbSafeNames = function(names) {
  names = gsub('[^a-z0-9]+','_',tolower(names))
  names = make.names(names, unique=TRUE, allow_=TRUE)
  names = gsub('.','_',names, fixed=TRUE)
  names
}

judgesOrig <- read.csv("https://www.fjc.gov/sites/default/files/history/judges.csv")
names(judgesOrig) <- dbSafeNames(names(judgesOrig))


db <- dbConnect(RPostgreSQL::PostgreSQL(), dbname = "judges", user = "postgres", password = "admin")
dbWriteTable(db, 'judge', judgesOrig)

sel <- dbGetQuery(db, "SELECT nid, jid FROM judge")
