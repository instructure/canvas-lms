/*
 * This is just copied from node_modules parse-decimal-number.js but wrapped
 * with a requireJS define(...) wrapper. it is only needed for requireJS and can
 * be removed once we are all webpack.
 */

define([], function() {
  var options, patterns;

  patterns = [];

  options = {};

  var exports = function(value, inOptions) {
    var decimal, fractionPart, integerPart, number, pattern, patternIndex, result, thousands;
    if (typeof inOptions === 'string') {
      if (inOptions.length !== 2) {
        throw {
          name: 'ArgumentException',
          message: 'The format for string options is \'<thousands><decimal>\' (exactly two characters)'
        };
      }
      thousands = inOptions[0];
      decimal = inOptions[1];
    } else if (inOptions instanceof Array) {
      if (inOptions.length !== 2) {
        throw {
          name: 'ArgumentException',
          message: 'The format for array options is [\'<thousands>\',\'[<decimal>\'] (exactly two elements)'
        };
      }
      thousands = inOptions[0];
      decimal = inOptions[1];
    } else {
      thousands = (inOptions != null ? inOptions.thousands : void 0) || options.thousands;
      decimal = (inOptions != null ? inOptions.decimal : void 0) || options.decimal;
    }
    patternIndex = "" + thousands + decimal;
    pattern = patterns[patternIndex];
    if (!pattern) {
      pattern = patterns[patternIndex] = new RegExp('^\\s*(-?(?:(?:\\d{1,3}(?:\\' + thousands + '\\d{3})+)|\\d*))(?:\\' + decimal + '(\\d*))?\\s*$');
    }
    result = value.match(pattern);
    if (!result || result.length !== 3) {
      return NaN;
    }
    integerPart = result[1].replace(new RegExp("\\" + thousands, 'g'), '');
    fractionPart = result[2];
    number = parseFloat(integerPart + "." + fractionPart);
    return number;
  };

  exports.setOptions = function(newOptions) {
    var key, value;
    for (key in newOptions) {
      value = newOptions[key];
      options[key] = value;
    }
  };

  exports.factoryReset = function() {
    return options = {
      thousands: ',',
      decimal: '.'
    };
  };

  exports.factoryReset();

  return exports;
})
