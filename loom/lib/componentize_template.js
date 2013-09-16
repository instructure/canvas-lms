var inflector = require('./inflector');
var path = require('path');

// foo_bar/x_foo.hbs -> foo_bar/x-foo.hbs
module.exports = function(savePath) {
  var basename = inflector.dasherize(path.basename(savePath));
  var dirname = path.dirname(savePath);
  return dirname+'/'+basename;
};

