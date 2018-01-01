#for scraping
library(rvest)
library(xml2)

#for cleanup and data manipulation
library(stringr)
library(dplyr)
library(tidyr)


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
  html_text() 


#making a dataframe for studio brussels
stubru <- data.frame(stubru_ranking, stubru_artist, stubru_title)


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
  html_text()

mnm <- data.frame(mnm_ranking, mnm_artist, mnm_title)



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

#cleaning up the dataframe
radio1 <- tidyr::separate(radio1_extract, 1, into= c("ranking","title", "artist"), sep="\n")
radio1$title <- str_trim(radio1$artist, side="both")
radio1$artist <- str_trim(radio1$title, side="both")
radio1$artist <- str_replace(radio1$title, "[0-9]+:[0-9]{2}", "")