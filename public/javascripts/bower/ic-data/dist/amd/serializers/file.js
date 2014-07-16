define(
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var FileSerializer = BaseSerializer.extend({
      extractDeleteRecord: function(store, type, payload) {
        // payload is {delete: true} and then ember data wants to go ahead and set
        // the new properties, return null so it doesn't try to do that
        return null;
      }
    });

    __exports__["default"] = FileSerializer;
  });