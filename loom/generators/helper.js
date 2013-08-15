var inflector = require('../lib/inflector');
var defaultGenerator = require('./default');

var generator = module.exports = Object.create(defaultGenerator);

generator.present = function(name) {
  return {
    helperName: inflector.camelize(name)
  };
};

