library(rvest)
library(xml2)
#library(httr)


#Webscraping etiquette: am i allowed to scrape this site?
robotstxt::paths_allowed("https://tijdloze.stubru.be")  
robotstxt::paths_allowed("https://tijdloze.stijnshome.be/lijst/2017")
robotstxt::paths_allowed("https://stubru.be/music/arcadefireopeenindeafrekening2017")



#Via stijnshome

list2017_html <- read_html("https://tijdloze.stijnshome.be/lijst/2017")

list2017_html %>%
  html_nodes(css= ".lijst") %>%
  html_table()




#eindafrekening

#generated a phantomJS script to create a rendered local html site
system("./phantomjs/bin/phantomjs scrape_stubru.js")

#scrape the local site
afrekening_html <- read_html("afrekening2017.html")

#extract the song info
artist <- afrekening_html %>%
  html_nodes(css =".song-title") %>%
  html_text()


title <- afrekening_html %>%
  html_nodes(css =".song-name") %>%
  html_text()


ranking <- afrekening_html %>%
  html_nodes(css =".song-position") %>%
  html_text()

data.frame(ranking, artist, title)

typeof(ranking)
class(ranking)

