define([], function () {

  function camelizeString(str, lowerFirst) {
    return (str || '').replace (/(?:^|[-_])(\w)/g, function (_, c, index) {
      if (index === 0 && lowerFirst) {
        return c ? c.toLowerCase() : '';
      }
      else {
        return c ? c.toUpperCase () : '';
      }
    });
  }

  function underscoreString(str) {
    return str.replace(/([A-Z])/g, function($1){
      return '_' + $1.toLowerCase();
    });
  }

  return {
    // Convert all property keys in an object to camelCase
    camelize: function(props) {
      var prop;
      var attrs = {};

      for (prop in props) {
        if (props.hasOwnProperty(prop)) {
          attrs[camelizeString(prop, true)] = props[prop];
        }
      }

      return attrs;
    },

    underscore: function(props) {
      var prop;
      var attrs = {};

      for (prop in props) {
        if (props.hasOwnProperty(prop)) {
          attrs[underscoreString(prop)] = props[prop];
        }
      }

      return attrs;
    }
  };

});