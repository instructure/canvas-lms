define(function() {
  /**
   * @method fromJSONAPI
   * @member Models
   *
   * Given a JSON payload, extract an object that *might* be scoped inside
   * a named JSON-API collection key. In the case that key does not exist,
   * regular JSON payload is assumed and the top-level object is returned.
   *
   * @param {Object} payload
   *
   * @param {String} collKey
   *        Key to the primary collection you expect to exist in the payload.
   *
   * @param {Boolean} [wantsObject=false]
   *        In the case the extracted object turns out to be an array, you can
   *        pass this to true and retrieve the first item in the array.
   *        It is common for JSON-API payloads to wrap single objects in an
   *        array.
   *
   * @return {Object|Array}
   */
  return function fromJSONAPI(payload, collKey, wantsObject) {
    var data = {};

    if (payload) {
      if (payload[collKey]) {
        data = payload[collKey];
      }
      else {
        data = payload;
      }
    }

    if (wantsObject && Array.isArray(data)) {
      return data[0];
    }
    else {
      return data;
    }
  };
});