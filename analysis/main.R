library('mongolite')
library('ggplot2')
library('reshape2')
library('RColorBrewer')
library('plyr')

con <- mongo("match_data", url = "mongodb://localhost:27017/battlerite")
match_data <- con$find()
# leagues: grandChampion = 7.champion = 6, diamond = 5, platinum = 4, gold = 3 . Silver = 2 , Bronze = 1
leaguesMap <- c("NoLeague","Bronze", "Silver", "Gold", "Platinum", "Diamond", "Champion", "GrandChampion")

match_data$league[match_data$league == 0] <- 'NoLeague'
match_data$league[match_data$league == 1] <- 'Bronze'
match_data$league[match_data$league == 2] <- 'Silver'
match_data$league[match_data$league == 3] <- 'Gold'
match_data$league[match_data$league == 4] <- 'Platinum'
match_data$league[match_data$league == 5] <- 'Diamond'
match_data$league[match_data$league == 6] <- 'Champion'
match_data$league[match_data$league == 7] <- 'GrandChampion'
match_data$league <- as.factor(match_data$league)

#teste <-as.data.frame.list(match_data)
#write.csv(teste, file="match_data.csv", na = "")

winRate <- function(c, ranked = FALSE, casual = FALSE) {
  filter <- match_data[match_data$champion == c,]
  
  if(ranked) {
    filter <- filter[filter$rank == 'RANKED',]
  }
  
  if(casual) {
    filter <- filter[filter$rank == 'UNRANKED',]
  }
  
  win <- filter[filter$won == TRUE,]
  loose <- filter[filter$won == FALSE,]
  all <- nrow(win) + nrow(loose)
  
  result_core <- (nrow(win)/all)
  result_core <- result_core *100
  
  return(formattable::percent(result_core,2))
}
gamesPlayed <- function(c = '') {
  
  filter <- match_data
  
  if(c != '') {
    filter <- match_data[match_data$champion == c,]
  }
  
  x2 <- filter[filter$match_type == "QUICK2V2",]
  x3 <- filter[filter$match_type == "QUICK3V3",]
  
  x2Ranked <- x2[x2$rank == 'RANKED',];
  x2UnRanked <- x2[x2$rank == 'UNRANKED',];
  
  x3Ranked <- x3[x3$rank == 'RANKED',];
  x3UnRanked <- x3[x3$rank == 'UNRANKED',];
  
  type <- c('2x2', 'ranked2v2' , 'unranked2v2', '3x3', 'ranked3v3', 'unranked3v3');
  delta <- c(nrow(x2)/4, nrow(x2Ranked)/4, nrow(x2UnRanked)/4, nrow(x3)/6, nrow(x3Ranked)/6, nrow(x3UnRanked)/6)
  
  df <- data.frame(type, delta)
  return(df);
}
getWinRateAll <- function() {
  champion_list <- unique(match_data$champion)
  options(stringsAsFactors = FALSE)
  data <- data.frame(stringsAsFactors=FALSE)

  for (i in champion_list) {
      data <- rbind(data, list(i, winRate(i), winRate(i, TRUE), winRate(i, FALSE, TRUE) ))
  }
  
  names(data) <- c("Champion", "WinRate", "RankedWinRate", 'CasualWinRate')
  return(data)
}

match_size <- length(unique(match_data$match_id))

all <- getWinRateAll()
all$Champion <- as.factor(all$Champion)

dat <- melt(all,id.vars = "Champion")

colourCount <- length((as.factor(all$Champion)))
getPalette = colorRampPalette(brewer.pal(9, "Set3"))

bar <- ggplot(dat, aes(Champion, value))
bar + facet_wrap(~variable) +
      geom_bar(aes(fill = Champion), stat = "identity") +
      ggtitle(paste("#Matches :", match_size)) +
      scale_y_continuous(limits = c(0,100)) +
      scale_fill_manual(values = getPalette(colourCount)) +
      theme(axis.text.x = element_text(angle=90, vjust=0.1, hjust=1))
      #scale_x_discrete(breaks=0:22, labels = c('A','Ba','Bo','C','D','E','F', 'I', 'Ja', 'Ju', 'L', 'O', 'Pea', 'Pes','Po', 'Ra','Ro', 'Ruh', 'Shi', 'Siri', 'Ta', 'Tho', 'V'))


parseTeams <- function(type = '2v2') {
  if(type == '2v2') { filter <- 'QUICK2V2'}
  if(type == '3v3') { filter <- 'QUICK3V3'}
  
  data <- match_data[match_data$match_type == filter,]
  
  keep <- c("match_id","champion", "won");
  ctxData <- data[keep]
  
  ctxSplitWon <- ctxData[ctxData$won == TRUE,]
  ctxSplitLost <- ctxData[ctxData$won == FALSE,]
  
  ctxSplitWon <- split(ctxSplitWon, ctxSplitWon$match_id)  
  ctxSplitLost <- split(ctxSplitLost, ctxSplitLost$match_id)  
  
  parsed <- data.frame(stringsAsFactors = FALSE)
  
  strAux <- ""
  
  for (i in ctxSplitWon) {
    for (champion in i$champion) {
      if(nchar(strAux) == 0) {
        if(champion == "Ruh Kaan") { champion <- c("RuhKann")}
        strAux <- paste(champion)
      } else {
        if(champion == "Ruh Kaan") { champion <- c("RuhKann")}
        strAux <- paste(strAux, champion)
      }
    }
    parsed <- rbind(parsed, list(strAux, TRUE))
    strAux <- ""
  }
  
  
  for (i in ctxSplitLost) {
    for (champion in i$champion) {
      if(nchar(strAux) == 0) {
        if(champion == "Ruh Kaan") { champion <- c("RuhKann")}
        strAux <- paste(champion)
      } else {
        if(champion == "Ruh Kaan") { champion <- c("RuhKann")}
        strAux <- paste(strAux, champion)
      }
    }
    parsed <- rbind(parsed, list(strAux, FALSE))
    strAux <- ""
  }
  
  names(parsed) <- c("Team", "Won")
  return(parsed)    
}
fixTeams <- function(x) {
  df <- character()
  for (i in x) {
    aux <- strsplit(i, " ")[[1]]
    aux <- sort(aux)
    aux <- paste(aux, collapse=' ')
    aux <- as.character(aux)
    df <- rbind(df, aux)
  }
  names(df) <- c("Team")
  return((df))
}

#=====================================================3v3===================

tt <- parseTeams('3v3')
tt$Team <- fixTeams(tt$Team)
names(tt) <- c("Team", "Won")

countSpaces <- function(s) { sapply(gregexpr(" ", s), function(p) { sum(p>=0) } ) }
cleanInvalidTeams <- function(teamList, case = '3v3') {
  if(case == '3v3') {
    return(teamList[ countSpaces(tt$Team) == 2, ])    
  }
  if(case == '2v2') {
    return(teamList[ countSpaces(tt$Team) == 1, ]) 
  }
}

validTeams <- cleanInvalidTeams(tt, '3v3')
validTeams$Team <- as.character(validTeams$Team)

validWinners <- validTeams[validTeams$Won == TRUE,]
validWinners<- count(validWinners)
validWinners$Won <- NULL

teste <- validWinners
teste <- teste[order(teste$freq, decreasing = TRUE),]
rownames(teste) <- NULL
teste <- teste[1:25,]

v3matches <- length(unique(match_data$match_id[match_data$match_type == 'QUICK3V3']))
colours <- length((as.factor(teste$Team)))
barWinners <- ggplot(teste, aes(Team, freq))
barWinners + geom_bar(aes(fill = Team), stat = 'identity') +
  scale_fill_manual(values = getPalette(colours)) +
  ggtitle(paste("# 3V3 Matches :", v3matches))


#===================================2v2========================

tt <- parseTeams('2v2')
tt$Team <- fixTeams(tt$Team)
names(tt) <- c("Team", "Won")

validTeams <- cleanInvalidTeams(tt, '2v2')
validTeams$Team <- as.character(validTeams$Team)

validWinners <- validTeams[validTeams$Won == TRUE,]
validWinners<- count(validWinners)
validWinners$Won <- NULL

teste <- validWinners
teste <- teste[order(teste$freq, decreasing = TRUE),]
rownames(teste) <- NULL
teste <- teste[1:25,]

v2matches <- length(unique(match_data$match_id[match_data$match_type == 'QUICK2V2']))
colours <- length((as.factor(teste$Team)))
barWinners <- ggplot(teste, aes(Team, freq))
barWinners + geom_bar(aes(fill = Team), stat = 'identity') +
  scale_fill_manual(values = getPalette(colours)) +
  ggtitle(paste("# 2V2 Matches :", v2matches))


#=================================Scatters=======================

t <- data.frame(match_data$champion,match_data$league,match_data$stats$damageDone,match_data$stats$abilityUses)
names(t) <- c("Champion", "League" ,"DamageDone", "abilityUses")

colours <- length((as.factor(t$Champion)))

scatter <- ggplot(t, aes(abilityUses, DamageDone))
scatter + geom_point(aes(colour = Champion)) +
  geom_smooth(method="lm") + scale_fill_manual(values = getPalette(colours)) +
  theme_bw() + facet_wrap( ~ League)


#================================DataByLeague===================

subset <- match_data[match_data$rank == "RANKED",]
subset <- subset[subset$league != "NoLeague",]
t <- data.frame(subset$champion,subset$league)
names(t) <- c("Champion", "League")

t <- count(t)
t<-t[order(t$League),]


barFreq <- ggplot(t, aes(Champion, freq))
barFreq + geom_bar(aes(fill = League), stat = 'identity') +
  scale_fill_brewer(palette="Dark2") +
  theme(axis.text.x = element_text(angle=90, vjust=0.1, hjust=1))

