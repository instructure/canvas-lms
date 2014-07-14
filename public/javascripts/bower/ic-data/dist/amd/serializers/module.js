define(
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseSerializer = __dependency1__["default"] || __dependency1__;

    var ModuleSerializer = BaseSerializer.extend({
      normalize: function(type, hash, prop){
        hash.links = hash.links || {};
        var url = hash.items_url;
        url = url.replace("https://localhost", "http://localhost:8080");
        hash.links.items = url;
        delete hash.items_url;
        return this._super(type, hash, prop);
      },

    });

    __exports__["default"] = ModuleSerializer;
  });