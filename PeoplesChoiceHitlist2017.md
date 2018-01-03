At the end of the year, everyone seems to be making lists. And radio
stations are no exceptions.  
Many of our radiostation have a weekly "people's choice" hitlist.
Throughout the week, people submit their top 3 recent songs and that
gets turned into a hitlist. At the end of the year, they collapse all
those weekly lists into a Year list.  
I find this one quite interesting because it's not dependent on what
people actually bought, but at what the audience of those radio stations
want to hear more of.

<br>

About the data
==============

I took different radio stations:

-   Radio 1: The most serious of our public broadcast stations. It's
    aimed at current affairs, politics, news, ...
-   Studio Brussels: Formerly known as the "rock station", but now it's
    really a mix of modern rock, pop, indie & dance music
-   MNM: it's described as the "contemporary hit radio station" of the
    public broadcast organisation
-   Q music: a commercial "contemporary hit radio station"

There is one annoying drawback here: Studio Brussels does a top 30,
while all the others do a top 100.

Before starting the scrape, I wanted to make sure that I was allowed to
do so using the rOpenSci robotstxt package:

    #Webscraping etiquette: am i allowed to scrape this site?
    robotstxt::paths_allowed("https://stubru.be/music/arcadefireopeenindeafrekening2017")
    robotstxt::paths_allowed("https://mnm.be/mnm50/dezesongstemdejijhetafgelopenjaartvaakstdemnm50")
    robotstxt::paths_allowed("https://open.spotify.com/embed/user/radio1be/playlist/5aeEaRJfIFF6lsxoN2IbRD")
    robotstxt::paths_allowed("https://qmusic.be/hitlijsten/favoriete-100-2017")

    ## [1] TRUE
    ## [1] TRUE
    ## [1] TRUE
    ## [1] TRUE

<br>

Loading all the packages needed:

    #for scraping
    library(rvest)
    library(xml2)

    #for cleanup and data manipulation
    library(stringr)
    library(dplyr)
    library(tidyr)

    #for graphing
    library(ggplot2)

<br>

Bad luck in normal scraping...
==============================

Trying the usual routine did not lead to any information. I used the
"Inspect Element" opion in my browser but no matter what I did no info
was obtained.

    #usual method
    read_html("https://stubru.be/music/arcadefireopeenindeafrekening2017") %>%
      html_nodes(css=".song-title")

    ## {xml_nodeset (0)}

The issue is that the website is rendered through Javascript so there is
no information yet when scraping. After a bit of googling I found [a
tutorial](https://www.datacamp.com/community/tutorials/scraping-javascript-generated-data-with-r)
that had all the answers I needed.

<br>

Scraping Javascript rendered websites
=====================================

Through `phantomJS` you can create a local copy of the website, which is
available for scraping afterwards.  
I opened a normal notepad and saved the following as `scrape_stubu.js`:

    var webPage = require('webpage');
    var page = webPage.create();

    var fs = require('fs');
    var path = 'scrape_stubru.html'

    page.open('https://stubru.be/music/arcadefireopeenindeafrekening2017', function (status) {
      var content = page.content;
      fs.write(path,content,'w')
      phantom.exit();
    });

<br>

Afterwards, you can use a `system` command in R to run the script and
return a local html version. You need `phantomJS` installed to do this,
but you can easily install it form
[here](http://phantomjs.org/download.html).

    #generate local copies of all required websites
    system("./phantomjs/bin/phantomjs scrape_stubru.js")
    system("./phantomjs/bin/phantomjs scrape_radio1.js")
    system("./phantomjs/bin/phantomjs scrape_qmusic.js")
    system("./phantomjs/bin/phantomjs scrape_mnm.js")

<br>

Scraping the data
=================

Many of the websites had quite similar structures so I wrote a function
to extract the ranking, artist and title from the website and return it
as a dataframe.

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

<br>

Using the function, three radio stations were easily scraped. Qmusic
needed a little bit of `stringr` to remove a few "/n" signs.

    #scraping studio brussels
    stubru <- scrape_music(html = "scrape_stubru.html", css_artist = ".song-title",
                                css_title = ".song-name", css_ranking=".song-position")
    colnames(stubru) <- c("stubru_ranking", "artist", "title")

    #scraping mnm
    mnm <- scrape_music(html = "scrape_mnm.html", css_artist = ".song-name",
                           css_title = ".song-title", css_ranking=".song-position")
    colnames(mnm) <- c("mnm_ranking", "artist", "title")

    #scraping mnm
    qmusic <- scrape_music(html = "scrape_qmusic.html", css_artist = ".title-bar",
                        css_title = ".subtitle", css_ranking=".hitlist-position")
    colnames(qmusic) <- c("qmusic_ranking", "artist", "title")
    qmusic$artist <- str_replace_all(qmusic$artist, "\\\n", "")
    qmusic$title <- str_replace_all(qmusic$title, "\\\n", "")

<br>

Radio 1 was the trickiest. They didn't actually have a website that
listed the songs, they just referred to a spotify playlist. I know
Spotify has an API to make life easier but as I had been scraping from
scratch, I just wanted to continue this way. I could not find seperate
CSS nodes for artist and title, but there was CSS node that contained
everything:

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

<br>

Comparing the radio stations
============================

Based on what I know of these stations, I would expect a huge overlap
between MNM and Qmusic given that they are both pop hit radios; a small
overlap between Studio Brussels and Radio 1 because they share some of
the softer indie and rock music, and very little overlap between the hit
radios and the two others. But am I right? I definitely won't bet my
wages against it...

    #studio brussels versus radio 1
    stubru %>%
      semi_join(radio1, by="title")

    ##    stubru_ranking                      artist                    title
    ## 1               1                 arcade fire           everything now
    ## 2               2                      bazart                    nacht
    ## 3               3              kendrick lamar                  humble.
    ## 4               6            the war on drugs      thinking of a place
    ## 5              13                      tamino                    cigar
    ## 6              17                      the xx                  on hold
    ## 7              18          oscar and the wolf                breathing
    ## 8              20                      delv!s              come my way
    ## 9              21                       elbow   magnificent (she says)
    ## 10             22 the chainsmokers & coldplay something just like this
    ## 11             23                       alt-j            in cold blood
    ## 12             26                      tamino                   habibi
    ## 13             27            the war on drugs               holding on
    ## 14             29                       coely             wake up call

    #studio brussels versus MNM
    stubru %>%
      semi_join(mnm, by="title")

    ##   stubru_ranking                      artist                    title
    ## 1              1                 arcade fire           everything now
    ## 2              7               van echelpoel             ziet em duun
    ## 3             10                  ed sheeran       castle on the hill
    ## 4             17                      the xx                  on hold
    ## 5             18          oscar and the wolf                breathing
    ## 6             22 the chainsmokers & coldplay something just like this
    ## 7             25             imagine dragons                  thunder

    mnm %>%
      semi_join(radio1, by="title")

    ##    mnm_ranking                                artist
    ## 1            3           the chainsmokers & coldplay
    ## 2            4                            ed sheeran
    ## 3           26                    oscar and the wolf
    ## 4           33            the weeknd feat. daft punk
    ## 5           39                      portugal the man
    ## 6           43                             sam smith
    ## 7           44                               blanche
    ## 8           70                           arcade fire
    ## 9           74                            bruno mars
    ## 10          77                                 drake
    ## 11          84                                the xx
    ## 12         100 nathaniel rateliff & the night sweats
    ##                       title
    ## 1  something just like this
    ## 2              shape of you
    ## 3                 breathing
    ## 4          i feel it coming
    ## 5             feel it still
    ## 6      too good at goodbyes
    ## 7               city lights
    ## 8            everything now
    ## 9        that's what i like
    ## 10             passionfruit
    ## 11                  on hold
    ## 12                   s.o.b.

    mnm %>%
      semi_join(qmusic, by="title") %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1    61
