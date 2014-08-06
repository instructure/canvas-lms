define(function() {
  var INTERPOLATER = /\%\{([^\}]+)\}/g;

  /**
   * Stupid i18n interpolator that interpolates anything between %{} with
   * a value you pass in @options.
   *
   * @param {String} contents
   *        The i18n text block you're interpolating.
   *
   * @param {Object} options
   *        Pairs of variable names and their interpolation values.
   *        The variable names should be snake_cased.
   *
   * @return {String}
   *         The interpolated text.
   */
  return function i18nInterpolate(contents, options) {
    var variables = contents.match(INTERPOLATER);

    if (variables) {
      variables.forEach(function(variable) {
        var optionKey = variable.substr(2, variable.length - 3);
        contents = contents.replace(new RegExp(variable, 'g'), options[optionKey]);
      });
    }

    return contents;
  };
});