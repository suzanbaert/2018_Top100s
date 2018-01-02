


robotstxt::paths_allowed("https://www.relisten.be/playlists/radio1/01-01-2018.html")


html_page <- read_html("https://www.relisten.be/playlists/radio1/01-01-2018.html")

#extracting song info
output <- html_page %>%
  html_nodes(css = ".media-body") %>%
  html_text() %>%
  tolower() %>%
  as.data.frame()

output %>%
  separate(output, title, artist, sep="\n")
