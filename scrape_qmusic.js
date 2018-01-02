var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'scrape_qmusic.html'

page.open('https://qmusic.be/hitlijsten/favoriete-100-2017', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});