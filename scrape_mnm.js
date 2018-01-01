var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'scrape_mnm.html'

page.open('https://mnm.be/mnm50/dezesongstemdejijhetafgelopenjaartvaakstdemnm50', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});