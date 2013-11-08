var parent = require('./default');
var msg = require('loom/lib/message');
var generator = module.exports = Object.create(parent);

generator.present = function(name, params, env) {
  var locals = parent.present(name, params, env);
  locals.type = types[params.type];
  if (locals.type == null) {
    locals.type = promptControllerType();
  }
  return locals;
}

function promptControllerType() {
  var userInput = msg.prompt('What kind of controller: object, array, or neither? [o|a|n]');
  return types[userInput];
}

var types = {
  'n': '',
  'neither': '',
  'o': 'Object',
  'object': 'Object',
  'a': 'Array',
  'array': 'Array'
};

