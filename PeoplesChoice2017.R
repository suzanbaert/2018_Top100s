#for scraping
library(rvest)
library(xml2)

#for cleanup and data manipulation
library(stringr)
library(dplyr)
library(tidyr)

#for graphing
library(ggplot2)
library(patchwork)


#Webscraping etiquette: am i allowed to scrape this site?
robotstxt::paths_allowed("https://stubru.be/music/arcadefireopeenindeafrekening2017")
robotstxt::paths_allowed("https://mnm.be/mnm50/dezesongstemdejijhetafgelopenjaartvaakstdemnm50")
robotstxt::paths_allowed("https://open.spotify.com/embed/user/radio1be/playlist/5aeEaRJfIFF6lsxoN2IbRD")



#######
#Studio Brussels
#######

#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_stubru.js")


#scrape the local site
stubru_html <- read_html("scrape_stubru.html")

#extract the song info
stubru_artist <- stubru_html %>%
  html_nodes(css =".song-title") %>%
  html_text() %>%
  tolower()


stubru_title <- stubru_html %>%
  html_nodes(css =".song-name") %>%
  html_text() %>%
  tolower()


stubru_ranking <- stubru_html %>%
  html_nodes(css =".song-position") %>%
  html_text() %>%
  as.numeric()


#making a dataframe for studio brussels
stubru <- data.frame(stubru_ranking, stubru_artist, stubru_title, stringsAsFactors = FALSE)
colnames(stubru) <- c("stubru_ranking", "artist", "title")


#######
#MNM
#######


#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_mnm.js")


#scrape the local site
mnm_html <- read_html("scrape_mnm.html")

#extract the song info
mnm_title <- mnm_html %>%
  html_nodes(css =".song-title") %>%
  html_text() %>%
  tolower()


mnm_artist <- mnm_html %>%
  html_nodes(css =".song-name") %>%
  html_text() %>%
  tolower()


mnm_ranking <- mnm_html %>%
  html_nodes(css =".song-position") %>%
  html_text() %>%
  as.numeric()


mnm <- data.frame(mnm_ranking, mnm_artist, mnm_title, stringsAsFactors = FALSE)
colnames(mnm) <- c("mnm_ranking", "artist", "title")



#######
#RADIO 1
#######

#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_radio1.js")


#scrape the local site
radio1_html <- read_html("scrape_radio1.html")


#extract the song info
radio1_extract <- radio1_html %>%
  html_nodes(css =".track-row") %>%
  html_text() %>%
  tolower() %>%
  as.data.frame()

#cleaning up the dataframe-
radio1 <- tidyr::separate(radio1_extract, 1, into= c("radio1_ranking","title", "artist"), sep="\n")
radio1$title <- str_trim(radio1$title, side="both")
radio1$artist <- str_trim(radio1$artist, side="both")
radio1$artist <- str_replace(radio1$artist, "[0-9]+:[0-9]{2}", "")
radio1$radio1_ranking <- as.numeric(radio1$radio1_ranking)





#commonalities
stubru %>%
  semi_join(radio1, by="title") %>%
  semi_join(mnm, by="title")


stubru %>%
  semi_join(radio1, by="title")

stubru %>%
  semi_join(mnm, by="title")

mnm %>%
  semi_join(radio1, by="title")


#joining them all.
#can't join artist as well due to inconsistencies in naming artists, see chainsmokers and coldplay as example
all_stations_messy <- stubru %>%
  full_join(mnm, by="title") %>%
  full_join(radio1, by="title")

#if empty take the artist name from the other list
all_stations_messy$artist.x <- ifelse(!is.na(all_stations_messy$artist.x), all_stations_messy$artist.x, all_stations_messy$artist.y)
all_stations_messy$artist.x <- ifelse(!is.na(all_stations_messy$artist.x), all_stations_messy$artist.x, all_stations_messy$artist)
all_stations_messy$artist <- all_stations_messy$artist.x

all_stations <- all_stations_messy %>%
  select(artist, title, stubru_ranking, mnm_ranking, radio1_ranking)


all_stations_messy$artistjoin <- ifelse(is.na(all_stations_messy$artist.x), 
                                        ifelse(is.na(all_stations_messy$artist.y), all_stations_messy$artist, 
                                        all_stations_messy$artist.y),
                                        all_stations_messy$artist.x)

str(all_stations)



#plotting stubru versus radio 1
stubru %>%
  inner_join(radio1, by="title") %>%
  unite(combo, artist.x, title, sep=" - ") %>%
  ggplot(aes(x=stubru_ranking, y=radio1_ranking, label = combo))+
    geom_point(colour="cadetblue4") +
    scale_x_reverse(name = "Studio Brussels ranking", limits=c(32,0)) +
    scale_y_reverse(name = "Radio 1 ranking") +
    geom_text(vjust = 0, nudge_y = 1, colour="cadetblue4")+
    ggtitle("Comparing Studio Brussels versus Radio1")


stubru %>%
  inner_join(radio1, by="title") %>%
  unite(combo, artist.x, title, sep=" - ") %>%
  ggplot(aes(x=stubru_ranking, y=radio1_ranking, label = combo))+
  geom_point(colour="cadetblue4") +
  scale_x_reverse(name = "Studio Brussels ranking", limits=c(30,15)) +
  scale_y_reverse(name = "Radio 1 ranking", limits=c(100,60)) +
  geom_text(vjust = 0, nudge_y = 1, colour="cadetblue4")+
  ggtitle("Comparing Studio Brussels versus Radio1 (zoomed on mid section")



#pltting mnm versus radio 1
mnm %>%
  inner_join(radio1, by="title") %>%
  unite(combo, artist.x, title, sep=" - ") %>%
  ggplot(aes(x=mnm_ranking, y=radio1_ranking, label = combo))+
  geom_point(colour="cadetblue4") +
  scale_x_reverse(name = "MNM ranking") +
  scale_y_reverse(name = "Radio 1 ranking") +
  geom_text(vjust = 0, nudge_y = 1, colour="cadetblue4")+
  ggtitle("Comparing MNM versus Radio1")


#plotting stubru versus mnm
stubru %>%
  inner_join(mnm, by="title") %>%
  unite(combo, artist.x, title, sep=" - ") %>%
  ggplot(aes(x=stubru_ranking, y=mnm_ranking, label = combo))+
  geom_point(colour="cadetblue4") +
  scale_x_reverse(name = "Studio Brussels ranking", limits=c(32,0)) +
  scale_y_reverse(name = "MNM ranking") +
  geom_text(vjust = 0, nudge_y = 1, colour="cadetblue4")+
  ggtitle("Comparing Studio Brussels versus MNM")
