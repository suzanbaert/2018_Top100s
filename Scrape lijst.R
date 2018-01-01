library(rvest)
library(xml2)
#library(httr)


#Webscraping etiquette: am i allowed to scrape this site?
robotstxt::paths_allowed("https://tijdloze.stubru.be")  
robotstxt::paths_allowed("https://tijdloze.stijnshome.be/lijst/2017")



#Via stijnshome

list2017_html <- read_html("https://tijdloze.stijnshome.be/lijst/2017")

list2017_html %>%
  html_nodes(css= ".lijst") %>%
  html_table()

