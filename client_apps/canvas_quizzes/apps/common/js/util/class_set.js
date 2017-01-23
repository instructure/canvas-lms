define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  /**
   * @member Util
   *
   * Shim for React.addons.classSet.
   *
   * @param  {Object} set
   *         A set of class strings and booleans. If the boolean is truthy,
   *         the class will be appended to the className.
   *
   * @return {String}
   *         The produced class string ready for use as a className prop.
   */
  const classSet = function (set) {
    return Object.keys(set).reduce((classes, key) => {
      if (set[key]) {
        classes.push(key);
      }

      return classes;
    }, []).join(' ');
  };

  return (React.addons || {}).classSet || classSet;
});
