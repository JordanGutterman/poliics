# Jusgeships

library(httr)
library(readr)
library(dplyr)

# Data exports from FJC (https://www.fjc.gov/history/judges/biographical-directory-article-iii-federal-judges-export):
# 1. By-judge file: https://www.fjc.gov/sites/default/files/history/judges.csv
# 2. by-category files: Demographics, Federal Judicial Service, Other Federal Judicial Service, Education, 
#    Professional Career, Other Nominations/Recess Appointments

judgesConn <- GET(url = "https://www.fjc.gov/sites/default/files/history/judges.csv")
judgesOrig <- content(judgesConn, type = "text/csv")


# Durations
judges <- judges %>%
  mutate(durationNomToReferral = `Committee Referral Date (1)` - `Nomination Date (1)`,
         durationReferralToHearing = `Hearing Date (1)` - `Committee Referral Date (1)`,
         durationHearingToCmteAction = ,
         durationCmteActionToSenateVote = )


# Ideas: durations
# to longform (just gather by (x))
# ABA ratings
# everything by prez
# join by senator & party
