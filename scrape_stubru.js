var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'scrape_stubru.html'

page.open('https://stubru.be/music/arcadefireopeenindeafrekening2017', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});