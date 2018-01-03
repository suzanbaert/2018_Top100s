var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'scrape_radio1.html'

//former link, but actually refers to playground
//page.open('https://radio1.be/vox-100-de-lijst-2017', function (status) {

//new link
page.open('https://playground.radio1.be/vox100/2017/index.html', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});