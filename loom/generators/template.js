var path = require('path');
var parent = require('./default');
var componentize = require('../lib/componentize_template');
var validateComponent = require('../lib/validate_component');
var generator = module.exports = Object.create(parent);

generator.before = function(env) {
  parent.before(env);
  if (isComponent(env.rawName)) {
    validateComponent(env.rawName);
  }
};

generator.template = function(env) {
  if (isComponent(env.rawName)) {
    return 'app/templates/components/component.hbs.hbs';
  } else {
    return 'app/templates/template.hbs.hbs';
  }
};

generator.savePath = function(template, env) {
  if (isComponent(env.rawName)) {
    var name = env.args[0].replace(/components\//, '');
    return componentize(path.dirname(template)+'/'+name+'.hbs');
  } else {
    return parent.savePath(template, env);
  }
};

function isComponent(name) {
  return name.match(/^components\//);
}

