var parent = require('loom/lib/generic_generator');
var inflector = require('../lib/inflector');
var msg = require('loom/lib/message');

var generator = module.exports = Object.create(parent);

generator.before = function(env) {
  if (!env.args.length) {
    msg.error("You must specify a resource name, ie 'generate "+env.name+" user'");
  } else {
    var split = env.args[0].split('/');
    if (split.length < 2) {
      msg.error("You must specify an app name, ie 'generate "+env.name+" inbox/message'");
    }
    env.appName = split.shift();
    var name = split.join('/');
    env.rawName = name;
    env.args[0] = inflector.underscore(name);
  }
};

generator.savePath = function(template, env) {
  var savePath = parent.savePath(template, env);
  return savePath.replace(/^app/, 'app/coffeescripts/ember/'+env.appName);
};

generator.present = function(name) {
  var params = arguments[arguments.length - 2];
  var env = arguments[arguments.length - 1];
  if (appendable(env.name)) {
    name += '_'+env.name;
  }
  return {
    objectName: inflector.objectify(name),
    params: params
  };
};

generator.template = function(env) {
  var plural = inflector.pluralize(env.name);
  var append = appendable(env.name) ? '_'+env.name : '';
  return 'app/'+plural+'/'+env.name+append+'.coffee.hbs';
};

function appendable(generatorName) {
  var types = ['component', 'controller', 'route', 'view'];
  return types.indexOf(generatorName) > -1;
}

