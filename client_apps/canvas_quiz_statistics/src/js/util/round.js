define([ '../config' ], function(config) {
  /**
   * @member Util
   * @method round
   * Round a number to N digits.
   *
   * TODO: import as a Canvas package (we have it in util/round.coffee)
   *
   * @param  {Number|String} n
   *         Your number
   *
   * @param  {Number} [digits=config.precision]
   *         Precision of the returned float (number of digits after the
   *         decimal point.)
   *
   * @return {Float}
   *         The rounded number, ready for human-consumption.
   */
  return function round(n, precision) {
    var scale;

    if (precision === undefined) {
      precision = config.precision;
    }

    if (typeof n !== 'number' || !(n instanceof Number)) {
      n = parseFloat(n);
    }

    return n.toFixed(precision);
  }
});