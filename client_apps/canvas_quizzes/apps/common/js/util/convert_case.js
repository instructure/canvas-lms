define((require) => {
  const Inflections = require('./inflections');
  const camelizeStr = Inflections.camelize;
  const underscoreStr = Inflections.underscore;

  return {
    // Convert all property keys in an object to camelCase
    camelize (props) {
      let prop;
      const attrs = {};

      for (prop in props) {
        if (props.hasOwnProperty(prop)) {
          attrs[camelizeStr(prop, true)] = props[prop];
        }
      }

      return attrs;
    },

    underscore (props) {
      let prop;
      const attrs = {};

      for (prop in props) {
        if (props.hasOwnProperty(prop)) {
          attrs[underscoreStr(prop)] = props[prop];
        }
      }

      return attrs;
    }
  };
});
