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
robotstxt::paths_allowed("https://qmusic.be/hitlijsten/favoriete-100-2017")



#function to scrap info
scrape_music <- function(html, css_artist, css_title, css_ranking) {
  html_page <- read_html(html)
  
  #extracting song info
  artist <- html_page %>%
    html_nodes(css = css_artist) %>%
    html_text() %>%
    tolower()
  
  #extracting artist info
  title <- html_page %>%
    html_nodes(css = css_title) %>%
    html_text() %>%
    tolower()
  
  #extracting ranking
  ranking <- html_page %>%
    html_nodes(css = css_ranking) %>%
    html_text() %>%
    as.numeric()
  
  #making a dataframe
  df <- data.frame(ranking, artist, title, stringsAsFactors = FALSE)
  return(df)
}



#######
#Studio Brussels
#######


#not working version
read_html("https://stubru.be/music/arcadefireopeenindeafrekening2017") %>%
  html_nodes(css=".song-title")



#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_stubru.js")


#scraping studio brussels
stubru <- scrape_music(html = "scrape_stubru.html", css_artist = ".song-title",
                            css_title = ".song-name", css_ranking=".song-position")
colnames(stubru) <- c("stubru_ranking", "artist", "title")



#######
#MNM
#######


#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_mnm.js")


#scraping mnm
mnm <- scrape_music(html = "scrape_mnm.html", css_artist = ".song-name",
                       css_title = ".song-title", css_ranking=".song-position")
colnames(mnm) <- c("mnm_ranking", "artist", "title")



#######
#QMUSIC
#######

#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_qmusic.js")


#scraping mnm
qmusic <- scrape_music(html = "scrape_qmusic.html", css_artist = ".title-bar",
                    css_title = ".subtitle", css_ranking=".hitlist-position")
colnames(qmusic) <- c("qmusic_ranking", "artist", "title")
qmusic$artist <- str_replace_all(qmusic$artist, "\\\n", "")
qmusic$title <- str_replace_all(qmusic$title, "\\\n", "")



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
  semi_join(mnm, by="title") %>%
  semi_join(qmusic, by="title")

radio1 %>%
  semi_join(mnm, by="title") %>%
  semi_join(qmusic, by="title")



st_ra <- stubru %>%
  semi_join(radio1, by="title") %>%
  count()

paste("Studio Brussels and Radio1 have", st_ra, "songs in common (out of 30)")

stubru %>%
  semi_join(mnm, by="title")

stubru %>%
  semi_join(qmusic, by="title")



mnm %>%
  semi_join(radio1, by="title")

mnm %>%
  semi_join(qmusic, by="title") %>%
  count()


compare_songs <- function(x, y, name.x, name.y) {
  count <- x %>%
    semi_join(y, by="title") %>%
    count()
  
  paste("Songs in common between", name.x, "and", name.y, ":", count)
  }

compare_songs(stubru, mnm, "Studio Brussels", "MNM")

#studio Brussels versus Radio1
sr <- stubru %>%
  semi_join(radio1, by="title") %>%
  count()
paste("Songs in common between Studio Brussels and Radio1:", sr, "(out of 30)")





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



#plotting stubru versus radio 1
radio1 %>%
  inner_join(stubru, by="title") %>%
  unite(combo, artist.x, title, sep=" - ") %>%
  ggplot(aes(x=radio1_ranking, y=stubru_ranking, label = combo))+
  geom_point(colour="cadetblue4") +
  scale_y_reverse(name = "Studio Brussels ranking", limits=c(32,0)) +
  scale_x_reverse(name = "Radio 1 ranking") +
  geom_text(vjust = 0, nudge_y = 1, colour="cadetblue4")+
  ggtitle("Comparing Radio 1 and Studio Brussels")

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


#plotting stubru versus mnm
qmusic %>%
  inner_join(mnm, by="title") %>%
  unite(combo, artist.x, title, sep=" - ") %>%
  ggplot(aes(x=qmusic_ranking, y=mnm_ranking, label = combo))+
  geom_point(colour="cadetblue4") +
  scale_x_reverse(name = "Q music ranking") +
  scale_y_reverse(name = "MNM ranking") +
  geom_text(vjust = 0, nudge_y = 1, colour="cadetblue4")+
  ggtitle("Comparing Q music versus MNM")

