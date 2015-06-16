define(function() {
  return {
    camelize: function(str, lowerFirst) {
      return (str || '').replace (/(?:^|[-_])(\w)/g, function (_, c, index) {
        if (index === 0 && lowerFirst) {
          return c ? c.toLowerCase() : '';
        }
        else {
          return c ? c.toUpperCase () : '';
        }
      });
    },

    underscore: function(str) {
      return str.replace(/([A-Z])/g, function($1){
        return '_' + $1.toLowerCase();
      });
    }
  };
});