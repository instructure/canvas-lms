define([
  'underscore'
], function(_) {
  // backward is a stupid requirement for discussions
  _.flattenObjects = function(array, key, backward, output) {
    if (!_.isArray(array)) {array = [array];}
    if (!_.isArray(output)) {output = [];}
    _.each(array, function(object) {
      output.push(object);
      if (object[key]) {
        children = object[key]
        if (backward) {
          children = _.clone(children)
          children.reverse()
        }
        _.flattenObjects(children, key, backward, output);
      }
    });
    return output;
  };
});
