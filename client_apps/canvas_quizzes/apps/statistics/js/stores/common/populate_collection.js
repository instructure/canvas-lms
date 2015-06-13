define(function() {
  /**
   * Populate a collection with some data.
   *
   * @method populateCollection
   * @member Statistics.Stores
   *
   * @param {Backbone.Collection} collection
   * @param {Object} payload
   *        The payload to extract data from. This is what you received by
   *        hitting the Canvas JSON-API endpoints.
   *
   * @param {Boolean} [replace=true]
   *        Consider the incoming data as a replacement for the current one.
   *        E.g, the collections will be reset instead of just adding the
   *        new data.
   *
   */
  return function populateCollection(collection, payload, replace) {
    var setter, setterOptions;

    if (arguments.length === 2) {
      replace = true;
    }

    setter = replace ? 'reset' : 'add';
    setterOptions = replace ?
      { parse: true } :
      { parse: true, merge: true };

    collection[setter].call(collection, payload, setterOptions);
  };
});