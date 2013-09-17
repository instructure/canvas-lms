var parent = require('./default');

var generator = module.exports = Object.create(parent);

generator.present = function(name) {
  // skip all the stuff inbetween
  var fields = arguments[arguments.length - 2];
  var locals = parent.present(name);
  locals.fields = parseFields(fields);
  return locals;
};

function parseFields(map) {
  var fields = [];
  for (var key in map) {
    fields.push({name: key, type: map[key], comma: ','});
  }
  if (fields.length) {
    fields[fields.length - 1].comma = '';
  }
  return fields;
}

