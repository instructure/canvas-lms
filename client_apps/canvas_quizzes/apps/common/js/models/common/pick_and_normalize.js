define(function(require) {
  var convertCase = require('../../util/convert_case');
  var _ = require('lodash');
  var pick = _.pick;
  var camelize = convertCase.camelize;

  /**
   * @method pickAndNormalize
   * @member Models
   *
   * Pick certain keys out of an object, and converts them to camelCase.
   *
   * @param  {Object} set
   * @param  {String[]} keys
   * @return {Object}
   */
  return function pickAndNormalize(set, keys) {
    return camelize(pick(set || {}, keys));
  };
});