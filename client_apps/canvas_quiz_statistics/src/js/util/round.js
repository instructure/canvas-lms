define([], function() {
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
   * @param  {Number} [digits=2]
   *         Number of digits to round to.
   *
   * @return {Number}
   *         The rounded number, ready for human-consumption.
   */
  return function round(n, digits) {
    var scale;

    if (digits === undefined) {
      digits = 0;
    }

    if (typeof n !== 'number' || !(n instanceof Number)) {
      n = parseFloat(n);
    }

    scale = Math.pow(10, parseInt(digits, 10));
    n = Math.round(n * scale) / scale;

    return n;
  };
});