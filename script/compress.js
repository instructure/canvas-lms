var glob = require('glob');
var fs = require('fs');
var UglifyJS = require("uglify-js");

glob.sync("public/optimized/compiled/{*.js,**/*.js}", function (err, files) {
  console.log('Running UglifyJS on ' + files.length + ' files');
  files.forEach(function(file) {
    var result = UglifyJS.minify(file, {
      screw_ie8: true,
      source_map: false
    });
    fs.writeFileSync(file,result.code, {flag: 'w'}, function(err) {
      if (err) throw err;
    });
  });
})