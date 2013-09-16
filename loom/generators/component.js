var componentize = require('../lib/componentize_template');
var validateComponent = require('../lib/validate_component');
var parent = require('./default');
var path = require('path');

var generator = module.exports = Object.create(parent);

generator.before = function(env) {
  parent.before(env);
  validateComponent(env.rawName);
};

generator.templates = [
  'app/components/component_component.coffee.hbs',
  'app/templates/components/component.hbs.hbs'
];

generator.savePath = function(template, env) {
  var savePath = parent.savePath(template, env);
  return isTemplate(savePath) ? componentize(savePath) : savePath;
}

function isTemplate(savePath) {
  return path.extname(savePath) === '.hbs';
}

