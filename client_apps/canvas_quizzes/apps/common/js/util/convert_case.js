define(function(require) {
  var Inflections = require('./inflections');
  var camelizeStr = Inflections.camelize;
  var underscoreStr = Inflections.underscore;

  return {
    // Convert all property keys in an object to camelCase
    camelize: function(props) {
      var prop;
      var attrs = {};

      for (prop in props) {
        if (props.hasOwnProperty(prop)) {
          attrs[camelizeStr(prop, true)] = props[prop];
        }
      }

      return attrs;
    },

    underscore: function(props) {
      var prop;
      var attrs = {};

      for (prop in props) {
        if (props.hasOwnProperty(prop)) {
          attrs[underscoreStr(prop)] = props[prop];
        }
      }

      return attrs;
    }
  };
});