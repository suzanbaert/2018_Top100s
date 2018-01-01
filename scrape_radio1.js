var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'scrape_radio1.html'

page.open('https://open.spotify.com/embed/user/radio1be/playlist/5aeEaRJfIFF6lsxoN2IbRD', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});