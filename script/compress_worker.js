const fs = require('fs');
const UglifyJS = require("uglify-js");

process.on('message', function(filename) {
  // console.log('minifying ', filename)
  // var start = new Date();
  var result = UglifyJS.minify(filename, {
    screw_ie8: true,
    source_map: false
  });
  fs.writeFileSync(filename, result.code, {flag: 'w'})
  // console.log('minified   ' + filename + ' in ' + (new Date() - start)/1000 + 's')
  process.send('complete');
});