define(
  ["ember-data","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var RESTSerializer = __dependency1__.RESTSerializer;

    var BaseSerializer =  RESTSerializer.extend({
      normalizePayload: function(primaryType, payload){
        var data = {};
        if (Array.isArray(payload)) {
          data[primaryType.typeKey+'s'] = payload;
        } else {
          data[primaryType.typeKey] = payload;
        }
        return data;
      },

      extractMeta: function(store, type, payload){
        if(payload.meta && payload.meta.next){
          payload.meta.next = payload.meta.next.replace("https://localhost", "http://localhost:8080");
        }
        this._super(store, type, payload);
      }
    });

    __exports__["default"] = BaseSerializer;
  });