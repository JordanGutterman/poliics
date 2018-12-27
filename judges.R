# Jusgeships

library(httr)
library(readr)
library(tidyr)
library(dplyr)
library(ggplot2)

# Data exports from FJC (https://www.fjc.gov/history/judges/biographical-directory-article-iii-federal-judges-export):
# 1. By-judge file: https://www.fjc.gov/sites/default/files/history/judges.csv
# 2. by-category files: Demographics, Federal Judicial Service, Other Federal Judicial Service, Education, 
#    Professional Career, Other Nominations/Recess Appointments

judgesConn <- GET(url = "https://www.fjc.gov/sites/default/files/history/judges.csv")
judgesOrig <- content(judgesConn, type = "text/csv")
#judgesOrig <- read.csv("https://www.fjc.gov/sites/default/files/history/judges.csv",
#                       check.names = F, stringsAsFactors = F)

# needed to make column numeric
judgesOrig$`Degree Year (1)` <- gsub("ca. ", "", judgesOrig$`Degree Year (1)`)
judgesOrig$`Degree Year (2)` <- gsub("1949-1951", "1950", judgesOrig$`Degree Year (2)`)

# Switch additional appointments to longform 
judges <- NULL
for (i in 1:3) { # todo: 4 has some, 5,6 have 1
  thisJudge <- judgesOrig %>%
    select(nid, contains(paste0("(",i,")")))
  
  newNames <- substr(names(thisJudge), 1, nchar(names(thisJudge)) - 4)
  newNames[1] <- "nid"
  names(thisJudge) <- make.names(newNames)
  
  # class alignments
  thisJudge$Degree.Year <- as.numeric(thisJudge$Degree.Year)
  
  # Remove judges without this iteration of a judgship
  thisJudge <- filter(thisJudge, !is.na(Court.Name))
  
  judges <- bind_rows(judges, thisJudge)
}

# Add back the other data
otherData <- judgesOrig %>%
  select(nid:`Race or Ethnicity`, `Professional Career`, `Other Nominations/Recess Appointments`)
judges <- judges %>%
  left_join(otherData, by = "nid")

# Calculate some durations
judges <- judges %>%
  mutate(durationNomToReferral = as.double(Committee.Referral.Date - Nomination.Date),
         durationReferralToHearing = as.double(Hearing.Date - Committee.Referral.Date),
         durationHearingToCmteAction = as.double(Committee.Action.Date - Hearing.Date),
         durationCmteActionToSenateVote = as.double(Confirmation.Date - Committee.Action.Date),
         durationTotal = as.double(Confirmation.Date - Nomination.Date))

# Add a numeric variable for President's Party (0=D, 1=R)
judges <- judges %>%
  mutate(Pres.Party = as.factor(case_when(Party.of.Appointing.President == "Democratic" ~ "D",
                                          Party.of.Appointing.President == "Republican" ~ "R")))

# Add the party control of the senate on the date of confirmation
# Issue: doesn't take into account the nomination date
senate_control <- read.csv("senate_control.csv") %>%
  mutate(Senate.Control = as.factor(ifelse(Rep > Dem, "R", "D")))

judges <- judges %>%
  mutate(Conf.Year = as.numeric(format(Confirmation.Date,'%Y'))) %>%
  left_join(senate_control, by = c("Conf.Year" = "Year"))

# Party control of senate = pres
judges <- judges %>%
  mutate(Party.Full.Control = Pres.Party == Senate.Control)

# After Carter
modernJudges <- judges %>%
  filter(Nomination.Date > as.Date("1976-01-20"))

judgesByPrez <- judges %>%
  filter(!is.na(Appointing.President),
         !(Appointing.President == "None (assignment)" |
             Appointing.President == "None (reassignment)")) %>%
  group_by(Appointing.President) %>%
  summarise(mean = mean(durationTotal, na.rm = T),
            median = median(durationTotal, na.rm = T))

judgesByCourt <- judges %>%
  group_by(Court.Type) %>%
  summarise(mean = mean(durationTotal, na.rm = T),
            median = median(durationTotal, na.rm = T))

# Graphs
plot(judges$Nomination.Date, judges$durationTotal)
plot(modernJudges$Nomination.Date, modernJudges$durationTotal)
judgesByPrez$mean <- as.double(judgesByPrez$mean)
plot(judgesByPrez$Appointing.President, judgesByPrez$mean)
ggplot(judgesByPrez, aes(x=Appointing.President, y=mean))

prezChanges <- as.Date(c("1981-01-20","1989-01-20","1993-01-20","2001-01-20","2009-01-20","2017-01-20"))

ggplot(data = modernJudges, aes(x=Nomination.Date, y=durationTotal)) +
  geom_point() +
  geom_vline(xintercept = prezChanges) +
  geom_smooth()


# Ideas: durations
# ABA ratings
# everything by prez
# join by senator & party
# table with gridextra

