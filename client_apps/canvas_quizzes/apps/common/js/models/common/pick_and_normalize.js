define((require) => {
  const convertCase = require('../../util/convert_case');
  const _ = require('lodash');
  const pick = _.pick;
  const camelize = convertCase.camelize;

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
  return function pickAndNormalize (set, keys) {
    return camelize(pick(set || {}, keys));
  };
});
