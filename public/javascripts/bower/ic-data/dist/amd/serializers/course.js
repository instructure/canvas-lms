define(
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var CourseSerializer = BaseSerializer.extend({
      extractDeleteRecord: function(store, type, payload) {
        // payload is {delete: true} and then ember data wants to go ahead and set
        // the new properties, return null so it doesn't try to do that
        return null;
      },
      normalize: function(type, hash, prop){
        hash.links = hash.links || {};
        var store = type.store;
        var adapter = store.adapterFor(type);
        hash.links.folder = adapter.urlPrefix() + '/courses/' + hash.id + '/folders/root';
        return this._super(type, hash, prop);
      }
    });

    __exports__["default"] = CourseSerializer;
  });