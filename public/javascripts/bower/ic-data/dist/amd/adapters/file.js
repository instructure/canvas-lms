define(
  ["./base","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var BaseAdapter = __dependency1__["default"] || __dependency1__;

    var FileAdapter = BaseAdapter.extend({
      createRecord: function(store, type, record) {
        var data = {};
        var serializer = store.serializerFor(type.typeKey);
        var url = this.urlPrefix()+'/accounts/'+record.get('account_id')+'/courses';
        record.set('account_id', null);
        serializer.serializeIntoHash(data, type, record, { includeId: true });
        return this.ajax(url, "POST", { data: data });
      },

      deleteRecord: function(store, type, record) {
        var id = record.get('id');
        var data = { event: 'delete' };
        return this.ajax(this.buildURL(type.typeKey, id), "DELETE", {data: data});
      }
    });

    __exports__["default"] = FileAdapter;
  });