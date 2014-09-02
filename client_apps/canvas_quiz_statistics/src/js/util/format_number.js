define([ '../config' ], function(config) {
  /**
   * @member Util
   * @method formatNumber
   * Format a decimal number into a human-readable string.
   * Examples:
   *
   *     83.2222224 => "83.22"
   *     25 => "25.00"
   *     24.94 => "24.94"
   *
   * @param  {Number|String} n
   *         Your number
   *
   * @param  {Number} [precision=config.precision]
   *         Precision of the returned float (number of digits after the
   *         decimal point.)
   *
   * @return {String}
   *         The formatted number, ready for rendering.
   */
  return function formatNumber(n, precision) {
    if (precision === undefined) {
      precision = config.precision;
    }

    if (typeof n !== 'number' || !(n instanceof Number)) {
      n = parseFloat(n);
    }

    return n.toFixed(parseInt(precision, 10));
  };
});